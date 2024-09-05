<!--
SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# Development Principles

The project was started as at the time there was not a deployment option which we felt met all of
our needs, speaking to partners they've liked our approach and have adopted our containers too.

The aim of the project is to deliver MISP in a way which:

* Is simple to get started.
* Is simple to maintain.
* Supports all core and optional functionality.
* Supports Single Sign On (SSO).
* Supports high-availability.
* Supports cloud deployment.

## Configuration Options

All core configuration options should have environment variables available, with sensible default
values. Each environment variable should be validated and used to reconfigure MISP on every startup.

## Optional Functionality

Optional functionality should be supported as much as possible, without impeding on core
functionality, e.g. install all dependencies but not setting default options which would require an
optional service or component which not all users will have free access to.
