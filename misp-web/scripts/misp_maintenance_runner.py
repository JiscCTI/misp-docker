#!/usr/bin/env python3

"""Wrapper to to run MISP maintenance jobs"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from ipaddress import ip_address, IPv6Address
from logging import DEBUG, Formatter, getLogger, INFO, Logger
from logging.handlers import RotatingFileHandler
from os import environ
from os.path import isfile
from re import compile as regex
from shutil import copy
from subprocess import DEVNULL, Popen
from time import sleep, time
from urllib.parse import urlparse
from urllib.request import urlopen
from urllib3 import disable_warnings
from urllib3.exceptions import InsecureRequestWarning
from ssl import CERT_NONE, create_default_context


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"

AuthKeyRegEx = regex(r"^[0-9A-z]{40}$")
# Regular expression by Tim Groeneveld, Nov 18, 2014, https://stackoverflow.com/a/26987741
DomainNameRegEx = regex(
    r"^(((?!-))(xn--|_)?[a-z0-9-]{0,61}[a-z0-9]{1,1}\.)*"
    r"(xn--)?([a-z0-9][a-z0-9\-]{0,60}|[a-z0-9-]{1,30}"
    r"\.[a-z]{2,})$"
)


def CreateLogger(Debug: bool = False) -> Logger:
    """Initialise a Logger for the job runner, using a self rotating log file.

    Returns:
        Logger: A configured logging endpoint for the job runner.
    """

    TALogger = getLogger("misp_maintenance_runner")
    TALogger.propagate = False
    if Debug:
        TALogger.setLevel(DEBUG)
    else:
        TALogger.setLevel(INFO)
    LogPath = "/var/www/MISPData/tmp/logs/misp_maintenance_runner.log"

    # Prevent the log from growing beyond 20MB
    LogHandler = RotatingFileHandler(LogPath, maxBytes=20000000)
    LogFormatter = Formatter(
        "%(asctime)s {} %(name)s[%(process)d]: [%(levelname)s] %(message)s".format(
            environ["FQDN"]
        ),
        "%b %d %H:%M:%S",
    )
    LogHandler.setFormatter(LogFormatter)
    TALogger.addHandler(LogHandler)
    return TALogger


def IsValidDomain(Domain: str, AllowIP: bool = False) -> bool:
    """Check if a string is a valid domain name.

    Args:
        Domain (str): The string to test.
        AllowIP (bool): If IP addresses should be considered valid. Defaults to False.

    Returns:
        bool: Whether the domain is valid domain or not.
    """
    # For validation, make the domain name lowercase and encode any unicode characters using the Internationalized
    # Domain Names in Applications (IDNA) protocol (i.e. into xn-- format).
    Domain = Domain.lower().encode("idna").decode("utf-8")
    if DomainNameRegEx.match(Domain):
        # The string is a valid domain or IPv4 address
        if AllowIP:
            return True
        else:
            try:
                ip_address(Domain)
                # The string is a valid IPv4 address
                return False
            except:
                # The string is a valid domain
                return True
    else:
        # the string isn't a valid domain or IPv4 address
        if AllowIP:
            if Domain[0] == "[" and Domain[-1] == "]":
                # strip URL wrapping of IPv6 addresses
                Domain = Domain[1:-1]
            try:
                return type(ip_address(Domain)) == IPv6Address
                # Only valid if the string is a valid IPv6 address, not an IPv4 address
            except:
                # The string isn't a valid IPv6 address
                return False
        else:
            return False


configFile = "/var/www/MISPData/misp_maintenance_jobs.ini"
if not isfile(configFile):
    copy("/opt/scripts/misp_maintenance_jobs.ini", configFile)

config = ConfigParser()
logger = None
disable_warnings(InsecureRequestWarning)
sslContext = create_default_context()
sslContext.check_hostname = False
sslContext.verify_mode = CERT_NONE

while True:
    now = time()
    if logger != None:
        logger.debug("Re-reading config file")
    # count of successfully parsed configuration files
    if len(config.read(configFile)) == 0:
        if logger != None:
            logger.critical(
                "Config file is corrupt cannot continue, waiting 5 minutes to try again"
            )
        else:
            print(
                "Config file is corrupt cannot continue, waiting 5 minutes to try again"
            )
        # wait five minutes then retry
        sleep(300)
        continue

    if logger == None:
        logger = CreateLogger(config.getboolean("DEFAULT", "debug", fallback=True))
        logger.info("Starting maintenance job scheduler")

    try:
        baseUrl = config.get("DEFAULT", "baseUrl")
        test = urlparse(baseUrl)
        # As urlparse splits a URL without validation, do manual validation of the result.
        if test.scheme not in ["http", "https"] or not IsValidDomain(
            test.hostname, AllowIP=True
        ):
            raise ValueError()
    except Exception as e:
        logger.error(
            "Configured Base URL is invalid, reverting to https://{}:{} without TLS verification".format(
                environ["FQDN"], environ["HTTPS_PORT"]
            )
        )
        config.set(
            "DEFAULT",
            "baseUrl",
            "https://{}:{}".format(environ["FQDN"], environ["HTTPS_PORT"]),
        )
        config.set("DEFAULT", "verifyTls", "False")
        with open(configFile, "w") as f:
            config.write(f)

    try:
        authKey = config.get("DEFAULT", "authKey")
        if not AuthKeyRegEx.match(authKey):
            raise ValueError()
    except Exception as e:
        logger.error("Configured AuthKey is invalid, clearing it")
        config.set(
            "DEFAULT",
            "authKey",
            "0000000000000000000000000000000000000000",
        )
        with open(configFile, "w") as f:
            config.write(f)

    try:
        verifyTls = config.getboolean("DEFAULT", "verifyTls")
    except Exception as e:
        logger.error("Invalid boolean value for Verify TLS, reverting to False")
        config.set("DEFAULT", "verifyTls", "False")
        with open(configFile, "w") as f:
            config.write(f)

    try:
        urlopen(config.get("DEFAULT", "baseUrl"), context=sslContext)
    except:
        logger.warning("MISP isn't up at {}".format(config.get("DEFAULT", "baseUrl")))
        # wait 1 minute before re-running
        sleep(60)
        continue

    for job in config.sections():
        logger.debug("Processing job: {}".format(job))
        try:
            if config.getboolean(job, "enabled"):
                # configuration interval is in minutes, script interval is in seconds
                interval = config.getint(job, "interval") * 60
                # stored as UNIX Epoch time
                lastRun = config.getint(job, "lastRun")
                # if time since last run is greater or equal to interval
                if now - lastRun >= interval:
                    if (
                        config.getboolean(job, "needsAuthKey")
                        and config.get("DEFAULT", "authKey")
                        == "0000000000000000000000000000000000000000"
                    ):
                        logger.error(
                            "{} skipped: a valid AuthKey is required but not present".format(
                                job
                            )
                        )
                    else:
                        logger.info("Triggering job: {}".format(job))
                        # fire and forget the job - it should have its own logging
                        Popen(
                            ["sh", "-c", config.get(job, "command")],
                            stderr=DEVNULL,
                            stdout=DEVNULL,
                        )
                        logger.debug("Job {} triggered successfully".format(job))
                    # update the config with the last run time, rounded to the closest second
                    config.set(job, "lastRun", str(int(now)))
                else:
                    logger.debug("Job {} is not due yet".format(job))
            else:
                logger.debug("Job {} is disabled".format(job))
        except Exception as e:
            logger.error("Error processing job {}: ({}) {}".format(job, type(e), e))

    logger.debug("Writing back config file")
    with open(configFile, "w") as f:
        config.write(f)

    # wait 1 minute before re-running
    sleep(60)
