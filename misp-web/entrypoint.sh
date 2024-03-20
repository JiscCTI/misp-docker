#!/bin/bash

# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: James Acris
# SPDX-FileContributor: James Ellor
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

set -e

set_env_vars() {
    if [[ "$HTTPS_PORT" -eq 443 ]]; then
        MISP_URL="https://$FQDN"
    else
        MISP_URL="https://$FQDN:$HTTPS_PORT"
    fi
}

setup_objects() {
    cd /var/www/MISPData/files/ || exit 1
    echo "Cloning misp-decaying-models..."
    git clone --quiet https://github.com/MISP/misp-decaying-models misp-decaying-models
    echo "Cloning misp-galaxy..."
    git clone --quiet https://github.com/MISP/misp-galaxy misp-galaxy
    echo "Cloning misp-objects..."
    git clone --quiet https://github.com/MISP/misp-objects misp-objects
    echo "Cloning misp-workflow-blueprints..."
    git clone --quiet https://github.com/MISP/misp-workflow-blueprints misp-workflow-blueprints
    echo "Cloning noticelists..."
    git clone --quiet https://github.com/MISP/misp-noticelist noticelists
    echo "Cloning taxonomies..."
    git clone --quiet https://github.com/MISP/misp-taxonomies taxonomies
    echo "Cloning warninglists..."
    git clone --quiet https://github.com/MISP/misp-warninglists warninglists
    cd /var/www/ || exit 1
}

setup_smtp() {
    cd /var/www/MISPData/ || exit 1
    echo "<?php
    class EmailConfig {
        public \$default = array(
            'transport'     => 'Smtp',
            'from'          => array('$MISP_EMAIL_ADDRESS' => '$MISP_EMAIL_NAME'),
            'host'          => '$SMTP_HOSTNAME',
            'port'          => $SMTP_PORT,
            'timeout'       => 30,
            'username'      => '$SMTP_USERNAME',
            'password'      => '$SMTP_PASSWORD',
            'client'        => null,
            'log'           => false,
            'tls'           => $SMTP_STARTTLS,
        );
    }" >config/email.php
}

setup_oidc() {
    # Configure Authentication method
    if [[ "$AUTH_METHOD" = OidcAuth.Oidc ]];
        # Enable the OidcAuth plugin
        cd /var/www/MISP/app/Config
        echo "CakePlugin::load('OidcAuth');" >>bootstrap.php
        auth_config="'auth' => array('$AUTH_METHOD'),"

        # Configure OIDC
        sed -i "/auth_enforced/a \    $auth_config" config.php
        sed -i '$ d' config.php
        echo "  'OidcAuth' =>
            array (
                'provider_url' => '$OIDC_PROVIDER',
                'client_id' => '$OIDC_CLIENT_ID',
                'client_secret' => '$OIDC_CLIENT_SECRET',
                'authentication_method' => '$OIDC_AUTH_METHOD',
                'code_challenge_method' => '$OIDC_CODE_CHALLENGE_METHOD',
                'redirect_uri' => '$FQDN/users/login',
                'role_mapper' =>
                array (
                    '$OIDC_ORG_ADMIN_ROLE' => 2,
                    '$OIDC_ADMIN_ROLE' => 1,
                    '$OIDC_SYNC_ROLE' => 5,
                    '$OIDC_PUBLISHER_ROLE' => 4,
                    '$OIDC_API_ROLE' => 'User with API access',
                    '$OIDC_USER_ROLE' => 3,
                ),
                'default_org' => '$ORG_NAME',
            ),
        );" >>config.php
}

