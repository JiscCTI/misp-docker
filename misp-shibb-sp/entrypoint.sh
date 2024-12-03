#!/bin/bash
# SPDX-FileCopyrightText: 2024 Jisc Services Limited
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

    if [[ "$SHIBB_SP_ENTITY_ID" == "default" ]]; then
        SHIBB_SP_ENTITY_ID="${MISP_URL}/shibboleth"
    fi
}

initial_config() {
    echo "Copying in default config files"
    cp -a /etc/shibboleth.dist/* /etc/shibboleth/
    echo "Generating shibboleth encryption key pair"
    /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp-encrypt 2>/dev/null
    echo "Generating shibboleth signing key pair"
    /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp-sign 2>/dev/null
    echo "Generating shibboleth shared signing and encryption key pair"
    /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp 2>/dev/null

    touch /etc/shibboleth/.configured
}

on_start() {
    if [[ "${SHIBB_IDP_METADATA_URL}" != "false" ]]; then
        echo "Downloading IdP Metadata"
        if curl -s --output /etc/shibboleth/idp-metadata.xml "${SHIBB_IDP_METADATA_URL}"; then
            echo "IdP Metadata Downloaded"
        else
            echo "IdP Metadata Download Failed"
            exit 1
        fi
    fi

    echo "Updating shibboleth2.xml"
    cp -a /etc/shibboleth.dist/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
    sed -i "s|https://sp.example.org/shibboleth|${SHIBB_SP_ENTITY_ID}|" /etc/shibboleth/shibboleth2.xml
    sed -i "s|https://idp.example.org/idp/shibboleth|${SHIBB_IDP_ENTITY_ID}|" /etc/shibboleth/shibboleth2.xml
    if [[ "${SHIBB_SP_ENCRYPT_REQUESTS}" == "false" ]]; then
        sed -i 's|encryption="true"|encryption="false"|' /etc/shibboleth/shibboleth2.xml
    fi
    if [[ "${SHIBB_SP_SIGN_REQUESTS}" == "false" ]]; then
        sed -i 's|signing="true"|signing="false"|' /etc/shibboleth/shibboleth2.xml
    fi
    if [[ "${SHIBB_SP_SHARE_KEY}" != "false" ]]; then
        sed -i 's|misp-encrypt|misp|g' /etc/shibboleth/shibboleth2.xml
        sed -i 's|misp-sign|misp|g' /etc/shibboleth/shibboleth2.xml
    fi

    echo "Updating attribute-map.xml"
    cp -a /etc/shibboleth.dist/attribute-map.xml /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_EMAIL_FORMAT/${SHIBB_EMAIL_FORMAT}/" /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_EMAIL_NAME/${SHIBB_EMAIL_NAME}/" /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_GROUP_FORMAT/${SHIBB_GROUP_FORMAT}/" /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_GROUP_NAME/${SHIBB_GROUP_NAME}/" /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_ORG_FORMAT/${SHIBB_ORG_FORMAT}/" /etc/shibboleth/attribute-map.xml
    sed -i "s/SHIBB_ORG_NAME/${SHIBB_ORG_NAME}/" /etc/shibboleth/attribute-map.xml

    rm -rf /run/shibboleth/*

    echo "Generating MISP Service Provider Metadata"
    if [ "${SHIBB_SP_ENCRYPT_REQUESTS}" != "false" ] && [ "${SHIBB_SP_SIGN_REQUESTS}" != "false" ]; then
        #encrypted and signed
        if [ "${SHIBB_SP_SHARE_KEY}" == "false" ]; then
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-encrypt-cert.pem -c /etc/shibboleth/misp-sign-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        else
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-cert.pem -c /etc/shibboleth/misp-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        fi
        sed -i '1,/<md:KeyDescriptor>/ s/<md:KeyDescriptor>/<md:KeyDescriptor use="encryption">/' /etc/shibboleth/misp-metadata.xml
        sed -i '1,/<md:KeyDescriptor>/ s/<md:KeyDescriptor>/<md:KeyDescriptor use="signing">/' /etc/shibboleth/misp-metadata.xml
    elif [ "${SHIBB_SP_ENCRYPT_REQUESTS}" != "false" ]; then
        #encrypted and unsigned
        if [ "${SHIBB_SP_SHARE_KEY}" == "false" ]; then
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-encrypt-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        else
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        fi
        sed -i 's/<md:KeyDescriptor>/<md:KeyDescriptor use="encryption">/' /etc/shibboleth/misp-metadata.xml
    elif [ "${SHIBB_SP_SIGN_REQUESTS}" != "false" ]; then
        #unencrypted and signed
        if [ "${SHIBB_SP_SHARE_KEY}" == "false" ]; then
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-sign-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        else
            /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        fi
        sed -i 's/<md:KeyDescriptor>/<md:KeyDescriptor use="signing">/' /etc/shibboleth/misp-metadata.xml
    else
        # have to generate metadata with a certificate then remove it or generation fails
        /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
        sed -i '/<md:KeyDescriptor>/,/<\/md:KeyDescriptor>/d' /etc/shibboleth/misp-metadata.xml
    fi
    echo "Saved to: [Volume:/etc/shibboleth]/misp-metadata.xml"

    chown shibd: /etc/shibboleth/*
}

set_env_vars
if [ ! -f /etc/shibboleth/.configured ]; then
    initial_config
fi
on_start
echo "Starting shibd in foreground"
/usr/sbin/shibd -F
