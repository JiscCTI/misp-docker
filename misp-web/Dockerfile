# SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

# Build PHP Modules
FROM php:8.4-apache AS php_build
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

COPY --chown=root:root php.ini /usr/local/etc/php/php.ini

RUN apt-get -qy update &&\
    apt-get -qy install --no-install-recommends git libc6 libcurl4-openssl-dev libfuzzy-dev libfreetype-dev libgd3 \
    libicu-dev libjpeg-dev libgpgme-dev libonig-dev libpng-dev librdkafka-dev libwebp-dev libzip-dev &&\
    docker-php-ext-install bcmath curl gd intl mysqli opcache pcntl pdo_mysql zip
RUN pecl install apcu &&\
    pecl install gnupg &&\
    pecl install mongodb &&\
    pecl install rdkafka &&\
    pecl install redis &&\
    pecl install simdjson &&\
    pecl install zstd
RUN ln -s /usr/lib/x86_64-linux-gnu/libfuzzy.so /usr/lib/libfuzzy.so &&\
    ldconfig &&\
    git clone --recursive --depth=1 https://github.com/JakubOnderka/pecl-text-ssdeep.git /tmp/pecl-text-ssdeep &&\
    cd /tmp/pecl-text-ssdeep && phpize && ./configure && make && make install
RUN git clone -q --recursive --depth=1 https://github.com/kjdev/php-ext-brotli.git &&\
    cd php-ext-brotli &&\
    phpize &&\
    ./configure &&\
    make install
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp &&\
    docker-php-ext-install exif gd gettext mbstring sockets &&\
    docker-php-ext-enable apcu brotli exif gd gettext gnupg mbstring mongodb rdkafka redis simdjson sockets ssdeep zstd

# Build MISP
FROM php:8.4-apache AS misp_build
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

# Install build dependencies
RUN apt-get -qy update &&\
    apt-get -qy install --no-install-recommends cmake gcc git libcaca-dev libfuzzy-dev libgpgme11 libjpeg-dev liblua5.3-dev\
    libopencv-dev libpoppler-cpp-dev librdkafka-dev libxml2-dev libxslt1-dev libyara-dev libzbar-dev libzip5 make\
    openssl python3 python3-dev python3-venv ruby sqlite3 ssdeep tesseract-ocr unzip zip zlib1g-dev

# Download MISP
WORKDIR /var/www/
RUN git config --global advice.detachedHead false &&\
    git clone -q --branch ${MISP_VERSION} --single-branch https://github.com/MISP/MISP &&\
    cd MISP &&\
    git rev-parse ${MISP_VERSION} > .git_commit_version &&\
    git submodule update -q --init --recursive &&\
    git submodule foreach --recursive git config core.filemode false &&\
    git config core.filemode false

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20230831/ \
    /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/

WORKDIR /var/www/MISP/app
ARG COMPOSER_ALLOW_SUPERUSER=1
RUN php composer.phar -q self-update &&\
    php composer.phar -q config --no-plugins allow-plugins.composer/installers true &&\
    php composer.phar -q config --no-plugins allow-plugins.php-http/discovery true &&\
    php composer.phar -q install &&\
    php composer.phar -q require --with-all-dependencies elasticsearch/elasticsearch &&\
    php composer.phar -q require --with-all-dependencies aws/aws-sdk-php &&\
    php composer.phar -q require --with-all-dependencies jakub-onderka/openid-connect-php
WORKDIR /var/www/MISP
RUN cp -fa INSTALL/setup/config.php app/Plugin/CakeResque/Config/config.php &&\
    python3 -m venv venv &&\
    . ./venv/bin/activate &&\
    pip -q install --no-cache-dir --upgrade pip setuptools &&\
    pip -q install --no-cache-dir ordered-set python-dateutil six weakrefmethod &&\
    pip -q install --no-cache-dir ./app/files/scripts/misp-stix &&\
    pip -q install --no-cache-dir ./PyMISP &&\
    pip -q install --no-cache-dir git+https://github.com/kbandla/pydeep.git &&\
    pip -q install --no-cache-dir lief &&\
    pip -q install --no-cache-dir zmq redis &&\
    pip -q install --no-cache-dir python-magic &&\
    pip -q install --no-cache-dir plyara yara &&\
    cd PyMISP &&\
    git submodule foreach "git pull -q origin main || git pull -q origin master || exit 0" &&\
    pip -q install --no-cache-dir /var/www/MISP/PyMISP/.[fileobjects,openioc,virustotal,pdfexport]
WORKDIR /var/www
RUN find /var/www -type d -name .git -exec rm -r {} + &&\
    mkdir MISP/.git &&\
    mv MISP/.git_commit_version MISP/.git/HEAD &&\
    cp MISP/.git/HEAD MISP/.git/ORIG_HEAD &&\
    chown -R www-data: MISP &&\
    chmod -R 750 MISP &&\
    chmod -R g+ws MISP/app/tmp &&\
    chmod -R g+ws MISP/app/files &&\
    cd /var/www/MISP/app/files/ &&\
    rm -rf misp-decaying-models misp-galaxy misp-objects misp-workflow-blueprints noticelists taxonomies warninglists

# Build final image
FROM php:8.4-apache AS final
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
LABEL org.opencontainers.image.title="misp-web" org.opencontainers.image.version=${MISP_VERSION} \
    org.opencontainers.image.ref.name="misp-web" \
    org.opencontainers.image.description="Open Source Threat Intelligence and Sharing Platform." \
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk" \
    org.opencontainers.image.base.name="hub.docker.com/_/php:8.3-apache"
EXPOSE 80 443

ENV CAKE="sudo -H -u www-data /var/www/MISP/app/Console/cake"

# Install runtime dependencies
RUN apt-get -qy update &&\
    apt-get -qy upgrade apache2 &&\
    apt-get -qy install --no-install-recommends git gnupg iputils-ping libapache2-mod-shib\
        libfuzzy2 libgd3 libgpgme11 libicu76 libpng16-16 librdkafka1 libzip5 mariadb-client python3\
        python3-venv ssdeep sudo uuid zip &&\
    rm -rf /var/lib/apt/lists/* &&\
    mkdir -p /opt/misp_custom &&\
    chown -R www-data:www-data /opt/misp_custom

COPY --from=php_build --chown=root:root /usr/local/lib/php/extensions/no-debug-non-zts-20230831/ /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php_build --chown=root:root /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=misp_build --chown=www-data:www-data /var/www/ /var/www
COPY --chown=root:root apache.* /etc/apache2/sites-available/
COPY --chown=root:root scripts/ /opt/scripts
COPY entrypoint.sh /entrypoint.sh
COPY wait-for-it.sh /wait-for-it.sh
RUN a2dismod status &&\
    a2enmod ssl rewrite headers shib setenvif &&\
    chmod +x /opt/scripts/* /*.sh
WORKDIR /var/www/MISP/
ENTRYPOINT ["sh", "-c", "/wait-for-it.sh -h ${MYSQL_HOSTNAME:-misp_db} -p 3306 -t 0 -- /entrypoint.sh"]
HEALTHCHECK --start-period=10m --timeout=3s CMD ["sh", "-c", "curl -fk https://127.0.0.1/users/login || exit 1"]
VOLUME "/etc/letsencrypt/live/MISP" "/etc/ssl/private/" "/var/www/MISPData" "/var/www/MISPGnuPG" \
    "/opt/misp_custom"
