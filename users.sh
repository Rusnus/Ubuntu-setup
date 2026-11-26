#!/usr/bin/env bash

source "$(dirname "$0")/logger.sh"

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-admin}"
SSH_KEY_FILE="${SSH_KEY_FILE:-}"

create_users() {
	if id "$ADMIN_USER" &>/dev/null; then
		log "User '$ADMIN_USER' already exists - skip creation"
	else
		useradd -m -s /bin/bash "$ADMIN_USER"
		if ! passwd "$ADMIN_USER"; then
			userdel --remove "$ADMIN_USER"
			die "password setup failed; user removed"
		fi
		usermod -aG sudo "$ADMIN_USER"
		log "User '$ADMIN_USER' created and added to sudo group"
	fi

}

setup_ssh_key() {
	local ssh_dir="/home/${ADMIN_USER}/.ssh"
	local auth_keys="${ssh_dir}/authorized_keys"

	mkdir -p "$ssh_dir" && chmod 700 "$ssh_dir"

	if [[ -n "$SSH_KEY_FILE" && -f "$SSH_KEY_FILE" ]]; then
		cat "$SSH_KEY_FILE" >> "$auth_keys"
		log "SSH public key copied from $SSH_KEY_FILE"
	else
		log "WARNING: SSH_KEY_FILE not set - skip key copy"
	fi

	chmod 600 "$auth_keys" 2>/dev/null || true
	chown -R "${ADMIN_USER}:${ADMIN_USER}" "$ssh_dir"

}

lock_root(){
	passwd -l root >> "$LOG_FILE" 2>&1
	log "Root account password locked (sudo works)"
}

main() {
	log "=== Module: user setup ==="
	create_users
	setup_ssh_key
	lock_root
	log "User setup complete. Admin user: $ADMIN_USER"
}
main "$@"

