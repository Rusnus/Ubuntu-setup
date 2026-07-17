#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/ubuntu-setup.log"
log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [fail2ban] $*" | tee -a $"LOG_FILE"; }

SSH_PORT="${SSH_PORT:-22}"
BAN_TIME="${BAN_TIME:-3600}"
FIND_TIME="${FIND_TIME:-600}"
MAX_RETRY="${MAX_RETRY:-5}"

install_fail2ban() {
	apt-get install -y fail2ban
	log "fail2ban installed"
}

configure_fail2ban() {}

main() {
	log "=== Module: fail2ban ==="
	install_fail2ban
}

main "$@"

