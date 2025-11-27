#!/bin/bash

# Initialize script environment
# Source this at the beginning of scripts

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPT_DIR

# Source common functions
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/constants.sh" 2>/dev/null || true

# Set error handling
trap 'log_error "Script failed at line $LINENO"' ERR







