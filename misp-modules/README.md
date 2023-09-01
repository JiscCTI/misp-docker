<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Modules Docker Image

Containerised version of v2.x of the MISP modules.

## Building

### Latest v2.x release

Use the Python script to determine the latest version and pass this to the build process:

```bash
VERSION=$(python3 latest.py); sudo docker build --pull --tag jisccti/misp-modules:latest --tag jisccti/misp-modules:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

### Specific release

Pass the desired version as a variable to the build process:

```bash
VERSION=v2.4.150; sudo docker build --pull --tag jisccti/misp-modules:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

## Acknowledgements

This image uses, contains or builds on:

* https://github.com/MISP/MISP
* https://github.com/MISP/misp-modules
