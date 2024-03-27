#!/usr/bin/env python3

"""Reusable Logger creator giving syslog-style output to a self rotating log file"""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from logging import DEBUG, Formatter, getLogger, INFO, Logger, StreamHandler
from logging.handlers import RotatingFileHandler
from socket import gethostname


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.1"


def CreateLogger(
    App: str,
    Hostname: str = gethostname(),
    LogDirectory: str = "/var/log",
    Debug: bool = False,
    Stderr: bool = False,
) -> Logger:
    """Initialise a Logger using syslog formatting into a self-rotating file

    Args:
        App (str): The name of the app the logger is for
        Hostname (str, optional): The hostname to show in log entries. Defaults to gethostname().
        LogDirectory (str, optional): The directory to store the log file. Defaults to "/var/log".
        Debug (bool, optional): Whether to write debug logging to file. Defaults to False.
        Stderr (bool, optional): Whether to write logging to stderr. Defaults to False.

    Returns:
        Logger: A configured Logger object
    """

    logger = getLogger(App)
    logger.propagate = False
    if Debug:
        logger.setLevel(DEBUG)
    else:
        logger.setLevel(INFO)

    LogPath = "{}/{}.log".format(LogDirectory, App)

    LogFormatter = Formatter(
        "%(asctime)s {} %(name)s[%(process)d]: [%(levelname)s] %(message)s".format(
            Hostname
        ),
        "%b %d %H:%M:%S",
    )

    # Prevent the log from growing beyond 20MB
    LogHandler = RotatingFileHandler(LogPath, maxBytes=20000000, backupCount=1)
    LogHandler.setFormatter(LogFormatter)
    logger.addHandler(LogHandler)

    if Stderr:
        # defaults to stderr
        StderrHandler = StreamHandler()
        StderrHandler.setFormatter(LogFormatter)
        logger.addHandler(StderrHandler)

    return logger
