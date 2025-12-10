<!--
SPDX-FileCopyrightText: 2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# Change Log

This page tracks significant changes to the images.

## December 2025 - MISP >=2.5.27

* Updated images to use PHP 8.5
* Enabled support for the new MISP task scheduler

## October 2025 - MISP >=2.5.23

* Made Start-Up locks in HA environments atomic, removing race conditions during startup
* Made PHP's `memory_limit` configurable 
    (see `PHP_ADDITIONAL_MEMORY_LIMIT` on 
    [Configuring MISP](configuration/general.md#environment-variables))
* Made Contact and Reply-To email addresses configurable (see `MISP_EMAIL_CONTACT_ADDRESS` and 
    `MISP_EMAIL_REPLY_ADDRESS` on 
    [Configuring MISP](configuration/general.md#environment-variables))

## October 2025 - MISP>=2.5.22

* **BREAKING CHANGE** for OIDC-authenticated environments: To disable Proof Key for Code Exchange
    (PKCE), `OIDC_CODE_CHALLENGE_METHOD` must now be set to `-` rather than an empty string. (see 
    [OpenID Connect (OIDC) Authentication](configuration/oidc.md#set-environment-variables))

## June 2025 - MISP>=2.5.13

* Enabled OIDC Support (see [OpenID Connect (OIDC) Authentication](configuration/oidc.md),
    [Microsoft Entra ID](configuration/entra-id.md) and [Keycloak](configuration/keycloak.md))
* Split SSO settings into their own `.env` files (see
    [OpenID Connect (OIDC) Authentication](configuration/oidc.md#set-environment-variables) and 
    [Shibboleth 2 Service Provider for MISP](configuration/shibb.md#environment-variables))
* Updated Docker Compose project to use Redis 8

## May 2025 - MISP>=2.5.9

* Updated MISP Modules to v3.*
* Ensured `Security.cipherSeed` is randomised during initial setup
* Blocked default credentials from being used
* Made session cookie `SameSite=strict`
* Added support for running Shibboleth in high availability environments (see
    [Shibboleth 2 Service Provider for MISP](configuration/shibb.md#high-availability))

## March 2025 - MISP>=2.5.8

* Added a customisation volume (see [Custom Content](configuration/custom.md))
* Added ACME support (see Automatic Certificate Issuance via ACME on
    [Configuring MISP](configuration/general.md#automatic-certificate-issuance-via-acme))

## March 2025 - MISP>=2.5.7

* Added support for Redis over TLS

## October 2024 - MISP>=2.5.0

* Migrated to MISP 2.5 and PHP 8.3
