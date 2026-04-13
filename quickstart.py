#!/usr/bin/env python3

"""Quickly create a testing instance of MISP."""

# SPDX-FileCopyrightText: 2023-2026 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

from argparse import ArgumentParser
from os import chdir, getenv
from os.path import abspath, dirname, exists, join
from getpass import getpass
from platform import system
from secrets import choice
from shutil import rmtree
from socket import getfqdn
from string import ascii_letters, digits
from subprocess import run
from time import sleep

try:
    from dotenv import set_key
    from get_latest_version.github import (
        get_latest_version_from_releases,
        get_latest_version_from_tags,
    )
    from get_latest_version.rpm import get_latest_from_rpm_repo
except ImportError as e:
    print("Failed to import third-party modules. Install them using:")
    print("  python3 -m venv .venv")
    print("  . .venv/bin/activate")
    print("  pip install --upgrade -r requirements.txt")
    print()
    raise e


__author__ = "Joe Pitt"
__copyright__ = "Copyright 2023-2026, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "2.0.0"

PROJECT_DIRECTORY = dirname(abspath(__file__))
ENV_FILE = join(PROJECT_DIRECTORY, ".env")
SHIBB_ENV_FILE = join(PROJECT_DIRECTORY, "shibb.env")
PERSISTENT_DIRECTORY = join(PROJECT_DIRECTORY, "persistent", "misp")

GITHUB_TOKEN = getenv("GITHUB_TOKEN")


def best_guess_env():
    """Generate a best guess .env file for testing purposes."""

    print("Creating best guess .env file...")
    set_key(ENV_FILE, "FQDN", getfqdn())
    set_key(ENV_FILE, "MISP_EMAIL_ADDRESS", f"misp@{getfqdn()}")
    set_key(ENV_FILE, "GPG_PASSPHRASE", generate_password())
    set_key(ENV_FILE, "MYSQL_PASSWORD", generate_password())
    set_key(ENV_FILE, "MYSQL_ROOT_PASSWORD", generate_password())
    set_key(ENV_FILE, "REDIS_PASSWORD", generate_password())
    set_key(ENV_FILE, "SMTP_PASSWORD", generate_password())
    set_key(ENV_FILE, "WORKERS_PASSWORD", generate_password())


def build_core_images():
    """Build the core MISP docker images"""

    print("Building MISP Modules image...")
    chdir(join(PROJECT_DIRECTORY, "misp-modules"))
    misp_modules_version = get_latest_version_from_tags(
        GITHUB_TOKEN,
        "MISP",
        "misp-modules",
        greater_equal_version="3.0.0",
        less_than_version="4.0.0",
    )
    run(
        [
            "/usr/bin/docker",
            "build",
            "--pull",
            "--tag",
            "jisccti/misp-modules:latest",
            "--tag",
            f"jisccti/misp-modules:{misp_modules_version}",
            "--build-arg",
            f"MISP_VERSION={misp_modules_version}",
            ".",
        ],
        check=True,
    )

    print("Building MISP Web image...")
    chdir(join(PROJECT_DIRECTORY, "misp-web"))
    misp_version = get_latest_version_from_releases(
        GITHUB_TOKEN,
        "MISP",
        "MISP",
        greater_equal_version="2.5.0",
        less_than_version="2.6.0",
    )
    run(
        [
            "/usr/bin/docker",
            "build",
            "--pull",
            "--tag",
            "jisccti/misp-web:latest",
            "--tag",
            f"jisccti/misp-web:{misp_version}",
            "--build-arg",
            f"MISP_VERSION={misp_version}",
            ".",
        ],
        check=True,
    )

    print("Building MISP Workers image...")
    chdir(join(PROJECT_DIRECTORY, "misp-workers"))
    run(
        [
            "/usr/bin/docker",
            "build",
            "--tag",
            "jisccti/misp-workers:latest",
            "--tag",
            f"jisccti/misp-workers:{misp_version}",
            "--build-arg",
            f"MISP_VERSION={misp_version}",
            ".",
        ],
        check=True,
    )


def build_shibb_image():
    """Build the Shibboleth service provider image"""

    print("Building MISP Shibboleth image...")
    shibb_version = get_latest_from_rpm_repo(
        "https://shibboleth.net/cgi-bin/mirrorlist.cgi/rockylinux9", "shibboleth"
    )
    chdir(join(PROJECT_DIRECTORY, "misp-shibb-sp"))
    run(
        [
            "/usr/bin/docker",
            "build",
            "--tag",
            "jisccti/misp-shibb-sp:latest",
            "--tag",
            f"jisccti/misp-shibb-sp:{shibb_version}",
            "--build-arg",
            f"SHIBB_VERSION={shibb_version}",
            ".",
        ],
        check=True,
    )


