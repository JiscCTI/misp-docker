<!--
SPDX-FileCopyrightText: 2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# Microsoft Entra ID

This guide provides the values needed for [OpenID Connect (OIDC) Authentication](./oidc.md) using
[Microsoft Entra ID](https://www.microsoft.com/en-gb/security/business/identity-access/microsoft-entra-id)
(formerly known as Azure Active Directory). The steps should work for most deployments.

**NOTE:** To successfully log into MISP, a user must have a valid email address set in the
**Email** field of the **Communication Information** tab of their User profile.

**NOTE:** While there is an [AadAuth](https://github.com/MISP/MISP/tree/2.5/app/Plugin/AadAuth)
plugin for MISP, at the time of writing this
[will not create new users](https://github.com/MISP/MISP/issues/9684) and
[lacks some user role mappings](https://github.com/MISP/MISP/issues/9683). It is therefore
recommended to use the generic OpenID Connect (OIDC) authentication plugin, as detailed below.

You may wish to copy this table into a document to capture the required values as you go:

| Entra ID Name | Environment Variable | Value |
|---------------|----------------------|-------|
| n/a | `AUTH_METHOD` | `oidc` |
| n/a | `OIDC_AUTH_METHOD` | `client_secret_basic` |
| n/a | `OIDC_CODE_CHALLENGE_METHOD` | `-` |
| Admin Group's Object Id | `OIDC_ADMIN_ROLE` |  |
| Org Admin Group's Object Id | `OIDC_ORG_ADMIN_ROLE` |  |
| Publisher Group's Object Id | `OIDC_PUBLISHER_ROLE` |  |
| Read-Only Group's Object Id | `OIDC_READONLY_ROLE` |  |
| Sync User Group's Object Id | `OIDC_SYNC_ROLE` |  |
| User Role Group's Object Id | `OIDC_USER_ROLE` |  |
| Application (client) ID | `OIDC_CLIENT_ID` |  |
| OpenID Connect metadata document | `OIDC_PROVIDER` |  |
| Client Secret "Value" | `OIDC_CLIENT_SECRET` |  |

## 1 - Create Security Groups

MISP uses the OIDC `roles` claim to assign users a role, users who cannot be mapped to a role will
be denied access - this includes disabling existing accounts.

1. In the Entra ID Portal go to **Groups** then **All Groups**.
2. Create **Security** groups for each of the default MISP roles in line with local naming
    standards. The default roles are:
    * Admin
    * Org Admin
    * Publisher
    * Read-Only
    * Sync User
    * User
3. Click **Refresh** to show the newly created groups.
3. Note the **Object Id** of each group.

## 2 - Assign Users

Once the Role-Based Access Control (RBAC) groups exist, users need to be allocated to their
respective roles.

This can be done via individual users' profiles. However, for bulk allocation the below method is
recommended.

1. Click into each group in turn and:
    1. Expand **Manage** in the left-hand-side menu.
    2. Select **Members**.
    3. Click **Add Members**.
    4. Find and tick each user to be allocated this role.
    5. Click **Select**.
    6. Go back by clicking **Groups | All groups** in the breadcrumb at the top of the page.

## 3 - Create Entra ID Application

MISP needs to be registered in Entra ID as an Enterprise Application.

1. Click **{Directory Name} | Groups** in the breadcrumb at the top of the page.
2. Click **Add** then **App Registration**.
3. Set **Name** in line with local policies, for example: *Example University MISP*.
4. In most cases you should leave **Supported account types** set to
    **Accounts in this organizational directory only**.
5. Under **Redirect URI**:
    1. Set **Select Platform** to **Web**.
    2. Set the URL to your MISP instance's base URL plus `/users/login`, e.g.
        `https://misp.example.ac.uk/users/login`.
6. Click **Register**.
7. Note the **Application (client) ID**.
8. Click **Endpoints**.
7. Note the URL under **OpenID Connect metadata document**.

## 4 - Generate A Client Secret

MISP will use a client secret to authenticate to Entra ID.

1. Expand **Manage** on the left-hand-side menu.
2. Click **Certificates & secrets**.
3. Go to the **Client secrets** tab.
4. Click **New client secret**.
5. Set Description and Expiry in line with local policies.
6. Click **Add**.
7. Note the string in the **Value** column.

**It is essential a new client secret is generated before the date shown in the Expires column**.
Otherwise users will not be able to authenticate to MISP.

## 5 - Include `roles` Claim

As mentioned, MISP requires the `roles` claim to map users to a role.

**NOTE:** Some licensing tiers allow constraining which groups are shared to "Groups assigned to the
application". This should work as expected if used, but is out of scope for this guide.

1. Select **Token configuration** from the left-hand menu.
2. Click **Add groups claim**.
3. Under **Select group types to include** tick **Security**.
4. Expand the **ID** section.
5. Tick **Emit groups as role claims**.
6. Click **Add**.

## 6 - Grant Admin Consent

Entra ID requires a directory admin to grant consent for an application to work.

**NOTE:** You may need another Entra ID administrator to do this step, depending on how the
permissions have been configured.

1. Select **API permissions** from the left hand menu.
2. Click **Grant Admin Consent for {Directory Name}**.
3. Click **Yes**.
