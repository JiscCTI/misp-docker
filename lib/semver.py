#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

"""Parse Semantic Versioning version numbers"""

from gzip import open as gzip_open
from io import BytesIO
from json import loads
from re import finditer
from typing import Dict, List

from defusedxml import ElementTree

try:
    from requests import get
    from requests.exceptions import RequestException
except ImportError as e:
    print("Failed to import requests. Install it using:")
    print("python3 -m pip install --user requests")
    raise e


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2024, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "2.1.0"


def get_highest_version(
    versions: List[dict], max_major: int = -1, max_minor: int = -1, max_hotfix: int = -1
) -> Dict[str, int]:
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
        Dict[str, int]: The highest version number in the list
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
            and (max_hotfix == -1 or int(version["hotfix"]) <= max_hotfix)
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
        max_major (int, optional): The highest allowed major version. Defaults to -1.
        max_minor (int, optional): The highest allowed minor version. Defaults to -1.
        max_hotfix (int, optional): The highest allowed hotfix version. Defaults to -1.

    Returns:
        str: The latest release available in the repository.
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
        max_major (int, optional): The highest allowed major version. Defaults to -1.
        max_minor (int, optional): The highest allowed minor version. Defaults to -1.
        max_hotfix (int, optional): The highest allowed hotfix version. Defaults to -1.

    Returns:
        str: The latest tag set in the repository.
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


def get_latest_from_rpm_repo(
    mirror_list_url: str,
    package_name: str,
    package_arch: str = "x86_64",
    max_major: int = -1,
    max_minor: int = -1,
    max_hotfix: int = -1,
) -> str:
    """Get the latest available version of an RPM from a dnf/yum repository.

    Args:
        mirror_list_url (str): The URL to download the mirror list from.
        package_name (str): The name of the package to check.
        package_arch (str, optional): The package architecture to check. Defaults to "x86_64".
        max_major (int, optional): The highest allowed major version. Defaults to -1.
        max_minor (int, optional): The highest allowed minor version. Defaults to -1.
        max_hotfix (int, optional): The highest allowed hotfix version. Defaults to -1.

    Returns:
        str: The latest rpm available in the repository.
    """
    versions: List[Dict[str, int]] = []

    mirror_urls: List[str] = (
        get(mirror_list_url, timeout=5).content.decode("utf-8").split("\n")
    )

    for mirror in mirror_urls:
        try:
            repo_metadata = ElementTree.fromstring(
                get(f"{mirror}repodata/repomd.xml", timeout=5).content.decode("utf-8")
            )
            for metadata in repo_metadata:
                if "type" in metadata.attrib and metadata.attrib["type"] == "primary":
                    for option in metadata:
                        if "href" in option.attrib:
                            repo = ElementTree.parse(
                                gzip_open(
                                    BytesIO(
                                        get(
                                            f"{mirror}{option.attrib['href']}",
                                            timeout=5,
                                        ).content
                                    )
                                )
                            ).getroot()
                            for rpm in repo:
                                if "type" in rpm.attrib and rpm.attrib["type"] == "rpm":
                                    package = rpm.findtext(
                                        ".//ns0:name",
                                        namespaces={
                                            "ns0": "http://linux.duke.edu/metadata/common"
                                        },
                                    )
                                    arch = rpm.findtext(
                                        ".//ns0:arch",
                                        namespaces={
                                            "ns0": "http://linux.duke.edu/metadata/common"
                                        },
                                    )
                                    if package == package_name and arch == package_arch:
                                        version = (
                                            rpm.find(
                                                ".//ns0:version",
                                                namespaces={
                                                    "ns0": "http://linux.duke.edu/metadata/common"
                                                },
                                            )
                                            .get("ver")
                                            .split(".")
                                        )
                                        semver: Dict[str, int] = {
                                            "major": int(version[0]),
                                            "minor": int(version[1]),
                                            "hotfix": int(version[2]),
                                        }
                                        versions.append(semver)
            break
        except RequestException:
            pass

    latest = get_highest_version(versions, max_major, max_minor, max_hotfix)
    return f'{latest["major"]}.{latest["minor"]}.{latest["hotfix"]}'
