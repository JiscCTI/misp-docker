# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

FROM haproxy:lts
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
VOLUME "/tls/"
EXPOSE 80 443

USER root
RUN apt-get -qy update && apt-get -qy install curl && rm -rf /var/lib/apt/lists/*
USER haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
HEALTHCHECK CMD curl -fk https://127.0.0.1/users/login || exit 1
