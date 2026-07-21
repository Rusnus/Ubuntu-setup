#!/usr/bin/env bash

set -euo pipefail

#colors
GREEN="\033[0;32m"
NC="\033[0m"

LOG_FILE="/var/log/ubuntu-setup.log"
log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [fail2ban] $*" | tee -a $"LOG_FILE"; }
ok() { echo -e "$(date '+%Y-%m-%d %H:%M:%S')[GREEN][OK][NC] $*" | tee -a $"LOG_FILE"; }

SSH_PORT="${SSH_PORT:-22}"
BAN_TIME="${BAN_TIME:-3600}"
FIND_TIME="${FIND_TIME:-600}"
MAX_RETRY="${MAX_RETRY:-5}"

install_fail2ban() {
	apt-get install -y fail2ban
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
	systemctl enable fail2ban
	systemctl restart fail2ban
	sleep 2
	fail2ban-client status sshd | tee -a "$LOG_FILE" || log "fail2ban sshd jail not yet active"
}

main() {
	log "=== Module: fail2ban ==="
	install_fail2ban
	configure_fail2ban
	enable_fail2ban
	ok "fail2ban configured"
}

main "$@"

