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

    groupadd -f ${APPGROUP}
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
    log "finished setting up directories"
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

    chown ${APPUSER}:${APPGROUP} ${CONFIG_DIR}/.env
    chmod 755 ${CONFIG_DIR}/.env

    log "finished installing configuration"
}

function install-app() {
    log "installing ${APPUSER} app"
    local repo_app_dir=${REPOSITORY}/python
    local current_dir=$(pwd)
    log "copying py files"
    cp ${repo_app_dir}/*.py ${APP_DIR}/
    log "copying requirements"
    cp ${repo_app_dir}/requirements.txt ${APP_DIR}/
    cd ${APP_DIR}
    log "creating venv"
    python3 -m venv venv
    log "activating venv"
    source ./venv/bin/activate
    log "installing requirements"
    pip3 install -r requirements.txt
    log "deactivating venv"
    deactivate
    log "setting permissions"
    chown -R ${APPUSER}:${APPGROUP} ${APP_DIR}
    chmod 755 ${APP_DIR}/*
    cd ${current_dir}
    log "finished installing ${APPUSER} app"
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

    log "finished installing ${APPUSER} service"
}

function remove-old-log() {
    rm -f "${INSTALL_LOG}"
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

function install() {
    check-root
    check-repository-in-root
    remove-old-log
    log "starting install"
    setup-directories
    install-configs
    install-app
    install-service
    log "install complete"
}

function uninstall() {
    check-root
    check-repository-in-root
    log "starting uninstall"
    log "stopping ${APPUSER}"
    systemctl stop ${APPUSER}
    log "disabling ${APPUSER}"
    systemctl disable ${APPUSER}
    log "removing ${APPUSER} service"
    rm /etc/systemd/system/${APPUSER}.service
    log "reloading daemon"
    systemctl daemon-reload
    log "removing ${APPUSER} app"
    rm -rf ${APP_DIR}
    log "removing ${APPUSER} config"
    rm -rf ${CONFIG_DIR}
    log "removing ${APPUSER} logs"
    rm -rf ${LOG_DIR}
    log "removing ${APPUSER} user"
    userdel -r ${APPUSER}
    log "uninstall complete"
}

function main() {
    if [ "$1" = "-u" ]; then
            log "uninstalling"
            uninstall
        else
            log "installing"
            install
        fi
    
}

main "$@"