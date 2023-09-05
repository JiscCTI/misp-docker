# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

# Build PHP Modules
FROM php:7.4-apache AS php_build
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

COPY --chown=root:root php.ini /usr/local/etc/php/php.ini

RUN apt -qy update &&\
    apt -qy install --no-install-recommends git libc6 libcurl4-openssl-dev libfuzzy-dev libgd3 libicu-dev libgpgme-dev\
    libpng-dev librdkafka-dev libzip-dev &&\
    docker-php-ext-install bcmath curl gd intl json mysqli opcache pcntl pdo_mysql zip &&\
    pecl install apcu &&\
    pecl install gnupg &&\
    pecl install rdkafka &&\
    pecl install redis &&\
    pecl install simdjson &&\
    ln -s /usr/lib/x86_64-linux-gnu/libfuzzy.so /usr/lib/libfuzzy.so &&\
    ldconfig &&\
    pecl install ssdeep &&\
    git clone -q --recursive --depth=1 https://github.com/kjdev/php-ext-brotli.git &&\
    cd php-ext-brotli &&\
    phpize &&\
    ./configure &&\
    make install &&\
    docker-php-ext-enable apcu brotli gnupg rdkafka redis simdjson ssdeep

# Build MISP
FROM php:7.4-apache AS misp_build
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ \
    /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/

# Install build dependencies
RUN apt -qy update &&\
    apt -qy install --no-install-recommends cmake gcc git libcaca-dev libfuzzy-dev libgpgme11 libjpeg-dev liblua5.3-dev\
    libopencv-dev libpoppler-cpp-dev librdkafka-dev libxml2-dev libxslt1-dev libyara-dev libzbar-dev libzip4 make\
    openssl\
    python3-dev python3-pip python3-redis python3-setuptools python3-virtualenv python3-yara python3-zmq\
    ruby sqlite3 ssdeep tesseract-ocr unzip zip zlib1g-dev

# Download MISP
WORKDIR /var/www/
RUN git config --global advice.detachedHead false &&\
    git clone -q --branch ${MISP_VERSION} --single-branch https://github.com/MISP/MISP &&\
    cd MISP &&\
    git submodule update -q --init --recursive &&\
    git submodule foreach --recursive git config core.filemode false &&\
    git config core.filemode false &&\
    cd app &&\
    php composer.phar -q self-update &&\
    php composer.phar -q config --no-plugins allow-plugins.composer/installers true &&\
    php composer.phar -q config --no-plugins allow-plugins.php-http/discovery true &&\
    php composer.phar -q install --no-dev &&\
    php composer.phar -q require --with-all-dependencies supervisorphp/supervisor:^4.0 \
    guzzlehttp/guzzle \
    php-http/message \
    lstrojny/fxmlrpc \
    elasticsearch/elasticsearch \
    aws/aws-sdk-php \
    jakub-onderka/openid-connect-php \
    php-http/message-factory &&\
    cd .. &&\
    cp -fa INSTALL/setup/config.php app/Plugin/CakeResque/Config/config.php &&\
    virtualenv -p python3 ./venv &&\
    ./venv/bin/pip -q install ordered-set python-dateutil six weakrefmethod &&\
    ./venv/bin/pip -q install ./app/files/scripts/misp-stix &&\
    ./venv/bin/pip -q install ./PyMISP &&\
    ./venv/bin/pip -q install git+https://github.com/kbandla/pydeep.git &&\
    ./venv/bin/pip -q install lief &&\
    ./venv/bin/pip -q install zmq redis &&\
    ./venv/bin/pip -q install python-magic &&\
    ./venv/bin/pip -q install plyara &&\
    cd PyMISP &&\
    git submodule foreach "git pull -q origin main || git pull -q origin master || exit 0" &&\
    /var/www/MISP/venv/bin/pip -q install /var/www/MISP/PyMISP/.[fileobjects,neo,openioc,virustotal,pdfexport] &&\
    cd /var/www/ &&\
    chown -R www-data: MISP &&\
    chmod -R 750 MISP &&\
    chmod -R g+ws MISP/app/tmp &&\
    chmod -R g+ws MISP/app/files &&\
    find /var/www -type d -name .git -exec rm -r {} + &&\
    cd /var/www/MISP/app/files/ &&\
    rm -rf misp-decaying-models misp-galaxy misp-objects misp-workflow-blueprints noticelists taxonomies warninglists

# Build final image
FROM php:7.4-apache AS final
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
LABEL Name="misp-web" Version=${MISP_VERSION}\
    org.opencontainers.image.title="misp-web" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-web"\
    org.opencontainers.image.description="Open Source Threat Intelligence and Sharing Platform."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/php:7.4-apache"
VOLUME "/etc/ssl/private/" "/var/www/MISPData" "/var/www/MISPGnuPG"
EXPOSE 80 443

ENV CAKE="sudo -H -u www-data /var/www/MISP/app/Console/cake"

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=misp_build --chown=www-data:www-data /var/www/ /var/www
COPY --chown=root:root apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY --chown=root:root scripts/ /opt/scripts

# Install runtime dependencies
RUN apt -qy update &&\
    apt -qy upgrade apache2 &&\
    apt -qy install --no-install-recommends git gnupg iputils-ping libfuzzy2 libgpgme11 libpng16-16 librdkafka1 libzip4\
    mariadb-client python3 ssdeep sudo uuid &&\
    rm -rf /var/lib/apt/lists/* &&\
    a2dismod status &&\
    a2enmod ssl rewrite headers setenvif &&\
    chmod +x /opt/scripts/*

WORKDIR /var/www/MISP/
COPY entrypoint.sh /entrypoint.sh
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod 755 /*.sh
ENTRYPOINT /wait-for-it.sh -h ${MYSQL_HOSTNAME:-misp_db} -p 3306 -t 0 -- /entrypoint.sh
HEALTHCHECK CMD curl -fk https://127.0.0.1/users/login || exit 1
