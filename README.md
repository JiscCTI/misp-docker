<!--
SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Docker Images

[![CodeFactor](https://www.codefactor.io/repository/github/jisccti/misp-docker/badge)](https://www.codefactor.io/repository/github/jisccti/misp-docker)
[![Production Images](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml/badge.svg)](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml)

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&sort=semver&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-web](https://img.shields.io/docker/v/jisccti/misp-web?sort=semver&logo=docker&label=misp-web)![misp-web size](https://img.shields.io/docker/image-size/jisccti/misp-web/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-web)
[![misp-workers](https://img.shields.io/docker/v/jisccti/misp-workers?sort=semver&logo=docker&label=misp-workers)![misp-workers size](https://img.shields.io/docker/image-size/jisccti/misp-workers/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-workers)

[![MISP-Modules release](https://img.shields.io/github/v/tag/MISP/misp-modules?logo=github&sort=semver&label=MISP-Modules%20(source))](https://github.com/MISP/misp-modules)
[![misp-modules](https://img.shields.io/docker/v/jisccti/misp-modules?sort=semver&logo=docker&label=misp-modules)![misp-modules size](https://img.shields.io/docker/image-size/jisccti/misp-modules/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-modules)

Project to build a set of three docker images containing the components of
[MISP](https://github.com/MISP/MISP) with self-configuration into a usable state from first start.

**This GitHub repository is for maintaining the images, to use the images refer to the
[documentation site](https://jisccti.github.io/misp-docker/) instead.**

## Build Dependencies

The images are build and tested using the latest docker engine, but should build on any Linux-based
Docker Engine which supports multi-stage images.

## Quick Start Deployment

`quickstart.py` is designed to create a test instance of MISP for validation of changes to the
builds, it **should not be used in production environments**.

It will:

* Create a "best guess" `.env` file if one does not exist,
* Delete ALL existing persistent storage,
* Pull the three required external images,
* Build the three images in this project,
* Start MISP at https://{docker-hostname}/.

Quick Start requires:

* A Python >= 3.9 virtual environment, with the following modules installed:
    * Dotenv (`python3 -m pip install python-dotenv`),
    * Defused XML (`python3 -m pip install defusedxml`), and
    * Requests (`python3 -m pip install requests`).

For customisation options see the
[documentation site](https://jisccti.github.io/misp-docker/configuration/general/).

### High Availability Simulation

To simulate a High Availability setup with Quick Start add the `--ha` option, this will spawn two
misp-web frontend containers behind a HAProxy load balancing container.

**Note:** It is expected for the HA Proxy container to continually restart until a misp-web
container generates the TLS keypair needed for a successful startup.

### SAML2/Shibboleth Testing

To test with SAML2/Shibboleth Single Sign On, ensure the appropriate options have been set in `.env`
(see the [SAML2 Documentation](https://jisccti.github.io/misp-docker/configuration/shibb/)), then
run Quick Start with the `--shibb` option.
