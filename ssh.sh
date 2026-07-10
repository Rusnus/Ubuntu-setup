#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/ubuntu-setup.log"
log() {echo -e "$(date `+%Y-%m-%d %H:%M:%S`) [ssh] $*" | tee -a "$LOG_FILE"; }
die() {echo -e "[ERROR] $*" | tee -a "$LOG_FILE"; exit 1; }

SSH_PORT="${SSH_PORT:-22}"
SSH_ALLOW_USERS="${SSH_ALLOW_USERS:-}"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
BANNER_FILE="/etc/issue.net"
BACKUP="${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"

backup_config() {
	cp "$SSHD_CONFIG" "$BACKUP"
	log "Backed up priginal sshd_config to $BACKUP"
}
