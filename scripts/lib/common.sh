#!/bin/bash

# Common functions and utilities for monitoring scripts
# Source this file in other scripts: source scripts/lib/common.sh

# Colors
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Script directory - point to project root
# If SCRIPT_DIR is already set (e.g., from configure-prometheus.sh), use it
# Otherwise, calculate from this file's location (scripts/lib/common.sh -> project root)
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
readonly SCRIPT_DIR

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker is running
check_docker() {
    if ! command_exists docker; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose is not installed. Please install it first."
        exit 1
    fi
}

# Get Docker Compose command
get_compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# Check if .env file exists
check_env_file() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        log_warning ".env file not found!"
        log_info "Creating .env from .env.example..."
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env" 2>/dev/null || {
            log_error ".env.example not found!"
            exit 1
        }
        log_warning "Please edit .env file with your configuration"
        return 1
    fi
    return 0
}

# Load environment variables safely
# This function safely loads .env file by disabling glob expansion
# to prevent special characters (like *, ?, etc.) from being interpreted
load_env() {
    if [ -f "$SCRIPT_DIR/.env" ]; then
        set -a
        # Disable glob expansion to prevent * and other special chars from being interpreted
        set -f
        # Source the .env file
        # shellcheck source=/dev/null
        source "$SCRIPT_DIR/.env"
        # Re-enable glob expansion
        set +f
        set +a
    fi
}

# Validate required environment variable
validate_env_var() {
    local var_name=$1
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ] || [[ "$var_value" == *"your_"* ]] || [[ "$var_value" == *"YOUR_"* ]]; then
        log_error "$var_name is not set or using default value"
        return 1
    fi
    return 0
}

# Wait for service to be healthy
wait_for_service() {
    local service=$1
    local url=$2
    local max_attempts=${3:-30}
    local attempt=0
    
    log_info "Waiting for $service to be ready..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -sf "$url" >/dev/null 2>&1; then
            log_success "$service is ready"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log_error "$service failed to become ready after $((max_attempts * 2)) seconds"
    return 1
}

# Check service health
check_service_health() {
    local service=$1
    local url=$2
    
    if curl -sf "$url" >/dev/null 2>&1; then
        log_success "$service is healthy"
        return 0
    else
        log_error "$service is not responding"
        return 1
    fi
}

# Print header
print_header() {
    local title=$1
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║$(printf "%*s" -50 "$title")║${NC}" | sed 's/ / /g'
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Confirm action
confirm() {
    local message=$1
    local default=${2:-"N"}
    
    if [ "$default" = "Y" ]; then
        local prompt="$message (Y/n): "
    else
        local prompt="$message (y/N): "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    elif [ -z "$REPLY" ] && [ "$default" = "Y" ]; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f log_info log_success log_warning log_error log_step
export -f command_exists check_docker check_docker_compose get_compose_cmd
export -f check_env_file load_env validate_env_var
export -f wait_for_service check_service_health print_header confirm







