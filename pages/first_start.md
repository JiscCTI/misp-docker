<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Clive Bream
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->

# Starting MISP For the First Time

To deploy MISP run the following command `sudo docker compose up -d`. Please note that the project
checks for a number of service health dependencies and will take a few minutes for all containers to
be started.

Once all containers have started, you can monitor the startup process using
`sudo docker container logs -f misp-web-1` (press CTRL+C to stop monitoring).

MISP should be available at `https://{FQDN}:{HTTPS_PORT}` when the container logs:

```log
[core:notice] [pid 7] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
```

Once MISP is available, renaming the default organisation from ORGNAME to the value of `ORG_NAME`
may take a few minutes to complete, you can wait for the log file to be created and for
`Organisation updated` to be logged using:
`while [ ! -f persistent/misp/data/tmp/logs/set_org_name.log ]; do sleep 0.5; done; tail -f persistent/misp/data/tmp/logs/set_org_name.log​`

if this does not occur, check `persistent/misp/data/tmp/logs/misp_maintenance_runner.log`.
The log entry `[WARNING] MISP isn't up at ...` should stop occurring once the above message has been
logged, if it does not, `FQDN` and / or `HTTPS_PORT` may be incorrect, `FQDN` must have a valid DNS
entry pointed to the MISP instance, cross container communication between workers and web is also
required.

## Access MISP

Once MISP is running, and the Organisation Name and UUID have been set, go to
`https://{FQDN}:{HTTPS_PORT}` and login with the default credentials: `admin@admin.test` with the
password `admin`.

**Note**: You will be forced to change this password, please ensure it is suitably strong as this
will be the password for the default admin account. It is also recommended that once the password
has been changed, you also change the email of the default admin account to a valid address, such as
a shared inbox for the team responsible for your MISP instance, e.g. mispteam@knowhere.ac.uk. This
can be changed via Administration / List Users and finding the user you would like to change (at
this point there should only be one user, the account you are logged into), use the Edit button on
the right side of the screen and change the email to the desired inbox.

## Instance Health & Diagnostics

MISP has a diagnostics page you can check at Administration / Server Settings & Maintenance /
Diagnostics, the expected output is all green down to the Database Schema and again from Redis to
the bottom of the page, with the exception of "Cortex module system... System not enabled".

### Database Schema Discrepancies

Due to discrepancies between versions of MySQL, the **Schema status** will show a high number of
minor discrepancies (E.g. `int` vs `int(11)`) - these can be ignored.

**Schema status** may also show some fields are indexed that shouldn't be or that should be but are
not. These fields can also be ignored but performance may not be optimal. MISP provides the MySQL
commands to fix indexing: click the Spanner (Fix Database Index Schema) icon, and run the provided
command manually against the MySQL database.
