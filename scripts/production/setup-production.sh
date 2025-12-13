#!/bin/bash

# Complete Production Setup Script

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

print_header "Eivan Pay Monitoring - Production Setup"

# Step 1: Docker Secrets (Optional)
echo ""
log_step "Step 1: Docker Secrets Setup (Optional)"
if confirm "Do you want to use Docker Secrets?" "N"; then
    "$SCRIPT_DIR/scripts/production/setup-secrets.sh"
    USE_SECRETS=true
else
    USE_SECRETS=false
fi

# Step 2: Update domain in configs
echo ""
log_step "Step 2: Domain Configuration"
read -p "Enter your domain name [monitoring.example.com]: " DOMAIN
DOMAIN=${DOMAIN:-monitoring.example.com}

# Update docker-compose.yml with domain
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    sed -i.bak "s|monitoring.example.com|$DOMAIN|g" "$SCRIPT_DIR/docker-compose.yml"
    log_success "docker-compose.yml updated with domain"
fi

# Cleanup backup files
find "$SCRIPT_DIR" -name "*.bak" -type f -delete 2>/dev/null || true

# Step 3: Deploy
echo ""
log_step "Step 3: Deploy Services"
if confirm "Ready to deploy?" "N"; then
    cd "$SCRIPT_DIR"
    COMPOSE_CMD=$(get_compose_cmd)
    
    if [ "$USE_SECRETS" = true ] && [ -f "$SCRIPT_DIR/docker-compose.secrets.yml" ]; then
        log_info "Deploying with Docker Secrets..."
        $COMPOSE_CMD -f docker-compose.yml -f docker-compose.secrets.yml up -d
    else
        log_info "Deploying with environment variables..."
        $COMPOSE_CMD -f docker-compose.yml up -d
    fi
    
    echo ""
    print_header "✅ Production Deployment Complete!"
    log_info "Access URLs:"
    echo "  - Grafana:      https://$DOMAIN/grafana/"
    echo "  - Prometheus:   https://$DOMAIN/prometheus/"
    echo "  - Alertmanager: https://$DOMAIN/alertmanager/"
    echo ""
    log_warning "Make sure your DNS points to this server!"
else
    log_info "Deployment cancelled. Run manually when ready."
fi
