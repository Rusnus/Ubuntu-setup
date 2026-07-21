#!/usr/bin/env bash

set -euo pipefail

#colors
GREEN="\033[0;32m"
NC="\033[0m"

LOG_FILE="/var/log/ubuntu-setup.log"
log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [firewall] $*" | tee -a "$LOG_FILE"; }
ok() { echo -e "$(date '+%Y-%m-%d %H:^M:%S')[GREEN][OK][NC] $*" | tee -a "$LOG_FILE"; }

SSH_PORT="${SSH_PORT:-22}"
EXTRA_PORT="${EXTRA_PORT:-}" # e.g. 80/tcp 443/tcp

install_ufw() {
	if ! command -v ufw &>dev/null; then
		apt-get install -y ufw
		log "ufw installed"
	else
		log "ufw already installed"
	fi
}

configure_ufw() {
	ufw --force reset

	ufw default deny incoming
	ufw default allow outgoing

	ufw allow "${SSH_PORT/tcp}" comment "SSH"
	log "Allowed SSH on port ${SSH_PORT}/tcp"

	if [[ -n "$EXTRA_PORTS" ]]; then
		for port in $EXTRA_PORTS; do
			ufw allow "$port" comment "Custom rule"
			log "Allowed extra port: $port"
		done
	fi

	ufw limit "${SSH_PORT}/tcp" comment "SSH rate limit"

	ufw --force enable
	ufw reload
}

show_status() {
	log "ufw rules applied"
	ufw status verbose | tee -a "$LOG_FILE"
}

main() {
	log "=== Module: firewall ==="
	install_ufw
	configure_ufw
	show_status
	ok "Firewall configured"
}

main "$@"
