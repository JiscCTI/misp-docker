#!/bin/bash

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

DATE=(date +"%b %d %H:%M:%S")
LOG=("${FQDN}" update_objects[$$]:)

{
    echo "$("${DATE[@]}")" "${LOG[@]}" Fixing permissions
    chown -R www-data: /var/www/
    echo "$("${DATE[@]}")" "${LOG[@]}" Fixed permissions

    (
        cd /var/www/MISPData/files/misp-decaying-models || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling misp-decaying-models
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled misp-decaying-models
    )

    (
        cd /var/www/MISPData/files/misp-galaxy || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling misp-galaxy
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled misp-galaxy
    )

    (
        cd /var/www/MISPData/files/misp-objects || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling misp-objects
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled misp-objects
    )

    (
        cd /var/www/MISPData/files/misp-workflow-blueprints || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling misp-workflow-blueprints
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled misp-workflow-blueprints
    )

    (
        cd /var/www/MISPData/files/noticelists || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling noticelists
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled noticelists
    )

    (
        cd /var/www/MISPData/files/taxonomies || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling taxonomies
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled taxonomies
    )

    (
        cd /var/www/MISPData/files/warninglists || exit
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulling warninglists
        su www-data -s /bin/bash -c "git pull --quiet --ff-only origin main"
        echo "$("${DATE[@]}")" "${LOG[@]}" Pulled warninglists
    )

    echo "$("${DATE[@]}")" "${LOG[@]}" Updating database
    $CAKE admin updateGalaxies | xargs -L1 echo "$("${DATE[@]}")" "${LOG[@]}"
    $CAKE admin updateObjectTemplates 1 | xargs -L1 echo "$("${DATE[@]}")" "${LOG[@]}"
    $CAKE admin updateNoticelists | xargs -L1 echo "$("${DATE[@]}")" "${LOG[@]}"
    $CAKE admin updateTaxonomies | xargs -L1 echo "$("${DATE[@]}")" "${LOG[@]}"
    $CAKE admin updateWarningLists | xargs -L1 echo "$("${DATE[@]}")" "${LOG[@]}"

    echo "$("${DATE[@]}")" "${LOG[@]}" Done
} | tee -a /var/www/MISPData/tmp/logs/update_objects.log
