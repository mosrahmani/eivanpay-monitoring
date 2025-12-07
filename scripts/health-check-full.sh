#!/bin/bash

# Comprehensive health check script for monitoring stack

set -e

# Load common functions
# Set SCRIPT_DIR to project root (this script is in scripts/, so go up one level)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/constants.sh"

print_header "Eivan Pay Monitoring Stack - Health Check"

ERRORS=0
WARNINGS=0

# Check Docker
if ! check_docker; then
    ERRORS=$((ERRORS + 1))
fi

# Check Docker Compose
if ! check_docker_compose; then
    ERRORS=$((ERRORS + 1))
fi

echo ""
log_info "Checking services..."

# Check services
check_service_health "Prometheus" "$PROMETHEUS_HEALTH" || ERRORS=$((ERRORS + 1))
check_service_health "Grafana" "$GRAFANA_HEALTH" || ERRORS=$((ERRORS + 1))
check_service_health "Alertmanager" "$ALERTMANAGER_HEALTH" || ERRORS=$((ERRORS + 1))
check_service_health "Node Exporter" "${NODE_EXPORTER_URL}/metrics" || WARNINGS=$((WARNINGS + 1))
check_service_health "cAdvisor" "${CADVISOR_URL}/healthz" || WARNINGS=$((WARNINGS + 1))
check_service_health "PostgreSQL Exporter" "${POSTGRES_EXPORTER_URL}/metrics" || WARNINGS=$((WARNINGS + 1))
check_service_health "Redis Exporter" "${REDIS_EXPORTER_URL}/metrics" || WARNINGS=$((WARNINGS + 1))
check_service_health "Telegram Webhook" "$WEBHOOK_HEALTH" || WARNINGS=$((WARNINGS + 1))

echo ""
log_info "Checking Prometheus targets..."

# Check Prometheus targets
TARGETS=$(curl -s "${PROMETHEUS_URL}/api/v1/targets" 2>/dev/null | grep -o '"health":"[^"]*"' | grep -v "up" | wc -l || echo "0")
if [ "$TARGETS" -gt 0 ]; then
    log_warning "${TARGETS} target(s) are down"
    WARNINGS=$((WARNINGS + TARGETS))
else
    log_success "All Prometheus targets are up"
fi

echo ""
log_info "Checking active alerts..."

# Check active alerts
ALERTS=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts" 2>/dev/null | grep -o '"state":"firing"' | wc -l || echo "0")
if [ "$ALERTS" -gt 0 ]; then
    log_warning "${ALERTS} alert(s) are firing"
    WARNINGS=$((WARNINGS + ALERTS))
else
    log_success "No active alerts"
fi

echo ""
log_info "Checking disk space..."

# Check disk space
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_error "Disk usage is ${DISK_USAGE}% (critical)"
    ERRORS=$((ERRORS + 1))
elif [ "$DISK_USAGE" -gt 80 ]; then
    log_warning "Disk usage is ${DISK_USAGE}% (warning)"
    WARNINGS=$((WARNINGS + 1))
else
    log_success "Disk usage is ${DISK_USAGE}%"
fi

echo ""
log_info "Checking memory..."

# Check memory (if available)
if command_exists free; then
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
    if [ "$MEM_USAGE" -gt 90 ]; then
        log_error "Memory usage is ${MEM_USAGE}% (critical)"
        ERRORS=$((ERRORS + 1))
    elif [ "$MEM_USAGE" -gt 80 ]; then
        log_warning "Memory usage is ${MEM_USAGE}% (warning)"
        WARNINGS=$((WARNINGS + 1))
    else
        log_success "Memory usage is ${MEM_USAGE}%"
    fi
fi

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_header "✅ All checks passed!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    print_header "⚠ Completed with ${WARNINGS} warning(s)"
    exit 0
else
    print_header "❌ Failed with ${ERRORS} error(s) and ${WARNINGS} warning(s)"
    exit 1
fi


