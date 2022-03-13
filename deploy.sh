#!/usr/bin/env bash

source "$(dirname "$0")/ft-util/ft_util_inc_var"

APP_NAME="futur-tech-zabbix-samba-addc"
REQUIRED_PKG_ARR=( "at" "jq" )

SRC_DIR="/usr/local/src/${APP_NAME}"
BIN_DIR="/usr/local/bin/${APP_NAME}"
SUDOERS_ETC="/etc/sudoers.d/${APP_NAME}"

$(which zabbix_agent2 >/dev/null) && ZBX_CONF_AGENT_D="/etc/zabbix/zabbix_agent2.d"
if [ ! -d "${ZBX_CONF_AGENT_D}" ] ; then $S_LOG -s crit -d $S_NAME "${ZBX_CONF_AGENT_D} Zabbix Include directory not found" ; exit 10 ; fi

$S_LOG -d $S_NAME "Start $S_DIR_NAME/$S_NAME $*"

echo "
  INSTALL NEEDED PACKAGES & FILES
------------------------------------------"

# Install packages
$S_DIR_PATH/ft-util/ft_util_pkg -u -i ${REQUIRED_PKG_ARR[@]} || exit 1

# Bin deploy
if [ ! -d "${BIN_DIR}" ] ; then mkdir "${BIN_DIR}" ; $S_LOG -s $? -d $S_NAME "Creating ${BIN_DIR} returned EXIT_CODE=$?" ; fi
$S_DIR/ft-util/ft_util_file-deploy "$S_DIR/samba4_ad.sh" "${BIN_DIR}/samba4_ad.sh"

# Zabbix Config
$S_DIR/ft-util/ft_util_file-deploy "$S_DIR/etc.zabbix/${APP_NAME}.conf" "${ZBX_CONF_AGENT_D}/${APP_NAME}.conf"

# Cron config
$S_DIR/ft-util/ft_util_file-deploy "$S_DIR/etc.cron.d/${APP_NAME}" "/etc/cron.d/${APP_NAME}"

echo "
  SETUP SUDOERS FILE
------------------------------------------"

$S_LOG -d $S_NAME -d "$SUDOERS_ETC" "==============================="

echo "Defaults:zabbix !requiretty" | sudo EDITOR='tee' visudo --file=$SUDOERS_ETC &>/dev/null
echo "zabbix ALL=(ALL) NOPASSWD:${SRC_DIR}/deploy-update.sh" | sudo EDITOR='tee -a' visudo --file=$SUDOERS_ETC &>/dev/null
echo "zabbix ALL=(ALL) NOPASSWD:${BIN_DIR}/samba4_ad.sh *" | sudo EDITOR='tee -a' visudo --file=$SUDOERS_ETC &>/dev/null

cat $SUDOERS_ETC | $S_LOG -d "$S_NAME" -d "$SUDOERS_ETC" -i 

$S_LOG -d $S_NAME -d "$SUDOERS_ETC" "==============================="


echo "
  RESTART ZABBIX LATER
------------------------------------------"

echo "systemctl restart zabbix-agent*" | at now + 1 min &>/dev/null ## restart zabbix agent with a delay
$S_LOG -s $? -d "$S_NAME" "Scheduling Zabbix Agent Restart"

$S_LOG -d "$S_NAME" "End $S_NAME"

exit