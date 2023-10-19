#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

"""Parse Semantic Versioning version numbers"""

from json import loads
from re import finditer
from typing import List

try:
    from requests import get
except ImportError:
    from sys import executable

    print("Failed to import requests. Install it using:")
    print('"{}" -m pip install --user requests'.format(executable))
    exit(1)


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


def GetHighestVersion(
    Versions: List[dict], MaxMajor: int = -1, MaxMinor: int = -1, MaxHotfix: int = -1
) -> dict:
    """Identify and return the highest Semantic Version in a list of versions

    Args:
        Versions (List[dict]): List of candidate version numbers
        MaxMajor (int, optional): The highest acceptable major version, -1 for no maximum. Defaults to -1.
        MaxMinor (int, optional): The highest acceptable minor version, -1 for no maximum. Defaults to -1.
        MaxHotfix (int, optional): The highest acceptable hotfix version, -1 for no maximum. Defaults to -1.

    Returns:
        dict: The highest version number in the list
    """

    latest = {"major": 0, "minor": 0, "hotfix": 0}
    for version in Versions:
        if int(version["major"]) > latest["major"] and (
            MaxMajor == -1 or int(version["major"]) <= MaxMajor
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif (
            int(version["major"]) == latest["major"]
            and int(version["minor"]) > latest["minor"]
            and (MaxMinor == -1 or int(version["minor"]) <= MaxMinor)
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif (
            int(version["major"]) == latest["major"]
            and int(version["minor"]) == latest["minor"]
            and int(version["hotfix"]) > latest["hotfix"]
            and (MaxHotfix == -1 or int(version["hotfix"]) <= MaxHotfix)
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
    return latest


def GetLatestVersionFromGitHubReleases(
    Repository: str, MaxMajor: int = -1, MaxMinor: int = -1, MaxHotfix: int = -1
) -> str:
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    Versions = []
    releases = loads(
        get("https://api.github.com/repos/{}/releases".format(Repository)).content
    )
    for release in releases:
        matches = finditer(regex, release["tag_name"])
        for version in matches:
            Versions.append(version)
    latest = GetHighestVersion(Versions, MaxMajor, MaxMinor, MaxHotfix)
    return "v{}.{}.{}".format(latest["major"], latest["minor"], latest["hotfix"])


def GetLatestVersionFromGitHubTags(
    Repository: str, MaxMajor: int = -1, MaxMinor: int = -1, MaxHotfix: int = -1
) -> str:
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    Versions = []
    tags = loads(get("https://api.github.com/repos/{}/tags".format(Repository)).content)
    for tag in tags:
        matches = finditer(regex, tag["name"])
        for version in matches:
            Versions.append(version)
    latest = GetHighestVersion(Versions, MaxMajor, MaxMinor, MaxHotfix)
    return "v{}.{}.{}".format(latest["major"], latest["minor"], latest["hotfix"])
