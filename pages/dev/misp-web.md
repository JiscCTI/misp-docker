<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->
# misp-web Image

The misp-web image contains the web front end of MISP, and can be deployed with multiple replicas to
support high availability and load balancing deployments.

The image only persists instance-specific directories, rather than the entire `/var/www` directory.
Symbolic links are used to remap these instance-specific directories.

## Build

The image uses a multi-stage build to minimise the size of the final image and keep build tools and
artefacts out of the final image.

### php_build

As not all of the required PHP modules are available out of the box in the official PHP image, the
`php_build` phase starts from the `php:8.4-apache` image and installs or builds then enables the
required modules. A customised
[php.ini](https://github.com/JiscCTI/misp-docker/blob/main/misp-web/php.ini) file is also copied in.

### misp_build

With PHP ready, the `misp_build` stage runs the MISP-specific build tasks, starting from the
`php:8.4-apache` image.

MISP is cloned from GitHub using the version number provided in the Build Argument `MISP_VERSION` as
the tag to pull.

The build and installed PHP modules from `php_build` are copied in, along with the configuration. As
is Python from `python_build`.

`composer.phar` installs dependencies based on requirements files in the MISP repo, see the MISP
repo for an up to date list.

MISP uses a Python virtual environment for all of its Python needs.

To minimise the image size, most git files and dynamically updated git submodules are deleted; only
those git files used for version checking are retained.

### final

The `final` stage pulls together what has been built in earlier stages, while only installing what
is required to operate the modules (i.e. no build tools of -dev packages). The image starts from the
`php:8.4-apache` image.

Default values are set for all environment variables, to allow MISP to start without any being
provided, though this is **not** recommended. For ease of use, the environment variable `$CAKE` is set to
the full command required to invoke CakePHP as the correct user.

The Apache `status` module is disabled, while the `headers`, `rewrite`, `setenvif`, `shib` and `ssl`
modules are enabled.

## Entrypoint

The entrypoint for the image:

* Enables / restores persistent storage.
* Creates the database on first start.
* Performs initial configuration on first start.
* Checks a TLS certificate is present, generating a self-signed one if not.
* Updates any settings based on changed environment variables.
* Runs any required database upgrades.
* Clones / updates dynamic content such as galaxies and object templates.
* Starts the Apache web server.

## Health Check

The image contains a basic health check which reports healthy (exit code 0) if the logon page is
reachable with a 200 (OK) status code and otherwise reports unhealthy (exit code 1).

## Exposed Ports

The image exposes:

* 80/tcp - HTTP to HTTPS redirect.
* 443/tcp - MISP Web UI (and API) over HTTPS .

## Volumes

The image uses the following volumes:

| Mount Point | Purpose |
|-------------|---------|
| /etc/ssl/private/ | Holds the TLS certificate (and chain) (`misp.crt`) and the private key (`misp.key`) used to serve MISP over HTTPS. |
| /var/www/MISPData | Holds the instance specific data which needs to be persisted between updates and container recreations. |
| /var/www/MISPGnuPG | Holds the GPG/PGP key chain used by MISP for email signing and encryption. |
