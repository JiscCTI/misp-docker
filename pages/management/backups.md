<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->
# Creating Backups

It is recommended to tear down the container first, to ensure nothing in memory is also persisted when the backup is taken. Once the container has been tore down, create a backup of the `persistent/misp` directory using a method of your choice, e.g. creating a `.tar`/`.targz` or using a backup solution.

# Restoring from Backups

Using the backup you created in the steps above, deploy the backup files to their respective directory on the docker container and start the container using `docker compose up -d`
