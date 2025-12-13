#!/bin/bash

# Script to update domain name in all configuration files

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

if [ -z "$1" ]; then
    log_error "Usage: $0 <domain-name>"
    echo "Example: $0 monitoring.eivanpay.com"
    exit 1
fi

DOMAIN=$1
OLD_DOMAIN="monitoring.example.com"

log_step "Updating Domain Configuration"
log_info "Updating domain from '$OLD_DOMAIN' to '$DOMAIN'..."

# Update docker-compose.yml
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    sed -i.bak "s|$OLD_DOMAIN|$DOMAIN|g" "$SCRIPT_DIR/docker-compose.yml"
    log_success "docker-compose.yml updated"
fi

# Cleanup backup files
find "$SCRIPT_DIR" -name "*.bak" -type f -delete 2>/dev/null || true

echo ""
log_success "Domain updated to: $DOMAIN"
echo ""
log_warning "Don't forget to:"
echo "  1. Update DNS records to point to this server"
echo "  2. Configure Traefik with SSL certificates if needed"
echo "  3. Restart services: make deploy"


