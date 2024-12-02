<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->
# misp-modules Image

The misp-modules image contains the import, export and enrichment modules for MISP. This image can
be replicated to support high availability.

## Build

The image starts from the `python:3.12-slim-bookworm` and installs the `misp-modules` package and
its dependencies in one stage, patches a python2 to 3 migration issue before copying the compiled
modules into the final image.

## Entrypoint

The entrypoint for the image points directly to the `misp-modules` executable.

## Health Check

The image contains a basic health check which reports healthy (exit code 0) if it can fetch a list
of enabled modules and otherwise reports unhealthy (exit code 1).

## Exposed Ports

The image exposes 6666/tcp - the modules web interface.

## Volumes

The image has no volumes.
