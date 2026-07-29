#!/usr/bin/env bash

source "$(dirname "$0")/logger.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
		modules=(users ssh firewall fail2ban updates)
	fi

	check_ubuntu
	log "Ubuntu Setup started"

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
