<!--
SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Web Docker Image

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&sort=semver&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-web](https://img.shields.io/docker/v/jisccti/misp-web?logo=docker&label=misp-web)![misp-web size](https://img.shields.io/docker/image-size/jisccti/misp-web?label=%20)](https://hub.docker.com/r/jisccti/misp-web)

Containerised version of the WebUI and API of MISP v2.x.

Unlike other images, MISP Modules, MISP Workers, MySQL and Redis are **not** bundled.

## Building

### Latest v2.x release

Use the Python script to determine the latest version and pass this to the build process:

```sh
VERSION=$(python3 latest.py); sudo docker build --pull \
  --tag jisccti/misp-web:latest --tag jisccti/misp-web:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

### Specific release

Pass the desired version as a variable to the build process:

```sh
VERSION=v2.4.150; sudo docker build --pull \
  --tag jisccti/misp-web:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

## Volumes

### `/etc/ssl/private/`

Requires two files `misp.crt` and `misp.key`, if either file is missing or invalid a self-signed certificate will be
generated.

* `misp.crt`
  * Must include the certificate and full chain to the root CA.
  * Should be appended with https://ssl-config.mozilla.org/ffdhe2048.txt.
* `misp.key`
  * Must be the unencrypted private key for `misp.crt`.

### `/var/www/MISPData`

Contains all MISP data that needs to persist through container recreation.

### `/var/www/MISPGnuPG`

GnuPG home directory for MISP, if no key for MISP's email address is found, one is created.

### `/opt/misp_custom`

For passing in instance specific customisations.

## Acknowledgements

This image uses, contains or builds on:

* https://github.com/MISP/MISP
* https://github.com/MISP/Docker-MISP
* https://github.com/vishnubob/wait-for-it
