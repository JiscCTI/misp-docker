# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

ARG MISP_VERSION=0.0.0
FROM jisccti/misp-web:${MISP_VERSION}
LABEL Name="misp-workers" Version=${MISP_VERSION}\
    org.opencontainers.image.title="misp-workers" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-workers"\
    org.opencontainers.image.description="Open Source Threat Intelligence and Sharing Platform."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/jisccti/misp-web:${MISP_VERSION}"

# Setup MISP Workers
RUN apt -qy update &&\
    apt -qy install supervisor

COPY misp-workers.conf /etc/supervisor/conf.d/misp-workers.conf
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod 755 /*.sh

ENTRYPOINT /wait-for-it.sh -h ${REDIS_HOST:-misp_redis} -p 6379 -t 0 -- /entrypoint.sh
HEALTHCHECK CMD /healthcheck.sh
