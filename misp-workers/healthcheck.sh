#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

DETAIL=$(supervisorctl status)
RESULT=$?
echo $RESULT

if [[ "$RESULT" == "0" ]]; then
    exit 0
elif [[ "$DETAIL" == *"FATAL"* ]]; then
    kill "$(cat /var/run/supervisord.pid)"
    exit 1
else
    exit 1
fi
