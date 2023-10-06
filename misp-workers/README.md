<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Workers

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-workers](https://img.shields.io/docker/v/jisccti/misp-workers?logo=docker&label=misp-workers)![misp-workers size](https://img.shields.io/docker/image-size/jisccti/misp-workers?label=%20)](https://hub.docker.com/r/jisccti/misp-workers)

Containerised version of the MISP v2.x `SimpleBackgroundJobs` workers.

This image depends on `misp-web` being build first.

## Building

### Latest v2.x release

Use the Python script to determine and build the latest version:

```sh
VERSION=$(python3 ../misp-web/latest.py); sudo docker build \
  --tag jisccti/misp-workers:latest --tag jisccti/misp-workers:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

### Specific release

Use the Python script to determine the latest version and pass this to the build process:

```sh
VERSION=v2.4.150; sudo docker build \
  --tag jisccti/misp-workers:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

## Acknowledgements

This image uses, contains or builds on:

* https://github.com/MISP/MISP
* https://github.com/MISP/misp-workers
* https://github.com/vishnubob/wait-for-it
