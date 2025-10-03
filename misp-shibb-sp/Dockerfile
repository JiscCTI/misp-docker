# SPDX-FileCopyrightText: 2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

FROM rockylinux:9.3
ARG SHIBB_VERSION=0.0.0
LABEL org.opencontainers.image.title="misp-shibb-sp" \
    org.opencontainers.image.version="${SHIBB_VERSION}" \
    org.opencontainers.image.ref.name="misp-shibb-sp" \
    org.opencontainers.image.description="Shibboleth 2 Service Provider for MISP." \
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk" \
    org.opencontainers.image.base.name="hub.docker.com/_/rockylinux:9.3"
VOLUME "/etc/shibboleth" "/run/shibboleth/" "/var/log/shibboleth/"

COPY shibboleth.repo /etc/yum.repos.d/shibboleth.repo
COPY *.xml /etc/shibboleth/
COPY entrypoint.sh /entrypoint.sh
RUN dnf install -yq shibboleth-${SHIBB_VERSION} && \
    dnf clean all && \
    rm -f /etc/shibboleth/*.dist /etc/shibboleth/*.html /etc/shibboleth/*.rpmnew \
        /etc/shibboleth/apache* /etc/shibboleth/attribute-policy.xml /etc/shibboleth/example-* \
        /etc/shibboleth/shibd-* /etc/shibboleth/sp-* && \
    cp -a /etc/shibboleth /etc/shibboleth.dist && \
    chmod +x /entrypoint.sh

HEALTHCHECK --timeout=3s CMD pgrep -x shibd || exit 1 && shibd -t || exit 1

ENTRYPOINT "/entrypoint.sh"
