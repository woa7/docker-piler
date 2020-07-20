FROM ubuntu:focal
#FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PILER_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="woa7"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV DISTRO="focal" \
MYSQL_HOSTNAME="localhost" \
MYSQL_DATABASE="piler" \
MYSQL_PILER_PASSWORD="piler123" \
MYSQL_ROOT_PASSWORD="abcde123"

RUN mkdir /data || true
RUN mkdir /config || true
RUN mkdir /config/etc || true
###RUN ln -s ln -s /config/etc/piler /etc/piler

# must be set in two steps, as in in one the env is still emty
ENV PUID_NAME="${PUID_NAME:-piler}"
ENV PILER_USER="${PUID_NAME}"

RUN set -vx && echo "${PUID_NAME}" && echo "${PILER_USER}" && env && set && ls -la $HOME || true
#RUN set -vx && echo "${PUID_NAME}" && echo "${PILER_USER}" && env && set &&  $(set +e ; set -vx ; ls -la $HOME ) || true

###ENV BUILD_DIR="${BUILD_DIR:-/tmp/build}"
ENV BUILD_DIR="${BUILD_DIR:-/BUILD}"
RUN mkdir -p ${BUILD_DIR}

###ENV SPHINX_DOWNLOAD_URL_BASE="https://download.mailpiler.com/generic-local" \
###SPHINX_BIN_TARGZ="sphinx-3.1.1-bin.tar.gz" \
###SPHINX_BIN_TARGZ_SHA256="f543fae12d4a240b424a906519936c8ada6e338346e215edfe0b8ec75c930d56" 

###RUN echo "${SPHINX_DOWNLOAD_URL_BASE}"
###RUN echo "${SPHINX_BIN_TARGZ}"
###RUN echo "${SPHINX_BIN_TARGZ_SHA256}"

#ENV PACKAGE_DOWNLOAD_URL_BASE="https://bitbucket.org/jsuto/piler/downloads" \
#PACKAGE="${PACKAGE:-piler_1.3.5~bionic-f2e4cb1_amd64.deb}" \
#PACKAGE_DOWNLOAD_SHA256="${PACKAGE_DOWNLOAD_SHA256:-b74e5f259a4a19c3cb166ab37cf84ade629bf0f0da9ec2c4fcf5c8a26965280f}"

#ENV PACKAGE_DOWNLOAD_URL_BASE="https://bitbucket.org/jsuto/piler/downloads" \
#PACKAGE="${PACKAGE:-piler_1.3.6~bionic-78e5a44_amd64.deb}" \
#PACKAGE_DOWNLOAD_SHA256="${PACKAGE_DOWNLOAD_SHA256:-0ae6d1cae62f90f47c167ef1c050ae37954cc5986be759512679b34044ea748c}"

###ENV PACKAGE_DOWNLOAD_URL_BASE="https://bitbucket.org/jsuto/piler/downloads" \
###PACKAGE="${PACKAGE:-piler_1.3.7-bionic-94c54a0_amd64.deb}" \
###PACKAGE_DOWNLOAD_SHA256="${PACKAGE_DOWNLOAD_SHA256:-025bf31155d31c4764c037df29703f85e2e56d66455616a25411928380f49d7c}"

ENV PACKAGE_DOWNLOAD_URL_BASE="https://bitbucket.org/jsuto/piler/downloads" \
PACKAGE="${PACKAGE:-piler-1.3.7.tar.gz}" \
PACKAGE_DOWNLOAD_SHA256="${PACKAGE_DOWNLOAD_SHA256:-21c0db70827b2bf6b6c9c5b467f748ea90adf7b4c2c38408edeee331e101925e}"


# https://bitbucket.org/jsuto/piler/downloads/piler-1.3.7.tar.gz
#https://bitbucket.org/jsuto/piler/downloads/piler_1.3.7-bionic-94c54a0_amd64.deb

ENV HOME="/var/piler" \
PUID_NAME=${PUID_NAME:-abc} \
PUID=${PUID:-9001} \
PGID=${PGID:-9001}
####PUID=${PUID:-911} \
####PGID=${PGID:-911}

