#!/usr/bin/env python3

"""Run feed and server synchronisation tasks in MISP"""

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: James Ellor
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from logging import DEBUG, Formatter, getLogger, INFO, Logger
from logging.handlers import RotatingFileHandler
from os import environ, getpid, kill, remove
from os.path import isfile
from socket import gethostname
from subprocess import PIPE, run

try:
    from pymisp import PyMISP
except ImportError:
    print("PyMISP is not installed, cannot run")
    exit(1)


__author__ = "James Ellor"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "James.Ellor@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "James Ellor"
__status__ = "Production"
__version__ = "1.0.0"


def CreateLogger(Debug: bool) -> Logger:
    """Initialise a Logger for the script using a self rotating log file.

    Returns:
        Logger: A configured logging endpoint for the script.
    """

    MISPLogger = getLogger("run_misp_sync_jobs")
    MISPLogger.propagate = False
    if Debug:
        MISPLogger.setLevel(DEBUG)
    else:
        MISPLogger.setLevel(INFO)
    LogPath = "/var/www/MISPData/tmp/logs/run_misp_sync_jobs.log"
    # Prevent the log from growing beyond 20MB
    LogHandler = RotatingFileHandler(LogPath, maxBytes=20000000, backupCount=1)
    hostname = gethostname()
    try:
        if len(environ["FQDN"]) > 0:
            hostname = environ["FQDN"]
    except:
        pass
    LogFormatter = Formatter(
        "%(asctime)s {} %(name)s[%(process)d]: [%(levelname)s] %(message)s".format(
            hostname
        ),
        "%b %d %H:%M:%S",
    )
    LogHandler.setFormatter(LogFormatter)
    MISPLogger.addHandler(LogHandler)
    return MISPLogger


configFile = "/var/www/MISPData/misp_maintenance_jobs.ini"

config = ConfigParser()
config.read(configFile)
baseUrl = config.get("DEFAULT", "baseUrl")
authKey = config.get("DEFAULT", "authKey")
verifyTls = config.getboolean("DEFAULT", "verifyTls")
debug = config.getboolean("DEFAULT", "debug")

MISPLogger = CreateLogger(debug)
MISPLogger.info("Starting sync script")

MISPLogger.debug("Checking for mutex")
Mutex = "/var/www/MISPData/tmp/run_misp_sync_jobs.pid"
if isfile(Mutex):
    with open(Mutex, "r") as f:
        try:
            PID = int(f.read())
            MISPLogger.debug("Mutex found, validating it")
        except:
            # Didn't look like a PID
            PID = None
    if PID == None:
        remove(Mutex)
    else:
        try:
            # Use kill to check if process exists, but do not send a signal
            kill(PID, 0)
        except (OSError, SystemError):
            # PID not running
            remove(Mutex)
            MISPLogger.debug("Mutex is invalid, removing it")
        else:
            # PID is running
            MISPLogger.warn("Already running under PID {}. Aborting.".format(PID))
            exit(1)

# Create Mutex with process PID in
with open(Mutex, "w") as f:
    f.write(str(getpid()))
    MISPLogger.debug("Mutex obtained")

MISPLogger.info("Connecting to MISP API")
try:
    misp = PyMISP(baseUrl, authKey, verifyTls)
except Exception as e:
    MISPLogger.critical(
        "Failed to connect to the MISP instance: ({}) {}".format(type(e), e)
    )
    exit(1)

MISPLogger.debug("Fetching list of configured feeds")
feeds = misp.feeds()
MISPLogger.debug("{} configured feeds found".format(len(feeds)))
for feed in feeds:
    feed = feed["Feed"]
    if feed["enabled"]:
        MISPLogger.info(
            'Fetching feed feed_id={} feed_name="{}" action=fetch'.format(
                feed["id"], feed["name"]
            )
        )
        fetch = run(
            [
                "sh",
                "-c",
                "$CAKE Server fetchFeed 1 {}".format(feed["id"]),
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        if b"Stack Trace" not in fetch.stderr:
            MISPLogger.info(
                'Successfully fetched feed feed_id={} feed_name="{}" action=fetch'.format(
                    feed["id"], feed["name"]
                )
            )
        else:
            MISPLogger.error(
                'Failed to fetch feed feed_id={} feed_name="{}" action=fetch'.format(
                    feed["id"], feed["name"]
                )
            )

    if feed["caching_enabled"]:
        MISPLogger.info(
            'Caching feed feed_id={} feed_name="{}" action=cache'.format(
                feed["id"], feed["name"]
            )
        )
        cache = run(
            [
                "sh",
                "-c",
                "$CAKE Server cacheFeed 1 {}".format(feed["id"]),
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        if b"Stack Trace" not in cache.stderr:
            MISPLogger.info(
                'Successfully cached feed feed_id={} feed_name="{}" action=cache'.format(
                    feed["id"], feed["name"]
                )
            )
        else:
            MISPLogger.error(
                'Failed to cache feed feed_id={} feed_name="{}" action=cache'.format(
                    feed["id"], feed["name"]
                )
            )

MISPLogger.debug("Fetching list of configured servers")
servers = misp.servers()
MISPLogger.debug("{} configured servers found".format(len(servers)))
for server in servers:
    server = server["Server"]
    if server["pull"]:
        MISPLogger.info(
            'Pulling from server server_id={} server_name="{}" action=pull'.format(
                server["id"], server["name"]
            )
        )
        pull = run(
            [
                "sh",
                "-c",
                "$CAKE Server pull 1 {} full".format(feed["id"]),
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        if b"Stack Trace" not in pull.stderr:
            MISPLogger.info(
                'Successfully pulled from server server_id={} server_name="{}" action=pull'.format(
                    server["id"], server["name"]
                )
            )
        else:
            MISPLogger.error(
                'Failed to pull from server server_id={} server_name="{}" action=pull'.format(
                    server["id"], server["name"]
                )
            )

    if server["caching_enabled"]:
        MISPLogger.info(
            'Caching server server_id={} server_name="{}" action=cache'.format(
                server["id"], server["name"]
            )
        )
        cache = run(
            [
                "sh",
                "-c",
                "$CAKE Server cacheServer 1 {}".format(server["id"]),
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        if b"Stack Trace" not in cache.stderr:
            MISPLogger.info(
                'Successfully cached server server_id={} server_name="{}" action=cache'.format(
                    server["id"], server["name"]
                )
            )
        else:
            MISPLogger.error(
                'Failed to cache server server_id={} server_name="{}" action=cache'.format(
                    server["id"], server["name"]
                )
            )

for server in servers:
    server = server["Server"]
    if server["push"]:
        MISPLogger.info(
            'Pushing to server server_id={} server_name="{}" action=push'.format(
                server["id"], server["name"]
            )
        )
        pull = run(
            [
                "sh",
                "-c",
                "$CAKE Server push 1 {} full".format(feed["id"]),
            ],
            stdout=PIPE,
            stderr=PIPE,
        )
        if b"Stack Trace" not in pull.stderr:
            MISPLogger.info(
                'Successfully pushed to server server_id={} server_name="{}" action=push'.format(
                    server["id"], server["name"]
                )
            )
        else:
            MISPLogger.error(
                'Failed to push to server server_id={} server_name="{}" action=push'.format(
                    server["id"], server["name"]
                )
            )

MISPLogger.info("Sync script finished")

# Remove Mutex file
MISPLogger.debug("Releasing mutex")
remove(Mutex)
