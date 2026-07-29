#!/usr/bin/env bash

source "$(dirname "$0")/logger.sh"

set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
EXTRA_PORTS="${EXTRA_PORTS:-}" # e.g. 80/tcp 443/tcp

install_ufw() {
	if ! command -v ufw &>/dev/null; then
		apt-get install -y ufw > /dev/null 2>&1
		log "ufw installed"
	else
		log "ufw already installed"
	fi
}

configure_ufw() {
	ufw --force reset > /dev/null 2>&1

	ufw default deny incoming > /dev/null 2>&1
	ufw default allow outgoing > /dev/null 2>&1

	ufw allow "${SSH_PORT/tcp}" comment "SSH" > /dev/null 2>&1
	log "Allowed SSH on port ${SSH_PORT}/tcp"

	if [[ -n "$EXTRA_PORTS" ]]; then
		for port in $EXTRA_PORTS; do
			ufw allow "$port" comment "Custom rule" > /dev/null 2>&1
			log "Allowed extra port: $port"
		done
	fi

	ufw limit "${SSH_PORT}/tcp" comment "SSH rate limit" > /dev/null 2>&1

	ufw --force enable > /dev/null 2>&1
	ufw reload > /dev/null 2>&1
}

show_status() {
	log "ufw rules applied"
	ufw status verbose >> "$LOG_FILE" 2>&1
}

main() {
	log "=== Module: firewall ==="
	install_ufw
	configure_ufw
	show_status
	log "Firewall configured"
}

main "$@"
