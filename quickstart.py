#!/usr/bin/env python3

"""Quickly create a testing instance of MISP."""

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser
from os import chdir
from os.path import abspath, dirname, exists, join
from secrets import choice
from shutil import copy, rmtree
from socket import getfqdn
from string import ascii_letters, digits
from subprocess import run

try:
    from dotenv import set_key
except ImportError as e:
    print("Failed to import dotenv. Install it using:")
    print("python3 -m pip install --user python-dotenv")
    raise e

from lib.semver import (
    get_latest_from_github_releases,
    get_latest_from_github_tags,
)


def generate_password() -> str:
    """Generate a 32 character alphanumeric password

    Returns:
        str: The generated password
    """

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
PersistentStorage = join(Base, "persistent", "misp")

run(["/usr/bin/docker", "compose", "down", "--remove-orphans"], check=False)

if not exists(DotEnv):
    print("Creating best guess .env file...")
    copy(join(Base, "example.env"), DotEnv)
    set_key(DotEnv, "FQDN", getfqdn())
    set_key(DotEnv, "MISP_EMAIL_ADDRESS", f"misp@{getfqdn()}")
    set_key(DotEnv, "GPG_PASSPHRASE", generate_password())
    set_key(DotEnv, "MYSQL_PASSWORD", generate_password())
    set_key(DotEnv, "MYSQL_ROOT_PASSWORD", generate_password())
    set_key(DotEnv, "REDIS_PASSWORD", generate_password())
    set_key(DotEnv, "WORKERS_PASSWORD", generate_password())

if exists(PersistentStorage):
    print("Deleting old persistent storage...")
    try:
        rmtree(join(PersistentStorage, "db"))
    except OSError as e:
        print(
            f"Failed to delete persistent storage. Delete {join(PersistentStorage, 'db')} "
            "manually, then run this script again."
        )
        raise e
    try:
        rmtree(join(PersistentStorage, "data"))
    except OSError as e:
        print(
            f"Failed to delete persistent storage. Delete {join(PersistentStorage, 'data')} "
            "manually, then run this script again."
        )
        raise e

print("Pulling external images...")
run(["/usr/bin/docker", "pull", "clamav/clamav:1.0_base"], check=True)
run(["/usr/bin/docker", "pull", "redis:7"], check=True)
run(["/usr/bin/docker", "pull", "mysql/mysql-server:8.0"], check=True)

print("Building MISP Modules image...")
chdir(join(Base, "misp-modules"))
MODULES_VERSION = get_latest_from_github_tags(
    repository="MISP/misp-modules", max_major=2
)
run(
    [
        "/usr/bin/docker",
        "build",
        "--pull",
        "--tag",
        "jisccti/misp-modules:latest",
        "--tag",
        f"jisccti/misp-modules:{MODULES_VERSION}",
        "--build-arg",
        f"MISP_VERSION={MODULES_VERSION}",
        ".",
    ],
    check=True,
)

print("Building MISP Web image...")
chdir(join(Base, "misp-web"))
WEB_VERSION = get_latest_from_github_releases(repository="MISP/MISP", max_major=2)
run(
    [
        "/usr/bin/docker",
        "build",
        "--pull",
        "--tag",
        "jisccti/misp-web:latest",
        "--tag",
        f"jisccti/misp-web:{WEB_VERSION}",
        "--build-arg",
        f"MISP_VERSION={WEB_VERSION}",
        ".",
    ],
    check=True,
)

print("Building MISP Workers image...")
chdir(join(Base, "misp-workers"))
run(
    [
        "/usr/bin/docker",
        "build",
        "--tag",
        "jisccti/misp-workers:latest",
        "--tag",
        f"jisccti/misp-workers:{WEB_VERSION}",
        "--build-arg",
        f"MISP_VERSION={WEB_VERSION}",
        ".",
    ],
    check=True,
)

print("Starting MISP...")
chdir(Base)
if Args.ha:
    run(
        ["/usr/bin/docker", "compose", "-f", "docker-compose-ha.yml", "up", "-d"],
        check=True,
    )
else:
    run(["/usr/bin/docker", "compose", "up", "-d"], check=True)
