#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/ubuntu-setup.log"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [ssh] $*" | tee -a "$LOG_FILE"; }
ok() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${GREEN}[ssh][OK]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[ssh][WARN]${NC} $*" | tee -a "$LOG_FILE"; }
die() { echo -e "[ERROR] $*" | tee -a "$LOG_FILE"; exit 1; }

SSH_PORT="${SSH_PORT:-22}"
SSH_ALLOW_USERS="${SSH_ALLOW_USERS:-}"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
BANNER_FILE="/etc/issue.net"
BACKUP="${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"

backup_config() {
	cp "$SSHD_CONFIG" "$BACKUP"
	log "Backed up original sshd_config to $BACKUP"
}

disable_conflicting_dropins() {
	[[ -d "$SSHD_CONFIG_DIR" ]] || return 0

	local found=false
	local f
	for f in "$SSHD_CONFIG_DIR"/*.conf; do
		[[ -e "$f" ]] || continue

		if ( grep -qiE '^\s*PasswordAuthentication\s+yes' "$f" || grep -qiE '^\s*PermitRootLogin\s+yes' "$f" ); then
			mv "$f" "${f}.disabler-by-ubuntu-setup"
			warn "Disabled conflicting drop-in: $f -> ${f}.disabler-by-ubutu-setup"
			found=true
		fi
	done

	[[ "$found" == false ]] && log "No conflicting drop-in configs found in $SSHD_CONFIG_DIR"
}

write_banner() {

	local line
	line= $(printf '%.0s' {1..63})
	cat > "$BANNER_FILE" <<EOF
${line}
This system is for authorized use only. All activity may be
monitored and logged. Unauthorized access is prohibited.
${line}
EOF
	ok "Wrote login banner to $BANNER_FILE"
}

write_config() {
	{
	echo "# Managed by ubuntu-setup - $(date)"
	echo "# Original backup: $BACKUP"
	echo ""
	echo "Port ${SSH_PORT}"
	echo "AddressFamily inet"
	echo "PermitRootLogin no"
	echo "PasswordAuthentication no"
	echo "ChallengeResponseAuthentication no"
	echo "KbdInteractiveAuthentication no"
	echo "PubkeyAuthentication yes"
	echo "PermitRootLogin no"
	echo "X11Forwarding no"
	echo "MaxAuthTries 3"
	echo "ClientAliveInterval 600"
	echo "ClientAliveCountMax 2"
	echo "Banner ${BANNER_FILE}"
	echo "Protocol 2"
	echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com"
	echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org"
	echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"

	[[ -n "$SSH_ALLOW_USERS" ]] && echo "AllowUsers $SSH_ALLOW_USERS"

	echo ""
	echo "Include ${SSHD_CONFIG_DIR}/*.conf"
	} > "SSHD_CONFIG"
	ok "Wrote new sshd_config (port ${SSH_PORT})"
}

validate_and_restart() {
	if ! sshd -t; then
		warn "sshd config test failed - restoring backup"
		cp "$BACKUP" "$SSHD_CONFIG"
		die "Reverted to backup. Check your settings and try again."
	fi
	ok "sshd config validated"
	systemctl restart ssh || systemctl restart sshd
	ok "SSH service restarted (port ${SSH_PORT})"
}

main() {
	log "=== Modules: SSH hardening ==="
	backup_config
	disable_conflicting_dropins
	write_banner
	write_config
	validate_and_restart
	ok "SSH hardening complete."
}

main "$@"
