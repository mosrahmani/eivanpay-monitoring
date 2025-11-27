#!/bin/bash

# Constants for monitoring scripts

# Service URLs
readonly GRAFANA_URL="http://localhost:3000"
readonly PROMETHEUS_URL="http://localhost:9090"
readonly ALERTMANAGER_URL="http://localhost:9093"
readonly NODE_EXPORTER_URL="http://localhost:9100"
readonly CADVISOR_URL="http://localhost:8080"
readonly POSTGRES_EXPORTER_URL="http://localhost:9187"
readonly REDIS_EXPORTER_URL="http://localhost:9121"
readonly WEBHOOK_URL="http://localhost:8080"

# Health check endpoints
readonly GRAFANA_HEALTH="${GRAFANA_URL}/api/health"
readonly PROMETHEUS_HEALTH="${PROMETHEUS_URL}/-/healthy"
readonly ALERTMANAGER_HEALTH="${ALERTMANAGER_URL}/-/healthy"
readonly WEBHOOK_HEALTH="${WEBHOOK_URL}/health"

# Default values
readonly DEFAULT_GRAFANA_USER="admin"
readonly DEFAULT_GRAFANA_PASSWORD="admin"
readonly DEFAULT_DOMAIN="monitoring.example.com"

# Timeouts
readonly HEALTH_CHECK_TIMEOUT=10
readonly SERVICE_START_TIMEOUT=30

# Export constants
export GRAFANA_URL PROMETHEUS_URL ALERTMANAGER_URL
export GRAFANA_HEALTH PROMETHEUS_HEALTH ALERTMANAGER_HEALTH WEBHOOK_HEALTH
export DEFAULT_GRAFANA_USER DEFAULT_GRAFANA_PASSWORD DEFAULT_DOMAIN
export HEALTH_CHECK_TIMEOUT SERVICE_START_TIMEOUT







