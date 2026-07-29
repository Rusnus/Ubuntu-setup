#!/usr/bin/env bash

source "$(dirname "$0")/logger.sh"

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-serveradmin}"
# Path to public key
set +o pipefail
SSH_KEY_FILE="${SSH_KEY_FILE:-$(find "${HOME:-/root}" "/home/${SUDO_USER:-}" -maxdepth 3 -type f -name "id_*.pub" 2>/dev/null | head -n 1)}"
set -o pipefail

create_users() {
	if id "$ADMIN_USER" &>/dev/null; then
		log "User '$ADMIN_USER' already exists - skip creation"
	else
		useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
		local generated_password
		generated_password="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 7)" || true
		echo "${ADMIN_USER}:${generated_password}" | chpasswd >>"$LOG_FILE" 2>&1
		log " Generated local password for '$ADMIN_USER' (used for sudo only):"
		log " ${generated_password}"
		log "User '$ADMIN_USER' created and added to sudo group"
	fi

}

setup_ssh_key() {
	local ssh_dir="/home/${ADMIN_USER}/.ssh"
	local auth_keys="${ssh_dir}/authorized_keys"

	mkdir -p "$ssh_dir"
	chmod 700 "$ssh_dir"

	if [[ -n "$SSH_KEY_FILE" && -f "$SSH_KEY_FILE" ]]; then
		cat "$SSH_KEY_FILE" >> "$auth_keys"
		log "SSH public key copied from $SSH_KEY_FILE"
	else
		log "SSH_KEY_FILE not set - skip key copy"
	fi

	chmod 600 "$auth_keys" 2>/dev/null || true
	chown -R "${ADMIN_USER}:${ADMIN_USER}" "$ssh_dir"

}

configure_sudo(){
	local sudoers_file="/etc/sudoers.d/${ADMIN_USER}"
	cat > "$sudoers_file" <<EOF
		${ADMIN_USER} ALL=(ALL:ALL) ALL
EOF
	chmod 440 "$sudoers_file"
	visudo -cf "$sudoers_file" > /dev/null || die "sudoers syntax error - check $sudoers_file"
	log "sudo configured for '$ADMIN_USER'"
}

lock_root(){
	passwd -l root >> "$LOG_FILE" 2>&1
	log "Root account password locked (sudo works)"
}

main() {
	log "=== Module: user setup ==="
	create_users
	setup_ssh_key
	configure_sudo
	lock_root
	log "User setup complete. Admin user: $ADMIN_USER"
}
main "$@"

