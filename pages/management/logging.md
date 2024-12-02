<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Logging

Most logs for the solution are held in `persistent/misp/data/tmp/logs`, if using Shibboleth, the
Service Provider logs are written to `persistent/misp/shibb/logs`. It is recommended these are
ingested into a SIEM  and monitored for errors.

The logs in `persistent/misp/data/tmp/logs/` are:

* apache_access.log - Apache's access combined log.
* apache_error.log - Apache's error log.
* debug.log - MISP's debug level logging - including duplicating content of error.log.
* error.log - MISP's error log.
* exec-errors.log - MISP's execution error log, different from the error log above.
* misp_maintenance_runner.log - [Automated Maintenance](maint_tasks.md) runner log.
* misp_maintenance_supervisor-errors.log - stderr from supervisor - typically empty.
* misp_maintenance_supervisor.log - stdout from supervisor - typically empty.
* misp-workers-errors.log - MISP Worker's error log.
* misp-workers.log - MISP Worker's activity log.
* run_misp_sync_jobs.log - Sync Job logs from [Automated Maintenance](maint_tasks.md).
* set_org_name.log - Logs from the script which sets the organisation's name and UUID, part of
    [Automated Maintenance](maint_tasks.md).
