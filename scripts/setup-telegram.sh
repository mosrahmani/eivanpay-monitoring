#!/bin/bash

# Script to setup Telegram bot for alerts
# This script helps you configure Telegram bot for Alertmanager

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

print_header "Telegram Bot Setup for Eivan Pay Alerts"

# Check if .env file exists
if ! check_env_file; then
    if ! confirm "Continue after editing .env file?" "N"; then
        log_info "Setup cancelled"
        exit 0
    fi
fi

# Load environment
load_env

log_info "Setting up Telegram Bot for Alerts"
echo ""
log_info "Follow these steps to configure Telegram alerts:"
echo ""
log_step "Step 1: Create a Telegram Bot"
echo "  1. Open Telegram and search for @BotFather"
echo "  2. Send /newbot command"
echo "  3. Follow the instructions to create your bot"
echo "  4. Copy the bot token (looks like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
echo ""
read -p "Enter your Telegram Bot Token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    log_error "Bot token is required!"
    exit 1
fi

echo ""
log_step "Step 2: Get Chat ID"
echo "  1. Start a chat with your bot (search for your bot username)"
echo "  2. Send any message to your bot (e.g., /start)"
echo "  3. Wait a moment..."
echo ""
read -p "Press Enter after sending a message to your bot..."

echo ""
log_info "Fetching chat ID..."
CHAT_ID=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | grep -o '"chat":{"id":[0-9]*' | head -1 | grep -o '[0-9]*$')

if [ -z "$CHAT_ID" ]; then
    log_error "Could not get chat ID. Please try:"
    echo "  1. Make sure you sent a message to your bot"
    echo "  2. Visit: https://api.telegram.org/bot${BOT_TOKEN}/getUpdates"
    echo "  3. Find 'chat':{'id':123456789} in the response"
    echo "  4. Enter the ID manually"
    echo ""
    read -p "Enter your Chat ID manually: " CHAT_ID
fi

if [ -z "$CHAT_ID" ]; then
    log_error "Chat ID is required!"
    exit 1
fi

echo ""
log_success "Chat ID found: ${CHAT_ID}"
echo ""

# Update .env file
cd "$SCRIPT_DIR/.."
if grep -q "TELEGRAM_BOT_TOKEN=" .env; then
    sed -i.bak "s|TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=${BOT_TOKEN}|g" .env
else
    echo "TELEGRAM_BOT_TOKEN=${BOT_TOKEN}" >> .env
fi

if grep -q "TELEGRAM_CHAT_ID=" .env; then
    sed -i.bak "s|TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=${CHAT_ID}|g" .env
else
    echo "TELEGRAM_CHAT_ID=${CHAT_ID}" >> .env
fi

# Remove backup file
rm -f .env.bak

log_success "Telegram configuration updated in .env file"
echo ""
log_info "Testing Telegram connection..."

# Test bot connection
TEST_RESULT=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getMe")
if echo "$TEST_RESULT" | grep -q '"ok":true'; then
    log_success "Bot connection successful!"
    
    # Send test message
    TEST_MSG="✅ Eivan Pay Monitoring Alert System is configured successfully!
    
This bot will send you alerts when issues are detected in your system.
    
Test message sent at: $(date)"
    
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${TEST_MSG}" \
        -d "parse_mode=HTML" > /dev/null
    
    log_success "Test message sent to your Telegram!"
else
    log_error "Bot connection failed. Please check your bot token."
    exit 1
fi

echo ""
print_header "✅ Setup Completed Successfully!"
log_info "Next steps:"
echo "  1. Restart Alertmanager: make restart alertmanager"
echo "  2. Check Alertmanager status: make status"
echo "  3. Test alerts by triggering a test alert in Prometheus"
echo ""
log_warning "Note: Critical alerts will be sent immediately to Telegram"
log_warning "Warning alerts will be grouped and sent every 6 hours"


