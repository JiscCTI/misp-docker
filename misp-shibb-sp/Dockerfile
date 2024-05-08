# SPDX-FileCopyrightText: 2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only
    
FROM rockylinux:9.3
ARG SHIBB_VERSION=0.0.0
ENV FQDN=misp.local HTTPS_PORT=443 \
    SHIBB_EMAIL_FORMAT=urn:oasis:names:tc:SAML:2.0:attrname-format:uri \
    SHIBB_EMAIL_NAME=urn:oid:0.9.2342.19200300.100.1.3 \
    SHIBB_GROUP_FORMAT=urn:oasis:names:tc:SAML:2.0:attrname-format:uri \
    SHIBB_GROUP_NAME=urn:oid:1.3.6.1.4.1.5923.1.5.1.1 \
    SHIBB_IDP_ENTITY_ID=https://idp.example.org/idp/shibboleth \
    SHIBB_IDP_METADATA_URL=false SHIBB_ORG_FORMAT=urn:oasis:names:tc:SAML:2.0:attrname-format:uri \
    SHIBB_ORG_NAME=urn:oid:1.3.6.1.4.1.25178.1.2.9 \ SHIBB_SP_ENCRYPT_REQUESTS=true \
    SHIBB_SP_ENTITY_ID=default SHIBB_SP_SHARE_KEY=true SHIBB_SP_SIGN_REQUESTS=true
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
