FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PILER_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="woa7"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"

ENV DISTRO="bionic" \
DOWNLOAD_URL="https://download.mailpiler.com" \
PILER_USER="piler" \
MYSQL_HOSTNAME="localhost" \
MYSQL_DATABASE="piler" \
MYSQL_PILER_PASSWORD="piler123" \
MYSQL_ROOT_PASSWORD="abcde123" \
SPHINX_BIN_TARGZ="sphinx-3.1.1-bin.tar.gz" \
PACKAGE="${PACKAGE:-piler_1.3.7-bionic-94c54a0_amd64.deb}"

ENV HOME="/var/piler" \
PUID=${PUID:-911} \
PGID=${PGID:-911}

RUN \
 echo "***** install gnupg ****" && \
 apt-get update && \
 apt-get install -y \
        gnupg && \
 ##echo "***** add sabnzbd repositories ****" && \
 ##apt-key adv --keyserver hkp://keyserver.ubuntu.com:11371 --recv-keys 0x98703123E0F52B2BE16D586EF13930B14BB9F05F && \
 ##echo "deb http://ppa.launchpad.net/jcfp/nobetas/ubuntu bionic main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 ##echo "deb-src http://ppa.launchpad.net/jcfp/nobetas/ubuntu bionic main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 ##echo "deb http://ppa.launchpad.net/jcfp/sab-addons/ubuntu bionic main" >> /etc/apt/sources.list.d/sabnzbd.list && \
 ##echo "deb-src http://ppa.launchpad.net/jcfp/sab-addons/ubuntu bionic main" >> /etc/apt/sources.list.d/sabnzbd.list
 
 RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
 wget rsyslog openssl sysstat php7.2-cli php7.2-cgi php7.2-mysql php7.2-fpm php7.2-zip php7.2-ldap \
 php7.2-gd php7.2-curl php7.2-xml catdoc unrtf poppler-utils nginx tnef sudo libodbc1 libpq5 libzip4 \
 libtre5 libwrap0 cron libmariadb3 libmysqlclient-dev python python-mysqldb mariadb-server
 
 RUN \
 service mysql start && mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}
 
 RUN \
 wget --no-check-certificate -q -O ${SPHINX_BIN_TARGZ} ${DOWNLOAD_URL}/generic-local/${SPHINX_BIN_TARGZ} && \
 tar zxvf ${SPHINX_BIN_TARGZ} && \
 rm -f ${SPHINX_BIN_TARGZ} && \
    sed -i 's/mail.[iwe].*//' /etc/rsyslog.conf && \
    sed -i '/session    required     pam_loginuid.so/c\#session    required     pam_loginuid.so' /etc/pam.d/cron && \
    mkdir /etc/piler && \
    printf "[mysql]\nuser = piler\npassword = ${MYSQL_PILER_PASSWORD}\n" > /etc/piler/.my.cnf && \
    printf "[mysql]\nuser = root\npassword = ${MYSQL_ROOT_PASSWORD}\n" > /root/.my.cnf && \
    echo "alias mysql='mysql --defaults-file=/etc/piler/.my.cnf'" > /root/.bashrc && \
    echo "alias t='tail -f /var/log/syslog'" >> /root/.bashrc && \
    dpkg -i $PACKAGE && \
    crontab -u $PILER_USER /usr/share/piler/piler.cron && \
    touch /var/log/mail.log && \
    rm -f $PACKAGE /etc/nginx/sites-enabled/default && \
    sed -i 's/#ngram/ngram/g' /etc/piler/sphinx.conf.dist && \
    sed -i 's/220/311/g' /etc/piler/sphinx.conf.dist && \
 echo "**** cleanup ****" && \
 apt-get purge --auto-remove -y && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

#### add local files
###COPY root/ /

# ports and volumes
#EXPOSE 8080 9090
EXPOSE 25 80 443
#VOLUME /config
VOLUME /var/piler

CMD ["/start.sh"]
