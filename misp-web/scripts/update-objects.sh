#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

echo "Fixing permissions..."
chown -R www-data: /var/www/

echo "Pulling MISP objects..."
cd /var/www/MISPData/files/

(
    cd misp-decaying-models || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd misp-galaxy || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd misp-objects || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd misp-workflow-blueprints || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd noticelists || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd taxonomies || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

(
    cd warninglists || exit
    su www-data -s /bin/bash -c "git pull --ff-only origin main"
)

echo "Loading updated MISP objects into database..."
$CAKE admin updateGalaxies
$CAKE admin updateObjectTemplates 1
$CAKE admin updateNoticelists
$CAKE admin updateTaxonomies
$CAKE admin updateWarningLists

echo "MISP objects updated."
