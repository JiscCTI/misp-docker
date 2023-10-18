#!/usr/bin/env python3

"""Update the name Org ID"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from os import environ

from pymisp import PyMISP

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"

try:
    environ["ORG_NAME"]
except KeyError:
    print("ORG_NAME environment variable missing")
    exit(1)

configFile = "/var/www/MISPData/misp_maintenance_jobs.ini"
Config = ConfigParser()
Config.read(configFile)

MISP = PyMISP(
    Config.get("DEFAULT", "baseUrl"),
    Config.get("DEFAULT", "authKey"),
    Config.getboolean("DEFAULT", "verifyTls"),
    tool="set_org_name/v{}".format(__version__),
)
Organisation = MISP.get_organisation(1, pythonify=True)
Organisation.name = environ["ORG_NAME"]
MISP.update_organisation(Organisation, 1)
