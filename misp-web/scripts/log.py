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
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "2.0.0"


def create_logger(
    app: str,
    hostname: str = gethostname(),
    log_directory: str = "/var/log",
    debug: bool = False,
    stderr: bool = False,
) -> Logger:
    """Initialise a Logger using syslog formatting into a self-rotating file

    Args:
        app (str): The name of the app the logger is for
        hostname (str, optional): The hostname to show in log entries. Defaults to gethostname().
        log_directory (str, optional): The directory to store the log file. Defaults to "/var/log".
        debug (bool, optional): Whether to write debug logging to file. Defaults to False.
        stderr (bool, optional): Whether to write logging to stderr. Defaults to False.

    Returns:
        Logger: A configured Logger object
    """

    logger = getLogger(app)
    logger.propagate = False
    if debug:
        logger.setLevel(DEBUG)
    else:
        logger.setLevel(INFO)

    log_file = f"{log_directory}/{app}.log"

    log_formatter = Formatter(
        f"%(asctime)s {hostname} %(name)s[%(process)d]: [%(levelname)s] %(message)s",
        "%b %d %H:%M:%S",
    )

    # Prevent the log from growing beyond 20MB
    log_handler = RotatingFileHandler(log_file, maxBytes=20000000, backupCount=1)
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)

    if stderr:
        # defaults to stderr
        stderr_handler = StreamHandler()
        stderr_handler.setFormatter(log_formatter)
        logger.addHandler(stderr_handler)

    return logger
