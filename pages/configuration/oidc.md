<!--
SPDX-FileCopyrightText: 2023 Science and Technology Facilities Council (STFC)
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: Iain Brown (Jisc Services Limited)
SPDX-FileContributor: James Acris (STFC)
SPDX-FileContributor: James Ellor (Jisc Services Limited)
SPDX-FileContributor: Joe Pitt (Jisc Services Limited)

SPDX-License-Identifier: GPL-3.0-only
-->
# OpenID Connect (OIDC) Authentication

MISP can use OpenID Connect (OIDC) to authenticate users. Instruction on setting this up are
detailed below.

## Configure the Identity Provider (IdP)

To setup MISP you need to have created a client in your OIDC Provider (OP). This step is dependant
on which OP you are using and local policies. Guides are available for:

* [Microsoft Entra ID](./entra-id.md)
* [Keycloak](./keycloak.md)

By default, JSON Web Tokens (JWTs) signed with a Client Secret will be used to authenticate MISP
to the OP with a Proof Key for Code Exchange (PKCE) Challenge Mode of S256.

## Set Environment Variables

Once the OP is configured, you need to add some environment variables to your `misp-web` container:

1. In your `.env` file:
    1. Add the line `AUTH_METHOD=oidc`.
    2. Optionally, if your OP enforces Multi-Factor Authentication (MFA), add `REQUIRE_TOTP=false`.
2. Create a new file called `oidc.env`,
3. In `oidc.env` add any settings that are being changed from their default values (below).
    * The items in **bold** are required.

| Option Name | Description | Default Value |
| ----------- | ----------- | ------------- |
| OIDC_ADMIN_ROLE | The OIDC group / role to be granted the MISP admin role. | `misp-admin` |
| OIDC_AUTH_METHOD | The Client Authenticator mode to use for OIDC authentication, commonly `client_secret_basic` or `client_secret_jwt`. | `client_secret_jwt` |
| OIDC_CLIENT_ID | The Client ID used to identify MISP in the Identity Provider. | `misp` |
| **OIDC_CLIENT_SECRET** | The Client Secret used to authenticate requests from MISP to the Identity Provider. | `misp` |
| OIDC_CODE_CHALLENGE_METHOD | The Proof Key for Code Exchange (PKCE) Code Challenge Method used to ensure that MISP starts and finishes the authentication flow. Set to `-` to disable PKCE. | `S256` |
| OIDC_ONLY | Require OIDC authentication for all users, disable local account access. | `false` |
| OIDC_ORG_ADMIN_ROLE | The OIDC group / role to be granted the MISP org admin role. | `misp-orgadmin` |
| **OIDC_PROVIDER** | The URL of the OIDC Provider's configuration, including the `.well-known/openid-configuration` suffix where applicable. | `example.com/auth/realms/realm/.well-known/openid-configuration` |
| OIDC_PUBLISHER_ROLE | The OIDC group / role to be granted the MISP publisher role. | `misp-publisher` |
| OIDC_READONLY_ROLE | The OIDC group / role to be granted the MISP read-only role. | `misp-readonly` |
| OIDC_SYNC_ROLE | The OIDC group / role to be granted the MISP sync user role. | `misp-sync` |
| OIDC_USER_ROLE | The OIDC group / role to be granted the MISP user role. | `misp-user` |

## Start MISP

Once the OP and MISP are configured, you need to (re)start MISP, using
`docker compose up -d --force-recreate`.

## Access MISP

Once MISP has finished starting, accessing `https://{FQDN}[:{HTTPS_PORT}]` will redirect the user to
authenticate against the OP. Once authenticated, the OP will redirect them back to MISP.
