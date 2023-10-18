# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

# Build PHP Modules
FROM php:7.4-apache AS php_build
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

COPY --chown=root:root php.ini /usr/local/etc/php/php.ini

RUN apt-get -qy update &&\
    apt-get -qy install --no-install-recommends git libc6 libcurl4-openssl-dev libfuzzy-dev libfreetype-dev libgd3 \
    libicu-dev libjpeg-dev libgpgme-dev libpng-dev librdkafka-dev libwebp-dev libzip-dev &&\
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
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp &&\
    docker-php-ext-install gd &&\
    docker-php-ext-enable apcu brotli gd gnupg rdkafka redis simdjson ssdeep

# Build Python 3.10
FROM debian:bullseye AS python_build
RUN apt-get -yq update
RUN apt-get -yq install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
WORKDIR /opt/
RUN wget https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz
RUN tar xfz Python-3.10.12.tgz
WORKDIR /opt/Python-3.10.12
RUN ./configure --prefix=/usr/local --enable-optimizations
RUN make
RUN make install
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools

# Build MISP
FROM php:7.4-apache AS misp_build
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ \
    /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=python_build /usr/local /usr/local

# Install build dependencies
RUN apt-get -qy update &&\
    apt-get -qy install --no-install-recommends cmake gcc git libcaca-dev libfuzzy-dev libgpgme11 libjpeg-dev liblua5.3-dev\
    libopencv-dev libpoppler-cpp-dev librdkafka-dev libxml2-dev libxslt1-dev libyara-dev libzbar-dev libzip4 make\
    openssl\
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
    python3 -m venv venv &&\
    ./venv/bin/pip -q install --no-cache-dir --upgrade pip setuptools &&\
    ./venv/bin/pip -q install --no-cache-dir ordered-set python-dateutil six weakrefmethod &&\
    ./venv/bin/pip -q install --no-cache-dir ./app/files/scripts/misp-stix &&\
    ./venv/bin/pip -q install --no-cache-dir ./PyMISP &&\
    ./venv/bin/pip -q install --no-cache-dir git+https://github.com/kbandla/pydeep.git &&\
    ./venv/bin/pip -q install --no-cache-dir lief &&\
    ./venv/bin/pip -q install --no-cache-dir zmq redis &&\
    ./venv/bin/pip -q install --no-cache-dir python-magic &&\
    ./venv/bin/pip -q install --no-cache-dir plyara yara &&\
    cd PyMISP &&\
    git submodule foreach "git pull -q origin main || git pull -q origin master || exit 0" &&\
    /var/www/MISP/venv/bin/pip -q install --no-cache-dir /var/www/MISP/PyMISP/.[fileobjects,openioc,virustotal,pdfexport] &&\
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
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
LABEL org.opencontainers.image.title="misp-web" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-web"\
    org.opencontainers.image.description="Open Source Threat Intelligence and Sharing Platform."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/php:7.4-apache"
VOLUME "/etc/ssl/private/" "/var/www/MISPData" "/var/www/MISPGnuPG"
EXPOSE 80 443

ENV CAKE="sudo -H -u www-data /var/www/MISP/app/Console/cake"

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20190902/ /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=python_build /usr/local /usr/local
COPY --from=misp_build --chown=www-data:www-data /var/www/ /var/www
COPY --chown=root:root apache.conf /etc/apache2/sites-enabled/000-default.conf
COPY --chown=root:root scripts/ /opt/scripts

# Install runtime dependencies
RUN apt-get -qy update &&\
    apt-get -qy upgrade apache2 &&\
    apt-get -qy install --no-install-recommends git gnupg iputils-ping libfuzzy2 libgd3 libgpgme11 libpng16-16 librdkafka1\
    libzip4 mariadb-client ssdeep sudo uuid &&\
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
