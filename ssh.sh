#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="/var/log/ubuntu-setup.log"

YELLOW="\033[0;33m"
NC="\033[0m"

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [ssh] $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${YELLOW}[ssh][WARN]${NC} $*" | tee -a "$LOG_FILE" }
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

		if grep -qiE '^\s*PasswordAuthentication\s+yes' "$f" || grep -qiE '^\s*PermitRootLogin\s+yes' "$f"; then
			mv "$f" "${f}.disabler-by-ubuntu-setup"
			warn "Disabled conflicting drop-in: $f -> ${f}.disabler-by-ubutu-setup"
			found=true
		fi
	done

	if [[ "$found" == "false" ]]; then
		log "No conflicting drop-in configs found in $SSHD_CONFIG_DIR"
	fi
}

main() {
	log "=== Modules: SSH hardening ==="
	backup_config
	disable_conflicting_dropins
}

main "$@"