def clear_persistent_data():
    """Delete persistent data to create a clean install"""

    if exists(join(PERSISTENT_DIRECTORY, "db")):
        print("Deleting old persistent storage...")
        try:
            rmtree(join(PERSISTENT_DIRECTORY, "db"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(PERSISTENT_DIRECTORY, 'db')} manually, then run this script again."
            )
            raise e
    if exists(join(PERSISTENT_DIRECTORY, "data")):
        try:
            rmtree(join(PERSISTENT_DIRECTORY, "data"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(PERSISTENT_DIRECTORY, 'data')} manually, "
                "then run this script again."
            )
            raise e
    if exists(join(PERSISTENT_DIRECTORY, "shibb", "run")):
        try:
            rmtree(join(PERSISTENT_DIRECTORY, "shibb", "run"))
        except OSError as e:
            print(
                "Failed to delete persistent storage. Delete "
                f"{join(PERSISTENT_DIRECTORY, 'shibb', 'run')} manually, "
                "then run this script again."
            )
            raise e


def generate_password() -> str:
    """Generate a 32 character alphanumeric password

    Returns:
        str: The generated password
    """

    alphabet = ascii_letters + digits
    return "".join(choice(alphabet) for i in range(32))


def pull_images():
    """Pull images for dependencies"""

    print("Pulling external images...")
    run(["/usr/bin/docker", "pull", "clamav/clamav:1.0_base"], check=True)
    run(["/usr/bin/docker", "pull", "redis:8"], check=True)
    run(["/usr/bin/docker", "pull", "mysql/mysql-server:8.0"], check=True)


if __name__ == "__main__":
    print("############################")
    print("# FOR DEVELOPMENT USE ONLY #")
    print("############################")
    print()
    print("For production use see: https://jisccti.github.io/misp-docker/")
    print()

    if system() != "Linux":
        print("This script only works on Linux systems")
        raise OSError("Unsupported OS")

    # sleep for two seconds to ensure above disclaimer is seen
    sleep(2)

    argument_parser = ArgumentParser(
        "MISP Quickstart", description="Quickstart script for MISP containers"
    )
    run_modes = argument_parser.add_mutually_exclusive_group()
    run_modes.add_argument(
        "--ha", action="store_true", help="High availability simulation"
    )
    run_modes.add_argument(
        "--shibb", action="store_true", help="Shibboleth authentication mode"
    )
    run_mode = argument_parser.parse_args()

    if GITHUB_TOKEN is None:
        print("GITHUB_TOKEN environment variable not set")
        print(
            "Create a Public Repositories key at "
            "https://github.com/settings/personal-access-tokens/new"
        )
        GITHUB_TOKEN = getpass("Enter GitHub key: ")

    chdir(PROJECT_DIRECTORY)
    run(["/usr/bin/docker", "compose", "down", "--remove-orphans"], check=False)

    if not exists(ENV_FILE):
        best_guess_env()

    if exists(PERSISTENT_DIRECTORY):
        clear_persistent_data()

    pull_images()

    build_core_images()

    if run_mode.shibb:
        build_shibb_image()

    print("Starting MISP...")
    chdir(PROJECT_DIRECTORY)
    if run_mode.ha:
        set_key(ENV_FILE, "AUTH_METHOD", "misp")
        run(
            ["/usr/bin/docker", "compose", "-f", "docker-compose-ha.yml", "up", "-d"],
            check=True,
        )
    elif run_mode.shibb:
        if not exists(SHIBB_ENV_FILE):
            print(
                "You must create shibb.env before running quickstart, "
                "see https://jisccti.github.io/misp-docker/configuration/shibb/"
            )
            raise FileNotFoundError("shibb.env")
        set_key(ENV_FILE, "AUTH_METHOD", "shibb")
        run(
            [
                "/usr/bin/docker",
                "compose",
                "-f",
                "docker-compose-shibb.yml",
                "up",
                "-d",
            ],
            check=True,
        )
    else:
        set_key(ENV_FILE, "AUTH_METHOD", "misp")
        run(["/usr/bin/docker", "compose", "up", "-d"], check=True)
