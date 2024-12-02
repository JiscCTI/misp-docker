<!-- # SPDX-FileCopyrightText: 2024 Jisc Services Limited
# SPDX-FileContributor: Clive Bream
# SPDX-FileContributor: James Ellor
#
# SPDX-License-Identifier: GPL-3.0-only
-->

## Deploying MISP For the First Time

To deploy MISP run the following command `sudo docker compose up -d` as the `docker-compose.yml` file. Please note that this file checks for a number of service health configuration dependencies and may take a few minutes for all containers to be started.

Once all containers have started, you can monitor the startup process using `sudo docker container logs -f {instanceName}-web-1` (press CTRL+C to stop monitoring).

MISP should be available by navigating to `https://{FQDN}:{HTTPS_PORT}` when the container logs:

```log
[core:notice] [pid 7] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
```

**Note**: Renaming the default organisation from ORGNAME to `ORG_NAME` may take a few minutes, if this does not occur, check `persistent/{instanceName}/data/tmp/logs/misp_maintenance_runner.log`. The log entry `[WARNING] MISP isn't up at ...` should stop occurring once the above message has been logged, if it does not, `FQDN` and / or `HTTPS_PORT` may be incorrect, `FQDN` may not have a DNS entry, or a firewall may be preventing cross container communication.

## Access MISP

Once MISP is running, it can be accessed by navigating to `https://{FQDN}:{HTTPS_PORT}` the default credentials are: `admin@admin.test` with a password of `admin`. 

**Note**: You will be forced to change this password, please ensure it is suitably strong as this will be the password for the default admin account. It is also recommended that once the password has been changed, you also change the email of the default admin account to a different email, such as a shared inbox for the team responsible for your misp instance, e.g. mispteam@knowhere.ac.uk. This can be changed via Administration / List Users and finding the user you would like to change (at this point there should only be one user, the account you are logged into), use the Edit button on the right side of the screen and change the email to the desired inbox. 

MISP has a diagnostics page you can check at Administration / Server Settings & Maintenance / Diagnostics, the expected output is all green down to the Database Schema and again from Redis to the bottom of the page, with the exception of "Cortex module system... System not enabled".

### Database Schema Discrepancies

Due to discrepancies between versions of MySQL, the **Schema status** will show a high number of minor discrepancies (E.g. `int` vs `int(11)`) - these can be ignored.

**Schema status** may also show some fields are indexed that shouldn't be or that should be but are not. These fields can also be ignored but performance may not be optimal. MISP provides the MySQL commands to fix indexing: click the Spanner (Fix Database Index Schema) icon, and run the provided command manually against the MySQL database.
