<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->

### Automated Maintenance

We have created some useful automated tasks and shipped them with the images by default, these can be seen in the table below:

| Task | Frequency |
| ---- | --------- |
| Feed and server synchronisation | Hourly |
| Update Decay Models, Galaxies, Notice Lists, Objects, Taxonomies, Warning Lists, and Workflow Blueprints | Daily |

If you would like to create your own custom automation scripts/tasks to be run by the misp-workers container, please see the below steps as a guide:

1. Create the automation/script you require. If your automation/script needs to talk to the MISP API, it is recommended that the `configparser` module is used in order to read in the `authkey`, `baseUrl` and `verifyTls` from the `DEFAULT` section of `/var/www/MISPData/misp_maintenance_jobs.ini`.
2. Place the automation/script into its own folder within the `./persistent/{instanceName}/data/custom_scripts` directory, mounted as `/var/www/MISPData/custom_scripts/`.
    - For Python automations, use the command `/usr/local/bin/python3 -m venv venv` within the misp-workers container to create a Python 3.10 virtual environment.
3. Add a section into `./persistent/{instanceName}/data/misp_maintenance_jobs.ini` to schedule your task. Please follow the guidelines below when doing this:
    - The section name **must** be unique.
    - `command` should use absolute paths to executables and scripts.
    - `enabled` can be set to `false` to temporarily disable a job(s) without deleting it.
    - `interval` sets how often the automation should be triggered, in minutes.
    - `lastRun` is set by the scheduling system and should be set to 0 on creation.
    - Setting `needsAuthKey` to `True` will prevent the automation from running until a valid Auth Key has been automatically set by the initial setup.
