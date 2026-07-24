#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
NC="\033[0m"

LOG_FILE="/var/log/ubuntu-setup.log"
log() { echo -e "$(date '+%Y-%m-%d %H:%m:%d') [updates] $*" | tee -a "$LOG_FILE"; }
ok() { echo -e "$(date '+%Y-%m-%d %H:%m:%d') ${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"; }

install_packages() {
	apt-get install -y unattended-upgrades apt-listchanges
	log "unattended-upgrades installed"
}

configure_updates() {
	cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
	"\${distro_id}:\${distro_codename}";
	"\${distro_id}:\${distro_codename}-security";
	"\${distro_id}ESMApps:\${distro_codename}-apps-security";
	"\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "false";

Unattended-Upgrade::Automatic-Reboot "${REBOOT_IF_NEEDED}";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
$([ -n "$NOTIFY_EMAIL" ] && echo "Unattended-Upgrade::Mail \"${NOTIFY_EMAIL}\";" || echo "// Unattended-Upgrade::Mail \"\";")
Unattended-Upgrade::MailReport "on-chande";
EOF

	cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
	log "unattended-upgrades configured (security-only, auto-reboot: ${REBOOT_IF_NEEDED})"
}

dry_run() {
	log "Running dry-run to verify configuration..."
	unattended-upgrade --dry-run --debug 2>&1 | tail -20 | tee -a "$LOG_FILE"
}

main() {
	log "=== Module: automatic updates ==="
	install_packages
	configure_updates
	dry_run
	ok "auto-updates configured"
}

main "$@"
