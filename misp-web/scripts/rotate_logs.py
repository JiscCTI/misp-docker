#!/usr/bin/env python3

"""Rotate logs that do not rotate automatically"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: James Ellor
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from os.path import getsize
from shutil import copy, chown


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.1"


LOGS = [
    "/var/www/MISPData/tmp/logs/apache_access.log",
    "/var/www/MISPData/tmp/logs/apache_error.log",
    "/var/www/MISPData/tmp/logs/debug.log",
    "/var/www/MISPData/tmp/logs/error.log",
    "/var/www/MISPData/tmp/logs/exec-errors.log",
    "/var/www/MISPData/tmp/logs/misp-workers-errors.log",
    "/var/www/MISPData/tmp/logs/misp-workers.log",
    "/var/www/MISPData/tmp/logs/update_objects.log",
]

for log_file in LOGS:
    try:
        # 99.75 MB
        if getsize(log_file) > 99750000:
            copy(log_file, f"{log_file}.1")
            with open(log_file, "w", encoding="utf-8") as f:
                pass
            chown(f"{log_file}.1", "www-data", "www-data")
    except (FileNotFoundError, OSError):
        pass
