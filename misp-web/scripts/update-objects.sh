#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

echo "Fixing permissions..."
chown -R www-data: /var/www/

echo "Pulling MISP objects..."
cd /var/www/MISPData/files/

cd misp-decaying-models
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd misp-galaxy
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd misp-objects
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd misp-workflow-blueprints
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd noticelists
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd taxonomies
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

cd warninglists
su www-data -s /bin/bash -c "git pull --ff-only origin main"
cd ..

echo "Loading updated MISP objects into database..."
$CAKE admin updateGalaxies
$CAKE admin updateObjectTemplates 1
$CAKE admin updateNoticelists
$CAKE admin updateTaxonomies
$CAKE admin updateWarningLists

echo "MISP objects updated."
