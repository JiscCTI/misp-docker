<!-- # SPDX-FileCopyrightText: 2024 Jisc Services Limited
# SPDX-FileContributor: James Ellor
#
# SPDX-License-Identifier: GPL-3.0-only
-->

# Configuring MISP

Before configuring MISP, it is recommended to view the steps necessary in deploying the Docker containers that best suit your deployment methods using either the [Local Deployment Page](../deploy/local.md) or the [Cloud Deployment Page](../deploy/cloud.md)  

### Environment Variables

Create a file within the directory your MISP instance sits in, the file should be called `.env`. Now add in all options that you would like to override based on the default values in the below table.

The format of the file should be as follows:
`OPTION_NAME=desired_override_value`

***Note*** In the table below there are multiple settings formatted in **bold**, it is highly recommended that these values are overridden as a bare minimum.

***Note*** Any passwords used ***MUST NOT*** contain the backslash (`\`) character or the plus (`+`) symbol otherwise the container will not start correctly.

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
| REDIS_MODULES_DB | The database number to use for the MISP Modules within Redis. | `1` |
| REDIS_WORKER_DB | The database number to use for the MISP Workers within Redis. | `3` |
| REQUIRE_TOTP | Toggle if Time-based One Time Passwords are required. | `true` |
| **SMTP_HOSTNAME** | The FQDN of the SMTP service. | `localhost` |
| **SMTP_PASSWORD** | The password MISP will use to connect to the SMTP service. | `misp` |
| SMTP_PORT | The port the SMTP service is listening on. | `587` |
| SMTP_STARTTLS | If the SMTP service supports STARTTLS encryption, **case-sensitive** `true` or `false`. | `true` |
| **SMTP_USERNAME** | The username MISP will use to connect to the SMTP service. | `misp` |
| WORKERS_HOSTNAME | The hostname of the MISP Workers container. | `misp_workers` |
| **WORKERS_PASSWORD** | The password MISP will use to connect to the MISP Workers container's Supervisor interface. | `misp` |

### Importing your TLS Certificate

By default, the container will generate a self-signed certificate for the specified FQDN, however if/when you have a signed certificate ready, please follow the below steps:

1. Acquire a publicly trusted certificate for the MISP instance. Some root CAs will provide you with a "certificate with chain" file, if so, download this as the full certificate chain (excluding the root CA) is needed.
    - If the "certificate with chain" file is not available from your root CA, please concatenate all `.crt` files that form the chain, into a `.chain` file. Please also concatenate the contents of [https://ssl-config.mozilla.org/ffdhe2048.txt](https://ssl-config.mozilla.org/ffdhe2048.txt) into the `.chain` file as well. This ensures OpenSSL does not use insecure Ephemeral Diffie-Hellman (DHE) keys while establishing TLS sessions with clients using DHE for key exchange, per the [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/). 
2. Place the resulting `.chain` file from step 1 into `./persistent/{instanceName}/tls/misp.chain`
3. Place the **unencrypted** private key into `./persistent/{instanceName}/tls/misp.key`

During startup, the container will confirm that the provided `misp.chain` and `misp.key` files match. ***Note*** If the files **do not** match, then the container will revert to using a self-signed certificate.

***Note*** When adding a TLS certificate after MISP has been started, you will need to restart the `misp-web` container for the new certificate to be applied.

### Importing GnuPG/PGP Keys

By default, the container will generate a GPG key for `{MISP_EMAIL_NAME} <{MISP_EMAIL_ADDRESS}> ({FQDN})`, however if you have an existing key that you would like to use, please follow the steps below:

1. Export the key into an ASCII-armored (.asc) file.
2. Copy the file to `./persistent/{instanceName}/gpg/import.asc`.

During startup, the container will confirm that the provided `import.asc` can be unlocked with GPG_PASSPHRASE and import it. If the container is not able to confirm this, it will revert to creating a brand new key.
