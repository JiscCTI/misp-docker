<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->

# Deploying MISP Locally

If you are looking to deploy the MISP images locally, follow the steps in this guide as well as on
the [Configuration Page](../configuration/general.md).

Single Sign On (SSO) support can be found on the pages below:

- Microsoft Entra ID (formerly Azure Active Directory, or AAD) - This is awaiting upstream fixes and
    cannot be implemented currently. We will endeavour to update this page when it is ready to be
    used.
- OpenID Connect (OIDC) - Please see the [OIDC Page](../configuration/oidc.md).
- Shibboleth / SAML 2.0 - Please see the [Shibboleth Page](../configuration/shibb.md).

## Docker Compose Configuration

Firstly, create a new directory to host your MISP instance and download the latest
[docker-compose.yml](https://github.com/JiscCTI/misp-docker/blob/main/docker-compose.yml) file from
the Jisc CTI GitHub.

By default the `docker-compose.yml` file provides ClamAV, MySQL and Redis for you. If you will be
providing these modules another way, such as through managed Cloud Services, then please comment
these sections out using `#`s at the start of each relevant line. Please also remember to set the
relevant Environment Variables as per the table further down on this page.

## Configure MISP

See [Configuring MISP](../configuration/general.md) for help configuring MISP ready for use.

## Adding Custom Image Files

If you require any custom image files to be used on your MISP instance, follow the steps below which
meet your requirements:

- For general images, such as the logo on the logon screen, place the image(s) in
    `./persistent/misp/data/images/`.
- For images to be used for specifying organisations, place the image(s) in
    `persistent/misp/data/files/img/orgs/`. E.g. `1.png`, `1.svg`, `{ORG_NAME}.png`, or
    `{ORG_NAME}.svg` will be used for the default organisation if present.

***Note*** Any other custom files, such as tagging taxonomies, must be added **after** the first
run or initial setup will not complete correctly. If you would like to add these files in before the
first run, they should be added into `./persistent/misp/data/import` to be moved into place by the
Custom Configuration step (below) - which runs at the end of the initial setup process.

## Custom Configuration

The container configures MISP into a usable state during initial start up, however, if you'd like to
further customise MISP during this initial startup, please create a shell script named
`./persistent/misp/data/custom-config.sh`.

`$CAKE` is set to the command to run MISP's CLI tool (CakePHP) properly.

### Example Custom Configuration Script

```sh
#!/bin/bash

# Adding a terms file
cp -r /var/www/MISPData/import/terms.htm /var/www/MISPData/files/terms/
$CAKE Admin setSetting "MISP.terms_file" "terms.htm"
$CAKE Admin setSetting "MISP.terms_download" false

# Installing a taxonomy
cp -r /var/www/MISPData/import/my-taxonomy /var/www/MISPData/files/taxonomies/
```

## Adding Custom Content

If you need to add in taxonomies or other custom content into your MISP instance, these can be
placed in their respective sub-directories of `./persistent/misp/data/files/` and loaded into the
database using the buttons within the web UI, or they will be loaded daily by one of the 
[Automated Maintenance](../management/maint_tasks.md) task that are created by default.
