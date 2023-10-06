#!/usr/bin/env python3

"""Rotate logs that do not rotate automatically"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: James Ellor
#
# SPDX-License-Identifier: GPL-3.0-only

from os.path import getsize
from shutil import copy, chown


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


logs = [
    "/var/www/MISPData/tmp/logs/apache_access.log",
    "/var/www/MISPData/tmp/logs/apache_error.log",
    "/var/www/MISPData/tmp/logs/debug.log",
    "/var/www/MISPData/tmp/logs/error.log",
    "/var/www/MISPData/tmp/logs/exec-errors.log",
    "/var/www/MISPData/tmp/logs/misp-workers-errors.log",
    "/var/www/MISPData/tmp/logs/misp-workers.log",
]

for logFile in logs:
    try:
        # 99.75 MB
        if getsize(logFile) > 99750000:
            copy(logFile, "{}.1".format(logFile))
            with open(logFile, "w") as f:
                pass
            chown("{}.1".format(logFile), "www-data", "www-data")
    except:
        pass