RUN set -vx && echo "${PUID_NAME}" && echo "${PILER_USER}" && env && set && ls -la $HOME || true

RUN \
 echo "***** apt-get update && apt-get upgrade ****" && \
 apt-get update && \
 apt-get upgrade -y

RUN \
 echo "***** install gnupg ****" && \
 apt-get update && \
 apt-get install -y \
        gpgv1 gpgv2
 
 RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
 nvi wget curl rsyslog openssl sysstat \
 catdoc unrtf poppler-utils nginx tnef sudo libodbc1 libpq5 libzip5 \
 libtre5 libwrap0 cron libmariadb3 libmysqlclient-dev python3 python3-mysqldb mariadb-server php-memcached memcached mariadb-client
 RUN \
 $(apt-get install -y php7.3-cli php7.3-cgi php7.3-mysql php7.3-fpm php7.3-zip php7.3-ldap php7.3-gd php7.3-curl php7.3-xml || \
 apt-get install -y php-cli php-cgi php-mysql php-fpm php-zip php-ldap php-gd php-curl php-xml )

# versions bump libzip4 -> libzip5

# need on ubuntu / debian etc
RUN \
 printf "www-data ALL=(root:root) NOPASSWD: /etc/init.d/rc.piler reload\n" > /etc/sudoers.d/81-www-data-sudo-rc-piler-reload && \
 printf "Defaults\\072\\045www-data \\041requiretty\\n" >> /etc/sudoers.d/81-www-data-sudo-rc-piler-reload && \
 chmod 0440 /etc/sudoers.d/81-www-data-sudo-rc-piler-reload

#RUN \
# echo "www-data ALL=(root:root) NOPASSWD: /etc/init.d/rc.piler reload" > /etc/sudoers.d/80-www-data-sudo-rc-piler-reload && \
# printf "Defaults\072\045www-data \041requiretty\n" >> /etc/sudoers.d/80-www-data-sudo-rc-piler-reload && \
# chmod 0440 /etc/sudoers.d/80-www-data-sudo-rc-piler-reload


# need on Centos / Redhat etc
RUN \
 printf "apache ALL=(root:root) NOPASSWD: /etc/init.d/rc.piler reload\n" > /etc/sudoers.d/82-apache-sudo-rc-piler-reload && \
 printf "Defaults\\072\\045apache \\041requiretty\\n" >> /etc/sudoers.d/82-apache-sudo-rc-piler-reload && \
 chmod 0440 /etc/sudoers.d/82-apache-sudo-rc-piler-reload

RUN \
 service mysql start && mysqladmin -u root password ${MYSQL_ROOT_PASSWORD}

#RUN curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
    #&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c -
##RUN curl -fSL -o ${SPHINX_BIN_TARGZ} "${SPHINX_BIN_TARGZ_DOWNLOAD_URL}" \
#RUN curl -fSL -o ${SPHINX_BIN_TARGZ} "${SPHINX_DOWNLOAD_URL_BASE}/${SPHINX_BIN_TARGZ}" \
#    && echo "$SPHINX_BIN_TARGZ_SHA256 *$SPHINX_BIN_TARGZ" | sha256sum -c - || echo "sha256sum FAILD: ${SPHINX_DOWNLOAD_URL_BASE}/${SPHINX_BIN_TARGZ}" \
#    ; echo "should $SPHINX_BIN_TARGZ_SHA256 but is:" ; sha256sum $SPHINX_BIN_TARGZ

#RUN curl -fSL -o ${PACKAGE} "${PACKAGE_DOWNLOAD_URL_BASE}/${PACKAGE}" \
#    && echo "$PACKAGE_DOWNLOAD_SHA256 *$PACKAGE" | sha256sum -c - || echo "sha256sum FAILD: ${PACKAGE_DOWNLOAD_URL_BASE}/${PACKAGE}" \
#    ; echo "should $PACKAGE_DOWNLOAD_SHA256 but is:" ; sha256sum $PACKAGE

