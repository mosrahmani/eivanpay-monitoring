#!/bin/bash

# Script to setup Basic Authentication for Nginx

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

print_header "Nginx Basic Authentication Setup"

# Check if htpasswd is available
if ! command_exists htpasswd; then
    log_warning "htpasswd not found. Installing apache2-utils..."
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y apache2-utils
    elif command_exists yum; then
        sudo yum install -y httpd-tools
    elif command_exists apk; then
        sudo apk add --no-cache apache2-utils
    else
        log_error "Cannot install htpasswd. Please install apache2-utils manually."
        exit 1
    fi
fi

# Create auth directory
mkdir -p "$SCRIPT_DIR/nginx/auth"

# Setup Grafana auth
log_step "Setting up Grafana authentication"
read -p "Enter Grafana username [admin]: " GRAFANA_USER
GRAFANA_USER=${GRAFANA_USER:-admin}
htpasswd -c "$SCRIPT_DIR/nginx/auth/grafana.htpasswd" "$GRAFANA_USER"
log_success "Grafana authentication configured"

# Setup Prometheus auth
echo ""
log_step "Setting up Prometheus authentication"
read -p "Enter Prometheus username [prometheus]: " PROM_USER
PROM_USER=${PROM_USER:-prometheus}
htpasswd -c "$SCRIPT_DIR/nginx/auth/prometheus.htpasswd" "$PROM_USER"
log_success "Prometheus authentication configured"

# Setup Alertmanager auth
echo ""
log_step "Setting up Alertmanager authentication"
read -p "Enter Alertmanager username [alertmanager]: " ALERT_USER
ALERT_USER=${ALERT_USER:-alertmanager}
htpasswd -c "$SCRIPT_DIR/nginx/auth/alertmanager.htpasswd" "$ALERT_USER"
log_success "Alertmanager authentication configured"

# Set permissions (644 so nginx can read them)
chmod 644 "$SCRIPT_DIR/nginx/auth"/*.htpasswd
chown $(whoami):$(whoami) "$SCRIPT_DIR/nginx/auth"/*.htpasswd 2>/dev/null || true

echo ""
print_header "✅ Authentication Setup Complete!"
log_info "Authentication files created:"
echo "  - nginx/auth/grafana.htpasswd"
echo "  - nginx/auth/prometheus.htpasswd"
echo "  - nginx/auth/alertmanager.htpasswd"
echo ""
log_warning "Keep these files secure and do not commit them to git!"
