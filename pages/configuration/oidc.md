<!--
SPDX-FileCopyrightText: 2023 Science and Technology Facilities Council (STFC)
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Acris (STFC)
SPDX-FileContributor: Joe Pitt (Jisc Services Limited)

SPDX-License-Identifier: GPL-3.0-only
-->
# OpenID Connect (OIDC) Authentication

MISP can use OpenID Connect (OIDC) to authenticate users, below are instruction on setting this up.

## Configure the Identity Provider (IdP)

To setup MISP you need to have created MISP as a client in your OIDC Identity Provider (IdP).

By default, MISP will use JSON Web Tokens (JWTs) signed with the Client Secret as the Client
Authenticator with a Challenge Mode of S256.

This step is dependant on which IdP you are using and local policies, an example for Keycloak is
provided at the bottom of this page.

## Set Environment Variables

To use OIDC for authentication you need to add some environment variables to your `.env` file. You
only need to add those that you will change from their default value. The items in **bold** are
highly recommended.

| Option Name | Description | Default Value |
| ----------- | ----------- | ------------- |
| **AUTH_METHOD** | The authentication engine to use, must be changed to `oidc`. | `misp` |
| OIDC_ADMIN_ROLE | The OIDC group / role to be granted the MISP admin role. | `misp-admin` |
| OIDC_AUTH_METHOD | The Client Authenticator mode to use for OIDC authentication, such as `client_secret_basic` or `client_secret_jwt`. | `client_secret_jwt` |
| OIDC_CLIENT_ID | The Client ID used to identify MISP in the Identity Provider. | `misp` |
| **OIDC_CLIENT_SECRET** | The Client Secret used to authenticate requests from MISP to the Identity Provider. | `misp` |
| OIDC_CODE_CHALLENGE_METHOD | The Proof Key for Code Exchange Code Challenge Method used to ensure that MISP starts and finishes the authentication flow. | `S256` |
| OIDC_ORG_ADMIN_ROLE | The OIDC group / role to be granted the MISP org admin role. | `misp-orgadmin` |
| **OIDC_PROVIDER** | The URL of the OIDC Provider's configuration, including the `.well-known/openid-configuration` suffix where applicable. | `example.com/auth/realms/realm/.well-known/openid-configuration` |
| OIDC_PUBLISHER_ROLE | The OIDC group / role to be granted the MISP publisher role. | `misp-publisher` |
| OIDC_READONLY_ROLE | The OIDC group / role to be granted the MISP read-only role. | `misp-readonly` |
| OIDC_SYNC_ROLE | The OIDC group / role to be granted the MISP sync user role. | `misp-sync` |
| OIDC_USER_ROLE | The OIDC group / role to be granted the MISP user role. | `misp-user` |
| REQUIRE_TOTP | Toggle if Time-based One Time Passwords are required. You may wish to disable if your IdP already implements OTP. | `true` |

## Start MISP

Start MISP as normal using `docker compose up -d`.

## Access MISP

Accessing `https://{FQDN}[:{HTTPS_PORT}]` will redirect users to authenticate against the IdP. Once
authenticated, the IdP will redirect the user back to MISP.

## Example using Keycloak

**Note:** You must be a realm admin in Keycloak in order to follow this guide. 

**Note:** This guide is based on the Keycloak admin console in version 26.

Ensure you are in the right Realm, then:

1. Go to **Clients** (left hand menu).
2. Click **Create client**.
3. On the **General Settings** screen use:
    1. **Client type:** OpenID Connect
    2. **Client ID:** misp (if different override `OIDC_CLIENT_ID` as above).
    3. Optionally, set a friendly **Name** and a **Description**.
    4. Optionally, set MISP to **Always display in UI**.
4. Click **Next**.
5. On the **Capability config** screen use:
    1. **Client authentication:** On
    2. **Authorization:** On
    3. **Authentication flow:** Standard flow (Direct access grants is ticked by default, but is not
        used so can be unticked).
6. Click **Next**.
7. On the **Login settings** screen use:
    1. Root URL: `https://{FQDN}[:{HTTPS_PORT}]`
    2. Home URL: /
    3. Valid redirect URIs: /users/login
    4. Valid post logout redirect URIs: (blank)
    5. Web origins: +
8. Click **Save**.
9. On the **Credentials** tab:
    1. Change **Client Authenticator** to **Signed Jwt with Client Secret**.
    2. Click the **Copy to clipboard** icon next to **Client Secret** (override `OIDC_CLIENT_SECRET`
        with this value as above).
    3. Click **Save** then **Yes**.
10. On the **Roles** tab:
    1. Click **Create role**.
    2. Set **Role name** to `misp-admin` (can be different, override `OIDC_ADMIN_ROLE` as above).
    3. Optionally, set **Role description**.
    4. Click **Save**.
    5. Click **Cancel** to return to the **Roles** tab.
    6. Repeat for `misp-orgadmin` (`OIDC_ORG_ADMIN_ROLE`), `misp-publisher` (`OIDC_PUBLISHER_ROLE`),
        `misp-readonly` (`OIDC_READONLY_ROLE`), `misp-sync` (`OIDC_SYNC_ROLE`), and `misp-user`
        (`OIDC_USER_ROLE`).
11. On the **Client scopes** tab:
    1. Click **misp-dedicated** (will be {Client ID}-dedicated if different Client ID was set).
    2. Click **Scope**.
    3. Turn **Full scope allowed** Off (Only sends MISP MISP-specific roles).
    4. Click **Client details** (top of window).
12. On the **Advanced** tab:
    1. Optionally, in the **Fine grain OpenID Connect configuration** section:
        1. Set **Logo URL** to **https://avatars.githubusercontent.com/u/4134875?s=128&v=4**.
        2. Click **Save**.
    2. In the **Advanced settings** section:
        1. Set **Proof Key for Code Exchange Code Challenge Method** to **S256**.
        2. Click **Save**.
13. On the **Users** page (left hand menu).
    1. Click on a user's username.
    2. Click on to the **Role mappings** tab.
    3. Click **Assign role**.
    4. Change **Filter by realm roles** to **Filter by clients**
    5. In **Search by role name** type **misp** (or the prefix you used for your roles) and click
        the Search icon.
    6. Tick the box next to the role to assign the user, e.g. **misp-admin**.
    7. Click **Assign**.
    8. Repeat as needed for each user.
