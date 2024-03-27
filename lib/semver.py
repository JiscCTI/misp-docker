#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

"""Parse Semantic Versioning version numbers"""

from json import loads
from re import finditer
from sys import exit as sys_exit
from typing import List

try:
    from requests import get
except ImportError:
    print("Failed to import requests. Install it using:")
    print("python3 -m pip install --user requests")
    sys_exit(1)


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"


def get_highest_version(
    versions: List[dict], max_major: int = -1, max_minor: int = -1, mat_hotfix: int = -1
) -> dict:
    """Identify and return the highest Semantic Version in a list of versions

    Args:
        versions (List[dict]): List of candidate version numbers
        max_major (int, optional): The highest acceptable major version, -1 for no maximum.
            Defaults to -1.
        max_minor (int, optional): The highest acceptable minor version, -1 for no maximum.
            Defaults to -1.
        max_hotfix (int, optional): The highest acceptable hotfix version, -1 for no maximum.
            Defaults to -1.

    Returns:
        dict: The highest version number in the list
    """

    latest = {"major": 0, "minor": 0, "hotfix": 0}
    for version in versions:
        if int(version["major"]) > latest["major"] and (
            max_major == -1 or int(version["major"]) <= max_major
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif (
            int(version["major"]) == latest["major"]
            and int(version["minor"]) > latest["minor"]
            and (max_minor == -1 or int(version["minor"]) <= max_minor)
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif (
            int(version["major"]) == latest["major"]
            and int(version["minor"]) == latest["minor"]
            and int(version["hotfix"]) > latest["hotfix"]
            and (mat_hotfix == -1 or int(version["hotfix"]) <= mat_hotfix)
        ):
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
    return latest


def get_latest_from_github_releases(
    repository: str, max_major: int = -1, max_minor: int = -1, max_hotfix: int = -1
) -> str:
    """Gets the latest semver from the releases on a GitHub repository.

    Args:
        repository (str): The GitHub repository to check.
        max_major (int, optional): The maximum major version to allow. Defaults to -1.
        max_minor (int, optional): The maximum minor version to allow. Defaults to -1.
        max_hotfix (int, optional): The maximum hotfix version to allow. Defaults to -1.

    Returns:
        str: The latest version available.
    """
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    versions = []
    releases = loads(
        get(f"https://api.github.com/repos/{repository}/releases", timeout=5).content
    )
    for release in releases:
        matches = finditer(regex, release["tag_name"])
        for version in matches:
            versions.append(version)
    latest = get_highest_version(versions, max_major, max_minor, max_hotfix)
    return f'v{latest["major"]}.{latest["minor"]}.{latest["hotfix"]}'


def get_latest_from_github_tags(
    repository: str, max_major: int = -1, max_minor: int = -1, max_hotfix: int = -1
) -> str:
    """Gets the latest semver from the tags on a GitHub repository.

    Args:
        repository (str): The GitHub repository to check.
        max_major (int, optional): The maximum major version to allow. Defaults to -1.
        max_minor (int, optional): The maximum minor version to allow. Defaults to -1.
        max_hotfix (int, optional): The maximum hotfix version to allow. Defaults to -1.

    Returns:
        str: The latest version available.
    """
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    versions = []
    tags = loads(
        get(f"https://api.github.com/repos/{repository}/tags", timeout=5).content
    )
    for tag in tags:
        matches = finditer(regex, tag["name"])
        for version in matches:
            versions.append(version)
    latest = get_highest_version(versions, max_major, max_minor, max_hotfix)
    return f'v{latest["major"]}.{latest["minor"]}.{latest["hotfix"]}'
