# misp-shibb-sp Image

The misp-shibb-sp image contains a pre-configured Shibboleth Service Provider module for use with
MISP.

## Build

The images starts from the `rockylinux:9.3` and installs the `shibboleth` repository and package.

## Entrypoint

The entrypoint for the image configures the SP based on environment variables and opens the unix
socket which gets mapped into misp-web.

## Health Check

The image contains a basic health check which reports healthy (exit code 0) if the `shibd` process
is alive and reports no syntax errors and otherwise reports unhealthy (exit code 1).

## Exposed Ports

This image does not expose any ports.

## Volumes

The image uses the following volumes:

| Mount Point | Purpose |
|-------------|---------|
| /etc/shibboleth | Contains the shibboleth-sp configuration. |
| /run/shibboleth | Contains the shibboleth-sp unix socket. |
| /var/log/shibboleth | Contains log files from the shibboleth-sp. |
