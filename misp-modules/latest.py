#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from json import loads
from urllib.request import urlopen
from re import finditer


regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
url = "https://api.github.com/repos/MISP/misp-modules/tags"
releases = loads(urlopen(url).read())

latest = {
    "major": 0,
    "minor": 0,
    "hotfix": 0
}

for release in releases:
    match = finditer(regex, release['name'])
    for version in match:
        if int(version['major']) > latest['major'] and int(version['major']) < 3:
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif int(version["major"]) == latest["major"] and int(version["minor"]) > latest["minor"]:
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])
        elif int(version["major"]) == latest["major"] and int(version["minor"]) == latest["minor"] and int(version["hotfix"]) > latest["hotfix"]:
            latest["major"] = int(version["major"])
            latest["minor"] = int(version["minor"])
            latest["hotfix"] = int(version["hotfix"])

print("v{}.{}.{}".format(latest["major"], latest["minor"], latest["hotfix"]))
