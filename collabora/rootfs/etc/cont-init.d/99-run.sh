#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if bashio::config.has_value 'domain'; then
    domain="$(bashio::config 'domain')"
    export domain
fi

if bashio::config.has_value 'username'; then
    username="$(bashio::config 'username')"
    export username
fi

if bashio::config.has_value 'password'; then
    password="$(bashio::config 'password')"
    export password
fi

if bashio::config.has_value 'aliasgroup1'; then
    aliasgroup1="$(bashio::config 'aliasgroup1')"
    export aliasgroup1
fi

if bashio::config.has_value 'dictionaries'; then
    dictionaries="$(bashio::config 'dictionaries')"
    export dictionaries
fi

extra_params=""
if bashio::config.has_value 'extra_params'; then
    extra_params="$(bashio::config 'extra_params')"
fi

if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    certfile="$(bashio::config 'certfile')"
    keyfile="$(bashio::config 'keyfile')"
    export DONT_GEN_SSL_CERT=true
    extra_params="${extra_params/--o:ssl.enable=false/}"
    extra_params="${extra_params} --o:ssl.enable=true --o:ssl.termination=false --o:ssl.cert_file_path=/ssl/${certfile} \
        --o:ssl.key_file_path=/ssl/${keyfile} --o:ssl.ca_file_path=/ssl/${certfile}"
fi

export extra_params

COOL_CONFIG="/etc/coolwsd/coolwsd.xml"
CONFIG_DEST="/config/coolwsd.xml"

mkdir -p /config
if [ ! -e "${CONFIG_DEST}" ]; then
    mv "${COOL_CONFIG}" "${CONFIG_DEST}"
    chown root:root "${CONFIG_DEST}"
    chmod 644 "${CONFIG_DEST}"
else
    rm -f "${COOL_CONFIG}"
fi
ln -sf "${CONFIG_DEST}" "${COOL_CONFIG}"

SYSTEMPLATE_DIR="/opt/cool/systemplate/etc"
if [ -d "${SYSTEMPLATE_DIR}" ]; then
    cp /etc/hosts "${SYSTEMPLATE_DIR}/hosts"
    cp /etc/hostname "${SYSTEMPLATE_DIR}/hostname" 2> /dev/null || true
    cp /etc/resolv.conf "${SYSTEMPLATE_DIR}/resolv.conf"
fi
chown -R 1001 /opt/cool/systemplate
chmod -R 755 /opt/cool/systemplate

bashio::log.info "Starting Collabora Online..."
su -p -s /bin/bash "$(getent passwd 1001 | cut -d: -f1)" -c "/start-collabora-online.sh"
