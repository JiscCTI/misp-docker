#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser
from json import loads
from os import chdir
from os.path import abspath, dirname, exists, join
from re import finditer
from secrets import choice
from shutil import copy, rmtree
from socket import getfqdn
from string import ascii_letters, digits
from subprocess import run
from urllib.request import urlopen

try:
    from dotenv import set_key
except ImportError:
    from sys import executable
    print("Failed to import dotenv. Install it using:")
    print('"{}" -m pip install --user python-dotenv'.format(executable))
    exit(1)


def GetLatestModulesVersion() -> str:
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    url = "https://api.github.com/repos/MISP/misp-modules/tags"
    releases = loads(urlopen(url).read())

    latest = {"major": 0, "minor": 0, "hotfix": 0}

    for release in releases:
        match = finditer(regex, release["name"])
        for version in match:
            if int(version["major"]) > latest["major"] and int(version["major"]) < 3:
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])
            elif (
                int(version["major"]) == latest["major"]
                and int(version["minor"]) > latest["minor"]
            ):
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])
            elif (
                int(version["major"]) == latest["major"]
                and int(version["minor"]) == latest["minor"]
                and int(version["hotfix"]) > latest["hotfix"]
            ):
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])
    return "v{}.{}.{}".format(latest["major"], latest["minor"], latest["hotfix"])


def GetLatestWebVersion() -> str:
    regex = r"v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<hotfix>\d+)"
    url = "https://api.github.com/repos/MISP/MISP/releases"
    releases = loads(urlopen(url).read())

    latest = {"major": 0, "minor": 0, "hotfix": 0}

    for release in releases:
        match = finditer(regex, release["tag_name"])
        for version in match:
            if int(version["major"]) > latest["major"] and int(version["major"]) < 3:
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])
            elif (
                int(version["major"]) == latest["major"]
                and int(version["minor"]) > latest["minor"]
            ):
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])
            elif (
                int(version["major"]) == latest["major"]
                and int(version["minor"]) == latest["minor"]
                and int(version["hotfix"]) > latest["hotfix"]
            ):
                latest["major"] = int(version["major"])
                latest["minor"] = int(version["minor"])
                latest["hotfix"] = int(version["hotfix"])

    return "v{}.{}.{}".format(latest["major"], latest["minor"], latest["hotfix"])


def GeneratePassword() -> str:
    alphabet = ascii_letters + digits
    return "".join(choice(alphabet) for i in range(32))


Parser = ArgumentParser(
    "MISP Quickstart", description="Quickstart script for MISP containers"
)
Parser.add_argument("--ha", action="store_true")
Args = Parser.parse_args()

Base = dirname(abspath(__file__))
chdir(Base)
DotEnv = join(Base, ".env")
PersistentStorage = join(Base, "persistent")

run(["docker", "compose", "down", "--remove-orphans"])

if not exists(DotEnv):
    print("Creating best guess .env file...")
    copy(join(Base, "example.env"), DotEnv)
    set_key(DotEnv, "FQDN", getfqdn())
    set_key(DotEnv, "MISP_EMAIL_ADDRESS", "misp@{}".format(getfqdn()))
    set_key(DotEnv, "GPG_PASSPHRASE", GeneratePassword())
    set_key(DotEnv, "MYSQL_PASSWORD", GeneratePassword())
    set_key(DotEnv, "MYSQL_ROOT_PASSWORD", GeneratePassword())
    set_key(DotEnv, "REDIS_PASSWORD", GeneratePassword())
    set_key(DotEnv, "WORKERS_PASSWORD", GeneratePassword())

if exists(PersistentStorage):
    print("Deleting old persistent storage...")
    try:
        rmtree(PersistentStorage)
    except:
        print(
            'Failed to delete persistent storage. Delete "{}" manually, then run this script again.'.format(
                PersistentStorage
            )
        )

print("Pulling external images...")
run(["docker", "pull", "clamav/clamav:1.0_base"]).check_returncode()
run(["docker", "pull", "redis:7"]).check_returncode()
run(["docker", "pull", "mysql/mysql-server:8.0"]).check_returncode()

print("Building MISP Modules image...")
chdir(join(Base, "misp-modules"))
ModulesVersion = GetLatestModulesVersion()
run(
    [
        "docker",
        "build",
        "--pull",
        "--tag",
        "jisccti/misp-modules:latest",
        "--tag",
        "jisccti/misp-modules:{}".format(ModulesVersion),
        "--build-arg",
        'MISP_VERSION={}'.format(ModulesVersion),
        ".",
    ]
).check_returncode()

print("Building MISP Web image...")
chdir(join(Base, "misp-web"))
WebVersion = GetLatestWebVersion()
run(
    [
        "docker",
        "build",
        "--pull",
        "--tag",
        "jisccti/misp-web:latest",
        "--tag",
        "jisccti/misp-web:{}".format(WebVersion),
        "--build-arg",
        'MISP_VERSION={}'.format(WebVersion),
        ".",
    ]
).check_returncode()

print("Building MISP Workers image...")
chdir(join(Base, "misp-workers"))
run(
    [
        "docker",
        "build",
        "--tag",
        "jisccti/misp-workers:latest",
        "--tag",
        "jisccti/misp-workers:{}".format(WebVersion),
        "--build-arg",
        'MISP_VERSION={}'.format(WebVersion),
        ".",
    ]
).check_returncode()

print("Starting MISP...")
chdir(Base)
if Args.ha:
    run(
        ["docker", "compose", "-f", "docker-compose-ha.yml", "up", "-d"]
    ).check_returncode()
else:
    run(["docker", "compose", "up", "-d"]).check_returncode()
