#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/ubuntu-setup.log"

# Colors
RED='\033[0;31m';
NC='\033[0m';

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [users] $*" | tee -a "$LOG_FILE"; }
die() { echo -e "${RED}[ERROR]${NC}   $*" | tee -a "$LOG_FILE"; exit 1; }

ADMIN_USER="${ADMIN_USER:-serveradmin}"
# Path to public key
set +o pipefail
SSH_KEY_FILE="${SSH_KEY_FILE:-$(find "${HOME:-/root}" "/home/$SUDO_USER" -maxdepth 3 -type f -name "id_*.pub" 2>/dev/null | head -n 1)}"
set -o pipefail

create_users() {
	if id "$ADMIN_USER" &>/dev/null; then
		log "User '$ADMIN_USER' already exists - skip creation"
	else
		useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
		passwd -e "$ADMIN_USER"
		log "User '$ADMIN_USER' created and added to sudo group"
	fi

}

setup_ssh_key() {
	local ssh_dir="/home/${ADMIN_USER}/.ssh"
	local auth_keys="${ssh_dir/authorized_keys}"

	mkdir -p "$ssh_dir"
	chmod 700 "$ssh_dir"

	if [[ -n "$SSH_KEY_FILE && -f $SSH_KEY_FILE" ]]; then
		cat "$SSH_KEY_FILE" >> "$auth_keys"
		log "SSH public key copied from $SSH_KEY_FILE"
	else
		log "SSH_KEY_FILE not set - skip key copy"
	fi

	chmod 600 "$auth_keys" 2>/dev/null || true
	chown -R "${ADMIN_USER}:${ADMIN_USER}" "$ssh_dir"

}
