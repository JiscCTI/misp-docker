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
though the file is not currently present.

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


***Note*** Any other custom files, such as tagging taxonomies, must be added **after** the first
run or initial setup will not complete correctly. If you would like to add these files in before the
first run, they should be added into `./persistent/misp/data/import` to be moved into place by the
Custom Configuration step (below) - which runs at the end of the initial setup process.

## Adding Custom Content

If you need to add in taxonomies or other custom content into your MISP instance, these can be
placed in their respective sub-directories of `./persistent/misp/data/files/` and loaded into the
database using the buttons within the web UI, or they will be loaded daily by one of the 
[Automated Maintenance](../management/maint_tasks.md) task that are created by default.
