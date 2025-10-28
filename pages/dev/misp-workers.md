<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->
# misp-workers Image

The misp-workers image contains the background workers for MISP. This image must not be replicated,
or race conditions will occur starting background jobs.

## Build

The image starts from the `php:8.4-cli` and imports MISP from the `jisccti/misp-web` image for the
MISP version being built.

The image also installs Supervisor for managing the workers.

## Entrypoint

The entrypoint for the image:

* Restores persistent storage.
* Sets the supervisor password from the respective environment variable.
* Starts supervisor.

## Health Check

The image contains a basic health check which reports healthy (exit code 0) all jobs managed by
supervisor are healthy and otherwise reports unhealthy (exit code 1).

If any job has failed too many times, supervisor will stop trying to restart it, if this state is
detected, the health check script will kill the supervisor process, causing the container to
restart.

## Exposed Ports

The image exposes 9001/tcp - the supervisor status page, read by the misp-web container.

## Volumes

The image uses the following volumes:

| Mount Point | Purpose |
|-------------|---------|
| /var/www/MISPData | Holds the instance specific data which needs to be persisted between updates and container recreations. |
| /var/www/MISPGnuPG | Holds the GPG/PGP key chain used by MISP for email signing and encryption. |
