#!/bin/bash

set -e -x -o pipefail

REPOSITORY=/root/flow_merchant.ibkr
APPUSER=ibkr_gateway
APPGROUP=${APPUSER}

INSTALL_LOG=/var/log/${APPUSER}-install.log
LOG_DIR=/var/log/${APPUSER}
CONFIG_DIR=/etc/${APPUSER}
APP_DIR=/opt/${APPUSER}

function log() {
    echo "$(date) $@" >> "${INSTALL_LOG}"
}

function setup-directories() {
    log "adding user"

    id -u ${APPUSER} &>/dev/null || useradd -m -s /bin/bash -g ${APPGROUP} ${APPUSER}

    log "Setting up ${APP_DIR}"
    [ -d "${APP_DIR}" ] || {
        mkdir -p ${APP_DIR}
        chown -R ${APPUSER}:${APPGROUP} ${APP_DIR}
        chmod 755 ${APP_DIR}
    }
    
    log "Setting up ${LOG_DIR}"
    [ -d "${LOG_DIR}" ] || {
        mkdir -p ${LOG_DIR}
        chown -R ${APPUSER}:${APPGROUP} ${LOG_DIR}
        chmod 755 ${LOG_DIR}
    }

    log "Setting up ${CONFIG_DIR}"
    [ -d "${CONFIG_DIR}" ] || {
        mkdir -p ${CONFIG_DIR}
        chown -R ${APPUSER}:${APPGROUP} ${CONFIG_DIR}
        chmod 755 ${CONFIG_DIR}
    }
}

function install-configs() {
    log "installing configuration"
    read -p "Enter password (alphanumeric and underscores only): " PASSWORD
    if ! [[ $PASSWORD =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "Error: Password must contain only letters, numbers and underscores"
        exit 1
    fi

    local repo_cfg_dir=${REPOSITORY}/infra/${APPUSER}/linux/etc

    cp ${repo_cfg_dir}/${APPUSER}/.env.tpl ${CONFIG_DIR}/.env.tpl
    sed -i "s/{{GATEWAY_PASSWORD}}/${PASSWORD}/g" ${CONFIG_DIR}/.env.tpl
    mv ${CONFIG_DIR}/.env.tpl ${CONFIG_DIR}/.env
}

function install-service() {
    log "installing ${APPUSER} service"
    local repo_cfg_dir=${REPOSITORY}/infra/${APPUSER}/linux/etc

    log "emplacing service file"
    cp ${repo_cfg_dir}/systemd/system/${APPUSER}.service /etc/systemd/system/
    chmod 755 /etc/systemd/system/${APPUSER}.service

    log "reloading daemon"
    systemctl daemon-reload

    log "enabling and starting ${APPUSER}"
    systemctl enable ${APPUSER}
    systemctl restart ${APPUSER}
}

function remove-old-log() {
    [ -f "${INSTALL_LOG}" ] && rm "${INSTALL_LOG}"
}

function check-repository-in-root() {
    [ -d "${REPOSITORY}" ] || { 
        log "Repository must be in root directory: ${REPOSITORY}"
        exit 1;
    }
}

function check-root() {
    [ "$(id -u)" -eq 0 ] || { 
        echo "This script must be run as root"; exit 1; 
    }
}

function main() {
    check-root
    check-repository-in-root
    remove-old-log
    setup-directories
    install-configs
    install-service
    log "install complete"
}

main