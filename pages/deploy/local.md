<!-- # SPDX-FileCopyrightText: 2024 Jisc Services Limited
# SPDX-FileContributor: James Ellor
#
# SPDX-License-Identifier: GPL-3.0-only
-->

# Deploying MISP Images Locally Or Via Virtual Machine

If you are looking to deploy the MISP images locally on a system or through the use of virtual machines such as Hyper-V or VMware ESXi, follow the steps in this guide as well as on the [Configuration Page](/configuration/general).

Single Sign On (SSO) support can be found on the pages below:

- Microsoft Entra ID (formerly Azure Active Directory, or AAD) - This is awaiting upstream fixes and cannot be implemented currently. We will endeavour to update this page when it is ready to be used.
- OpenID Connect (OIDC) - Please see the [OIDC Page](/configuration/oidc/).
- Shibboleth / SAML 2.0 - Please see the [Shibboleth Page](/configuration/shibb/).

## MISP Web Configuration
### Docker Compose Configuration

Firstly, create a new directory to host your MISP instance and download the latest [docker-compose](https://github.com/JiscCTI/misp-docker/blob/main/docker-compose.yml) file from the JiscCTI GitHub.

By default the `docker-compose.yml` file provides ClamAV, MySQL and Redis for you. If you will be providing these modules another way, such as through managed Cloud Services, then please comment these sections out using `#`s at the start of each relevant line. Please also remember to set the relevant Environment Variables as per the table further down on this page.

In the instructions that follow, please replace `{instance name}` with `misp` or the Docker Compose project name if you specify one on the comand line or in the `COMPOSE_PROJECT_NAME` environment variable.


### Adding Custom Image Files

If you require any custom image files to be used on your MISP instance, follow the steps below which met your requirements:

- For general images, such as the logo on the logon screen, place the image(s) in `./persistent/{instanceName}/data/images/`.
- For images to be used for specifying organisatons, place the image(s) in `persistent/misp/data/files/img/orgs/`
    - `1.png`, `1.svg`, `{ORG_NAME}.png`, or `{ORG_NAME}.svg` will be used for the default organisation if present.

***Note*** Any other custom files, such as tagging taxonomies, must be added **after** the first run. If you would like to add these files in before the first run, they should be added into `./persistent/{instanceName}/data/import` to be used after the first run and can be used by creating custom scripts. Adding these files in before the first run will cause conflicts when cloning occurs

### MISP Settings

The container configures MISP into a usable state during initial start up, however, if you'd like to further customise MISP during this initial startup, please create a shell script named `./persistent/{instanceName}/data/custom-config.sh`. `$CAKE` is set to the command to run MISP's CLI tool (CakePHP) properly.

#### Example Custom Config

```
#!/bin/bash

# Adding a terms file
cp -r /var/www/MISPData/import/terms.htm /var/www/MISPData/files/terms/
$CAKE Admin setSetting "MISP.terms_file" "terms.htm"
$CAKE Admin setSetting "MISP.terms_download" false

# Installing a taxonomy
cp -r /var/www/MISPData/import/my-taxonomy /var/www/MISPData/files/taxonomies/
```

## After First Run

### Adding Custom Content

If you need to add in taxonomies or other custom content into your MISP instance, these can be places in their respective sub-directories of `./persistent/{instanceName}/data/files/` and loaded into the database using the buttons within the web UI, or they will be loaded daily by one of the automated tasks that have been created by us as default.

