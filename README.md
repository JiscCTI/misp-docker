<!--
SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
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

**This GitHub repository is for maintaining the images, to use the images please see
[jisccti/misp-web on DockerHub](https://hub.docker.com/r/jisccti/misp-web) instead.**

## Build Dependencies

The images have been build and tested against
[Docker Engine v26]((https://docs.docker.com/engine/install/#server)), but should build on any
Linux-based Docker Engine which supports multi-stage images and the built images should run on any
Linux-based Docker Engine.

## Runtime Dependencies

The created Docker images contain only the MISP components and depend on the following external
services:

* ClamAV TCP endpoint. Tested against Docker image: `clamav/clamav:1.0_base`.
* MySQL/MariaDB server (5.7 or 8.0). Tested against Docker image: `mysql/mysql-server:8.0`.
* Redis server (6, 7 or 8). Tested against Docker Image: `redis:8`.
* An SMTP service. Tested against Postfix.

## System Requirements

The standard [docker_compose.yml](./docker-compose.yml) deployment has been tested on a system with:

* 2 Cores
* 8GB RAM
* 50GB Storage

Depending on the features used, MISP can run on very little resources and could potentially run with
less RAM.

## Quick Start Deployment

`quickstart.py` is designed to create a test instance of MISP for validation of changes to the
builds it **should not be used in production environments**.

It will:

* Create a "best guess" `.env` file if one does not exist,
* Delete ALL existing persistent storage,
* Pull the three required external images,
* Build the three images in this project,
* Start MISP at https://{docker-hostname}/.

Quick Start requires:

* Python >= 3.6 with pip >= 21.2, and
* Dotenv (can be installed with `python3 -m pip install --user python-dotenv`).
* Defused XML (can be installed with `python3 -m pip install --user defusedxml`)
* Requests (can be installed with `python3 -m pip install --user requests`).

For a more customised test instance see the [misp-web](./docs/misp-web.md) documentation.

### High Availability Simulation

To simulate a High Availability setup with Quick Start add the `--ha` option, this will spawn two
misp-web frontend containers behind a HAProxy load balancing container.

**Note:** It is expected for the HA Proxy container to continually restart until a misp-web
container completes its initial setup, generating the TLS keypair needed for a successful startup.
