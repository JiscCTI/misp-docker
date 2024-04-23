#!/usr/bin/env python3

"""Update the name of the default organisation"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from os import environ
from os.path import isfile
from socket import gethostname
from uuid import UUID, uuid4

from pymisp import PyMISP, PyMISPError

from log import create_logger


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.1.0"

CONFIG_FILE = "/var/www/MISPData/misp_maintenance_jobs.ini"
config = ConfigParser()
config.read(CONFIG_FILE)

hostname = gethostname()
try:
    if len(environ["FQDN"]) > 0:
        hostname = environ["FQDN"]
except KeyError:
    pass
LOGGER = create_logger(
    "set_org_name",
    hostname,
    "/var/www/MISPData/tmp/logs",
    config.getboolean("DEFAULT", "debug"),
)
LOGGER.info("Starting set org name and UUID script")

MISP = PyMISP(
    config.get("DEFAULT", "baseUrl"),
    config.get("DEFAULT", "authKey"),
    config.getboolean("DEFAULT", "verifyTls"),
    tool=f"set_org_name/v{__version__}",
)

LOGGER.debug("Fetching default organisation from MISP")
try:
    organisation = MISP.get_organisation(1, pythonify=True)
    CHANGED = False
except PyMISPError as e:
    LOGGER.critical("Unable to get organisation 1 from MISP: (%s) %s", type(e), e)
    raise e

LOGGER.debug("Updating organisation name")
if environ["ORG_NAME"] is None or environ["ORG_NAME"] == "ORGNAME":
    LOGGER.warning("Organisation name not provided, keeping current.")
elif organisation.name == environ["ORG_NAME"]:
    LOGGER.debug("Organisation name already set to '%s'", environ["ORG_NAME"])
else:
    organisation.name = environ["ORG_NAME"]
    LOGGER.info("Organisation name changed to '%s'", environ["ORG_NAME"])
    CHANGED = True

LOGGER.debug("Updating organisation UUID")
if (
    environ["ORG_UUID"] is None
    or environ["ORG_UUID"] == "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
):
    if isfile("/var/www/MISPData/.org_uuid_set"):
        LOGGER.warning(
            "No UUID provided, keeping existing UUID '%s'", organisation.uuid
        )
    else:
        organisation.uuid = uuid4()
        LOGGER.warning("No UUID provided, new UUID '%s' generated", organisation.uuid)
        CHANGED = True

elif organisation.uuid == environ["ORG_UUID"]:
    LOGGER.debug("Provided UUID matches the organisation UUID")
else:
    try:
        UUID(environ["ORG_UUID"])
        organisation.uuid = environ["ORG_UUID"]
        LOGGER.info("Organisation UUID changed to '%s'", organisation.uuid)
        CHANGED = True
    except ValueError:
        if isfile("/var/www/MISPData/.org_uuid_set"):
            LOGGER.error(
                "Invalid UUID '%s' provided, keeping current organisation UUID '%s'",
                environ["ORG_UUID"],
                organisation.uuid,
            )
        else:
            organisation.uuid = uuid4()
            LOGGER.error(
                "Invalid UUID '%s' provided, new organisation UUID '%s' generated",
                environ["ORG_UUID"],
                organisation.uuid,
            )
            CHANGED = True

if CHANGED:
    try:
        LOGGER.debug("Updating organisation in MISP")
        MISP.update_organisation(organisation, 1)
        with open("/var/www/MISPData/.org_uuid_set", "w", encoding="utf-8"):
            pass
        LOGGER.info("Organisation updated")
    except PyMISPError as e:
        LOGGER.critical("Failed to update organisation in MISP: (%s) %s", type(e), e)
        raise e
else:
    LOGGER.info("Nothing to do")
