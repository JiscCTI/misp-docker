#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

restore_persistence() {
    echo "Restoring persistent file storage..."
    cd /var/www/ || exit 1

    if [ ! -L MISP/app/Config ]; then
        echo "Persisting config..."
        rm -rf MISP/app/Config
        ln -s /var/www/MISPData/config/ /var/www/MISP/app/Config
    else
        echo "Config already persistent."
    fi

    if [ ! -L MISP/app/files ]; then
        echo "Persisting app files..."
        rm -rf MISP/app/files
        ln -s /var/www/MISPData/files/ /var/www/MISP/app/files
    else
        echo "App files already persistent."
    fi

    if [ ! -L MISP/app/tmp ]; then
        echo "Persisting temp files..."
        rm -rf MISP/app/tmp
        ln -s /var/www/MISPData/tmp/ /var/www/MISP/app/tmp
    else
        echo "Temp files already persistent."
    fi

    if [ ! -L MISP/app/webroot/img/orgs ]; then
        echo "Persisting org icons..."
        rm -rf MISP/app/webroot/img/orgs
        ln -s /var/www/MISPData/icons/ /var/www/MISP/app/webroot/img/orgs
    else
        echo "Org icons already persistent."
    fi

    if [ ! -L MISP/app/webroot/img/custom ]; then
        echo "Persisting images..."
        rm -rf MISP/app/webroot/img/custom
        ln -s /var/www/MISPData/images/ /var/www/MISP/app/webroot/img/custom
    else
        echo "Images already persistent."
    fi

    echo "Persistent file storage restored."
}

if [ ! -f /var/www/MISPData/.configured ]; then
    echo "Waiting for misp_web to finish configuration..."
    while [ ! -f /var/www/MISPData/.configured ]; do
        sleep 5
    done
fi

restore_persistence
mkdir -p /var/www/MISPData/tmp/logs
WORKERS_PASSWORD="${WORKERS_PASSWORD:-misp}"
SED_WORKERS_PASSWORD=${WORKERS_PASSWORD//\//\\\/}
sed -i "s/^\(password\)=.*/\1=${SED_WORKERS_PASSWORD}/" /etc/supervisor/conf.d/misp-workers.conf

echo "Starting MISP Workers..."
supervisord -c /etc/supervisor/conf.d/misp-workers.conf
