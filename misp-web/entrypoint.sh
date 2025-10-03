#!/bin/bash

# SPDX-FileCopyrightText: 2023-2025 Jisc Services Limited
# SPDX-FileContributor: James Acris
# SPDX-FileContributor: James Ellor
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

apply_customisations() {
    echo "Processing /opt/misp_custom customisations..."

    if [ -d /opt/misp_custom/images ]; then
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/images/ | grep -q "\.jpg"; then
            for image in /opt/misp_custom/images/*.jpg; do
                echo "Custom image ${image} found, copying..."
                cp "$image" /var/www/MISPData/files/img/custom/
            done
        fi
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/images/ | grep -q "\.png"; then
            for image in /opt/misp_custom/images/*.png; do
                echo "Custom image ${image} found, copying..."
                cp "$image" /var/www/MISPData/files/img/custom/
            done
        fi
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/images/ | grep -q "\.svg"; then
            for image in /opt/misp_custom/images/*.svg; do
                echo "Custom image ${image} found, copying..."
                cp "$image" /var/www/MISPData/files/img/custom/
            done
        fi
    fi

    if [ -d /opt/misp_custom/org_icons ]; then
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/org_icons/ | grep -q "\.png"; then
            for image in /opt/misp_custom/org_icons/*.png; do
                echo "Custom image ${image} found, copying..."
                cp "$image" /var/www/MISPData/files/img/orgs/
            done
        fi
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/org_icons/ | grep -q "\.svg"; then
            for image in /opt/misp_custom/org_icons/*.svg; do
                echo "Custom image ${image} found, copying..."
                cp "$image" /var/www/MISPData/files/img/orgs/
            done
        fi
    fi

    if [ -d /opt/misp_custom/taxonomies ]; then
        if [ -n "$(ls /opt/misp_custom/taxonomies/)" ]; then
            for taxonomy in /opt/misp_custom/taxonomies/*; do
                if [ -d "$taxonomy" ]; then
                    if [ -f "${taxonomy}/machinetag.json" ]; then
                        echo "Custom taxonomy ${taxonomy} found, copying..."
                        cp -r -f "$taxonomy" /var/www/MISPData/files/taxonomies/
                    else
                        echo "Custom taxonomy ${taxonomy} has no machinetag.json."
                    fi
                fi
            done
        fi
    fi

    if [ -d /opt/misp_custom/terms ]; then
        if [ -n "$(ls /opt/misp_custom/terms/)" ]; then
            for terms_file in /opt/misp_custom/terms/*; do
                if [ -f "${terms_file}" ]; then
                    echo "Custom terms file ${terms_file} found, copying..."
                    cp -f "${terms_file}" /var/www/MISPData/files/terms/
                fi
            done
        fi
    fi

    if [ -d /opt/misp_custom/on_start ]; then
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/on_start/ | grep -q "\.sh"; then
            for startup_script in /opt/misp_custom/on_start/*.sh; do
                echo "Custom startup script ${startup_script} found, executing..."
                bash "$startup_script"
            done
        else
            echo "Custom startup script directory found - but no *.sh scripts to run"
        fi
    fi

    echo "Done processing /opt/misp_custom customisations."
}

apply_env_vars() {
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
    python3 /opt/scripts/trigger_set_org_name.py
    $CAKE Admin setSetting "Security.otp_required" "$REQUIRE_TOTP"
    setup_redis
    /wait-for-it.sh -h "$MODULES_HOSTNAME" -p 6666 -t 0 -- true
    $CAKE Admin setSetting "Plugin.Enrichment_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Import_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Export_services_url" "http://$MODULES_HOSTNAME"
    $CAKE Admin setSetting "Plugin.Action_services_url" "http://$MODULES_HOSTNAME"

    /wait-for-it.sh -h "$CLAMAV_HOSTNAME" -p 3310 -t 0 -- true
    $CAKE Admin setSetting "Plugin.Enrichment_clamav_connection" "${CLAMAV_HOSTNAME}:3310"

    /wait-for-it.sh -h "$WORKERS_HOSTNAME" -p 9001 -t 0 -- true
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_host" "$WORKERS_HOSTNAME"
    $CAKE Admin setSetting "SimpleBackgroundJobs.supervisor_password" "$WORKERS_PASSWORD" >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.supervisor_password" changed to "[REDACTED]"'

    if [ "$AUTH_METHOD" == "oidc" ]; then
        echo "Enabling OIDC Authentication"
        sed -i "s/^\(session.cookie_samesite\).*/\1 = \"Lax\"/" /usr/local/etc/php/php.ini
        $CAKE Admin setSetting "Security.require_password_confirmation" false
        if variable_is_true "$OIDC_ONLY" ; then
            $CAKE Admin setSetting "Security.auth_enforced" true
        else
            $CAKE Admin setSetting "Security.auth_enforced" false
        fi
        cp /etc/apache2/sites-available/apache.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_oidc.php
    elif [ "$AUTH_METHOD" == "shibb" ]; then
        echo "Enabling Shibboleth Authentication"
        sed -i "s/^\(session.cookie_samesite\).*/\1 = \"Strict\"/" /usr/local/etc/php/php.ini
        $CAKE Admin setSetting "Security.require_password_confirmation" false
        if variable_is_true "$SHIBB_ONLY" ; then
            $CAKE Admin setSetting "Security.auth_enforced" true
        else
            $CAKE Admin setSetting "Security.auth_enforced" false
        fi
        cp /etc/apache2/sites-available/apache.shibb.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_shibb.php
    else
        if [ "$AUTH_METHOD" != "misp" ]; then
            echo "Unknown AUTH_METHOD ($AUTH_METHOD), must be 'misp', 'oidc' or 'shibb'"
        fi
        echo "Enabling MISP Native Authentication"
        sed -i "s/^\(session.cookie_samesite\).*/\1 = \"Strict\"/" /usr/local/etc/php/php.ini
        $CAKE Admin setSetting "Security.require_password_confirmation" true
        $CAKE Admin setSetting "Security.auth_enforced" false
        cp /etc/apache2/sites-available/apache.conf /etc/apache2/sites-enabled/000-default.conf
        php /opt/scripts/auth_misp.php
    fi

    if variable_is_true "$X_FORWARDED_FOR"; then
        a2enmod remoteip >/dev/null 2>&1
        echo "RemoteIPHeader X-Forwarded-For" > /etc/apache/conf-available/remoteip.conf
        if variable_is_true "$X_FORWARDED_FOR_ALLOW_INTERNAL"; then
            echo "RemoteIPInternalProxy $X_FORWARDED_FOR_PROXY" >> /etc/apache/conf-available/remoteip.conf
            echo "Enabled X-Forwarded-For from '$X_FORWARDED_FOR_PROXY' (RFC 1918 IPs Allowed)"
        else
            echo "RemoteIPTrustedProxy $X_FORWARDED_FOR_PROXY" >> /etc/apache/conf-available/remoteip.conf
            echo "Enabled X-Forwarded-For from '$X_FORWARDED_FOR_PROXY' (RFC 1918 IPs Prohibited)"
        fi
    else
        a2dismod remoteip >/dev/null 2>&1
        echo "Disabled X-Forwarded-For"
    fi

    echo "Settings updated based on environment variables."
}

