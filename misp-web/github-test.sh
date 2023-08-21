#/usr/bin/env bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

for i in {1..300}
do
    if curl -fk https://127.0.0.1/users/login; then
        exit 
    else
        sleep 3
    fi
done

