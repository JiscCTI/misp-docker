#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

"""Get the latest version of the MISP"""

from os.path import dirname, join
from sys import path


try:
    path.insert(0, join(dirname(__file__), "..", "lib"))
    from semver import get_latest_from_github_releases
except (OSError, ImportError) as e:
    raise ImportError("Failed to load semver") from e


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.1"


print(get_latest_from_github_releases("MISP/MISP", 2))
