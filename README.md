<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Docker Images

[![CodeFactor](https://www.codefactor.io/repository/github/jisccti/misp-docker/badge)](https://www.codefactor.io/repository/github/jisccti/misp-docker)
[![Production Images](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml/badge.svg)](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml)

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-web](https://img.shields.io/docker/v/jisccti/misp-web?sort=semver&logo=docker&label=misp-web)![misp-web size](https://img.shields.io/docker/image-size/jisccti/misp-web/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-web)
[![misp-workers](https://img.shields.io/docker/v/jisccti/misp-workers?sort=semver&logo=docker&label=misp-workers)![misp-workers size](https://img.shields.io/docker/image-size/jisccti/misp-workers/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-workers)

[![MISP-Modules release](https://img.shields.io/github/v/tag/MISP/misp-modules?logo=github&label=MISP-Modules%20(source))](https://github.com/MISP/misp-modules)
[![misp-modules](https://img.shields.io/docker/v/jisccti/misp-modules?sort=semver&logo=docker&label=misp-modules)![misp-modules size](https://img.shields.io/docker/image-size/jisccti/misp-modules/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-modules)

Project to build a set of three docker images containing the components of [MISP](https://github.com/MISP/MISP) with
self-configuration into a usable state from first start.

**This GitHub repository is for maintaining the images, to use the images see
[`jisccti/misp-web` on DockerHub](https://hub.docker.com/r/jisccti/misp-web) instead.**

## Build Dependencies

The images have been build and tested against [Docker Engine v24]((https://docs.docker.com/engine/install/#server)).

The images should build on any Linux-based Docker Engine which supports multi-stage images and the final images should
run on any Linux-based Docker Engine.

## Runtime Dependencies

The created Docker images contain only the MISP components and depend on the following external services:

* ClamAV TCP endpoint. Tested against Docker image: `clamav/clamav:1.0_base`.
* MySQL/MariaDB server (5.7 or 8.0). Tested against Docker image: `mysql/mysql-server:8.0`.
* Redis server (v6 or v7). Tested against Docker Image: `redis:7`.
* An SMTP service. Tested against a Postfix v3.6.4 server.

## System Requirements

The smallest VM this deployment was tested on had:

* 2 Cores
* 8GB RAM
* 50GB Storage

Depending on the features used, MISP can run on very little resources and could potentially run with less RAM.

## Quick Start Deployment

`quickstart.py` is designed to create a test instance of MISP for validation of changes to the builds, it will:

* Create a "best guess" `.env` file,
* **Delete *ALL* existing persistent storage**,
* Pull the three required external images,
* Build the three images in this project,
* Start MISP on https://{docker-hostname}/

As this deployment method uses best guesses for important values, it **should not be used in production environments**.

Quick Start requires:

* Python >= 3.6,
* Pip >= 21.2, and
* Dotenv Python package: `python3 -m pip install --user python-dotenv`

### High Availability Simulation

To simulate a High Availability setup with Quick Start add the `--ha` option, this will spawn two misp-web frontend
containers behind a HAProxy load balancing container. 

**Note:** It is expected for the HA Proxy container to continually restart until a misp-web container completes its
initial setup, generating the TLS keypair needed for a successful startup.

## Custom Deployment

MISP can be deployed in a more predictable / customised way following these steps. **This is designed for testing
changes to the images only, for test and production environments see 
[`jisccti/misp-web` on DockerHub](https://hub.docker.com/r/jisccti/misp-web) instead.**

In the following paths, replace `{instanceName}` with the folder name, `misp-docker` by default, or the Docker Compose
project name if you specify one on the command line or in the `COMPOSE_PROJECT_NAME` environment variable.

This deployment method requires Python >= 3.6 to get the current version of MISP from GitHub.

### 1 - Set Deployment Variables

Passwords set in `.env` ***MUST NOT*** contain the backslash `\` character - they will cause the initial setup process
to fail.

1. Copy `example.env` to `.env`
2. Customise `.env` as follows:

| Variable | Description |
| -------- | ----------- |
| CLAMAV_HOSTNAME | The hostname or IP of a host with ClamAV exposed on port 3310. |
| FQDN | The fully qualified domain name users will use to access MISP. |
| GPG_PASSPHRASE | The passphrase to generate / access the GnuPG key used by MISP. |
| HTTP_PORT | The port HTTP will be exposed on at the FQDN. |
| HTTPS_PORT | The port HTTPS will be exposed on at the FQDN. |
| MISP_EMAIL_ADDRESS | The email address MISP will send emails from. |
| MISP_EMAIL_NAME | The email display name MISP will use. |
| MISP_HOSTNAME | The internal hostname of the MISP Web container. |
| MODULES_HOSTNAME | The internal hostname of the MISP Modules container. |
| MYSQL_DBNAME | The database to use for MISP. |
| MYSQL_HOSTNAME | The hostname of the MySQL container OR the FQDN of the external MySQL service. |
| MYSQL_PASSWORD | The password MISP will use to connect to MySQL. |
| MYSQL_ROOT_PASSWORD | The root password that will be set in the MySQL container. |
| MYSQL_USERNAME | The username MISP will use to connect to MySQL. |
| ORG_NAME | The organisation that owns this instance of MISP. |
| REDIS_HOST | The hostname of the Redis container OR the FQDN of the external Redis service. |
| REDIS_MISP_DB | The database number to use for MISP within Redis. |
| REDIS_PASSWORD | The password to set on the Redis container AND / OR that MISP will use to connect to Redis. |
| REDIS_WORKER_DB | The database number to use for the MISP Workers within Redis. |
| SMTP_HOSTNAME | The FQDN of the SMTP service. |
| SMTP_PASSWORD | The password MISP will use to connect to the SMTP service. |
| SMTP_PORT | The port the SMTP service is listening on, typically 587. |
| SMTP_STARTTLS | If the SMTP service supports STARTTLS encryption, case-sensitive `true` or `false`. |
| SMTP_USERNAME | The username MISP will use to connect to the SMTP service. |
| WORKERS_HOSTNAME | The hostname of the MISP Workers container. |
| WORKERS_PASSWORD | The password MISP will use to connect to the MISP Workers container's Supervisor interface. |

### 2 - Pull and Build Images

Pull the external images as required, and build the latest version of the three MISP images.

```sh
sudo docker pull clamav/clamav:1.0_base
sudo docker pull redis:7
sudo docker pull mysql/mysql-server:8.0

cd misp-modules
VERSION=$(python3 latest.py); sudo docker build --pull --quiet --tag jisccti/misp-modules:latest --tag jisccti/misp-modules:"$VERSION" --build-arg MISP_VERSION="$VERSION" .

cd ../misp-web
VERSION=$(python3 latest.py); sudo docker build --pull --quiet --tag jisccti/misp-web:latest --tag jisccti/misp-web:"$VERSION" --build-arg MISP_VERSION="$VERSION" .

cd ../misp-workers
sudo docker build --quiet --tag jisccti/misp-workers:latest --tag jisccti/misp-workers:"$VERSION" --build-arg MISP_VERSION="$VERSION" .
```

### 3 - Import GnuPG Keys

If you have an existing GnuPG private key to import to MISP, copy this, in ASCII-armored format, to 
`./persistent/{instanceName}/gpg/import.asc`, ensuring `GPG_PASSPHRASE` is correctly set in `.env`.

### 4 - Import TLS Certificate

If you have a TLS certificate ready for MISP:

1. Place the certificate, then any required certificate chain, and finally the content of 
  https://ssl-config.mozilla.org/ffdhe2048.txt* into ``./persistent/{instanceName}/tls/misp.crt`.
2. Place the **unencrypted** private key into `./persistent/{instanceName}/tls/misp.key`.
3. If using the HA simulation, place certificate, private key and chain and `ffdhe2048`* into 
  `./persistent/{instanceName}/tls/haproxy.pem`.

*This ensures OpenSSL does not use insecure Ephemeral Diffie-Hellman (DHE) keys while establishing TLS sessions with
clients using DHE for key exchange, per the [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/).

### 5 - Add Custom Image Files

If any custom image files are needed for MISP settings (below), create these folders and place the files accordingly:

* Images (e.g. for the logon screen): `./persistent/{instanceName}/data/images/`.
* Organisation Icons: `./persistent/{instanceName}/data/icons/`.

Any other custom files, such as tagging taxonomies, should be placed within `./persistent/{instanceName}/data/` but not
in their final destination, these should be copied into their final location in step 6 below to prevent conflicts.

### 6 - MISP Settings

To customise MISP settings during initial setup create `./persistent/{instanceName}/data/custom-config.sh` and populate
it as follows:

```sh
#!/bin/bash

# Configuring MISP
$CAKE Admin setSetting "MISP.setting1" "new value"
$CAKE Admin setSetting "MISP.setting2" true

# Installing taxonomies
cp -r /var/www/MISPData/my-files/my-taxonomy /var/www/MISPData/files/taxonomies/
```

`$CAKE` will be populated with the command to run `CakePHP` as the web server user by the image build process.

### 7 - Deploy MISP

To deploy MISP:

1. Remove any unneeded service definitions from `docker-compose.yml` (or `docker-compose-ha.yml` for HA simulation),
  e.g. `misp_clamav`, `misp_db`, and / or `misp_redis`.
2. Start the Docker service: `sudo docker compose up -d` (or `sudo docker compose -f docker-compose-ha.yml up -d` for
  HA simulation).
3. Monitor the startup process of MISP: `sudo docker compose logs -f` (or
  `sudo docker compose -f docker-compose-ha.yml logs -f` for HA simulation).

### 8 - Access MISP

Once `misp-web` reports this line:

```log
[core:notice] [pid 7] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
```

1. Access MISP via https://{FQDN}:{HTTPS_PORT}.
2. Log in using `admin@admin.test` / `admin`.
3. Change the password and setup your OTP token when prompted.
4. Go to Administration / List Users.
5. Click edit on user `admin@admin.test`.
6. Update the email address accordingly.
7. Go to Administration / List Organisations.
8. Click edit on `ORGNAME`.
9. Update the default organisation accordingly.
7. Check these sections of Administration / Server Settings & Maintenance / Diagnostics:
  * **PHP Settings** - all should be green,
  * **PHP Extensions** - all should show green ticks under Web and CLI,
  * **Redis info** - should show the server version and some memory usage.
  * **Advanced attachment handler** - all should show "OK".
  * **Attachment scan module** - should show a status of "OK" - this may take a few minutes while ClamAV loads its DB.
  * **STIX and Cybox libraries** - all should show a green tick under status.
  * **Yara** - should show a status of "OK".
  * **GnuPG** - should show a status of "OK".
  * **Module System** - Enrichment, Import and Export should show a status of "OK".
  * **PHP Sessions** - should show `php_redis` as the handler and a status of "OK".

#### Database Schema Discrepancies

Due to how MISP deploys its databases and discrepancies between versions 5.7 and 8.0 of MySQL:

* It is normal for **Schema status** to show a high number of minor discrepancies (E.g. `int` vs `int(11)`) - these can
  be ignored, alternatively, MISP provides MySQL queries to run on the MySQL command line interface to try and fix these
  discrepancies, if desired, by clicking the Spanner (Fix database schema) icon.
* It is normal for **Schema status** to show some fields are indexed that shouldn't be and vice versa, these indexes can
  optionally be created / removed via the MySQL command line interface using the commands provided by clicking the
  Spanner (Fix database schema) icon.

### 9 - Adding Custom Content

Where you need to add taxonomies and similar custom content after initial setup, these can be placed in the respective
sub-directories of `./persistent/{instanceName}/data/files/` and loaded into the database by running
`/opt/scripts/update-objects.sh` within the container.

### 10 - Automated Maintenance

Routine tasks have been automated in the misp-workers container which will run the following:

| Task | Frequency |
| ---- | --------- |
| Rotate log files | Hourly |
| Run feed and server synchronisation tasks | Hourly |
| Update Decay Models, Galaxies, Notice Lists, Objects, Taxonomies, Warning Lists, and Workflow Blueprints | Daily |

#### Custom Automations

The maintenance scheduling system is extensible, meaning you can add your own automations to run periodically.

To add a custom automation:

1. Create your automation, if you need to talk to the MISP API, it is recommended you read `authKey`, `baseUrl`, and
  `verifyTls` from the `DEFAULT` section of `/var/www/MISPData/misp_maintenance_jobs.ini` for consistency.
2. Place the automation into its own folder within `/var/www/MISPData/custom_scripts` on the `misp-workers` container.
    * For Python automations, use `/usr/local/bin/python3 -m venv venv` to create a virtual environment.
3. Add a section to `/var/www/MISPData/misp_maintenance_jobs.ini` to schedule your task (see the example below).
    * The section name (`unique_job_name` below) must be unique.
    * `command` should use absolute paths to executables and scripts.
    * `enabled` allows a job to be temporarily disabled without removing it.
    * `interval` sets how often the automation should be triggered, in minutes.
    * `lastRun` is set by the scheduling system and should be set to 0 on creation.
    * Setting `needsAuthKey` to `True` will prevent the automation from running until a valid Auth Key has been set as
      above.

```ini
[unique_job_name]
command = /var/www/MISPData/custom_scripts/unique_job_name/venv/python3 /var/www/MISPData/custom_scripts/unique_job_name/unique_job_name.py
enabled = True
interval = 60
lastRun = 0
needsAuthKey = False
```
