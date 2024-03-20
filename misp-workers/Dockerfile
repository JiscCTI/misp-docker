# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

ARG MISP_VERSION=0.0.0
FROM jisccti/misp-web:${MISP_VERSION} as web
FROM php:7.4-cli AS final
ARG MISP_VERSION=0.0.0
LABEL org.opencontainers.image.title="misp-workers" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-workers"\
    org.opencontainers.image.description="Open Source Threat Intelligence and Sharing Platform."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/php:7.4-cli"
ENV CAKE="sudo -H -u www-data /var/www/MISP/app/Console/cake"
EXPOSE 9001
VOLUME "/var/www/MISPData" "/var/www/MISPGnuPG"

# Setup MISP Workers
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
RUN apt-get -qy update &&\
    apt-get -qy upgrade curl libtasn1-6 openssl libncurses6 libkrb5-3 gnutls-bin libxml2 systemd &&\
    apt-get -qy install git gnupg iputils-ping libfuzzy2 libgd3 libgpgme11 libpng16-16 librdkafka1\
    libzip4 mariadb-client ssdeep sudo supervisor uuid zip && \
    rm -rf /var/lib/apt/lists/*

# Copy in dependencies and MISP
COPY --from=web --chown=root:root /opt/scripts/ /opt/scripts
COPY --from=web --chown=root:root /usr/local/ /usr/local/
COPY --from=web --chown=root:root /wait-for-it.sh /wait-for-it.sh
COPY --from=web --chown=www-data:www-data /var/www/ /var/www
# Copy in worker specific items
COPY misp-workers.conf /etc/supervisor/conf.d/misp-workers.conf
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod 755 /*.sh

WORKDIR /var/www/MISP/
ENTRYPOINT /wait-for-it.sh -h ${REDIS_HOST:-misp_redis} -p 6379 -t 0 -- /entrypoint.sh
HEALTHCHECK --start-period=10m --timeout=5s CMD /healthcheck.sh
