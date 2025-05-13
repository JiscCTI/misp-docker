#!/usr/bin/env python3

"""Generate a 30 digit cipher seed for MISP"""

# SPDX-FileCopyrightText: 2025 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

import secrets

__author__ = "Joe Pitt"
__copyright__ = "Copyright 2025, Jisc Services Limited"
__email__ = "Joe.Pitt@jisc.ac.uk"
__license__ = "GPL-3.0-only"
__maintainer__ = "Joe Pitt"
__status__ = "Production"
__version__ = "1.0.0"

def main():
    """Main Function"""
    cipher_seed = ""
    for _i in range(30):
        cipher_seed = cipher_seed + secrets.choice(
            ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        )
    print(cipher_seed)


if __name__ == "__main__":
    main()
