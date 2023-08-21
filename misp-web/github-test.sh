#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

echo "Waiting 15 minutes for initial startup to finish..."
sleep 900

for i in $(seq 1 120)
do
    echo "$i/120: Testing if MISP is up..."
    if curl -fkq https://127.0.0.1/users/login ; then
        echo "$i/120: MISP is up, test completed successfully."
        exit 
    else
        if [ "$i" -eq 120 ]; then
            echo "$i/120: MISP isn't up after 25 minutes, test failed."
            exit 1
        else
            echo "$i/120: MISP isn't up yet, waiting 5 seconds..."
            sleep 5
        fi
    fi
done
