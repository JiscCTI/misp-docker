<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Deploying MISP On-Premises

If you are looking to deploy MISP locally, follow the steps in this guide to set up the host machine
before moving on to [Configuration](../configuration/general.md).

## Installing Docker

Firstly, you will need to install Docker, to do this please follow the official
[Docker installation instructions](https://docs.docker.com/engine/install/) for your chosen
Operating System.

## Docker Compose Configuration

Once Docker is installed, create a new directory to host your MISP instance, for ease of reference
this documentation uses `/opt/misp`.

Download the latest
[docker-compose.yml](https://github.com/JiscCTI/misp-docker/blob/main/docker-compose.yml) file from
GitHub to `/opt/misp/docker-compose.yml`.

By default the `docker-compose.yml` file provides ClamAV, MySQL and Redis. If you will be providing
these components another way, such as through managed Cloud Services, then please comment these
sections out using `#`s at the start of each relevant line.

## Configure MISP

Now move on to [Configuring MISP](../configuration/general.md).
