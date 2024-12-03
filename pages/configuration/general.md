<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Configuring MISP

Before configuring MISP, it is recommended to view the steps necessary in deploying the Docker
containers that best suit your deployment methods using either the
[Local Deployment Page](../deploy/local.md) or the [Cloud Deployment Page](../deploy/cloud.md).

This page assumed a local deployment, you will need to adapt it to suit your chosen cloud provider's
systems for a cloud deployment.

## Environment Variables

Create a file within the directory your MISP instance sits in, the file should be called `.env`. Now
add in all options that you would like to override based on the default values in the below table.

The format of the file should be as follows: `OPTION_NAME=desired_override_value`.

***Note*** In the table below there are multiple settings formatted in **bold**, it is highly
recommended that these values are overridden as a bare minimum.

***Note*** Any passwords used ***MUST NOT*** contain the backslash (`\`) or plus (`+`) characters
otherwise the container may not start correctly.

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

## Importing TLS Certificate

By default, the container will generate a self-signed certificate for the specified FQDN, however
if/when you have a signed certificate ready, please follow the below steps:

1. Acquire a publicly trusted certificate for the MISP instance.
    - Some CAs will provide you with a "certificate with chain" file, if so, download this.
    - If the "certificate with chain" file is not available from your CA, concatenate each
        `.crt` files that form the chain, into one file putting your certificate first, then each
        intermediate certificate in order.
2. Concatenate the contents of
    [https://ssl-config.mozilla.org/ffdhe2048.txt](https://ssl-config.mozilla.org/ffdhe2048.txt)
    to the end of the `.crt` file as well. This ensures OpenSSL does not use insecure Ephemeral
    Diffie-Hellman (DHE) keys while establishing TLS sessions with clients using DHE for key
    exchange, per the [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/). 
2. Place the `.crt` file into `./persistent/misp/tls/misp.crt`.
3. Place the **unencrypted** private key into `./persistent/misp/tls/misp.key`.

`./persistent/misp/tls/misp.crt` should look like ths:

```
-----BEGIN CERTIFICATE-----
MISP server certificate - signed by intermediate 1
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
intermediate 1 certificate - signed by intermediate 2
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
Intermediate 2 certificate - signed by trusted root
-----END CERTIFICATE-----
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----
```

During startup, the container will confirm that the provided `misp.crt` and `misp.key` files match.
***Note*** If the files **do not** match, then the container will revert to using a self-signed
certificate.

***Note*** When adding a TLS certificate after MISP has been started, you will need to restart the
`misp-web` container for the new certificate to be applied.

## Importing GnuPG/PGP Keys

By default, the container will generate a GPG key for
`{MISP_EMAIL_NAME} <{MISP_EMAIL_ADDRESS}> ({FQDN})`, however if you have an existing key that you
would like to use, follow the steps below:

1. Export the key into an ASCII-armoured (.asc) file.
2. Copy the file to `./persistent/misp/gpg/import.asc`.

During startup, the container will confirm that the provided `import.asc` can be unlocked with
GPG_PASSPHRASE and import it. If the container is not able to confirm this, it will revert to
creating a brand new key.
