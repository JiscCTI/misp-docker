#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

restore_persistence() {
    echo "Restoring persistent file storage..."
    cd /var/www/
    set +e
    mkdir -p MISPData/config MISPData/icons MISPData/images MISPData/files MISPData/tmp

    if [ -d MISP/app/Config ]; then
        #mv MISP/app/Config/* MISPData/config/
        rm -rf MISP/app/Config
    fi
    if [ ! -L /var/www/MISP/app/Config ]; then
        ln -s /var/www/MISPData/config/ /var/www/MISP/app/Config
    fi

    if [ -d MISP/app/files ]; then
        #mv MISP/app/files/* MISPData/files/
        rm -rf MISP/app/files
    fi
    if [ ! -L /var/www/MISP/app/Config ]; then
        ln -s /var/www/MISPData/files/ /var/www/MISP/app/files
    fi

    if [ -d MISP/app/tmp ]; then
        #mv MISP/app/tmp/* MISPData/tmp/
        rm -rf MISP/app/tmp
    fi
    if [ ! -L /var/www/MISP/app/tmp ]; then
        ln -s /var/www/MISPData/tmp/ /var/www/MISP/app/tmp
    fi

    if [ -d MISP/app/webroot/img/orgs ]; then
        #mv MISP/app/webroot/img/orgs/* MISPData/icons/
        rm -rf MISP/app/webroot/img/orgs
    fi
    if [ ! -L /var/www/MISP/app/Config ]; then
        ln -s /var/www/MISPData/icons/ /var/www/MISP/app/webroot/img/orgs
    fi

    if [ -d MISP/app/webroot/img/custom ]; then
        #mv MISP/app/webroot/img/custom/* MISPData/images/
        rm -rf MISP/app/webroot/img/custom
    fi
    if [ ! -L /var/www/MISP/app/Config ]; then
        ln -s /var/www/MISPData/images/ /var/www/MISP/app/webroot/img/custom
    fi

    set -e
    echo "Persistent file storage created."
}


while [ ! -f /var/www/MISPData/.configured ]; do
    echo "Waiting 5 seconds for misp_web to finish configuration..."
    sleep 5
done

restore_persistence
mkdir -p /var/www/MISPData/tmp/logs
WORKERS_PASSWORD="${WORKERS_PASSWORD:-misp}"
SED_WORKERS_PASSWORD=${WORKERS_PASSWORD//\//\\\/}
sed -i "s/^\(password\)=.*/\1=${SED_WORKERS_PASSWORD}/" /etc/supervisor/conf.d/misp-workers.conf

echo "Starting MISP Workers..."
supervisord -c /etc/supervisor/conf.d/misp-workers.conf
