#!/usr/bin/env python3

"""Import initial auth key"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser, ArgumentTypeError
from configparser import ConfigParser
from os.path import isfile
from re import compile
from shutil import copy


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


def AuthKeyType(AuthKey: str) -> str:
    """Check the Auth Key has the correct format

    Args:
        AuthKey (str): The Auth Key passed on the command line

    Raises:
        ArgumentTypeError: The Auth Key is invalid

    Returns:
        str: The Auth Key if it is valid
    """
    if not compile(r"^[0-9A-z]{40}$").match(AuthKey):
        raise ArgumentTypeError("invalid value")
    return AuthKey


Parser = ArgumentParser()
Parser.add_argument("-k", "--auth-key", dest="key", required=True, type=AuthKeyType)
Arguments = Parser.parse_args()

configFile = "/var/www/MISPData/misp_maintenance_jobs.ini"
if not isfile(configFile):
    copy("/opt/scripts/misp_maintenance_jobs.ini", configFile)

Config = ConfigParser()
Config.read(configFile)
Config.set("DEFAULT", "authKey", Arguments.key)
with open(configFile, "w") as f:
    Config.write(f)
