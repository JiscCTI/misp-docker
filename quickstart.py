#!/usr/bin/env python3

"""Quickly create a testing instance of MISP."""

# SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser
from os import chdir
from os.path import abspath, dirname, exists, join
from secrets import choice
from shutil import rmtree
from socket import getfqdn
from string import ascii_letters, digits
from subprocess import run

try:
    from dotenv import set_key
except ImportError as e:
    print("Failed to import dotenv. Install it using:")
    print("pip install python-dotenv~=1.2.1")
    raise e
try:
    from get_latest_version.github import (
        get_latest_version_from_releases,
        get_latest_version_from_tags,
    )
    from get_latest_version.rpm import get_latest_from_rpm_repo
except ImportError as e:
    print("Failed to import dotenv. Install it using:")
    print("pip install get_latest_version~=2.0.0")
    raise e
try:
    from semver import Version
except ImportError as e:
    print("Failed to import semver. Install it using:")
    print("pip install semver~=3.0.4")
    raise e

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2025, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.2"


def generate_password() -> str:
    """Generate a 32 character alphanumeric password

    Returns:
        str: The generated password
    """

    alphabet = ascii_letters + digits
    return "".join(choice(alphabet) for i in range(32))


argument_parser = ArgumentParser(
    "MISP Quickstart", description="Quickstart script for MISP containers"
)
argument_parser.add_argument(
    "-g",
    "--github-token",
    required=True,
    help="GitHub Token with public repo and packages read rights",
)
run_modes = argument_parser.add_mutually_exclusive_group()
run_modes.add_argument("--ha", action="store_true", help="High availability simulation")
run_modes.add_argument(
    "--shibb", action="store_true", help="Shibboleth authentication mode"
)
args = argument_parser.parse_args()

home_directory = dirname(abspath(__file__))
chdir(home_directory)
dot_env_file = join(home_directory, ".env")
persistent_storage_directory = join(home_directory, "persistent", "misp")

run(["/usr/bin/docker", "compose", "down", "--remove-orphans"], check=False)

if not exists(dot_env_file):
    print("Creating best guess .env file...")
    set_key(dot_env_file, "FQDN", getfqdn())
    set_key(dot_env_file, "MISP_EMAIL_ADDRESS", f"misp@{getfqdn()}")
    set_key(dot_env_file, "GPG_PASSPHRASE", generate_password())
    set_key(dot_env_file, "MYSQL_PASSWORD", generate_password())
    set_key(dot_env_file, "MYSQL_ROOT_PASSWORD", generate_password())
    set_key(dot_env_file, "REDIS_PASSWORD", generate_password())
    set_key(dot_env_file, "WORKERS_PASSWORD", generate_password())

if exists(persistent_storage_directory):
    if exists(join(persistent_storage_directory, "db")):
        print("Deleting old persistent storage...")
        try:
            rmtree(join(persistent_storage_directory, "db"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(persistent_storage_directory, 'db')} manually, then run this script again."
            )
            raise e
    if exists(join(persistent_storage_directory, "data")):
        try:
            rmtree(join(persistent_storage_directory, "data"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(persistent_storage_directory, 'data')} manually, "
                "then run this script again."
            )
            raise e
    if exists(join(persistent_storage_directory, "shibb", "run")):
        try:
            rmtree(join(persistent_storage_directory, "shibb", "run"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(persistent_storage_directory, 'shibb', 'run')} manually, "
                "then run this script again."
            )
            raise e

print("Pulling external images...")
run(["/usr/bin/docker", "pull", "clamav/clamav:1.0_base"], check=True)
run(["/usr/bin/docker", "pull", "redis:8"], check=True)
run(["/usr/bin/docker", "pull", "mysql/mysql-server:8.0"], check=True)

print("Building MISP Modules image...")
chdir(join(home_directory, "misp-modules"))
MODULES_VERSION = get_latest_version_from_tags(
    args.github_token, "MISP", "MISP-Modules", less_than_version=Version(4)
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
chdir(join(home_directory, "misp-web"))
WEB_VERSION = get_latest_version_from_releases(
    args.github_token, "MISP", "MISP", less_than_version=Version(2, 6)
)
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
chdir(join(home_directory, "misp-workers"))
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

if args.shibb:
    print("Building MISP Shibboleth image...")
    SHIBB_VERSION = get_latest_from_rpm_repo(
        mirror_list_url="https://shibboleth.net/cgi-bin/mirrorlist.cgi/rockylinux9",
        package_name="shibboleth",
        less_than_version=Version(4),
    )
    chdir(join(home_directory, "misp-shibb-sp"))
    run(
        [
            "/usr/bin/docker",
            "build",
            "--tag",
            "jisccti/misp-shibb-sp:latest",
            "--tag",
            f"jisccti/misp-shibb-sp:{SHIBB_VERSION}",
            "--build-arg",
            f"SHIBB_VERSION={SHIBB_VERSION}",
            ".",
        ],
        check=True,
    )

print("Starting MISP...")
chdir(home_directory)
if args.ha:
    run(
        ["/usr/bin/docker", "compose", "-f", "docker-compose-ha.yml", "up", "-d"],
        check=True,
    )
elif args.shibb:
    run(
        ["/usr/bin/docker", "compose", "-f", "docker-compose-shibb.yml", "up", "-d"],
        check=True,
    )
else:
    run(["/usr/bin/docker", "compose", "up", "-d"], check=True)
