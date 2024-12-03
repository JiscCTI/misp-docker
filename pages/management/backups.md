<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Creating Backups

It is recommended that you periodically backup your MISP instance, especially before applying
updates and other significant changes.

## Stop MISP

It is recommended to tear down the container first, to ensure no in-memory database transactions are
missed when the backup is taken. 

This can be done with the command `docker compose down`

## Backup MISP

This step will vary depending on your local back solutions, for the sake of example we will create a
simple .tar.gz archive in a backup folder.

```sh
mkdir -p backups
tar cfz backups/20241203-MISPBackup.tar.gz persistent/misp/
```

## Restart MISP

Once the backup has been taken, bring MISP back online using `docker compose up -d`.

## Restoring from Backups

if you need to restore a backup:

1. Stop MISP with `docker compose down`,
2. Delete the `persistent/misp/` directory,
3. Restore `persistent/misp/` from the backup, and
4. Start MISP with `docker compose up -d`.
