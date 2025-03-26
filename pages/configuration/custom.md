<!--
SPDX-FileCopyrightText: 2025 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# Custom Content

Adding custom content to the instance should be done using the `/opt/misp_custom` volume of the
`mis-web` and `misp-workers` containers.

For ease of reference, on this page `./` refers to the root of the `/opt/misp_custom` volume.

## Initial Setup Customisation

The container configures MISP into a usable state during initial start up, however, if you'd like to
further customise MISP during the initial startup phase, you can provide one or more bash scripts
which will be run at the end of the standard initial configuration process.

Place these scripts in `./init/`, ensuring they have a `.sh` extension - all other files in this
directory will be ignored.

The environment variable `$CAKE` will be available to to run MISP's CLI tool (CakePHP). If a setting
change references a file that will be copied in by a later section on this page, such as an image or
terms file, you make needed to include the `--force` flag to ensure the setting is changed even
though the file is not currently present, on consider using On Startup Actions below to change the
setting after the file has been copied into place.

### Example Custom Configuration Script

```sh
#!/bin/bash

# Adding a terms file
$CAKE Admin setSetting "MISP.terms_file" "terms.htm" --force
$CAKE Admin setSetting "MISP.terms_download" false
```

## On Startup Actions

If there are actions that need to be performed on every startup of the `misp-web` container, you can
provide one or more bash scripts to perform these steps.

Place these scripts in `./on_start/`, ensuring they have a `.sh` extension - all other files in this
directory will be ignored.

The environment variable `$CAKE` will be available to to run MISP's CLI tool (CakePHP).

## Custom Images

If you require any custom images to be used on your MISP instance, you can provide one or more files
in one of the two following locations.

### General Purpose Images

For general images, such as the logo on the logon screen, place the image(s) in: `./images/`,
ensuring they have a `.jpg`, `.png` or `.svg` extension - all other files in this directory will be
ignored.

### Organisation Logos

For images to be used as organisation logos, place the image(s) in `./org_icons/`, ensuring they
have a `.png` or `.svg` extension - all other files in this directory will be ignored.

These files must be named as either the display name or numeric identifier of the organisation, i.e.
`1.png` or `1.svg` will apply to the default organisation, `Jisc.png` or `Jisc.svg` will be used for
an organisation named "Jisc" in MISP.

## Custom Tagging Taxonomies

To install additional tagging taxonomies, create a folder for each under `./taxonomies/`, each
taxonomy folder **must** contain at least `machinetag.json` or it will not be copied into place.

Newly installed taxonomies will **not** be enabled by default, this must be done manually using the
MISP UI as follows:

1. Go to **Event Actions** / **List Taxonomies**,
1. Find the taxonomy in the list,
1. Click the corresponding Enable button (play icon) and confirm the action,
1. Click "enable all" and confirm the action, and
1. Optionally, toggle Required and Highlight to meet your local event standards.

***NOTE:*** MISP will only load the taxonomy into the database if either (i) the namespace doesn't
already exist in the database or (ii) the version number specified in `machinetag.json` is greater
than the version number already loaded into the database.

## Custom Terms Files

To install a Terms & Conditions file, place it in `./terms/`, a `.html` or `.pdf` file is
recommended but any file will be copied into place.

`MISP.terms_file` needs to be set to the filename for MISP to use the file, additionally for HTML
content it is recommended to set `MISP.terms_download` to `false`, for all other file types it is
recommended to set `MISP.terms_download` to `true`.

## Custom Maintenance Tasks

For details on adding additional background tasks to be run by the `misp-workers` container, see the
[Maintenance Tasks page](../management/maint_tasks.md).
