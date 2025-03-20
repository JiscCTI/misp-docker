<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Configuring MISP

This page assumes an [On-Premises Deployment](../deploy/local.md), if you are using a
[Cloud Deployment](../deploy/cloud.md) you will need to complete the same steps using the tools made
available by your cloud provider.

## Environment Variables

Create the file `/opt/misp/.env` adding all the options that you need to override from their default
values in the below table.

The format of the file is one variable per line: `OPTION_NAME=desired_override_value`.

***Note*** In the table below there are multiple settings formatted in **bold**, it is highly
recommended that these values are overridden as a bare minimum.

***Note*** Any passwords used ***MUST NOT*** contain the backslash (`\`) or plus (`+`) characters
otherwise the container may not start correctly.

***NOTE*** Ensure all passwords are strong and unique, it is recommended you use a cryptographically
secure password generator. One option is to run `openssl rand -hex 32` to generate a 64-character
hexadecimal password.

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

By default, the container will generate a self-signed certificate for the specified FQDN, however it
is strongly recommended that you provide a signed certificate using either ACME or manually.

During startup, the container will confirm that the provided certificate and private key match. If
not, then the container will revert to using a self-signed certificate.

### Automatic Certificate Issuance via ACME

The Automatic Certificate Management Environment (ACME) protocol can be used to automate the
issuance and renewal of MISP's TLS certificate.

These instructions assume Let's Encrypt as the Certification Authority (CA) for simplicity however
any other CA which offers ACME can be also be used, see their documentation for the correct values
of additional arguments like `--server`, `--eab-kid` and `--eab-hmac-key`.

These instructions assume the use of the HTTP-01 challenge type, see the Certbot documentation and
your chosen CA's documentation for how to use other challenge types such as DNS-01.

1. Read and accept the [Let's Encrypt Terms of Service](https://community.letsencrypt.org/tos) (or
    your alternate ACME-enabled CA's equivalent agreement).
1. Installed Certbot on the host machine per the
    [Certbot documentation](https://certbot.eff.org/instructions).
1. Uncomment the `/etc/letsencrypt/live/MISP` volume of `misp-web` in `docker-compose.yml`.
1. Start MISP as usual and wait for until MISP is up and running.
1. Use the following command to request the certificate, setting `--email`, `--webroot-path` and
    `--domain` to appropriate values for your environment and adding any additional options for your
    chosen CA.

```sh
certbot certonly --non-interactive --agree-tos --email certmaster@org.ac.uk \
    --webroot --webroot-path /opt/misp/persistent/misp/acme \
    --cert-name MISP --domain misp.org.ac.uk \
    --deploy-hook '/usr/bin/docker container restart $(docker ps --filter ancestor=jisccti/misp-web:latest -aq)'
```

The `--deploy-hook` option tells Certbot how to deploy the certificate, in this case to restart all
containers running the `jisccti/misp-web:latest` image.

If Certbot is set up correctly, then it will automatically renew the certificate and restart
`misp-web` in advance of certificate expiry.

### Manual Certificate Installation

If you are unable to use ACME, you can manually obtain and install a TLS certificate. This page will
not cover obtaining a certificate as this varies between Certification Authorities (CAs).

Once your certificate has been issued, you will need two files:

1. Public Certificate - save as `./tls/misp.crt` in the `misp_custom` volume:
    * Some CAs will provide you with a "certificate with chain" file, if so, download this.
    * If the "certificate with chain" file is not available from your CA, concatenate each of the
        `.crt` files that form the chain of trust, into one file putting your certificate first, 
        then each intermediate certificate in order up to but excluding the CA's root certificate.
1. **Unencrypted** private key - save as `./tls/misp.key` in the `misp_custom` volume.

`./tls/misp.crt` should resemble:

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
```

Once the two files are in place (re)start MISP using `docker compose up -d --force-recreate`.

For renewals, repeat the above process.

## Importing GnuPG/PGP Keys

By default, the container will generate a GPG key for
`{MISP_EMAIL_NAME} <{MISP_EMAIL_ADDRESS}> ({FQDN})`, however if you have an existing key that you
would like to use, follow the steps below:

1. Export the key into an ASCII-armoured (.asc) file.
2. Copy the file to `./persistent/misp/gpg/import.asc`.

During startup, the container will confirm that the provided `import.asc` can be unlocked with
GPG_PASSPHRASE and import it. If the container is not able to confirm this, it will revert to
creating a brand new key.

## Single Sign On

Details about configuring Single Sign On (SSO) can be found on the pages below:

- Microsoft Entra ID (formerly Azure Active Directory, or AAD) 
    - This integration is awaiting upstream fixes, however SSO with Entra ID may be possible using
        OIDC.
- [OpenID Connect (OIDC)](../configuration/oidc.md)
- [Shibboleth / SAML 2.0](../configuration/shibb.md).

## Log Forwarding to Splunk

See the [Splunk page](../splunk.md) for details on forwarding MISP's logs to Splunk.

## Customisation

Further customisation of MISP is possible by following the instructions on the
[Customisation page](../configuration/custom.md).

## First Start

You should now be ready for the [First Start](../first_start.md) of MISP.
