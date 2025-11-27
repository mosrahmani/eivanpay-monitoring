#!/bin/bash

# Script to setup Docker secrets for production

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

print_header "Docker Secrets Setup"

# Check if Docker Swarm is initialized
if ! docker info | grep -q "Swarm: active"; then
    log_warning "Docker Swarm is not active. Initializing..."
    docker swarm init
    log_success "Docker Swarm initialized"
fi

echo ""
log_info "Creating Docker secrets..."
echo ""

# PostgreSQL Password
if [ -z "$POSTGRES_PASSWORD" ]; then
    read -sp "Enter PostgreSQL password: " POSTGRES_PASSWORD
    echo ""
fi
echo -n "$POSTGRES_PASSWORD" | docker secret create postgres_password - 2>/dev/null && \
    log_success "postgres_password secret created" || \
    log_warning "postgres_password secret already exists"

# Redis Password
if [ -z "$REDIS_PASSWORD" ]; then
    read -sp "Enter Redis password: " REDIS_PASSWORD
    echo ""
fi
echo -n "$REDIS_PASSWORD" | docker secret create redis_password - 2>/dev/null && \
    log_success "redis_password secret created" || \
    log_warning "redis_password secret already exists"

# Telegram Bot Token
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    read -sp "Enter Telegram Bot Token: " TELEGRAM_BOT_TOKEN
    echo ""
fi
echo -n "$TELEGRAM_BOT_TOKEN" | docker secret create telegram_bot_token - 2>/dev/null && \
    log_success "telegram_bot_token secret created" || \
    log_warning "telegram_bot_token secret already exists"

# Telegram Chat ID
if [ -z "$TELEGRAM_CHAT_ID" ]; then
    read -sp "Enter Telegram Chat ID: " TELEGRAM_CHAT_ID
    echo ""
fi
echo -n "$TELEGRAM_CHAT_ID" | docker secret create telegram_chat_id - 2>/dev/null && \
    log_success "telegram_chat_id secret created" || \
    log_warning "telegram_chat_id secret already exists"

# Grafana Admin Password
if [ -z "$GRAFANA_ADMIN_PASSWORD" ]; then
    read -sp "Enter Grafana Admin Password: " GRAFANA_ADMIN_PASSWORD
    echo ""
fi
echo -n "$GRAFANA_ADMIN_PASSWORD" | docker secret create grafana_admin_password - 2>/dev/null && \
    log_success "grafana_admin_password secret created" || \
    log_warning "grafana_admin_password secret already exists"

echo ""
print_header "✅ Secrets Setup Complete!"
log_info "Created secrets:"
docker secret ls | grep -E "(postgres_password|redis_password|telegram_|grafana_)" || echo "No secrets found"
echo ""
log_info "Next steps:"
echo "  1. Copy docker-compose.secrets.yml.example to docker-compose.secrets.yml"
echo "  2. Deploy with: make deploy"
echo ""
log_warning "Secrets are encrypted and stored in Docker Swarm"


