# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

FROM haproxy:2.7
ARG DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
VOLUME "/tls/"
EXPOSE 80 443

USER root
RUN apt -qy update && apt -qy install curl
USER haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
HEALTHCHECK CMD curl -fk https://127.0.0.1/users/login || exit 1
