#!/bin/bash

# Script to configure Prometheus targets from .env file

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

if ! check_env_file; then
    exit 1
fi

# Load environment variables
load_env

# Set defaults if not set
API_HOST=${API_HOST:-your_api_host}
API_PORT=${API_PORT:-3000}
GATEWAY_HOST=${GATEWAY_HOST:-your_gateway_host}
GATEWAY_PORT=${GATEWAY_PORT:-3003}
NGINX_HOST=${NGINX_HOST:-your_nginx_host}
NGINX_PORT=${NGINX_PORT:-80}
PWA_API_HOST=${PWA_API_HOST:-your_pwa_api_host}
PWA_API_PORT=${PWA_API_PORT:-3002}
PROMETHEUS_API_KEY=${PROMETHEUS_API_KEY:-your_prometheus_api_key_here}

log_step "Configuring Prometheus Targets"

# Check if template exists
if [ ! -f "$SCRIPT_DIR/prometheus/prometheus.yml.template" ]; then
    log_warning "Template file not found. Creating from current prometheus.yml..."
    cp "$SCRIPT_DIR/prometheus/prometheus.yml" "$SCRIPT_DIR/prometheus/prometheus.yml.template"
fi

# Use envsubst if available, otherwise use sed
if command_exists envsubst; then
    log_info "Using envsubst to generate configuration..."
    envsubst < "$SCRIPT_DIR/prometheus/prometheus.yml.template" > "$SCRIPT_DIR/prometheus/prometheus.yml"
else
    log_info "Using sed to update configuration..."
    # Backup original
    cp "$SCRIPT_DIR/prometheus/prometheus.yml" "$SCRIPT_DIR/prometheus/prometheus.yml.bak"
    
    # Replace placeholders
    sed -i.bak "s|your_api_host:3000|${API_HOST}:${API_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|your_gateway_host:3003|${GATEWAY_HOST}:${GATEWAY_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|your_nginx_host:80|${NGINX_HOST}:${NGINX_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|your_pwa_api_host:3002|${PWA_API_HOST}:${PWA_API_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|your_prometheus_api_key_here|${PROMETHEUS_API_KEY}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    
    # Remove backup files
    rm -f "$SCRIPT_DIR/prometheus/prometheus.yml.bak"
fi

log_success "Prometheus configuration updated!"
echo ""
log_info "Current targets:"
echo "   - API: ${API_HOST}:${API_PORT}"
echo "   - Gateway: ${GATEWAY_HOST}:${GATEWAY_PORT}"
echo "   - Nginx: ${NGINX_HOST}:${NGINX_PORT}"
if [ "$PWA_API_HOST" != "your_pwa_api_host" ]; then
  echo "   - PWA API: ${PWA_API_HOST}:${PWA_API_PORT}"
fi
echo ""
log_info "Prometheus API Key configured: ${PROMETHEUS_API_KEY:0:10}..."
echo ""
log_info "To reload Prometheus configuration:"
echo "   curl -X POST http://localhost:9090/-/reload"
echo "   (or restart: make restart prometheus)"


