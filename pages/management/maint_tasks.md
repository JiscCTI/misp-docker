<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Automated Maintenance

We have created some useful automated tasks and shipped them with the images by default, these can
be seen in the table below:

| Task | Frequency |
| ---- | --------- |
| Feed and server synchronisation | Hourly |
| Update Decay Models, Galaxies, Notice Lists, Objects, Taxonomies, Warning Lists, and Workflow Blueprints | Daily |

## Custom Tasks

If you would like to create your own custom automation scripts/tasks to be run by the misp-workers
container, please see the below steps as a guide:

1. Create the automation/script you require. If your automation/script needs to talk to the MISP
    API, it is recommended that the `configparser` module is used in order to read in the `authkey`,
    `baseUrl` and `verifyTls` options from the `DEFAULT` section of
    `/var/www/MISPData/misp_maintenance_jobs.ini`.
2. Place the automation/script into its own folder within the
    `./persistent/misp/data/custom_scripts` directory, mounted at
    `/var/www/MISPData/custom_scripts/` within the container.
3. For Python automations,
    1. Open a shell on the container: `docker compose exec -it workers bash`.
    2. Move to your task's directory: `cd /var/www/MISPData/custom_scripts/my_script`.
    3. Create a virtual environment: `/usr/local/bin/python3 -m venv venv`.
    4. Install any dependencies: `./venv/bin/python -m pip install -r requirements.txt`.
    5. Use `/var/www/MISPData/custom_scripts/my_script/venv/bin/python` as the executable below.
4. Add a section into `./persistent/misp/data/misp_maintenance_jobs.ini` to schedule your task.
    Please follow the guidelines below when doing this:
    - The section name **must** be unique.
    - `command` should use absolute paths to executables and scripts.
    - `enabled` can be set to `false` to temporarily disable a job without deleting it.
    - `interval` sets how often the automation should be triggered, in minutes.
    - `lastRun` is set by the scheduling system and should be set to 0 on creation.
    - Setting `needsAuthKey` to `True` will prevent the automation from running until a valid Auth
        Key has been automatically set in `/var/www/MISPData/misp_maintenance_jobs.ini` by the
        initial setup.
