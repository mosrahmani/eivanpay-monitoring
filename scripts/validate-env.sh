#!/bin/bash

# Script to validate environment variables

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

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


