#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset


DATAROOTDIR="/usr/share"
SYSCONFDIR="/etc"
SPHINXCFG="/etc/piler/sphinx.conf"
PILER_HOST=${PILER_HOST:-archive.yourdomain.com}
PILER_CONF="/etc/piler/piler.conf"
CONFIG_SITE_PHP="/etc/piler/config-site.php"
CONFIG_PHP="/var/piler/www/config.php"

create_dir_if_not_exist() {
   [[ -d $1 ]] || mkdir $1
}

create_mysql_db() {
   echo "Creating mysql database"

   sed -e "s%MYSQL_HOSTNAME%${MYSQL_HOSTNAME}%g" \
       -e "s%MYSQL_DATABASE%${MYSQL_DATABASE}%g" \
       -e "s%MYSQL_USERNAME%${PILER_USER}%g" \
       -e "s%MYSQL_PASSWORD%${MYSQL_PILER_PASSWORD}%g" \
       "${DATAROOTDIR}/piler/db-mysql-root.sql.in" | \
       mysql -h "$MYSQL_HOSTNAME" -u root --password="$MYSQL_ROOT_PASSWORD"

   mysql -h "$MYSQL_HOSTNAME" -u "$PILER_USER" --password="$MYSQL_PILER_PASSWORD" "$MYSQL_DATABASE" < "${DATAROOTDIR}/piler/db-mysql.sql"

   echo "Done."
}


pre_seed_sphinx() {
   echo "Writing sphinx configuration"
   sed -e "s%MYSQL_HOSTNAME%${MYSQL_HOSTNAME}%" \
       -e "s%MYSQL_DATABASE%${MYSQL_DATABASE}%" \
       -e "s%MYSQL_USERNAME%${PILER_USER}%" \
       -e "s%MYSQL_PASSWORD%${MYSQL_PILER_PASSWORD}%" \
       -e "s%220%311%" \
       -e "s%type = mysql%type = mysql\n   sql_sock = /var/run/mysqld/mysqld.sock%" \
       "${SYSCONFDIR}/piler/sphinx.conf.dist" > "$SPHINXCFG"

   echo "Done."

   echo "Initializing sphinx indices"
   su "$PILER_USER" -c "indexer --all --config ${SYSCONFDIR}/piler/sphinx.conf"
   echo "Done."
}


fix_configs() {
   local piler_nginx_conf="/etc/piler/piler-nginx.conf"

   if [[ ! -f "$PILER_CONF" ]]; then
      cp /etc/piler/piler.conf.dist "$PILER_CONF"
      chmod 640 "$PILER_CONF"
      chown root:piler "$PILER_CONF"
      sed -i "s%hostid=.*%hostid=${PILER_HOST%%:*}%" "$PILER_CONF"
      sed -i "s%tls_enable=.*%tls_enable=1%" "$PILER_CONF"
      sed -i "s%mysqlpwd=.*%mysqlpwd=${MYSQL_PILER_PASSWORD}%" "$PILER_CONF"
   fi

   if [[ ! -f "$piler_nginx_conf" ]]; then
      cp /etc/piler/piler-nginx.conf.dist "$piler_nginx_conf"
      sed -i "s%PILER_HOST%${PILER_HOST}%" "$piler_nginx_conf"
   fi

   ln -sf "$piler_nginx_conf" /etc/nginx/sites-enabled/piler

   sed -i "s%HOSTNAME%${PILER_HOST}%" "$CONFIG_SITE_PHP"
   sed -i "s%MYSQL_PASSWORD%${MYSQL_PILER_PASSWORD}%" "$CONFIG_SITE_PHP"

   sed -i "s%^\$config\['DECRYPT_BINARY'\].*%\$config\['DECRYPT_BINARY'\] = '/usr/bin/pilerget';%" "$CONFIG_PHP"
   sed -i "s%^\$config\['DECRYPT_ATTACHMENT_BINARY'\].*%\$config\['DECRYPT_ATTACHMENT_BINARY'\] = '/usr/bin/pileraget';%" "$CONFIG_PHP"
   sed -i "s%^\$config\['PILER_BINARY'\].*%\$config\['PILER_BINARY'\] = '/usr/sbin/piler';%" "$CONFIG_PHP"
}



create_dir_if_not_exist /var/piler
create_dir_if_not_exist /var/piler/error
create_dir_if_not_exist /var/piler/imap
create_dir_if_not_exist /var/piler/sphinx
create_dir_if_not_exist /var/piler/stat
create_dir_if_not_exist /var/piler/store
create_dir_if_not_exist /var/piler/tmp
create_dir_if_not_exist /var/run/piler
###
create_dir_if_not_exist /var/piler/www
create_dir_if_not_exist /var/piler/www/tmp 
create_dir_if_not_exist /var/piler/www/images
/bin/bash /piler-postinst || true


service rsyslog start
service mysql start

mysqlshow -h "$MYSQL_HOSTNAME" -u "$PILER_USER" --password="$MYSQL_PILER_PASSWORD" "$MYSQL_DATABASE" > /dev/null 2>&1 || create_mysql_db
pre_seed_sphinx
fix_configs

service cron start
####service php7.2-fpm start
service php7.2-fpm start || service php7.3-fpm start
###service php7.3-fpm status
service nginx start
/etc/init.d/rc.searchd start

# fix for overlay, https://github.com/phusion/baseimage-docker/issues/198
touch /var/spool/cron/crontabs/piler

/etc/init.d/rc.piler start

while true; do sleep 120; done
