#!/usr/bin/env python3

"""Import initial auth key"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser, ArgumentTypeError
from configparser import ConfigParser
from os.path import isfile
from re import compile as regex
from shutil import copy


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


def check_auth_key(auth_key: str) -> str:
    """Check the Auth Key has the correct format

    Args:
        auth_key (str): The Auth Key passed on the command line

    Raises:
        ArgumentTypeError: The Auth Key is invalid

    Returns:
        str: The Auth Key if it is valid
    """
    if not regex(r"^[0-9A-Za-z]{40}$").match(auth_key):
        raise ArgumentTypeError("invalid value")
    return auth_key


Parser = ArgumentParser()
Parser.add_argument("-k", "--auth-key", dest="key", required=True, type=check_auth_key)
Arguments = Parser.parse_args()

CONFIG_FILE = "/var/www/MISPData/misp_maintenance_jobs.ini"
if not isfile(CONFIG_FILE):
    copy("/opt/scripts/misp_maintenance_jobs.ini", CONFIG_FILE)

Config = ConfigParser()
Config.read(CONFIG_FILE)
Config.set("DEFAULT", "authKey", Arguments.key)
with open(CONFIG_FILE, "w", encoding="utf-8") as f:
    Config.write(f)
