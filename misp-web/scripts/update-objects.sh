#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

echo "Fixing permissions..."
chown -R www-data: /var/www/

echo "Pulling MISP objects..."

(
    cd /var/www/MISPData/files/misp-decaying-models || exit
    echo "Updating misp-decaying-models..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/misp-galaxy || exit
    echo "Updating misp-galaxy..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/misp-objects || exit
    echo "Updating misp-objects..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/misp-workflow-blueprints || exit
    echo "Updating misp-workflow-blueprints..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/noticelists || exit
    echo "Updating noticelists..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/taxonomies || exit
    echo "Updating taxonomies..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

(
    cd /var/www/MISPData/files/warninglists || exit
    echo "Updating warninglists..."
    su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
)

echo "Loading updated MISP objects into database..."
$CAKE admin updateGalaxies
$CAKE admin updateObjectTemplates 1
$CAKE admin updateNoticelists
$CAKE admin updateTaxonomies
$CAKE admin updateWarningLists

echo "MISP objects updated."
