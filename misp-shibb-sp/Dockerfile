FROM rockylinux:9.3
ARG SHIBB_VERSION=0.0.0
LABEL org.opencontainers.image.title="misp-shibb-sp" org.opencontainers.image.version="${SHIBB_VERSION}"\
    org.opencontainers.image.ref.name="misp-shibb-sp"\
    org.opencontainers.image.description="Shibboleth 2 Service Provider for MISP."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/rockylinux:9.3"
VOLUME "/etc/shibboleth" "/run/shibboleth/" "/var/log/shibboleth/"

COPY entrypoint.sh /entrypoint.sh
COPY shibboleth.repo /etc/yum.repos.d/shibboleth.repo
COPY *.xml /etc/shibboleth/
RUN dnf install -yq shibboleth.x86_64 && \
    dnf clean all && \
    cp -a /etc/shibboleth /etc/shibboleth.dist && \
    chmod +x /entrypoint.sh

HEALTHCHECK --timeout=3s CMD pgrep -x shibd || exit 1 && shibd -t || exit 1

ENTRYPOINT "/entrypoint.sh"
