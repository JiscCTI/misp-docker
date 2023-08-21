#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

echo "Waiting 15 minutes for initial startup to finish..."
sleep 900

for i in $(seq 1 90)
do
    echo "$i/90: Testing if MISP is up..."
    if curl -fk https://misp_web/users/login ; then
        echo "$i/90: MISP is up, test completed successfully."
        exit 
    else
        if [ "$i" -eq 1200 ]; then
            echo "$i/90: MISP isn't up after 45 minutes, test failed."
            exit 1
        else
            echo "$i/90: MISP isn't up yet, waiting 30 seconds..."
            sleep 30
        fi
    fi
done
