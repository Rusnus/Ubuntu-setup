#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/setup.log"

#Colors
RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[1;33m';
NC='\033[0m'

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*" | tee -a "$LOG_FILE"; }
ok() { echo -e "${GREEN}[OK]${NC}   $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC}   $*" | tee -a "$LOG_FILE"; }
die() { echo -e "${RED}[ERROR]${NC}   $*" | tee -a "$LOG_FILE"; exit 1; }

check_root() {
	[[ "$EUID" -eq 0 ]] || die "Run as root: sudo bash setup.sh"
}

check_ubuntu() {
	grep -qi ubuntu /etc/os-release || warn "Not Ubuntu - some steps may not work!"
	log "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2)"
}

usage() {

	echo "Usage: sudo bash setup.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "   --all          Run all modules (recommended for fresh server)"
	echo "   --users        Create admin user, disable root login"
	echo "   --ssh          Harden SHH configuration"
	echo "   --firewall     Configure ufw firewall"
	echo "   --fail2ban     Install and configure fail2ban"
	echo "   --updates      Enable automatic security updates"
	echo "   --hardening    Apply sysctl, limits, auditd hardening"
	echo "   --help         Show this message"
	echo ""
	echo "Example: sudo bash setup.sh --all"
}

main() {
	check_root
	check_ubuntu
	log "Ubuntu Setup started"

	local run_all=false
	local modules=()

	[[ $# -eq 0 ]] && { usage; exit 0; }

	for arg in "$@"; do
		case "$arg" in
			--all)		run_all=true ;;
			--users)	modules+=(users) ;;
			--ssh)		modules+=(ssh) ;;
			--firewall)	modules+=(firewall) ;;
			--fail2ban)	modules+=(fail2ban) ;;
			--updates)	modules+=(updates) ;;
			--hardening)	modules+=(hardening) ;;
			--help)		usage; exit 0 ;;
			*)		die "Unknown option: $arg. Use --help for usage"
		esac
	done

	if $run_all; then
		modules=(users ssh firewall fail2ban updates hardening)
	fi

	for module in "${modules[@]}"; do
		log "--- Running module: $module ---"
		bash "$SCRIPT_DIR/${module}.sh" || die "Module '$module' failed"
		ok "Module '$module' completed"
	done

	log "Setup complete. Review log: $LOG_FILE"
	echo ""
	echo -e "${GREEN}All done!${NC}"
}
main "$@"
