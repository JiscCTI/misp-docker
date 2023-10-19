#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

"""Get the latest version of the MISP-Modules"""

from os.path import dirname, join
from sys import path

try:
    path.insert(0, join(dirname(__file__), "..", "lib"))
    from semver import GetLatestVersionFromGitHubTags
except (OSError, ImportError):
    raise ImportError("Failed to load semver")


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"

print(GetLatestVersionFromGitHubTags(Repository="MISP/misp-modules", MaxMajor=2))
