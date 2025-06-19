#!/usr/bin/env python3

"""Wrapper to to run MISP maintenance jobs"""

# SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from ipaddress import ip_address, IPv6Address
from logging import DEBUG, INFO
from os import environ
from os.path import isfile
from re import compile as regex
from shutil import copy
from socket import gethostname
from subprocess import DEVNULL, Popen
from time import sleep, time

from urllib3 import disable_warnings
from urllib3.exceptions import InsecureRequestWarning

try:
    from requests import get, RequestException
except ImportError as e:
    print("Failed to import requests.")
    raise e

from log import create_logger

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2025, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.1.0"

AUTH_KEY_REGEX = regex(r"^[0-9A-Za-z]{40}$")
# Regular expression by Tim Groeneveld, Nov 18, 2014, https://stackoverflow.com/a/26987741
DOMAIN_REGEX = regex(
    r"^(((?!-))(xn--|_)?[a-z0-9-]{0,61}[a-z0-9]{1,1}\.)*"
    r"(xn--)?([a-z0-9][a-z0-9\-]{0,60}|[a-z0-9-]{1,30}"
    r"\.[a-z]{2,})$"
)


def is_valid_domain(domain: str, allow_ip: bool = False) -> bool:
    """Check if a string is a valid domain name.

    Args:
        domain (str): The string to test.
        allow_ip (bool): If IP addresses should be considered valid. Defaults to False.

    Returns:
        bool: Whether the domain is valid domain or not.
    """
    # For validation, make the domain name lowercase and encode any unicode characters using the
    # Internationalized Domain Names in Applications (IDNA) protocol (i.e. into xn-- format).
    domain = domain.lower().encode("idna").decode("utf-8")
    if DOMAIN_REGEX.match(domain):
        # The string is a valid domain or IPv4 address
        if allow_ip:
            return True

        try:
            ip_address(domain)
            # The string is a valid IPv4 address
            return False
        except ValueError:
            # The string is a valid domain
            return True

    # the string isn't a valid domain or IPv4 address
    if allow_ip:
        if domain[0] == "[" and domain[-1] == "]":
            # strip URL wrapping of IPv6 addresses
            domain = domain[1:-1]
        try:
            return isinstance(ip_address(domain), IPv6Address)
            # Only valid if the string is a valid IPv6 address, not an IPv4 address
        except ValueError:
            # The string isn't a valid IPv6 address
            return False

    return False


CONFIG_FILE = "/var/www/MISPData/misp_maintenance_jobs.ini"
CUSTOM_CONFIG_FILE = "/opt/misp_custom/jobs/misp_maintenance_jobs.ini"

config = ConfigParser()
LOGGER = None
disable_warnings(InsecureRequestWarning)

hostname = gethostname()
try:
    if len(environ["FQDN"]) > 0:
        hostname = environ["FQDN"]
except KeyError:
    pass