await_startup_lock() {
    # Check for startup lock
    STARTUP_LOCK=/var/www/MISPData/.init_lock
    CURRENT_LOCK="$(cat $STARTUP_LOCK)"
    while [ -f "$STARTUP_LOCK" ]; do
        if [ "$(hostname)" == "$CURRENT_LOCK" ]; then
            echo "Self-referencing startup lock found, clearing..."
            rm $STARTUP_LOCK
        elif ping -q -c 1 "$CURRENT_LOCK" >/dev/null; then
            # Random timeout between 3 and 10 seconds
            TIMEOUT=$((RANDOM % 8 + 3))
            echo "Valid startup lock for $CURRENT_LOCK found, waiting $TIMEOUT seconds..."
            sleep $TIMEOUT
        else
            echo "Invalid startup lock for $CURRENT_LOCK found, clearing..."
            rm $STARTUP_LOCK
        fi
    done

    # Obtain startup lock
    hostname >$STARTUP_LOCK
    echo "Obtained startup lock."
}

check_gnupg() {
    mkdir -p /opt/misp_custom/gpg/
    chown -R www-data: /opt/misp_custom/gpg/
    chmod 700 /opt/misp_custom/gpg/
    chown -R www-data: /var/www/MISPGnuPG
    chmod 700 /var/www/MISPGnuPG
    if [ -r /var/www/MISPGnuPG/import.asc ]; then
        set +e
        echo "[Deprecated] /var/www/MISPGnuPG/import.asc found, importing..."
        echo "Deprecation Warning: use /opt/misp_custom/gpg/import.asc instead"
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --import /var/www/MISPGnuPG/import.asc"
        echo "Setting trust level for imported GnuPG key..."
        su -s /bin/bash www-data -c "echo $(gpg --homedir /var/www/MISPGnuPG --batch --show-keys /var/www/MISPGnuPG/import.asc | sed -n '2p' | awk '{$1=$1};1'):6 | gpg --homedir /var/www/MISPGnuPG --batch --import-ownertrust"
        set -e
    fi
    if [ -r /opt/misp_custom/gpg/import.asc ]; then
        set +e
        echo "/opt/misp_custom/gpg/import.asc found, importing..."
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --import /opt/misp_custom/gpg/import.asc"
        echo "Setting trust level for imported GnuPG key..."
        su -s /bin/bash www-data -c "echo $(gpg --homedir /var/www/MISPGnuPG --batch --show-keys /opt/misp_custom/gpg/import.asc | sed -n '2p' | awk '{$1=$1};1'):6 | gpg --homedir /var/www/MISPGnuPG --batch --import-ownertrust"
        set -e
    elif [ -r /opt/misp_custom/gpg/export.asc ]; then
        set +e
        echo "/opt/misp_custom/gpg/export.asc found, importing..."
        su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --import /opt/misp_custom/gpg/export.asc"
        echo "Setting trust level for imported GnuPG key..."
        su -s /bin/bash www-data -c "echo $(gpg --homedir /var/www/MISPGnuPG --batch --show-keys /opt/misp_custom/gpg/export.asc | sed -n '2p' | awk '{$1=$1};1'):6 | gpg --homedir /var/www/MISPGnuPG --batch --import-ownertrust"
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
    echo "Exporting encrypted GnuPG private key to ASCII File"
    su -s /bin/bash www-data -c "gpg --homedir /var/www/MISPGnuPG --batch --passphrase '$GPG_PASSPHRASE' --pinentry-mode=loopback --yes --export-secret-key --armor $MISP_EMAIL_ADDRESS>/opt/misp_custom/gpg/export.asc"
    chown -R www-data: /var/www/MISPGnuPG
    chmod 700 /var/www/MISPGnuPG
}

