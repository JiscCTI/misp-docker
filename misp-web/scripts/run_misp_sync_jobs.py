#!/usr/bin/env python3

"""Run feed and server synchronisation tasks in MISP"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: James Ellor
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from configparser import ConfigParser
from os import environ, getpid, kill, remove
from os.path import isfile
from socket import gethostname
from subprocess import PIPE, run
from sys import exit as sys_exit

try:
    from pymisp import PyMISP
    from pymisp.exceptions import PyMISPError
except ImportError as e:
    print("PyMISP is not installed, cannot run")
    raise e

from log import create_logger


__author__ = "James Ellor"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "James.Ellor@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "James Ellor"
__status__ = "Production"
__version__ = "1.0.1"


CONFIG_FILE = "/var/www/MISPData/misp_maintenance_jobs.ini"
config = ConfigParser()
config.read(CONFIG_FILE)
base_url = config.get("DEFAULT", "baseUrl")
auth_key = config.get("DEFAULT", "authKey")
verify_tls = config.getboolean("DEFAULT", "verifyTls")
debug = config.getboolean("DEFAULT", "debug")

hostname = gethostname()
try:
    if len(environ["FQDN"]) > 0:
        hostname = environ["FQDN"]
except KeyError:
    pass
LOGGER = create_logger(
    "run_misp_sync_jobs",
    hostname,
    "/var/www/MISPData/tmp/logs",
    debug,
)
LOGGER.info("Starting sync script")

LOGGER.debug("Checking for mutex")
MUTEX_FILE = "/var/www/MISPData/tmp/run_misp_sync_jobs.pid"
if isfile(MUTEX_FILE):
    with open(MUTEX_FILE, "r", encoding="utf-8") as f:
        try:
            PID = int(f.read())
            LOGGER.debug("Mutex found, validating it")
        except ValueError:
            # Didn't look like a PID
            PID = None
    if PID is None:
        remove(MUTEX_FILE)
    else:
        try:
            # Use kill to check if process exists, but do not send a signal
            kill(PID, 0)
        except (OSError, SystemError):
            # PID not running
            remove(MUTEX_FILE)
            LOGGER.debug("Mutex is invalid, removing it")
        else:
            # PID is running
            LOGGER.warning("Already running under PID %s. Aborting.", PID)
            sys_exit(1)

# Create Mutex with process PID in
with open(MUTEX_FILE, "w", encoding="utf-8") as f:
    f.write(str(getpid()))
    LOGGER.debug("Mutex obtained")

LOGGER.info("Connecting to MISP API")
try:
    misp = PyMISP(base_url, auth_key, verify_tls)
except PyMISPError as e:
    LOGGER.critical("Failed to connect to the MISP instance: (%s) %s", type(e), e)
    raise e

LOGGER.debug("Fetching list of configured feeds")
feeds = misp.feeds()
LOGGER.debug("%s configured feeds found", len(feeds))
for feed in feeds:
    feed = feed["Feed"]
    if feed["enabled"]:
        LOGGER.info(
            'Fetching feed feed_id=%s feed_name="%s" action=fetch',
            feed["id"],
            feed["name"],
        )
        fetch = run(
            [
                "/bin/bash",
                "-c",
                f"$CAKE Server fetchFeed 1 {feed['id']}",
            ],
            stdout=PIPE,
            stderr=PIPE,
            check=False,
        )
        if b"Error" not in fetch.stderr and b"Stack Trace" not in fetch.stderr:
            LOGGER.info(
                'Successfully fetched feed feed_id=%s feed_name="%s" action=fetch',
                feed["id"],
                feed["name"],
            )
        else:
            LOGGER.error(
                'Failed to fetch feed feed_id=%s feed_name="%s" action=fetch',
                feed["id"],
                feed["name"],
            )

    if feed["caching_enabled"]:
        LOGGER.info(
            'Caching feed feed_id=%s feed_name="%s" action=cache',
            feed["id"],
            feed["name"],
        )
        cache = run(
            [
                "/bin/bash",
                "-c",
                f"$CAKE Server cacheFeed 1 {feed['id']}",
            ],
            stdout=PIPE,
            stderr=PIPE,
            check=False,
        )
        if b"Error" not in cache.stderr and b"Stack Trace" not in cache.stderr:
            LOGGER.info(
                'Successfully cached feed feed_id=%s feed_name="%s" action=cache',
                feed["id"],
                feed["name"],
            )
        else:
            LOGGER.error(
                'Failed to cache feed feed_id=%s feed_name="%s" action=cache',
                feed["id"],
                feed["name"],
            )

LOGGER.debug("Fetching list of configured servers")
servers = misp.servers()
LOGGER.debug("%s configured servers found", len(servers))
for server in servers:
    server = server["Server"]
    if server["pull"]:
        LOGGER.info(
            'Pulling from server server_id=%s server_name="%s" action=pull',
            server["id"],
            server["name"],
        )
        pull = run(
            [
                "/bin/bash",
                "-c",
                f"$CAKE Server pull 1 {server['id']} full",
            ],
            stdout=PIPE,
            stderr=PIPE,
            check=False,
        )
        if b"Error" not in pull.stderr and b"Stack Trace" not in pull.stderr:
            LOGGER.info(
                'Successfully pulled from server server_id=%s server_name="%s" action=pull',
                server["id"],
                server["name"],
            )
        else:
            LOGGER.error(
                'Failed to pull from server server_id=%s server_name="%s" action=pull',
                server["id"],
                server["name"],
            )

    if server["caching_enabled"]:
        LOGGER.info(
            'Caching server server_id=%s server_name="%s" action=cache',
            server["id"],
            server["name"],
        )
        cache = run(
            [
                "/bin/bash",
                "-c",
                f"$CAKE Server cacheServer 1 {server['id']}",
            ],
            stdout=PIPE,
            stderr=PIPE,
            check=False,
        )
        if b"Error" not in cache.stderr and b"Stack Trace" not in cache.stderr:
            LOGGER.info(
                'Successfully cached server server_id=%s server_name="%s" action=cache',
                server["id"],
                server["name"],
            )
        else:
            LOGGER.error(
                'Failed to cache server server_id=%s server_name="%s" action=cache',
                server["id"],
                server["name"],
            )

for server in servers:
    server = server["Server"]
    if server["push"]:
        LOGGER.info(
            'Pushing to server server_id=%s server_name="%s" action=push',
            server["id"],
            server["name"],
        )
        push = run(
            [
                "/bin/bash",
                "-c",
                f"$CAKE Server push 1 {server['id']} full",
            ],
            stdout=PIPE,
            stderr=PIPE,
            check=False,
        )
        if b"Error" not in push.stderr and b"Stack Trace" not in push.stderr:
            LOGGER.info(
                'Successfully pushed to server server_id=%s server_name="%s" action=push',
                server["id"],
                server["name"],
            )
        else:
            LOGGER.error(
                'Failed to push to server server_id=%s server_name="%s" action=push',
                server["id"],
                server["name"],
            )

LOGGER.info("Sync script finished")

# Remove Mutex file
LOGGER.debug("Releasing mutex")
remove(MUTEX_FILE)
