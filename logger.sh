#!/usr/bin/env bash

RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[0;33m';
NC='\033[0m';

LOG_FILE="/var/log/ubuntu-setup.log"

log() { echo -e "$(date '+%d.%m.%Y %H:%M:%S')	[INFO] $*" | tee -a "$LOG_FILE"; }
ok() { echo -e "${GREEN}[OK]${NC} 	$*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC}	$*" | tee -a "$LOG_FILE"; }
die() { echo -e "${RED}[ERROR]${NC}	$*" | tee -a "$LOG_FILE"; exit 1; }
