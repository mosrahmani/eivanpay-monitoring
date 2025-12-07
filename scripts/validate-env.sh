#!/bin/bash

# Script to validate environment variables

set -e

# Load common functions
# Set SCRIPT_DIR to project root (this script is in scripts/, so go up one level)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

log_step "Validating Environment Variables"

ERRORS=0
WARNINGS=0

# Check if .env exists
if ! check_env_file; then
    exit 1
fi

# Load environment variables
load_env

# Required variables
REQUIRED_VARS=(
    "POSTGRES_HOST"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "POSTGRES_DB"
    "REDIS_HOST"
    "REDIS_PASSWORD"
)

# Check required variables
for var in "${REQUIRED_VARS[@]}"; do
    if validate_env_var "$var"; then
        log_success "$var is set"
    else
        ERRORS=$((ERRORS + 1))
    fi
done

# Optional but recommended
OPTIONAL_VARS=(
    "TELEGRAM_BOT_TOKEN"
    "TELEGRAM_CHAT_ID"
    "API_HOST"
    "GATEWAY_HOST"
    "PROMETHEUS_API_KEY"
)

echo ""
log_info "Optional variables:"
for var in "${OPTIONAL_VARS[@]}"; do
    if validate_env_var "$var"; then
        log_success "$var is set"
    else
        log_warning "$var is not set (optional but recommended)"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Validate Telegram if set
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    echo ""
    log_info "Testing Telegram connection..."
    TEST_RESULT=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" 2>/dev/null)
    if echo "$TEST_RESULT" | grep -q '"ok":true'; then
        log_success "Telegram bot connection successful"
    else
        log_error "Telegram bot connection failed"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Validate PROMETHEUS_API_KEY if API scraping is configured
if [ -n "$API_HOST" ] && [ "$API_HOST" != "your_api_host" ]; then
    echo ""
    if [ -z "$PROMETHEUS_API_KEY" ] || [[ "$PROMETHEUS_API_KEY" == *"your_"* ]] || [[ "$PROMETHEUS_API_KEY" == *"YOUR_"* ]]; then
        log_warning "PROMETHEUS_API_KEY is not set or using default value"
        log_info "This is required if your API endpoints require authentication for metrics scraping"
        WARNINGS=$((WARNINGS + 1))
    elif [ ${#PROMETHEUS_API_KEY} -lt 32 ]; then
        log_warning "PROMETHEUS_API_KEY is less than 32 characters (recommended minimum for security)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "PROMETHEUS_API_KEY is configured (${#PROMETHEUS_API_KEY} characters)"
    fi
fi

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_success "All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    log_warning "Validation completed with ${WARNINGS} warning(s)"
    exit 0
else
    log_error "Validation failed with ${ERRORS} error(s)"
    exit 1
fi


