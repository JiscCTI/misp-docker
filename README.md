<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP Docker Images

[![Production Images](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml/badge.svg)](https://github.com/jisccti/misp-docker/actions/workflows/production-images.yml)

A set of three docker images containing the components of MISP.

## Dependencies

This project requires the following external components.

* ClamAV version 1.0, exposing a TCP interface. Docker image: `clamav/clamav:1.0_base`.
* A MySQL/MariaDB server running either 5.7 or 8.0. Docker image: `mysql/mysql-server:8.0`.
* A Redis server running v6 or v7. Docker Image: `redis:7`.
* An SMTP service.

## System Requirements

The smallest VM this deployment was tested on had:

* 2 Cores
* 8GB RAM
* 50GB Storage

Depending on the features used, MISP can run on very little resources and could potentially run with less RAM.

## Prerequisites

Base requirements:

* Docker 24.0 - [Installation instructions](https://docs.docker.com/engine/install/#server). For Rocky 8/9, following
the CentOS instructions works.

In order to run the `quickstart.py` script:

* Python 3.6, 
* Pip 21.2
* Dotenv Python package: `python3 -m pip install --user python-dotenv`

## Testing / Quick Start Deployment

`quickstart.py` is designed to create a testing instance of MISP easily, it will:

* Create a "best guess" `.env` file,
* Delete any existing persistent storage,
* Pull the three required external images,
* Build the three images in this project,
* Start MISP on https://{docker-hostname}/

As this deployment method uses best guesses for some important values, it should not be used in production environments.

### High Availability Simulation

To simulate a High Availability setup with quickstart add the `--ha` option, this will spawn three misp-web backend 
containers and a HAProxy frontend container. The HA Proxy container will continually restart until a misp-web container
completes its initial setup, generating the required TLS file.

## Production / Custom Deployment

MISP can be deployed in a more predictable / customised way following these steps.

In the following paths, replace `{instanceName}` with `misp-docker` by default, or the Docker Compose project name used
on the command line if different.

### 1 - Set Deployment Variables

Passwords set in `.env` ***MUST NOT*** contain the backslash `\` character.

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

```bash
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

1. Create `./persistent/{instanceName}/tls/`,
2. Place the certificate, chain, and the content of https://ssl-config.mozilla.org/ffdhe2048.txt into
  `./persistent/{instanceName}/tls/misp.crt`.
2. Place the unencrypted private key into `./persistent/{instanceName}/tls/misp.key`.
4. If using the HA simulation, place certificate, private key and chain into `./persistent/{instanceName}/tls/haproxy.pem`.

### 5 - Add Custom Image Files

If any custom image files are needed for MISP settings (below), create these folders and place the files accordingly:

* Images (e.g. for the logon screen): `./persistent/{instanceName}/data/images/`.
* Organisation Icons: `./persistent/{instanceName}/data/icons/`.

### 6 - MISP Settings

To customise MISP settings automatically post deployment create `./persistent/{instanceName}/data/custom-config.sh` and populate it
as follows:

```bash
#!/bin/bash

$CAKE Admin setSetting "MISP.setting1" "new value"
$CAKE Admin setSetting "MISP.setting2" true
```

`$CAKE` will be populated with the command to run `CakePHP` as the web server user by the image build process.

### 7 - Deploy MISP

To deploy MISP:

1. Remove any unneeded service definitions from `docker-compose.yml`, namely `misp_clamav`, `misp_db`, and / or
  `misp_redis`.
2. Start the Docker service: `sudo docker compose up -d` (or `sudo docker compose -f docker-compose-ha.yml up -d` for
  HA simulation).
3. Monitor the startup process of MISP Web: `sudo docker container logs -f {instanceName}-misp_web-1` (or
  `sudo docker container logs -f {instanceName}-misp_webs_1` for HA simulation).

### 8 - Access MISP

1. Access MISP via https://{FQDN}:{HTTPS_PORT}
2. Log in using `admin@admin.test` / `admin`.
3. Change the password when prompted.
4. Go to Administration / List Users.
5. Click edit on user `admin@admin.test`.
6. Update the email address accordingly.
7. Check these sections of Administration / Server Settings & Maintenance / Diagnostics:
  * **PHP Settings** - all should be green,
  * **PHP Extensions** - all should show green ticks under Web and CLI,
  * **Redis info** - should show the server version and some memory usage.
  * **Advanced attachment handler** - all should show "OK".
  * **Attachment scan module** - should show a status of "OK".
  * **STIX and Cybox libraries** - all should show a green tick under status.
  * **Yara** - should show a status of "OK".
  * **GnuPG** - should show a status of "OK".
  * **Module System** - Enrichment, Import and Export should show a status of "OK".
  * **PHP Sessions** - should show `php_redis` as the handler and a status of "OK".

#### Database Schema Discrepancies

Due to how MISP deploys its databases and discrepancies between versions of MySQL:

* It is normal for **Schema status** to show a high number of minor discrepancies (E.g. `int` vs `int(11)`) - these can
  be ignored, alternatively, MISP provides MySQL queries to run on the MySQL command line interface to try and fix these
  discrepancies, if desired, by clicking the Spanner (Fix database schema) icon.
* It is normal for **Schema status** to show some fields are indexed that shouldn't be, these indexes can optionally
  be removed via the MySQL command line interface using the commands provided by MISP as above.

### 9 - Adding Custom Content

Where you need to add taxonomies and similar custom content, these can be placed in the respective sub-directories of
`./persistent/{instanceName}/data/files/` and loaded into the database as normal.