####RUN curl -fSL -o ${SPHINX_BIN_TARGZ} "${SPHINX_DOWNLOAD_URL_BASE}/${SPHINX_BIN_TARGZ}" \
####    && echo "$SPHINX_BIN_TARGZ_SHA256 *$SPHINX_BIN_TARGZ" | sha256sum -c - || echo "sha256sum FAILD: ${SPHINX_DOWNLOAD_URL_BASE}/${SPHINX_BIN_TARGZ}" \
####    ; echo "should $SPHINX_BIN_TARGZ_SHA256 but is:" ; sha256sum $SPHINX_BIN_TARGZ

#RUN curl -fSL -o ${PACKAGE} "${PACKAGE_DOWNLOAD_URL_BASE}/${PACKAGE}" \
#    && echo "$PACKAGE_DOWNLOAD_SHA256 *$PACKAGE" | sha256sum -c - || echo "sha256sum FAILD: ${PACKAGE_DOWNLOAD_URL_BASE}/${PACKAGE}" \
#    ; echo "should $PACKAGE_DOWNLOAD_SHA256 but is:" ; sha256sum $PACKAGE

RUN sha256check () { printf %s\\n "$2 *$1" ; printf %s\\n "$2 *$1" | sha256sum -c - || $(printf %s\\n "sha256sum FAILD: $1 should $2 but is:" ; sha256sum $1 ; exit 1) ; } && \
	curl -fSL -o ${PACKAGE} "${PACKAGE_DOWNLOAD_URL_BASE}/${PACKAGE}" && \
	sha256check ${PACKAGE} ${PACKAGE_DOWNLOAD_SHA256}


 
 ##RUN \
 ##wget --no-check-certificate -q -O ${SPHINX_BIN_TARGZ} ${DOWNLOAD_URL}/generic-local/${SPHINX_BIN_TARGZ} && \
 
 ####RUN echo "**** install sphinxsearch package via bin.tgz ****" && tar zxvf ${SPHINX_BIN_TARGZ} && \
 ####rm -f ${SPHINX_BIN_TARGZ} && \
 # OR  +++++++++++++ #
 RUN echo "**** install sphinxsearch package via apt-get ****" && apt-get update && apt-get install -y sphinxsearch
 
   RUN \
    sed -i 's/^/###/' /etc/init.d/sphinxsearch && \
    echo "### piler install, comment full file to stop the OS reindex" >> /etc/init.d/sphinxsearch && \
    sed -i 's/mail.[iwe].*//' /etc/rsyslog.conf && \
    sed -i '/session    required     pam_loginuid.so/c\#session    required     pam_loginuid.so' /etc/pam.d/cron && \
    mkdir /etc/piler && \
    printf "[mysql]\nuser = piler\npassword = ${MYSQL_PILER_PASSWORD}\n" > /etc/piler/.my.cnf && \
    printf "[mysql]\nuser = root\npassword = ${MYSQL_ROOT_PASSWORD}\n" > /root/.my.cnf && \
    echo "alias mysql='mysql --defaults-file=/etc/piler/.my.cnf'" > /root/.bashrc && \
    echo "alias t='tail -f /var/log/syslog'" >> /root/.bashrc

##### RUN echo "**** install piler package via dpkg ****"  && \
#####    dpkg -i $PACKAGE

 RUN echo "**** install piler package via source tgz ****"  && \
    tar --directory=${BUILD_DIR} --restrict --strip-components=1 -zxvf ${PACKAGE} && \
    rm -f ${PACKAGE}
#RUN $([[ $(id -g piler 2>/dev/null) ]] || groupadd --gid $PGID piler)
#RUN $([[ $(id -u piler 2>/dev/null) ]] || useradd --uid $PUID -g piler -d /var/piler -s /bin/bash piler)

