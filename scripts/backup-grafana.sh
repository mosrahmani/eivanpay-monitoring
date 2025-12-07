#!/bin/bash

# Script to backup Grafana dashboards and configuration

set -e

# Load common functions
# Set SCRIPT_DIR to project root (this script is in scripts/, so go up one level)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

BACKUP_DIR="$SCRIPT_DIR/backups/grafana"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/grafana_backup_${TIMESTAMP}"

log_info "Backing up Grafana configuration..."

# Create backup directory
mkdir -p "${BACKUP_PATH}"

# Backup dashboards
if [ -d "$SCRIPT_DIR/grafana/dashboards" ]; then
    cp -r "$SCRIPT_DIR/grafana/dashboards" "${BACKUP_PATH}/"
    log_success "Dashboards backed up"
fi

# Backup provisioning
if [ -d "$SCRIPT_DIR/grafana/provisioning" ]; then
    cp -r "$SCRIPT_DIR/grafana/provisioning" "${BACKUP_PATH}/"
    log_success "Provisioning configs backed up"
fi

# Create archive
cd "${BACKUP_DIR}" || exit 1
tar -czf "grafana_backup_${TIMESTAMP}.tar.gz" "grafana_backup_${TIMESTAMP}"
rm -rf "grafana_backup_${TIMESTAMP}"
cd - > /dev/null || exit 1

BACKUP_FILE="${BACKUP_DIR}/grafana_backup_${TIMESTAMP}.tar.gz"
log_success "Backup completed: ${BACKUP_FILE}"

# Keep only last 10 backups
cd "${BACKUP_DIR}" || exit 1
ls -t grafana_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
cd - > /dev/null || exit 1

log_info "Old backups cleaned (keeping last 10)"


