<!--
SPDX-FileCopyrightText: 2023 Science and Technology Facilities Council (STFC)
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: Iain Brown (Jisc Services Limited)
SPDX-FileContributor: James Acris (STFC)
SPDX-FileContributor: James Ellor (Jisc Services Limited)
SPDX-FileContributor: Joe Pitt (Jisc Services Limited)

SPDX-License-Identifier: GPL-3.0-only
-->
# Keycloak

This guide provides the values needed for [OpenID Connect (OIDC) Authentication](./oidc.md) using
[Keycloak](https://www.keycloak.org/). The steps should work for most deployments.

**Note:** You must be a realm admin in Keycloak in order to enroll MISP as a client.

**Note:** This guide is based on the Keycloak admin console in version 26.2.5 (May 2025).

You may wish to copy this table into a document to capture the required values as you go:

| Keycloak Name | Environment Variable | Value |
|---------------|----------------------|-------|
| Client ID | `OIDC_CLIENT_ID` |  |
| Client Secret | `OIDC_CLIENT_SECRET` |  |
| OpenID Endpoint Configuration (URL) | `OIDC_PROVIDER` |  |

Depending on your configuration, you may also need to set:

| Keycloak Name | Environment Variable | Value |
|---------------|----------------------|-------|
| Admin Role Name | `OIDC_ADMIN_ROLE` |  |
| Org Admin Role Name | `OIDC_ORG_ADMIN_ROLE` |  |
| Publisher Role Name | `OIDC_PUBLISHER_ROLE` |  |
| Read-Only Role Name | `OIDC_READONLY_ROLE` |  |
| Sync User Role Name | `OIDC_SYNC_ROLE` |  |
| User Role Name | `OIDC_USER_ROLE` |  |

## 1 - Switch Realms

After logging into the Keycloak admin console:

1. Click **Manage realms** in the left hand menu.
2. Click on the desired realm.

## 2 - Create Client

MISP needs to be added as an OIDC Client in Keycloak:

1. Click **Clients** in the left hand menu.
2. Click the **Create client** button.
3. On the Create Client > **General Settings** screen:
    1. Set **Client type** to **OpenID Connect**.
    2. Set (and note) **Client ID** in line with local policies, e.g. `misp`.
    3. Optionally, set a friendly **Name** and **Description**.
    4. Optionally, enable **Always display in UI**, to show MISP in the Applications screen of the
        Keycloak user portal.
    5. Click **Next**.
4. On the Create Client > **Capability config** screen:
    1. Enable **Client authentication**.
    2. Enable **Authorization**.
    3. In the **Authentication flow** section:
        * Enable **Standard flow**.
        * Disable **Direct access grants**.
    4. Click **Next**.
5. On the Create Client > **Login settings** screen:
    1. Set **Root URL** to `https://{FQDN}[:{HTTPS_PORT}]` (e.g. `https://misp.example.ac.uk`).
    2. Set **Home URL** to `/`.
    3. Set **Valid redirect URIs** to `/users/login`.
    4. Leave **Valid post logout redirect URIs** blank.
    5. Set **Web origins** to `+`.
    6. Click **Save**.

## 3 - Configure Client

Some additional configuration is required for MISP to successful authenticate using this client.

1. Go to the **Client details** screen.
    * You should be redirected here after creating the client.
    * You can get to this page via **Clients** > **misp**.
2. In the **Logout settings** section, disable **Front channel logout**.
3. Click **Save**.
4. On the **Credentials** tab:
    1. Change **Client Authenticator** to **Signed Jwt with Client Secret**.
    2. Click **Save** then **Yes**.
    3. Click the View (eye) icon next to **Client Secret** and note the value.
5. On the **Roles** tab:
    1. Click **Create role**.
    2. Set **Role name** to `misp-admin` (can be different, override `OIDC_ADMIN_ROLE` as above).
    3. Optionally, set **Role description**.
    4. Click **Save**.
    5. On the **Role details** screen, click **Cancel** to return to the **Roles** tab.
    6. Repeat for `misp-orgadmin` (`OIDC_ORG_ADMIN_ROLE`), `misp-publisher` (`OIDC_PUBLISHER_ROLE`),
        `misp-readonly` (`OIDC_READONLY_ROLE`), `misp-sync` (`OIDC_SYNC_ROLE`), and `misp-user`
        (`OIDC_USER_ROLE`).
6. On the **Client scopes** tab:
    1. Click **misp-dedicated** (will be {Client ID}-dedicated if different Client ID was set).
    2. Click the **Add predefined mapper** button.
    3. Tick **Client roles** and click **Add**.
    4. Click **client roles** and in the next window:
        1. Set **Client ID** to `misp` (or your chosen Client ID).
        2. Set **Token Claim Name** to `roles`.
        3. Enable **Add to ID token**.
        4. Disable **Add to access token**.
        5. Click **Save**.
    5. Click **Dedicated scopes**.
    6. On the **Scope** tab:
        1. Disable **Full scope allowed**.
    7. Click **Client details** (top of window).
7. On the **Advanced** tab:
    1. In the **Fine grain OpenID Connect configuration** section:
        1. Optionally, set **Logo URL** to **https://avatars.githubusercontent.com/u/4134875?s=128&v=4**.
        2. Set **Request object signature algorithm**  to **HS256**.
        3. Click this section's **Save** button.
    2. In the **Advanced settings** section:
        1. Set **Proof Key for Code Exchange Code Challenge Method** to **S256**.
        2. Click this section's **Save** button.

## 4 - Assign User Roles

MISP users must be assigned to a role to be granted access:

1. Go to the **Users** page (left hand menu).
2. For each MISP user:
    1. Click on a user's username.
    2. On the **Role mappings** tab:
        1. Click **Assign role**.
        2. Ensure **Filter by clients** is selected.
        3. In **Search by role name** type **misp** (or the prefix you used for your roles) and
            click the search (arrow) icon.
        4. Tick the role to assign to this user, e.g. `misp-admin` or `misp-user`.
        5. Click **Assign**.
        6. Click **Users** to return to the user list.
    3. Repeat as needed for each user.

## 5 - OIDC Provider Metadata

MISP needs the OpenID Endpoint Configuration URL to authenticate users:

1. Go to **Realm settings** in the left hand menu.
2. Right click the link **OpenID Endpoint Configuration** and select the copy option.
3. Note the URL; it is used as the `OIDC_PROVIDER` environment variable.
