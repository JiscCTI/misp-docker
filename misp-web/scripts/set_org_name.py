#!/usr/bin/env python3

"""Update the name of the default organisation"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from os import environ

from pymisp import PyMISP

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.1"

try:
    environ["ORG_NAME"]
except KeyError as e:
    print("ORG_NAME environment variable missing")
    raise e

CONFIG_FILE = "/var/www/MISPData/misp_maintenance_jobs.ini"
Config = ConfigParser()
Config.read(CONFIG_FILE)

MISP = PyMISP(
    Config.get("DEFAULT", "baseUrl"),
    Config.get("DEFAULT", "authKey"),
    Config.getboolean("DEFAULT", "verifyTls"),
    tool=f"set_org_name/v{__version__}",
)
Organisation = MISP.get_organisation(1, pythonify=True)
Organisation.name = environ["ORG_NAME"]
MISP.update_organisation(Organisation, 1)