check_tls_certificate() {
    if [ -r /etc/letsencrypt/live/MISP/fullchain.pem ]; then
        if [ -r /etc/letsencrypt/live/MISP/privkey.pem ]; then
            PUBLIC=$(openssl x509 -noout -pubkey -in /etc/letsencrypt/live/MISP/fullchain.pem | openssl sha256 | awk '{print $2}')
            PRIVATE=$(openssl pkey -pubout -in /etc/letsencrypt/live/MISP/privkey.pem | openssl sha256 | awk '{print $2}')
            if [[ "$PUBLIC" == "$PRIVATE" ]]; then
                echo "Found certificate to import in /etc/letsencrypt/live/MISP"
                cp -f /etc/letsencrypt/live/MISP/fullchain.pem /etc/ssl/private/misp.crt
                cp -f /etc/letsencrypt/live/MISP/privkey.pem /etc/ssl/private/misp.key
            else
                echo "Found certificate in /etc/letsencrypt/live/MISP, but private key does not match"
            fi
        else
            echo "Found certificate in /etc/letsencrypt/live/MISP, but private key missing"
        fi
    elif [ -r /opt/misp_custom/tls/misp.crt ]; then
        if [ -r /opt/misp_custom/tls/misp.key ]; then
            PUBLIC=$(openssl x509 -noout -pubkey -in /opt/misp_custom/tls/misp.crt | openssl sha256 | awk '{print $2}')
            PRIVATE=$(openssl pkey -pubout -in /opt/misp_custom/tls/misp.key | openssl sha256 | awk '{print $2}')
            if [[ "$PUBLIC" == "$PRIVATE" ]]; then
                echo "Found certificate to import in /opt/misp_custom/tls"
                cp -f /opt/misp_custom/tls/misp.crt /etc/ssl/private/misp.crt
                cp -f /opt/misp_custom/tls/misp.key /etc/ssl/private/misp.key
            else
                echo "Found certificate in /opt/misp_custom/tls, but private key does not match"
            fi
        else
            echo "Found certificate in /opt/misp_custom/tls, but private key missing"
        fi
    fi

    if [ -r /etc/ssl/private/misp.crt ]; then
        if [ -r /etc/ssl/private/misp.key ]; then
            PUBLIC=$(openssl x509 -noout -pubkey -in /etc/ssl/private/misp.crt | openssl sha256 | awk '{print $2}')
            PRIVATE=$(openssl pkey -pubout -in /etc/ssl/private/misp.key | openssl sha256 | awk '{print $2}')
            if [[ "$PUBLIC" == "$PRIVATE" ]]; then
                echo "TLS key validated successfully"
                if ! grep -q -- "-----BEGIN DH PARAMETERS-----" /etc/ssl/private/misp.crt; then
                    echo "Appending Mozilla recommended Ephemeral Diffie-Hellman (DHE) parameters to certificate"
                    curl https://ssl-config.mozilla.org/ffdhe2048.txt >>/etc/ssl/private/misp.crt
                fi
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

generate_self_signed_certificate() {
    openssl req -x509 -newkey rsa:4096 -subj "/CN=${FQDN}" \
        -keyout /etc/ssl/private/misp.key -out /etc/ssl/private/misp.crt -sha256 -days 365 -nodes >/dev/null 2>&1
    cat /etc/ssl/private/misp.crt /etc/ssl/private/misp.key >/etc/ssl/private/haproxy.pem
    curl https://ssl-config.mozilla.org/ffdhe2048.txt >>/etc/ssl/private/misp.crt
}

initial_config() {
    echo "Starting initial configuration..."
    cd /var/www/ || exit 1
    cp -a MISP/app/Config/bootstrap.default.php MISP/app/Config/bootstrap.php
    cp /opt/scripts/core.php MISP/app/Config/core.php
    echo "Generating encryption cipher seed value..."
    {
        echo "Configure::write('Security.cipherSeed', '$(python3 /opt/scripts/generate_cipher_seed.py)');"
        echo "//Comment the following out if you do not with to use the background workers (not recommended)"
        echo "require_once '/var/www/MISP/app/Vendor/autoload.php';"
    } >>MISP/app/Config/core.php
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
    setup_redis
    $CAKE userInit -q >/dev/null 2>&1
    $CAKE Admin setSetting "Security.advanced_authkeys" false
    python3 /opt/scripts/set_auth_key.py -k "$($CAKE Admin getAuthKey admin@admin.test | tr -d "[:blank:]" 2>&1)" >/dev/null 2>&1
    $CAKE Admin setSetting "MISP.baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.external_baseurl" "$MISP_URL"
    $CAKE Admin setSetting "MISP.uuid" "$(uuid -v 4)"
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
    /wait-for-it.sh -h "$WORKERS_HOSTNAME" -p 9001 -t 0 -- true

    echo "Executing all updates to bring the database up to date with the current version."
    $CAKE Admin runUpdates >/dev/null 2>&1
    echo "All updates completed."
    $CAKE Admin setSetting "Security.encryption_key" "$(openssl rand -base64 32)" >/dev/null 2>&1
    echo 'Setting "Security.encryption_key" changed to "[REDACTED]"'
    $CAKE Admin setSetting "MISP.email_from_name" "$MISP_EMAIL_NAME"
    $CAKE Admin setSetting "Plugin.Enrichment_clamav_connection" "${CLAMAV_HOSTNAME}:3310"
    $CAKE Admin setSetting "MISP.email_reply_to" "$MISP_EMAIL_ADDRESS"
    echo "Setting $(grep --count CAKE /opt/scripts/misp-post-update-config.sh) post upgrade configuration settings..."
    /opt/scripts/misp-post-update-config.sh >/dev/null
    echo "Post upgrade configuration complete."

    if [ -f /var/www/MISPData/custom-config.sh ]; then
        echo "[Deprecated] Custom config options script found, executing..."
        echo "Deprecation Warning: use /opt/misp_custom/init/*.sh instead"
        bash /var/www/MISPData/custom-config.sh
    fi
    if [ -d /opt/misp_custom/init ]; then
        # shellcheck disable=SC2010
        if ls /opt/misp_custom/init/ | grep -q "\.sh"; then
            for custom_init_script in /opt/misp_custom/init/*.sh; do
                echo "Custom initial setup script ${custom_init_script} found, executing..."
                bash "$custom_init_script"
            done
        else
            echo "Custom initial setup directory found - but no *.sh scripts to run"
        fi
    fi

    # Set MISP Live
    $CAKE Live 1 >/dev/null 2>&1
    echo "Maintenance mode disabled"

    $CAKE Admin setSetting "MISP.server_settings_skip_backup_rotate" false
    echo "Initial configuration finished."
}

load_env_vars() {
    export AUTH_METHOD=${AUTH_METHOD:-misp}
    export CLAMAV_HOSTNAME=${CLAMAV_HOSTNAME:-misp_clamav}
    export FQDN=${FQDN:-misp.local}
    export GPG_PASSPHRASE=${GPG_PASSPHRASE:-misp}
    if [ "$GPG_PASSPHRASE" == "misp" ]; then
        echo "The GPG_PASSPHRASE environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
    export HTTPS_PORT=${HTTPS_PORT:-443}
    export MISP_EMAIL_ADDRESS=${MISP_EMAIL_ADDRESS:-misp@misp.local}
    export MISP_EMAIL_NAME=${MISP_EMAIL_NAME:-MISP}
    if [[ "$HTTPS_PORT" -eq 443 ]]; then
        export MISP_URL="https://$FQDN"
    else
        export MISP_URL="https://$FQDN:$HTTPS_PORT"
    fi
    export MODULES_HOSTNAME=${MODULES_HOSTNAME:-misp_modules}
    export MYSQL_DBNAME=${MYSQL_DBNAME:-misp}
    export MYSQL_HOSTNAME=${MYSQL_HOSTNAME:-misp_db}
    export MYSQL_PASSWORD=${MYSQL_PASSWORD:-misp}
    if [ "$MYSQL_PASSWORD" == "misp" ]; then
        echo "The MYSQL_PASSWORD environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
    export MYSQL_USERNAME=${MYSQL_USERNAME:-misp}
    export ORG_NAME=${ORG_NAME:-ORGNAME}
    export REDIS_HOST=${REDIS_HOST:-misp_redis}
    export REDIS_MISP_DB=${REDIS_MISP_DB:-2}
    export REDIS_PASSWORD=${REDIS_PASSWORD:-misp}
    if [ "$REDIS_PASSWORD" == "misp" ]; then
        echo "The REDIS_PASSWORD environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
    export REDIS_PORT=${REDIS_PORT:-6379}
    export REDIS_TLS=${REDIS_TLS:-false}
    export REDIS_WORKER_DB=${REDIS_WORKER_DB:-3}
    export REQUIRE_TOTP=${REQUIRE_TOTP:-true}
    export SMTP_HOSTNAME=${SMTP_HOSTNAME:-localhost}
    export SMTP_PASSWORD=${SMTP_PASSWORD:-misp}
    if [ "$SMTP_PASSWORD" == "misp" ]; then
        echo "The SMTP_PASSWORD environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
    export SMTP_PORT=${SMTP_PORT:-587}
    export SMTP_STARTTLS=${SMTP_STARTTLS:-true}
    export SMTP_USERNAME=${SMTP_USERNAME:-misp}
    export WORKERS_HOSTNAME=${WORKERS_HOSTNAME:-misp_workers}
    export WORKERS_PASSWORD=${WORKERS_PASSWORD:-misp}
    if [ "$WORKERS_PASSWORD" == "misp" ]; then
        echo "The WORKERS_PASSWORD environment variable must be overwritten in .env for MISP to start"
        exit 1
    fi
    export X_FORWARDED_FOR=${X_FORWARDED_FOR:-false}
    export X_FORWARDED_FOR_ALLOW_INTERNAL=${X_FORWARDED_FOR_ALLOW_INTERNAL:-false}
    export X_FORWARDED_FOR_PROXY=${X_FORWARDED_FOR_PROXY:-127.0.0.1}

    if [ "$AUTH_METHOD" == "oidc" ]; then
        export OIDC_ADMIN_ROLE=${OIDC_ADMIN_ROLE:-misp-admin}
        export OIDC_AUTH_METHOD=${OIDC_AUTH_METHOD:-client_secret_jwt}
        export OIDC_CLIENT_ID=${OIDC_CLIENT_ID:-misp}
        export OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET:-misp}
        if [ "$OIDC_CLIENT_SECRET" == "misp" ]; then
            echo "The OIDC_CLIENT_SECRET environment variable must be overwritten in oidc.env for MISP to start"
            exit 1
        fi
        export OIDC_CODE_CHALLENGE_METHOD=${OIDC_CODE_CHALLENGE_METHOD:-S256}
        export OIDC_ONLY=${OIDC_ONLY:-false}
        export OIDC_ORG_ADMIN_ROLE=${OIDC_ORG_ADMIN_ROLE:-misp-orgadmin}
        export OIDC_PROVIDER=${OIDC_PROVIDER:-example.com/auth/realms/realm/.well-known/openid-configuration}
        export OIDC_PUBLISHER_ROLE=${OIDC_PUBLISHER_ROLE:-misp-publisher}
        export OIDC_READONLY_ROLE=${OIDC_READONLY_ROLE:-misp-readonly}
        export OIDC_SYNC_ROLE=${OIDC_SYNC_ROLE:-misp-sync}
        export OIDC_USER_ROLE=${OIDC_USER_ROLE:-misp-user}
    fi

    if [ "$AUTH_METHOD" == "shibb" ]; then
        export SHIBB_ADMIN_ROLE=misp-admin
        export SHIBB_BLOCK_ORG_CHANGE=false
        export SHIBB_BLOCK_ROLE_CHANGE=false
        export SHIBB_DEFAULT_ROLE=false
        export SHIBB_ONLY=${SHIBB_ONLY:-false}
        export SHIBB_ORG_ADMIN_ROLE=misp-orgadmin
        export SHIBB_PUBLISHER_ROLE=misp-publisher
        export SHIBB_READONLY_ROLE=misp-readonly
        export SHIBB_SYNC_ROLE=misp-sync
        export SHIBB_USER_ROLE=misp-user
    fi
}

restore_persistence() {
    echo "Restoring persistent file storage..."
    cd /var/www/ || exit 1
    mkdir -p MISPData/attachments MISPData/config MISPData/custom_scripts MISPData/files \
        MISPData/images MISPData/tmp MISPData/acme/.well-known/acme-challenge

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

    if mysql --skip-ssl-verify-server-cert -h "$MYSQL_HOSTNAME" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" <<<"SELECT id FROM users LIMIT 1" >/dev/null 2>&1; then
        echo "Database schema appears to already be created"
    else
        echo "Database schema not present"
        echo "Creating database schema..."
        mysql --skip-ssl-verify-server-cert -h "$MYSQL_HOSTNAME" -u "$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" </var/www/MISP/INSTALL/MYSQL.sql
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

setup_redis() {
    /wait-for-it.sh -h "$REDIS_HOST" -p "$REDIS_PORT" -t 0 -- true

    if variable_is_true "$REDIS_TLS"; then
        REDIS_URL="tls:\/\/${REDIS_HOST}:${REDIS_PORT}"
        $CAKE Admin setSetting "MISP.redis_host" "tls://$REDIS_HOST" --force
        $CAKE Admin setSetting "SimpleBackgroundJobs.redis_host" "tls://$REDIS_HOST" --force
        $CAKE Admin setSetting "Plugin.ZeroMQ_redis_host" "tls://$REDIS_HOST" --force
    else
        REDIS_URL="tcp:\/\/${REDIS_HOST}:${REDIS_PORT}"
        $CAKE Admin setSetting "MISP.redis_host" "$REDIS_HOST" --force
        $CAKE Admin setSetting "SimpleBackgroundJobs.redis_host" "$REDIS_HOST" --force
        $CAKE Admin setSetting "Plugin.ZeroMQ_redis_host" "$REDIS_HOST" --force
    fi
    sed -i "s/^\(session.save_handler\).*/\1 = redis/" /usr/local/etc/php/php.ini
    if [ -z "${REDIS_PASSWORD}" ]; then
        echo "Warning: No Redis password is set, ensure network access control is implemented"
        sed -i "s/^\(session.save_path\).*/\1 = \"${REDIS_URL}\"/" /usr/local/etc/php/php.ini
    else
        SED_REDIS_PASSWORD=${REDIS_PASSWORD//\//\\\/}
        sed -i "s/^\(session.save_path\).*/\1 = \"${REDIS_URL}?auth=${SED_REDIS_PASSWORD}\"/" /usr/local/etc/php/php.ini
    fi

    $CAKE Admin setSetting "MISP.redis_port" "$REDIS_PORT" --force
    $CAKE Admin setSetting "MISP.redis_database" "$REDIS_MISP_DB" --force
    $CAKE Admin setSetting "MISP.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "MISP.redis_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_port" "$REDIS_PORT" --force
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_database" "$REDIS_WORKER_DB" --force
    $CAKE Admin setSetting "SimpleBackgroundJobs.redis_password" "$REDIS_PASSWORD" --force >/dev/null 2>&1
    echo 'Setting "SimpleBackgroundJobs.redis_password" changed to "[REDACTED]"'
    $CAKE Admin setSetting "Plugin.ZeroMQ_redis_port" "$REDIS_PORT" --force
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

variable_is_true() {
    # adapted from: https://stackoverflow.com/a/20473191
    if [[ "$1" == "" ]]; then
        return 1
    elif [[ " 1 on On t true True y yes Yes " =~ (^|[[:space:]])"$1"($|[[:space:]]) ]] ; then
        # variable is true
        return 0
    else
        return 1
    fi
}

set -e
# Prevent race conditions in HA deployments
await_startup_lock
# Populate missing environment variables with default values
load_env_vars
# Persist required directories
restore_persistence
# Ensure the database schema is in place
setup_db
# Run initial configuration if not already done
if [ ! -f /var/www/MISPData/.configured ]; then
    initial_config
fi
# Ensure a valid TLS certificate is present
check_tls_certificate
# Apply environment variables to MISP configuration
apply_env_vars
# Apply any customisations in /opt/misp_custom
apply_customisations
# Ensure database schema and objects are up to date
$CAKE Admin runUpdates
/opt/scripts/update_objects.sh
# Release startup lock
rm -f /run/shibboleth/.init_lock
echo "Released startup lock."
# Start MISP
echo "Starting MISP at $MISP_URL..."
# shellcheck disable=SC1091
source /etc/apache2/envvars && exec /usr/sbin/apache2 -D FOREGROUND
