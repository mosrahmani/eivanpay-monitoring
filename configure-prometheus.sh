#!/bin/bash

# Script to configure Prometheus targets from .env file

set -e

# Get project root directory (this script is in the root)
# Set SCRIPT_DIR before sourcing common.sh so it uses the correct path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
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
PWA_API_HOST=${PWA_API_HOST:-your_pwa_api_host}
PWA_API_PORT=${PWA_API_PORT:-3002}
PROMETHEUS_API_KEY=${PROMETHEUS_API_KEY:-your_prometheus_api_key_here}
# Set defaults if not set
POSTGRES_EXPORTER_ENDPOINT=${POSTGRES_EXPORTER_ENDPOINT:-188.121.105.218:9187}
REDIS_EXPORTER_ENDPOINT=${REDIS_EXPORTER_ENDPOINT:-188.121.105.218:9121}

log_step "Configuring Prometheus Targets"

# Check if template exists
if [ ! -f "$SCRIPT_DIR/prometheus/prometheus.yml.template" ]; then
    log_warning "Template file not found. Creating from current prometheus.yml..."
    cp "$SCRIPT_DIR/prometheus/prometheus.yml" "$SCRIPT_DIR/prometheus/prometheus.yml.template"
fi

# Use envsubst if available, otherwise use sed
if command_exists envsubst; then
    log_info "Using envsubst to generate configuration from template..."
    # Export variables for envsubst
    export API_HOST API_PORT GATEWAY_HOST GATEWAY_PORT
    export PWA_API_HOST PWA_API_PORT PROMETHEUS_API_KEY
    export POSTGRES_EXPORTER_ENDPOINT REDIS_EXPORTER_ENDPOINT
    envsubst < "$SCRIPT_DIR/prometheus/prometheus.yml.template" > "$SCRIPT_DIR/prometheus/prometheus.yml"
else
    log_info "Using sed to generate configuration from template..."
    # Copy template to prometheus.yml
    cp "$SCRIPT_DIR/prometheus/prometheus.yml.template" "$SCRIPT_DIR/prometheus/prometheus.yml"
    
    # Replace environment variables in template
    sed -i.bak "s|\${API_HOST}|${API_HOST}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${API_PORT}|${API_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${GATEWAY_HOST}|${GATEWAY_HOST}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${GATEWAY_PORT}|${GATEWAY_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${PWA_API_HOST}|${PWA_API_HOST}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${PWA_API_PORT}|${PWA_API_PORT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${PROMETHEUS_API_KEY}|${PROMETHEUS_API_KEY}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${POSTGRES_EXPORTER_ENDPOINT}|${POSTGRES_EXPORTER_ENDPOINT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    sed -i.bak "s|\${REDIS_EXPORTER_ENDPOINT}|${REDIS_EXPORTER_ENDPOINT}|g" "$SCRIPT_DIR/prometheus/prometheus.yml"
    
    # Remove backup files
    rm -f "$SCRIPT_DIR/prometheus/prometheus.yml.bak"
fi

log_success "Prometheus configuration updated!"
echo ""
log_info "Current targets:"
echo "   - API: ${API_HOST}:${API_PORT}"
echo "   - Gateway: ${GATEWAY_HOST}:${GATEWAY_PORT}"
if [ "$PWA_API_HOST" != "your_pwa_api_host" ]; then
  echo "   - PWA API: ${PWA_API_HOST}:${PWA_API_PORT}"
fi
echo "   - PostgreSQL Exporter: ${POSTGRES_EXPORTER_ENDPOINT}"
echo "   - Redis Exporter: ${REDIS_EXPORTER_ENDPOINT}"
echo ""
log_info "Prometheus API Key configured: ${PROMETHEUS_API_KEY:0:10}..."
echo ""
log_info "To reload Prometheus configuration:"
echo "   curl -X POST http://localhost:9090/-/reload"
echo "   (or restart: docker compose restart prometheus)"