while True:
    now = time()
    if LOGGER is not None:
        LOGGER.debug("Re-reading config file")
    if not isfile(CONFIG_FILE):
        copy("/opt/scripts/misp_maintenance_jobs.ini", CONFIG_FILE)
    # count of successfully parsed configuration files
    if len(config.read(CONFIG_FILE)) == 0:
        if LOGGER is not None:
            LOGGER.critical(
                "Config file is corrupt cannot continue, waiting 5 minutes to try again"
            )
        else:
            print(
                "Config file is corrupt cannot continue, waiting 5 minutes to try again"
            )
        # wait five minutes then retry
        sleep(300)
        continue

    if isfile(CUSTOM_CONFIG_FILE):
        if len(config.read(CUSTOM_CONFIG_FILE)) == 0:
            if LOGGER is not None:
                LOGGER.error(
                    "Custom config file is corrupt cannot continue, ignoring it"
                )
            else:
                print("Custom config file is corrupt cannot continue, ignoring it")

    if LOGGER is None:
        LOGGER = create_logger(
            "misp_maintenance_runner",
            hostname,
            "/var/www/MISPData/tmp/logs",
            config.getboolean("DEFAULT", "debug", fallback=True),
        )
        LOGGER.info("Starting maintenance job scheduler")

    try:
        if not is_valid_domain(environ["FQDN"], allow_ip=True):
            raise ValueError()
        base_url = f"https://{environ['FQDN']}:{environ['HTTPS_PORT']}"
        if base_url.endswith(":443"):
            base_url = base_url.replace(":443", "")
        config.set("DEFAULT", "baseUrl", base_url)
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            config.write(f)
    except (KeyError, ValueError) as e:
        LOGGER.critical("Configured FQDN is invalid, cannot start maintenance tasks")
        raise e

    try:
        authKey = config.get("DEFAULT", "authKey")
        if not AUTH_KEY_REGEX.match(authKey):
            raise ValueError()
    except (KeyError, ValueError) as e:
        LOGGER.error("Configured AuthKey is invalid, clearing it")
        config.set(
            "DEFAULT",
            "authKey",
            "0000000000000000000000000000000000000000",
        )
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            config.write(f)

    try:
        verifyTls = config.getboolean("DEFAULT", "verifyTls")
    except (KeyError, ValueError):
        LOGGER.error("Invalid boolean value for Verify TLS, reverting to False")
        config.set("DEFAULT", "verifyTls", "False")
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            config.write(f)

    try:
        DEBUG_LOGGING = config.getboolean("DEFAULT", "debug")
    except (KeyError, ValueError):
        LOGGER.error("Invalid boolean value for Debug, reverting to False")
        config.set("DEFAULT", "debug", "False")
        DEBUG_LOGGING = False
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            config.write(f)

    if DEBUG_LOGGING:
        LOGGER.setLevel(DEBUG)
    else:
        LOGGER.setLevel(INFO)

    try:
        response = get(
            config.get("DEFAULT", "baseUrl"),
            timeout=3,
            verify=config.getboolean("DEFAULT", "verifyTls"),
        )
        if response.status_code >= 400:
            raise ValueError(f"HTTP Status: {response.status_code} ({response.reason})")
    except (KeyError, ValueError, RequestException) as e:
        LOGGER.warning("MISP isn't up at %s", config.get("DEFAULT", "baseUrl"))
        LOGGER.debug("Reason: (%s): %s", type(e), e)
        # wait 1 minute before re-running
        sleep(60)
        continue

    for job in config.sections():
        LOGGER.debug("Processing job: %s", job)
        try:
            if config.getboolean(job, "enabled"):
                # configuration interval is in minutes, script interval is in seconds
                interval = config.getint(job, "interval") * 60
                # stored as UNIX Epoch time
                last_run = config.getint(job, "lastRun", fallback=0)
                # if time since last run is greater or equal to interval
                if now - last_run >= interval:
                    if (
                        config.getboolean(job, "needsAuthKey")
                        and config.get("DEFAULT", "authKey")
                        == "0000000000000000000000000000000000000000"
                    ):
                        LOGGER.error(
                            "%s skipped: a valid AuthKey is required but not present",
                            job,
                        )
                    else:
                        LOGGER.info("Triggering job: %s", job)
                        # fire and forget the job - it should have its own logging
                        Popen(  # pylint: disable=consider-using-with
                            ["/bin/bash", "-c", config.get(job, "command")],
                            stderr=DEVNULL,
                            stdout=DEVNULL,
                        )
                        LOGGER.debug("Job %s triggered", job)
                    # update the config with the last run time, rounded to the closest second
                    config.set(job, "lastRun", str(int(now)))
                else:
                    LOGGER.debug("Job %s is not due yet", job)
            else:
                LOGGER.debug("Job %s is disabled", job)
        # Broad exception deliberately caught to prevent a malformed job crashing scheduler
        except Exception as e:  # pylint: disable=broad-exception-caught
            LOGGER.error("Error processing job %s: (%s) %s", job, type(e), e)

    LOGGER.debug("Writing back config file")
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        config.write(f)

    # wait 1 minute before re-running
    sleep(60)
