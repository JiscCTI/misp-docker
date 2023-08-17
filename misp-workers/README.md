<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Workers

Containerised version of the MISP v2.x SimpleBackgroundJobs workers.

This image depends on having `misp-web` build to the same version.

## Building

### Latest v2.x release

Use the Python script to determine and build the latest version:

```bash
VERSION=$(python3 latest.py); sudo docker build --tag jisc/misp-workers:latest --tag jisc/misp-workers:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

### Specific release

Use the Python script to determine the latest version and pass this to the build process:

```bash
VERSION=$(python3 latest.py); sudo docker build --tag jisc/misp-workers:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

## Acknowledgements

This image uses, contains or builds on:

* https://github.com/MISP/MISP
* https://github.com/MISP/misp-workers
* https://github.com/vishnubob/wait-for-it
