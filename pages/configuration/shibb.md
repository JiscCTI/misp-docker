<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Clive Bream
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Shibboleth 2 Service Provider for MISP

## What is Shibboleth?

Shibboleth is an open source tool that supports single sign-on (SSO) using the SAML protocol, It
allows people to sign in using s single identity to various systems run by federations of different
organisations. Shibboleth allows users to securely send trusted information to remote resources,
allowing this information to then be used for authentication, authorisation and enabling single
login across a range of services from different providers.

## Environment Variables

To use Shibboleth for authentication you need to add some environment variables to your `misp-web`
container:

1. In your `.env` file:
    1. Add the line `AUTH_METHOD=shibb`.
    2. Optionally, if your OP enforces Multi-Factor Authentication (MFA), add `REQUIRE_TOTP=false`.
2. Create a new file called `shibb.env`,
3. In `shibb.env` add any settings that are being changed from their default values (below).
    * The items in **bold** are highly recommended.

| Option Name | Description | Default Value |
|-------------|-------------|---------------|
| SHIBB_ADMIN_ROLE | The shibboleth group / role to be granted the MISP admin role. | `misp-admin` |
| SHIBB_BLOCK_ORG_CHANGE | If shibboleth should be prevented from changing a user's organisation. | `false` |
| SHIBB_BLOCK_ROLE_CHANGE | If shibboleth should be prevented from changing a user's role. | `false` |
| SHIBB_DEFAULT_ROLE | The default role to assign to users who are not given one by shibboleth. `false` = no role. | `false` |
| SHIBB_EMAIL_FORMAT | The Name Format of the attribute containing a user's email address. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_EMAIL_NAME | The Name (not Friendly Name) of the attribute containing a user's email address. | `urn:oid:0.9.2342.19200300.100.1.3` |
| SHIBB_GROUP_FORMAT | The Name Format of the attribute containing a user's groups / roles. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_GROUP_NAME | The Name (not Friendly Name) of the attribute containing a user's groups / roles. | `urn:oid:1.3.6.1.4.1.5923.1.5.1.1` |
| SHIBB_HOSTNAME | The hostname of the Shibboleth service container. | `misp_shibb` |
| **SHIBB_IDP_ENTITY_ID** | The entity ID of the shibboleth identity provider. | `https://idp.example.org/idp/shibboleth` |
| **SHIBB_IDP_METADATA_URL** | The URL of the shibboleth identity provider's metadata file. `false` = use `./persistent/misp/shibb/etc/idp-metadata.xml` | `false` |
| SHIBB_ONLY | Require shibboleth authentication for all users, disable local account access. | `false` |
| SHIBB_ORG_ADMIN_ROLE | The shibboleth group / role to be granted the MISP org admin role. | `misp-orgadmin` |
| SHIBB_ORG_FORMAT | The Name Format of the attribute containing a user's organisation. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_ORG_NAME | The Name (not Friendly Name) of the attribute containing a user's organisation. | `urn:oid:1.3.6.1.4.1.25178.1.2.9` |
| SHIBB_PUBLISHER_ROLE | The shibboleth group / role to be granted the MISP publisher role. | `misp-publisher` |
| SHIBB_READONLY_ROLE | The shibboleth group / role to be granted the MISP read only role. | `misp-readonly` |
| SHIBB_SP_ENCRYPT_REQUESTS | If the MISP Service Provider should encrypt the shibboleth requests. | `true` |
| SHIBB_SP_ENTITY_ID | The entity ID of MISP's Service Provider. `default` = `https://{FQDN}[:{HTTPS_PORT}]/shibboleth`. | `default` |
| SHIBB_SP_SHARE_KEY | If the MISP Service Provider should use the same (`true`) or separate (`false`) keys for signing and encryption. | `true` |
| SHIBB_SP_SIGN_REQUESTS | If the MISP Service Provider should sign the shibboleth requests. | `true` |
| SHIBB_SYNC_ROLE | The shibboleth group / role to be granted the MISP sync user role. | `misp-sync` |
| SHIBB_USER_ROLE | The shibboleth group / role to be granted the MISP user role. | `misp-user` |

## Docker Compose

To use shibboleth, use the
[docker-compose-shibb.yml⁠](https://github.com/JiscCTI/misp-docker/blob/main/docker-compose-shibb.yml)
as your `docker-compose.yml` file. The compose file contains all of the MISP service dependencies
related to using shibboleth.

## Identity Provider (IdP) Metadata

IdP metadata can either be provided by setting a `SHIBB_IDP_METADATA_URL` in `.env`, or by saving
the IdP's metadata file to `./persistent/misp/shibb/etc/idp-metadata.xml`.

If `SHIBB_IDP_METADATA_URL` is set, then during startup the URL will be fetched, replacing
`./persistent/misp/shibb/etc/idp-metadata.xml` - ensure `SHIBB_IDP_METADATA_URL` is not set in
`.env` or is explicitly set to `false` to prevent this. If the URL is invalid, the container will
not start.

## Service Provider (SP) Metadata

To generate the Service Provider metadata, start MISP as normal using `docker compose up -d`.

Once the `shibb` service has finished starting, `./persistent/misp/shibb/etc/misp-metadata.xml` will
have been created / updated and can be imported into the Identity Provider manually.

## Accessing MISP

Once MISP has been enrolled into the Identify Provider, access `https://{FQDN}:{HTTPS_PORT}` and you
will be redirected to authenticate against the Identity Provider before being redirected back to
MISP.

## High Availability

With some additional configuration the Shibboleth container can be run in a high availability mode.

* All `misp-shibb-sp` and `misp-web` containers need to share the same `/etc/shibboleth` volume.
* Each pair of `misp-shibb-sp` and `misp-web` containers need to share a unique `/run/shibboleth`
    volume.
* Each `misp-shibb-sp` container needs a unique `/var/log/shibboleth` volume.

For example, an instance running in AWS's eu-west-2 region across three availability zones and using
EFS for persistent storage could be configured like this:

| Container | Region | AZ | `/etc/shibboleth` | `/run/shibboleth` | `/var/log/shibboleth` |
|-----------|--------|----|-------------------|-------------------|-----------------------|
| `misp-shibb-sp` | eu-west-2 | az1 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az1` | `EFS://shibb/log/euw2-az1` |
| `misp-web` | eu-west-2 | az1 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az1` | N/A |
| `misp-shibb-sp` | eu-west-2 | az2 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az2` | `EFS://shibb/log/euw2-az2` |
| `misp-web` | eu-west-2 | az2 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az2` | N/A |
| `misp-shibb-sp` | eu-west-2 | az3 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az3` | `EFS://shibb/log/euw2-az3` |
| `misp-web` | eu-west-2 | az3 | `EFS://shibb/etc` | `EFS://shibb/run/euw2-az3` | N/A |
