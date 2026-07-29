#!/usr/bin/env bash

source "$(dirname "$0")/logger.sh"

set -euo pipefail

SSH_PORT="${SSH_PORT:-22}"
BAN_TIME="${BAN_TIME:-3600}"
FIND_TIME="${FIND_TIME:-600}"
MAX_RETRY="${MAX_RETRY:-5}"

install_fail2ban() {
	apt-get install -y fail2ban > /dev/null 2>&1
	log "fail2ban installed"
}

configure_fail2ban() {
	cat > /etc/fail2ban/jail.local <<EOF

[DEFAULT]
bantime = ${BAN_TIME}
findtime = ${FIND_TIME}
maxretry = ${MAX_RETRY}
backend = systemd
banaction = ufw

[sshd]
enabled = true
port 	= ${SSH_PORT}
filter	= sshd
logpath	= /var/log/auth.log
maxretry = ${MAX_RETRY}
EOF
	log "jail.local written (bantime=${BAN_TIME})"
}

enable_fail2ban() {
	systemctl enable fail2ban > /dev/null 2>&1
	systemctl restart fail2ban > /dev/null 2>&1
	sleep 2
	fail2ban-client status sshd >> "$LOG_FILE" 2>&1 || log "fail2ban sshd jail not yet active"
}

main() {
	log "=== Module: fail2ban ==="
	install_fail2ban
	configure_fail2ban
	enable_fail2ban
	log "fail2ban configured"
}

main "$@"

