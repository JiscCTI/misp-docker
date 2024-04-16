#!/bin/bash

set -e

set_env_vars() {
    FQDN="${FQDN:-misp.local}"
    HTTPS_PORT="${HTTPS_PORT:-443}"
    MISP_EMAIL_ADDRESS="${MISP_EMAIL_ADDRESS:-misp@local}"
    SHIBB_EMAIL_TAG="${SHIBB_EMAIL_TAG:-urn:oid:0.9.2342.19200300.100.1.3}"
    SHIBB_GROUP_TAG="${SHIBB_GROUP_TAG:-urn:oid:1.3.6.1.4.1.5923.1.5.1.1}"
    SHIBB_IDP_ENTITY_ID="${SHIBB_IDP_ENTITY_ID:-https://idp.example.org/idp/shibboleth}"
    SHIBB_IDP_METADATA_URL="${SHIBB_IDP_METADATA_URL:-false}"
    SHIBB_ORG_TAG="${SHIBB_ORG_TAG:-urn:oid:1.3.6.1.4.1.25178.1.2.9}"
    SHIBB_SP_ENCRYPT_REQUESTS="${SHIBB_SP_ENCRYPT_REQUESTS:-true}"
    SHIBB_SP_ENTITY_ID="${SHIBB_SP_ENTITY_ID:-default}"
    SHIBB_SP_SHARE_KEY="${SHIBB_SP_SHARE_KEY:-true}"
    SHIBB_SP_SIGN_REQUESTS="${SHIBB_SP_SIGN_REQUESTS:-true}"

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
    if [[ "${SHIBB_SP_SHARE_KEY}" == "false" ]]; then
        echo "Generating shibboleth encryption key pair"
        /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp-encrypt 2>/dev/null
        echo "Generating shibboleth signing key pair"
        /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp-sign 2>/dev/null
    else
        echo "Generating shibboleth signing and encryption key pair"
        /etc/shibboleth/keygen.sh -f -h "${FQDN}" -y 5 -e "${SHIBB_SP_ENTITY_ID}" -o /etc/shibboleth -n misp 2>/dev/null
    fi

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
    sed -i "s|root@localhost|${MISP_EMAIL_ADDRESS}|" /etc/shibboleth/shibboleth2.xml
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
    sed -i "s/Email/${SHIBB_EMAIL_TAG}/" attribute-map.xml
    sed -i "s/Group/${SHIBB_GROUP_TAG}/" attribute-map.xml
    sed -i "s/Organisaiton/${SHIBB_ORG_TAG}/" attribute-map.xml

    rm -rf /run/shibboleth/*

    echo "Generating MISP Service Provider Metadata"
    if [[ "${SHIBB_SP_SHARE_KEY}" == "false" ]]; then
        /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-encrypt-cert.pem -c /etc/shibboleth/misp-sign-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
    else
        /etc/shibboleth/metagen.sh -2 -T SHIB -L -c /etc/shibboleth/misp-cert.pem -h "${FQDN}" -e "${SHIBB_SP_ENTITY_ID}" >/etc/shibboleth/misp-metadata.xml
    fi
    echo "Saved to: [Volume:/etc/shibboleth]/misp-metadata.xml"
}

set_env_vars
if [ ! -f /etc/shibboleth/.configured ]; then
    initial_config
fi
on_start
echo "Starting shibd in foreground"
/usr/sbin/shibd -F
