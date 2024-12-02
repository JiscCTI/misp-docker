<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->
# Upgrading the MISP Instance

In order to upgrade the MISP instance when new images are pushed to the DockerHub repository, follow the steps below. **Note:** It is **highly** recommended that you create a backup of your data already in the MISP instance before proceeding with an upgrade to the instance. Steps to create a backup can be found on the [Backups Page](/backups.md)

Firstly, use the `docker compose pull` command to pull any new/updated images from the DockerHub repository.

Next, use the following command which tells Docker to tear down the current containers, and re-deploy them using the latest images that have been pulled from the first step `docker compose up -d --force-recreate`.

Your MISP instance should now re-deploy and once started, be using the latest images/version.
