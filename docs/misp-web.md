# MISP Web UI & API

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-web](https://img.shields.io/docker/v/jisccti/misp-web?sort=semver&logo=docker&label=misp-web)![misp-web size](https://img.shields.io/docker/image-size/jisccti/misp-web/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-web)
[![misp-workers](https://img.shields.io/docker/v/jisccti/misp-workers?sort=semver&logo=docker&label=misp-workers)![misp-workers size](https://img.shields.io/docker/image-size/jisccti/misp-workers/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-workers)

[![MISP-Modules release](https://img.shields.io/github/v/tag/MISP/misp-modules?logo=github&label=MISP-Modules%20(source))](https://github.com/MISP/misp-modules)
[![misp-modules](https://img.shields.io/docker/v/jisccti/misp-modules?sort=semver&logo=docker&label=misp-modules)![misp-modules size](https://img.shields.io/docker/image-size/jisccti/misp-modules/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-modules)

MISP with self-configuration into a usable state from first start.

This image is designed to be used in conjunction with
[jisccti/misp-modules](https://hub.docker.com/r/jisccti/misp-modules) and
[jisccti/misp-workers](https://hub.docker.com/r/jisccti/misp-workers) and is dependent on
third-party ClamAV, MySQL, Redis and SMTP services.

Single Sign On (SSO) support:

* Microsoft Entra ID (formerly Azure Active Directory) -
  [awaiting upstream fixes](https://github.com/JiscCTI/misp-docker/issues/20).
* OpenID Connect (OIDC) - [Configuration guide](https://github.com/JiscCTI/misp-docker/blob/main/docs/oidc.md).
* Shibboleth / SAML 2.0 - [Configuration guide](https://hub.docker.com/r/jisccti/misp-shibb-sp).

## 1 - Docker Compose

Create a directory to host your MISP instance and download the latest
[docker-compose.yml](https://github.com/JiscCTI/misp-docker/blob/main/docker-compose.yml) file from
GitHub.

By default, the `docker-compose.yml` file provides ClamAV, MySQL, and Redis for you, if you will
provide these another way, such as managed cloud services, then comment out these sections with
`#`s at the start of each line and be sure to set the relevant Environment Variables below.

In the following instructions, replace `{instanceName}` with `misp` or the Docker Compose project
name if you specify one on the command line or in the `COMPOSE_PROJECT_NAME` environment variable.

## 2 - Environment Variables

Create a file called `.env`, adding all options you'd like to override, one per line in the format
`OPTION_NAME=desired value`. It is strongly recommended you override the settings in **bold** below.

Passwords ***MUST NOT*** contain the backslash (`\`) character or the container will not start
properly.

| Option Name | Description | Default Value |
| ----------- | ----------- | ------------- |
| CLAMAV_HOSTNAME | The hostname or IP of a host with ClamAV exposed on port 3310. | `misp_clamav` |
| **FQDN** | The fully qualified domain name users will use to access MISP. | `misp.local` |
| **GPG_PASSPHRASE** | The passphrase to generate / access the GnuPG key used by MISP. | `misp` |
| HTTP_PORT | The port HTTP will be exposed on at the FQDN - redirects to HTTPS. | `80` |
| HTTPS_PORT | The port HTTPS will be exposed on at the FQDN. | `443` |
| **MISP_EMAIL_ADDRESS** | The email address MISP will send emails from. | `misp@local` |
| MISP_EMAIL_NAME | The email display name MISP will use. | `MISP` |
| MISP_HOSTNAME | The internal hostname of the MISP Web container. | `misp_web` |
| MODULES_HOSTNAME | The internal hostname of the MISP Modules container. | `misp_modules` |
| MYSQL_DBNAME | The database to use for MISP. | `misp` |
| MYSQL_HOSTNAME | The hostname of the MySQL service. | `misp_db` |
| **MYSQL_PASSWORD** | The password MISP will use to connect to MySQL. Must have all privileges on `MYSQL_DBNAME` for a third-party DB. | `misp` |
| **MYSQL_ROOT_PASSWORD** | The root password that will be set in the MySQL container. Not used for a third-party DB. | `misp` |
| MYSQL_USERNAME | The username MISP will use to connect to MySQL. | `misp` |
| **ORG_NAME** | The organisation that owns this instance of MISP. | `ORGNAME` |
| **ORG_UUID** | The unique identifier of the organisation that owns this instance of MISP. | (generate a new UUID on first start) |
| REDIS_HOST | The hostname of the Redis service. | `misp_redis` |
| REDIS_MISP_DB | The database number to use for MISP within Redis. | `2` |
| **REDIS_PASSWORD** | The password MISP will use to connect to Redis. | `misp` |
| REDIS_WORKER_DB | The database number to use for the MISP Workers within Redis. | `3` |
| REQUIRE_TOTP | Toggle if Time-based One Time Passwords are required. | `true` |
| **SMTP_HOSTNAME** | The FQDN of the SMTP service. | `localhost` |
| **SMTP_PASSWORD** | The password MISP will use to connect to the SMTP service. | `misp` |
| SMTP_PORT | The port the SMTP service is listening on. | `587` |
| SMTP_STARTTLS | If the SMTP service supports STARTTLS encryption, **case-sensitive** `true` or `false`. | `true` |
| **SMTP_USERNAME** | The username MISP will use to connect to the SMTP service. | `misp` |
| WORKERS_HOSTNAME | The hostname of the MISP Workers container. | `misp_workers` |
| **WORKERS_PASSWORD** | The password MISP will use to connect to the MISP Workers container's Supervisor interface. | `misp` |

## 3 - Import TLS Certificate

By default, the container will generate a self-signed certificate for the specified `FQDN`, however
if/when* you have a signed certificate ready:

1. Place the certificate, then any required certificate chain, and finally the content of 
  https://ssl-config.mozilla.org/ffdhe2048.txt † into `./persistent/{instanceName}/tls/misp.crt`.
2. Place the **unencrypted** private key into `./persistent/{instanceName}/tls/misp.key`.

During startup, the container will confirm that the provided `misp.crt` and `misp.key` files match
and revert to a self-signed certificate if they do not.

\* When adding a TLS certificate after MISP has been started, you will need to restart the `misp-web`
container for the new certificate to be applied.

† This ensures OpenSSL does not use insecure Ephemeral Diffie-Hellman (DHE) keys while establishing
TLS sessions with clients using DHE for key exchange, per the
[Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/).

## 4 - Import GnuPG/PGP Key

By default, the container will generate a GPG key for
`{MISP_EMAIL_NAME} <{MISP_EMAIL_ADDRESS}> ({FQDN})`, however if you have an existing key:

1. Export the key into an ASCII-armored (.asc) file.
2. Copy the file to `./persistent/{instanceName}/gpg/import.asc`.

During startup, the container will confirm that the provided `import.asc` can be unlocked with
`GPG_PASSPHRASE` and import it, reverting to generating a key on failure.

## 5 - Add Custom Image Files

If any custom image files are needed for custom MISP settings (below), create these folders and
place the files accordingly:

* Images (e.g. for the logon screen): `./persistent/{instanceName}/data/images/`.
* Organisation Icons: `persistent/misp/data/files/img/orgs/`.
  * `1.png`, `1.svg`, `{ORG_NAME}.png`, or `{ORG_NAME}.svg` will be used for the default
    organisation if present.

Any other custom files, such as tagging taxonomies, must be placed in
`./persistent/{instanceName}/data/import` and moved into place in step 5 to prevent conflicts.

## 6 - MISP Settings

The container configures MISP into a usable state during initial start up, however, if you'd like to
further customise MISP during this initial startup create a shell script named
`./persistent/{instanceName}/data/custom-config.sh`. `$CAKE` is set to the command to run MISP's CLI
tool (CakePHP) properly.

### Example 

```sh
#!/bin/bash

# Adding a terms file
cp -r /var/www/MISPData/import/terms.htm /var/www/MISPData/files/terms/
$CAKE Admin setSetting "MISP.terms_file" "terms.htm"
$CAKE Admin setSetting "MISP.terms_download" false

# Installing a taxonomy
cp -r /var/www/MISPData/import/my-taxonomy /var/www/MISPData/files/taxonomies/
```

## 7 - Deploy MISP

To deploy MISP run `sudo docker compose up -d` as the `docker-compose.yml` file has service health
based dependencies configured, it may take a few minutes for all containers to be started.

Once all containers have started, you can monitor the startup process using
`sudo docker container logs -f {instanceName}-web-1` (press CTRL+C to stop).

MISP should be available at `https://{FQDN}:{HTTPS_PORT}` when the container logs:

```log
[core:notice] [pid 7] AH00094: Command line: '/usr/sbin/apache2 -D FOREGROUND'
```

**Note**: Renaming the default organisation from ORGNAME to `ORG_NAME` may take a few minutes, if
this doesn't happen, check `persistent/{instanceName}/data/tmp/logs/misp_maintenance_runner.log`.
`[WARNING] MISP isn't up at ...` should stop occurring once the above message has been logged,
if it doesn't `FQDN` and / or `HTTPS_PORT` may be wrong, `FQDN` may not have a DNS entry, or a
firewall may be preventing cross container communication.

## 8 - Access MISP

Once MISP is up, if can be accessed at `https://{FQDN}:{HTTPS_PORT}` the default credentials are
email: `admin@admin.test` password: `admin`. You will be forced to change the password.

MISP has a diagnostics page you can check at Administration / Server Settings & Maintenance /
Diagnostics, the expected output is all green down to the Database Schema and again from Redis to
the bottom of the page, with the exception of " Cortex module system... System not enabled".

### Database Schema Discrepancies

Due to discrepancies between versions of MySQL **Schema status** will show a high number of minor
discrepancies (E.g. `int` vs `int(11)`) - these can be ignored.

**Schema status** may also show some fields are indexed that shouldn't be or that should be but
aren't, while these can be ignored too, performance may not be optimal. MISP provides the MySQL
commands to fix indexing: click the Spanner (Fix Database Index Schema) icon, and run the provided 
command manually against the MySQL database.

## 9 - Adding Custom Content

Where you need to add taxonomies and similar custom content after initial setup, these can be placed
in their respective sub-directories of `./persistent/{instanceName}/data/files/` and loaded into the
database using the buttons within the web UI, or they will be loaded daily by the automated task
below.

## 10 - Automated Maintenance

These routine tasks have been automated in the misp-workers container:

| Task | Frequency |
| ---- | --------- |
| Feed and server synchronisation | Hourly |
| Update Decay Models, Galaxies, Notice Lists, Objects, Taxonomies, Warning Lists, and Workflow Blueprints | Daily |

### Custom Automations

You can add your own automations to be run periodically by the same component of misp-workers.

To add a custom automation:

1. Create your automation, if you need to talk to the MISP API, it is recommended you use
  `configparser` to read `authKey`, `baseUrl`, and `verifyTls` from the `DEFAULT` section of
  `/var/www/MISPData/misp_maintenance_jobs.ini`.
2. Place the automation into its own folder within `./persistent/{instanceName}/data/custom_scripts`
  mounted as `/var/www/MISPData/custom_scripts/`.
    * For Python automations, use `/usr/local/bin/python3 -m venv venv` within misp-workers to
      create a Python 3.10 virtual environment.
3. Add a section to `./persistent/{instanceName}/data/misp_maintenance_jobs.ini` to schedule your
  task.
    * The section name must be unique.
    * `command` should use absolute paths to executables and scripts.
    * `enabled` can be set to `false` to temporarily disable a job without removing it.
    * `interval` sets how often the automation should be triggered, in minutes.
    * `lastRun` is set by the scheduling system and should be set to 0 on creation.
    * Setting `needsAuthKey` to `True` will prevent the automation from running until a valid Auth
      Key has been automatically set by the initial setup.
