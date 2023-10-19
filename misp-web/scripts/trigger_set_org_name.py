#!/usr/bin/env python3

"""Set last run on set_org_name to zero to force it to run"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


configFile = "/var/www/MISPData/misp_maintenance_jobs.ini"
Config = ConfigParser()
Config.read(configFile)
Config.set("set_org_name", "lastRun", "0")
with open(configFile, "w") as f:
    Config.write(f)
