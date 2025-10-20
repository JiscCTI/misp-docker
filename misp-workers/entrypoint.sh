#!/bin/bash

# SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

apply_env_vars() {
    PHP_MEMORY_LIMIT=$((2+PHP_ADDITIONAL_MEMORY_LIMIT))
    sed -i "s/^\(memory_limit\).*/\1 = ${PHP_MEMORY_LIMIT}G/" /usr/local/etc/php/php.ini
    echo "PHP memory_limit set to ${PHP_MEMORY_LIMIT}G"
    SED_WORKERS_PASSWORD=${WORKERS_PASSWORD//\//\\\/}
    sed -i "s/^\(password\)=.*/\1=${SED_WORKERS_PASSWORD}/" /etc/supervisor/conf.d/misp-workers.conf
    echo "Supervisor password set to [REDACTED]"
}

load_env_vars() {
    export FQDN=${FQDN:-misp.local}
    export HTTPS_PORT=${HTTPS_PORT:-443}
    export PHP_ADDITIONAL_MEMORY_LIMIT=${PHP_ADDITIONAL_MEMORY_LIMIT:-0}
    export WORKERS_PASSWORD=${WORKERS_PASSWORD:-misp}
    if [ "$WORKERS_PASSWORD" == "misp" ]; then
        echo "The WORKERS_PASSWORD environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
}

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

load_env_vars
if [ ! -f /var/www/MISPData/.configured ]; then
    echo "Waiting for misp_web to finish configuration..."
    while [ ! -f /var/www/MISPData/.configured ]; do
        sleep 5
    done
fi
restore_persistence
apply_env_vars
mkdir -p /var/www/MISPData/tmp/logs
echo "Starting MISP Workers..."
supervisord -c /etc/supervisor/conf.d/misp-workers.conf