restore_persistence() {
    echo "Restoring persistent file storage..."
    cd /var/www/ || exit 1
    mkdir -p MISPData/attachments MISPData/config MISPData/custom_scripts MISPData/files MISPData/images MISPData/tmp

    if [ ! -L MISP/app/Config ]; then
        echo "Persisting config..."
        if [ ! -f /var/www/MISPData/.configured ]; then
            if [ "$(ls -A MISPData/config/)" ]; then
                echo "MISP isn't configured but files exist - assuming files are valid"
                echo "If MISP does not run properly clear MISPData mountpoint and create misp-web container"
            else
                mv MISP/app/Config/* MISPData/config/
            fi
        fi
        rm -rf MISP/app/Config
        ln -s /var/www/MISPData/config/ /var/www/MISP/app/Config
    else
        echo "Config already persistent."
    fi

    if [ ! -L MISP/app/files ]; then
        echo "Persisting app files..."
        if [ ! -f /var/www/MISPData/.configured ]; then
            if [ "$(ls -A MISPData/files/)" ]; then
                echo "MISP isn't configured but files exist - assuming files are valid"
                echo "If MISP does not run properly clear MISPData mountpoint and create misp-web container"
            else
                mv MISP/app/files/* MISPData/files/
            fi
            setup_objects
        fi
        rm -rf MISP/app/files
        ln -s /var/www/MISPData/files/ /var/www/MISP/app/files
    else
        echo "App files already persistent."
    fi

    if [ ! -L MISP/app/tmp ]; then
        echo "Persisting temp files..."
        if [ ! -f /var/www/MISPData/.configured ]; then
            if [ "$(ls -A MISPData/tmp/)" ]; then
                echo "MISP isn't configured but files exist - assuming files are valid"
                echo "If MISP does not run properly clear MISPData mountpoint and create misp-web container"
            else
                mv MISP/app/tmp/* MISPData/tmp/
            fi
        fi
        rm -rf MISP/app/tmp
        ln -s /var/www/MISPData/tmp/ /var/www/MISP/app/tmp
    else
        echo "Temp files already persistent."
    fi
    mkdir -p MISPData/tmp/logs
    touch -a MISPData/tmp/logs/apache_access.log MISPData/tmp/logs/apache_error.log MISPData/tmp/logs/debug.log MISPData/tmp/logs/error.log MISPData/tmp/logs/exec-errors.log MISPData/tmp/logs/misp_maintenance_runner.log MISPData/tmp/logs/misp_maintenance_supervisor-errors.log MISPData/tmp/logs/misp_maintenance_supervisor.log MISPData/tmp/logs/misp-workers-errors.log MISPData/tmp/logs/misp-workers.log MISPData/tmp/logs/run_misp_sync_jobs.log
    chmod 755 MISPData/tmp/logs
    chmod 644 MISPData/tmp/logs/*
    chown -R www-data: MISPData/tmp/logs

    # Migrate organisation icons from pre v2.4.185
    if [ -d MISPData/icons/ ]; then
        if [ -n "$(ls -A MISPData/icons/)" ]; then
            # If MISPData/icons is not empty
            echo "Relocating org icons..."
            mkdir -p MISPData/files/img/orgs
            mv MISPData/icons/* MISPData/files/img/orgs/
        fi
        rm -rf MISPData/icons/
    fi

    if [ ! -L MISP/app/webroot/img/custom ]; then
        echo "Persisting images..."
        if [ ! -f /var/www/MISPData/.configured ]; then
            if [ "$(ls -A MISPData/images/)" ]; then
                echo "MISP isn't configured but files exist - assuming files are valid"
                echo "If MISP does not run properly clear MISPData mountpoint and create misp-web container"
            else
                mv MISP/app/webroot/img/custom/* MISPData/images/
            fi
        fi
        rm -rf MISP/app/webroot/img/custom
        ln -s /var/www/MISPData/images/ /var/www/MISP/app/webroot/img/custom
    else
        echo "Images already persistent."
    fi

    echo "Persistent file storage restored."
}

setup_db() {
    cd /var/www/MISPData/ || exit 1
    echo "<?php
    class DATABASE_CONFIG {
        public \$default = array(
            'datasource' => 'Database/Mysql',
            'persistent' => false,
            'host' => '$MYSQL_HOSTNAME',
            'login' => '$MYSQL_USERNAME',
            'port' => 3306,
            'password' => '$MYSQL_PASSWORD',
            'database' => '$MYSQL_DBNAME',
            'prefix' => '',
            'encoding' => 'utf8',
        );
    }" >config/database.php

    if mysql -h "$MYSQL_HOSTNAME" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" <<<"SELECT id FROM users LIMIT 1" >/dev/null 2>&1; then
        echo "Database schema appears to already be created"
    else
        echo "Database schema not present"
        echo "Creating database schema..."
        mysql -h "$MYSQL_HOSTNAME" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" </var/www/MISP/INSTALL/MYSQL.sql
    fi
}

initial_config() {
    echo "Starting initial configuration..."
    sed -i "s/^\(session.save_handler\).*/\1 = redis/" /usr/local/etc/php/php.ini
    if [ -z "${REDIS_PASSWORD}" ]; then
        echo "Warning: No Redis password is set, ensure network access control is implemented"
        sed -i "s/^\(session.save_path\).*/\1 = \"tcp:\/\/${REDIS_HOST}:6379\"/" /usr/local/etc/php/php.ini
    else
        SED_REDIS_PASSWORD=${REDIS_PASSWORD//\//\\\/}
        sed -i "s/^\(session.save_path\).*/\1 = \"tcp:\/\/${REDIS_HOST}:6379?auth=${SED_REDIS_PASSWORD}\"/" /usr/local/etc/php/php.ini
    fi

    cd /var/www/ || exit 1
    cp -a MISP/app/Config/bootstrap.default.php MISP/app/Config/bootstrap.php
    cp /opt/scripts/core.php MISP/app/Config/core.php
    cp -a MISP/app/Config/config.default.php MISP/app/Config/config.php

    echo "Setting file ownership and permissions..."
    chown -R www-data: /var/www/MISP/
    chown -R www-data: /var/www/MISPData/
    chown -R www-data: /var/www/MISPGnuPG/
    chmod -R 750 /var/www/MISP/app/Config/

    $CAKE Admin setSetting "MISP.server_settings_skip_backup_rotate" true
    echo "Generating encryption salt value..."
    $CAKE Admin setSetting "Security.salt" "$(openssl rand -base64 32)" >/dev/null 2>&1
    echo 'Setting "Security.salt" changed to "[REDACTED]"'
    $CAKE userInit -q >/dev/null 2>&1
    $CAKE Admin setSetting "Security.advanced_authkeys" false
    python3 /opt/scripts/set_auth_key.py -k "$($CAKE Admin getAuthKey admin@admin.test | tr -d "[:blank:]" 2>&1)" >/dev/null 2>&1
    $CAKE Admin setSetting "MISP.baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.external_baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.uuid" "$(uuid -v 4)"
    $CAKE Admin setSetting "MISP.redis_host" "$REDIS_HOST"
    $CAKE Admin setSetting "MISP.redis_database" "$REDIS_MISP_DB"
    $CAKE Admin setSetting "MISP.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "MISP.redis_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "GnuPG.email" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "GnuPG.password" "$GPG_PASSPHRASE" >/dev/null 2>&1
    echo 'Setting "GnuPG.password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "GnuPG.binary" "$(which gpg)"
    $CAKE Admin setSetting "MISP.email" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "MISP.contact" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "Plugin.Enrichment_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Import_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Export_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Action_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_host" "$REDIS_HOST"
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_database" "$REDIS_WORKER_DB"
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.redis_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_host" "$WORKERS_HOSTNAME"
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_password" "$WORKERS_PASSWORD" >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.supervisor_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "SimpleBackgroundJobs.enabled" true
    $CAKE Admin setSetting "MISP.org" "$ORG_NAME"
    echo "Setting $(grep --count CAKE /opt/scripts/misp-base-config.sh) base configuration settings..."
    /opt/scripts/misp-base-config.sh >/dev/null
    echo "Base configuration complete."
    setup_smtp

    touch /var/www/MISPData/.configured
    /wait-for-it.sh -h "${WORKERS_HOSTNAME:-misp_workers}" -p 9001 -t 0 -- true

    echo "Executing all updates to bring the database up to date with the current version."
    $CAKE Admin runUpdates >/dev/null 2>&1
    echo "All updates completed."
    $CAKE Admin setSetting "Security.encryption_key" "$(openssl rand -base64 32)" >/dev/null 2>&1
    echo 'Setting "Security.encryption_key" changed to "[REDACTED]"'
    $CAKE Admin setSetting "MISP.email_from_name" "$MISP_EMAIL_NAME"
    $CAKE Admin setSetting "Plugin.Enrichment_clamav_connection" "${CLAMAV_HOSTNAME}:3310"
    echo "Setting $(grep --count CAKE /opt/scripts/misp-post-update-config.sh) post upgrade configuration settings..."
    /opt/scripts/misp-post-update-config.sh >/dev/null
    echo "Post upgrade configuration complete."

    if [ -f /var/www/MISPData/custom-config.sh ]; then
        echo "Custom config options script found, executing..."
        bash /var/www/MISPData/custom-config.sh
    fi

    # Set MISP Live
    $CAKE Live 1 >/dev/null 2>&1
    echo "Maintenance mode disabled"

    $CAKE Admin setSetting "MISP.server_settings_skip_backup_rotate" false
    echo "Initial configuration finished."
}

check_gnupg() {
    MISP_EMAIL_ADDRESS="${MISP_EMAIL_ADDRESS:-misp@misp.local}"
    chown -R www-data: /var/www/MISPGnuPG
    chmod 700 /var/www/MISPGnuPG
    if [ -r /var/www/MISPGnuPG/import.asc ]; then
        set +e
        echo "/var/www/MISPGnuPG/import.asc found, importing..."
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --import /var/www/MISPGnuPG/import.asc"
        echo "Setting trust level for imported GnuPG key..."
        su -s /bin/bash www-data -c "echo $(gpg --homedir /var/www/MISPGnuPG --batch --show-keys /var/www/MISPGnuPG/import.asc | sed -n '2p' | awk '{$1=$1};1'):6 | gpg --homedir /var/www/MISPGnuPG --batch --import-ownertrust"
        set -e
    fi
    echo "Checking for usable GnuPG Key..."
    GPG_KEY=$(su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --export --armor $MISP_EMAIL_ADDRESS 2>/dev/null")
    if [[ "$GPG_KEY" != "-----BEGIN PGP PUBLIC KEY BLOCK-----"* ]]; then
        echo "Generating new GnuPG Key"
        echo "%echo Generating a default key
        Key-Type: RSA
        Key-Length: 4096
        Subkey-Type: RSA
        Name-Real: $MISP_EMAIL_NAME
        Name-Comment: $FQDN
        Name-Email: $MISP_EMAIL_ADDRESS
        Expire-Date: 0
        Passphrase: $GPG_PASSPHRASE
        # Do a commit here, so that we can later print 'done'
        %commit
        %echo done" >/tmp/gen-key-script
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --gen-key /tmp/gen-key-script" >/dev/null 2>&1
        rm /tmp/gen-key-script
        echo "GnuPG key generated, exporting to webroot..."
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --export --armor $MISP_EMAIL_ADDRESS>/var/www/MISP/app/webroot/gpg.asc"
    else
        echo "GnuPG key found, exporting to webroot..."
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --export --armor $MISP_EMAIL_ADDRESS>/var/www/MISP/app/webroot/gpg.asc"
    fi
    echo "Exporting encrypted GnuPG privtate key to ASCII File"
    su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --pinentry-mode=loopback --yes --export-secret-key --armor $MISP_EMAIL_ADDRESS>/var/www/MISPGnuPG/import.asc"
    chown -R www-data: /var/www/MISPGnuPG
    chmod 700 /var/www/MISPGnuPG
}

generate_self_signed_certificate() {
    openssl req -x509 -newkey rsa:4096 -subj "/CN=$(hostname)" \
        -keyout /etc/ssl/private/misp.key -out /etc/ssl/private/misp.crt -sha256 -days 365 -nodes >/dev/null 2>&1
    cat /etc/ssl/private/misp.crt /etc/ssl/private/misp.key >/etc/ssl/private/haproxy.pem
}

check_tls_certificate() {
    if [ -r /etc/ssl/private/misp.crt ]; then
        if [ -r /etc/ssl/private/misp.key ]; then
            PUBLIC=$(openssl x509 -noout -pubkey -in /etc/ssl/private/misp.crt | openssl sha256 | awk '{print $2}')
            PRIVATE=$(openssl pkey -pubout -in /etc/ssl/private/misp.key | openssl sha256 | awk '{print $2}')
            if [[ "$PUBLIC" == "$PRIVATE" ]]; then
                echo "TLS key validated successfully"
            else
                echo "Key /etc/ssl/private/misp.key does not match certificate /etc/ssl/private/misp.crt"
                echo "Generating temporary certificate..."
                generate_self_signed_certificate
            fi
        else
            echo "Key /etc/ssl/private/misp.key for certificate /etc/ssl/private/misp.crt missing"
            echo "Generating temporary certificate..."
            generate_self_signed_certificate
        fi
    else
        echo "Certificate /etc/ssl/private/misp.crt missing"
        echo "Generating temporary certificate..."
        generate_self_signed_certificate
    fi
}

on_start() {
    echo "Updating settings based on environment variables..."
    sed -i "s/^\(ServerName\).*/\1 \${FQDN}/" /etc/apache2/sites-enabled/000-default.conf
    setup_smtp
    check_gnupg
    if echo "1234" | su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --pinentry-mode loopback -o /dev/null --local-user $MISP_EMAIL_ADDRESS -as -" >/dev/null 2>&1; then
        $CAKE Admin setSetting "GnuPG.password" "$GPG_PASSPHRASE" >/dev/null 2>&1
        echo 'Setting "GnuPG.password" changed to "[REDACTED]"'
    else
        echo "GPG Passphrase not changed as new value doesn't unlock the current key"
    fi
    $CAKE Admin setSetting "GnuPG.email" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "MISP.email" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "MISP.contact" "$MISP_EMAIL_ADDRESS"
    $CAKE Admin setSetting "MISP.baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.external_baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.org" "$ORG_NAME"
    /usr/local/bin/python3 /opt/scripts/trigger_set_org_name.py
    $CAKE Admin setSetting "Security.otp_required" "$REQUIRE_TOTP"

    sed -i "s/^\(session.save_handler\).*/\1 = redis/" /usr/local/etc/php/php.ini
    if [ -z "${REDIS_PASSWORD}" ]; then
        echo "Warning: No Redis password is set, ensure network access control is implemented"
        sed -i "s/^\(session.save_path\).*/\1 = \"tcp:\/\/${REDIS_HOST}:6379\"/" /usr/local/etc/php/php.ini
    else
        SED_REDIS_PASSWORD=${REDIS_PASSWORD//\//\\\/}
        sed -i "s/^\(session.save_path\).*/\1 = \"tcp:\/\/${REDIS_HOST}:6379?auth=${SED_REDIS_PASSWORD}\"/" /usr/local/etc/php/php.ini
    fi

    /wait-for-it.sh -h "${REDIS_HOST:-misp_redis}" -p 6379 -t 0 -- true
    $CAKE Admin setSetting "MISP.redis_host" "$REDIS_HOST"
    $CAKE Admin setSetting "MISP.redis_database" "$REDIS_MISP_DB"
    $CAKE Admin setSetting "MISP.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "MISP.redis_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_host" "$REDIS_HOST"
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_database" "$REDIS_WORKER_DB"
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.redis_password" changed to "[REDACTED]"'

    /wait-for-it.sh -h "${MODULES_HOSTNAME:-misp_modules}" -p 6666 -t 0 -- true
    $CAKE Admin setSetting "Plugin.Enrichment_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Import_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Export_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Action_services_url" "http://$MODULES_HOSTNAME"

    /wait-for-it.sh -h "${CLAMAV_HOSTNAME:-misp_clamav}" -p 3310 -t 0 -- true
    $CAKE Admin setSetting "Plugin.Enrichment_clamav_connection" "${CLAMAV_HOSTNAME}:3310"

    /wait-for-it.sh -h "${WORKERS_HOSTNAME:-misp_workers}" -p 9001 -t 0 -- true
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_host" "$WORKERS_HOSTNAME"
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_password" "$WORKERS_PASSWORD" >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.supervisor_password" changed to "[REDACTED]"'

    if [ "$AUTH_METHOD" == oidc ]; then
        echo "Enabling OIDC Authentication"
        cp /etc/apache2/sites-available/apache.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_oidc.php
    elif [ "$AUTH_METHOD" == shibb ]; then
        echo "Enabling Shibboleth Authentication"
        cp /etc/apache2/sites-available/apache.shibb.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_shibb.php
    else
        if [ "$AUTH_METHOD" != misp ]; then
            echo "Unknown AUTH_METHOD ($AUTH_METHOD), must be 'misp' or 'shibb'"
        fi
        echo "Enabling MISP Native Authentication"
        cp /etc/apache2/sites-available/apache.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_misp.php
    fi

    echo "Settings updated based on environment variables."
}

# Check for startup lock
STARTUP_LOCK=/var/www/MISPData/.init_lock
while [ -f "$STARTUP_LOCK" ]; do
    if [ "$(hostname)" == "$(cat $STARTUP_LOCK)" ]; then
        echo "Self-referencing startup lock found, clearing..."
        rm $STARTUP_LOCK
    elif ping -q -c 1 "$(cat $STARTUP_LOCK)" >/dev/null; then
        # Random timeout between 3 and 10 seconds
        TIMEOUT=$((RANDOM % 8 + 3))
        echo "Valid startup lock for $(cat $STARTUP_LOCK) found, waiting $TIMEOUT seconds..."
        sleep $TIMEOUT
    else
        echo "Invalid startup lock for $(cat $STARTUP_LOCK) found, clearing..."
        rm $STARTUP_LOCK
    fi
done
# Obtain startup lock
hostname >$STARTUP_LOCK
echo "Obtained startup lock."
# Initalise container
set_env_vars
restore_persistence
setup_db
if [ ! -f /var/www/MISPData/.configured ]; then
    initial_config
fi
check_tls_certificate
# Apply all environment variables
on_start
# Ensure database schema and objects are up to date
$CAKE Admin runUpdates
/opt/scripts/update_objects.sh
# Release startup lock
rm /var/www/MISPData/.init_lock
echo "Released startup lock."
# Start MISP
echo "Starting MISP at $MISP_URL..."
source /etc/apache2/envvars && exec /usr/sbin/apache2 -D FOREGROUND
