<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: Clive Bream
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Starting MISP For the First Time

For an [On-Premises Deployment](deploy/local.md), to start MISP for the first time move to your
MISP directory (`cd /opt/misp`) and run `sudo docker compose up -d`. Please note that the project
checks for a number of service health dependencies and it will take a few minutes for all containers
to be started.

Once all containers have started, you can monitor the startup process using
`sudo docker container logs -f misp-web-1` (press CTRL+C to stop monitoring).

MISP should be available at `https://{FQDN}:{HTTPS_PORT}` when the container logs:

```log
[core:notice] [pid 7] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
```

Once MISP is available, renaming the default organisation from ORGNAME to the value of the
`ORG_NAME` environment variable may take a few minutes to complete, you should for this to happen
before continuing. To do this run the following command and wait for `Organisation updated` to be
logged:
`while [ ! -f persistent/misp/data/tmp/logs/set_org_name.log ]; do sleep 0.5; done; tail -f persistent/misp/data/tmp/logs/set_org_name.log​`

if this does not occur, check `persistent/misp/data/tmp/logs/misp_maintenance_runner.log`.
The log entry `[WARNING] MISP isn't up at ...` should stop occurring once the above `core:notice`
message has been logged by `misp-web`, if it does not, `FQDN` and / or `HTTPS_PORT` may be
incorrect, `FQDN` must have a valid DNS entry pointed to the MISP instance, cross container
communication between workers and web is also required.

For a [Cloud Deployment](deploy/cloud.md) follow your chosen provider's documentation to start the
containers and monitor the logs for the above message.

***NOTE*** The database container log will warn about the `--skip-host-cache` option being
deprecated, this option is set within the container image itself and can be ignored.

## Access MISP

Once MISP is running, and the Organisation Name and UUID have been set, go to
`https://{FQDN}:{HTTPS_PORT}` and login with the default credentials: `admin@admin.test` with the
password `admin`.

1. You will be forced to change this password, please ensure it is suitably strong as this will be
    the password for the default admin account.
1. Unless the `REQUIRE_TOTP` environment variable was set to `false` you will also be force to set
    up the accounts Time-base One Time Password (TOTP) token.
1. It is recommended that once the password has been changed, you also change the email of the
    default admin account to a valid address, such as a shared inbox for the team responsible for
    your MISP instance, e.g. mispteam@knowhere.ac.uk.
    1. Go to Administration / List Users,
    1. Find the `admin@admin.test` user (at this point there should only be one user),
    1. Click use the Edit button on the right side of the screen,
    1. Change the email to the desired inbox,
    1. Confirm your password, and
    1. Click Submit.

## Instance Health & Diagnostics

MISP has a diagnostics page you can check at Administration / Server Settings & Maintenance /
Diagnostics, the expected output is all green down to the Database Schema and again from Redis to
the bottom of the page, with the exception of "Cortex module system... System not enabled".

### Database Schema Discrepancies

Due to discrepancies between versions of MySQL, the **Schema status** may show a high number of
minor discrepancies (E.g. `int` vs `int(11)`) - these can be ignored.

**Schema status** may also show some fields are indexed that shouldn't be or that should be but are
not. These fields can also be ignored but performance may not be optimal. MISP provides the MySQL
commands to fix indexing: click the Spanner (Fix Database Index Schema) icon, and run the provided
command manually against the MySQL database.

### Workers Tab

The Workers tab under Administration / Server Settings & Maintenance will show these errors, both
can be safely ignored:

* `Issues prevent jobs from being processed. Please resolve them below.` for all queues.
* `The worker was started with a user other than the apache user. MISP cannot check whether or not the worker is alive.`
    For all processes.

This occurs as the workers are running in a different container, meaning this health check cannot
communicate directly with the processes to check if they are alive.