RUN set -vx && echo "${PUID_NAME}" && echo "${PILER_USER}" && env && set && ls -la $HOME || true
RUN groupadd --gid $PGID piler
RUN useradd --uid $PUID -g piler -d /var/piler -s /bin/bash piler
RUN usermod -L piler
RUN mkdir -p /var/piler
RUN chmod 755 /var/piler

RUN \
 echo "**** install build-essential ****" && \
 apt-get update && \
 apt-get install -y \
 build-essential \
 libcurl4-openssl-dev libwrap0-dev libtre-dev libzip-dev libmariadb-dev libc6 libc6-dev
RUN \
 $(apt-get install -y php7.2-dev || apt-get install -y php7.3-dev || apt-get install -y php7.4-dev || apt-get install -y php-dev)
 ####libc6-x32 libc6-dev-x32 libc6-i386 libc6-dev-i386 libc6-amd64-cross libc6-amd64-i386-cross libc6-amd64-x32-cross libc6-arm64-cross libc6-armhf-cross libc6-dev-arm64-cross libc6-dev-armhf-cross
 ###libcurl4-openssl-dev php7.3-dev libwrap0-dev libtre-dev libzip-dev libmysqlclient-dev


 RUN echo "**** patch piler source ****"
 COPY 101-piler-1-3-7-sphinxsearch-310-220-compatily-php-if-fix.patch ${BUILD_DIR}
 RUN cd ${BUILD_DIR} && patch -p1 < ${BUILD_DIR}/101-piler-1-3-7-sphinxsearch-310-220-compatily-php-if-fix.patch

RUN echo "**** build piler package from source ****"  && \
    cd ${BUILD_DIR} && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-database=mariadb  && \
    make clean all && \
    su -c 'make install' && \
    ldconfig

RUN echo "**** piler unit_tests ****"  && \
cd ${BUILD_DIR}/unit_tests && ./run.sh

RUN echo "**** piler phpunit ****"  && \
apt-get update && apt-get install -y phpunit && \
cd ${BUILD_DIR} && phpunit
###mysql -u piler -ppiler123 piler1 < /usr/share/piler/db-mysql.sql

RUN echo "**** continue with the setup ****"  && \
    crontab -u $PILER_USER /usr/share/piler/piler.cron && \
    touch /var/log/mail.log && \
    rm -f $PACKAGE /etc/nginx/sites-enabled/default && \
    sed -i 's/#ngram/ngram/g' /etc/piler/sphinx.conf.dist && \
    echo "FIX me ---sed -i 's/220/311/g' /etc/piler/sphinx.conf.dist---" && grep -i SPHINX_VERSION /etc/piler/sphinx.conf.dist && \
 echo "**** cleanup ****" && \
 apt-get purge --auto-remove -y && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

#### add local files
###COPY root/ /

COPY start.sh /start.sh
COPY piler_1.3.7-postinst /piler-postinst
###COPY piler_1.3.7-etc_piler-nginx.conf.dist /piler-nginx.conf.dist
###COPY piler_1.3.7-etc_piler-nginx.conf.dist-mod-php7.3 /piler-nginx.conf.dist
COPY piler_1.3.7-etc_piler-nginx.conf.dist-mod-php7.4 /piler-nginx.conf.dist
### FIXME 
#RUN $( [[ -f /etc/piler/piler-nginx.conf.dist ]] && mv /piler-nginx.conf.dist /piler-nginx.conf.dist-FILE-NOT-IN-USE || cp -p /piler-nginx.conf.dist /etc/piler/ )
RUN $( [ -f /etc/piler/piler-nginx.conf.dist ] && mv /piler-nginx.conf.dist /piler-nginx.conf.dist-FILE-NOT-IN-USE || cp -p /piler-nginx.conf.dist /etc/piler/ )

###USER $PUID:$PGID
RUN set -vx && echo "${PUID_NAME}" && echo "${PILER_USER}" && env && set && ls -la $HOME || true
# ports and volumes
#EXPOSE 8080 9090
EXPOSE 25 80 443
VOLUME /config
VOLUME /data
###VOLUME ["/var/piler"]

CMD ["/bin/bash", "/start.sh"]
