#/usr/bin/env bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

for i in {1..300}
do
    if curl -fk https://127.0.0.1/users/login ; then
        echo "$i/300: MISP is up"
        exit 
    else
        echo "$i/300: MISP isn't up yet, waitng 3 seconds..."
        sleep 3
    fi
done
exit 1
