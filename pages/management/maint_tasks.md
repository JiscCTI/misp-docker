<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
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

If you would like to create your own custom automation scripts/tasks to be run by the `misp-workers`
container, please see the below steps as a guide:

1. Create the automation/script you require. If your automation/script needs to talk to the MISP
    API, it is recommended that you read the `authkey`, `baseUrl` and `verifyTls` options from the
    `DEFAULT` section of `/var/www/MISPData/misp_maintenance_jobs.ini`.
    * For an example of doing this in Python see
        [set_org_name.py](https://github.com/JiscCTI/misp-docker/blob/main/misp-web/scripts/set_org_name.py)
2. Place the automation/script into its own folder under `./jobs/` within the `/opt/misp_custom`
    volume.
3. For Python automations,
    1. Open a shell on the container: `docker compose exec -it workers bash`.
    2. Move to your task's directory: `cd /opt/misp_custom/jobs/my_script`.
    3. Create a virtual environment: `/usr/local/bin/python3 -m venv .venv`.
    4. Install any dependencies: `./.venv/bin/python -m pip install -r requirements.txt`.
    5. Use `/opt/misp_custom/jobs/my_script/.venv/bin/python` as the executable below.
4. Add a section into `misp_maintenance_jobs.ini` in `./jobs/` of the `/opt/misp_custom` volume to
    schedule your task.
    * The section name **must** be unique and must not be `DEFAULT`, `rotate_logs`,
        `run_misp_sync_jobs`, `set_org_name` or `update_objects`.
    * `command` must be the absolute paths to the executable and where required scripts.
    * `enabled` can be set to `false` to temporarily disable a job without deleting it.
    * `interval` sets how often the automation should be triggered, in minutes.
    * Setting `needsAuthKey` to `True` will prevent the automation from running until a valid Auth
        Key has been automatically set in `/var/www/MISPData/misp_maintenance_jobs.ini` by the
        initial setup.

Here is an example entry in `/opt/misp_custom/jobs/misp_maintenance_jobs.ini`

```ini
[my_script]
command = /opt/misp_custom/jobs/my_script/.venv/bin/python /opt/misp_custom/jobs/my_script/run.py
enabled = true
interval = 15
needsAuthKey = true
```

## Disabling Custom Tasks

Once a custom task is created, it will be populated into the main `misp_maintenance_jobs.ini`,
therefore if you need to disable or remove a task, you need leave it in your custom
`misp_maintenance_jobs.ini` but set `enabled` to `false`, for ease of maintenance, you can remove
all other options.

### Example: Temporarily Disabled 

```ini
[my_script]
command = /opt/misp_custom/jobs/my_script/.venv/bin/python /opt/misp_custom/jobs/my_script/run.py
enabled = false
interval = 15
needsAuthKey = true
```

### Example: Permanently Disabled

```ini
[my_script]
enabled = false
```
