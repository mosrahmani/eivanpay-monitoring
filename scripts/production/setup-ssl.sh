#!/bin/bash

# Script to setup SSL certificates for Nginx

set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

print_header "SSL Certificate Setup"

# Create SSL directory
mkdir -p "$SCRIPT_DIR/nginx/ssl"

log_info "SSL Certificate Setup Options:"
echo "  1. Use existing certificates"
echo "  2. Generate self-signed certificate (for testing)"
echo "  3. Use Let's Encrypt (certbot)"
echo ""
read -p "Choose option (1/2/3) [1]: " OPTION
OPTION=${OPTION:-1}

case $OPTION in
    1)
        echo ""
        log_info "Using existing certificates..."
        read -p "Enter path to certificate file (.crt): " CERT_PATH
        read -p "Enter path to private key file (.key): " KEY_PATH
        
        if [ ! -f "$CERT_PATH" ] || [ ! -f "$KEY_PATH" ]; then
            log_error "Certificate files not found!"
            exit 1
        fi
        
        cp "$CERT_PATH" "$SCRIPT_DIR/nginx/ssl/monitoring.crt"
        cp "$KEY_PATH" "$SCRIPT_DIR/nginx/ssl/monitoring.key"
        chmod 600 "$SCRIPT_DIR/nginx/ssl/monitoring.key"
        chmod 644 "$SCRIPT_DIR/nginx/ssl/monitoring.crt"
        
        log_success "Certificates copied"
        ;;
    2)
        echo ""
        log_info "Generating self-signed certificate..."
        read -p "Enter domain name [monitoring.example.com]: " DOMAIN
        DOMAIN=${DOMAIN:-monitoring.example.com}
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SCRIPT_DIR/nginx/ssl/monitoring.key" \
            -out "$SCRIPT_DIR/nginx/ssl/monitoring.crt" \
            -subj "/C=IR/ST=Tehran/L=Tehran/O=Eivan Pay/OU=IT/CN=$DOMAIN"
        
        chmod 600 "$SCRIPT_DIR/nginx/ssl/monitoring.key"
        chmod 644 "$SCRIPT_DIR/nginx/ssl/monitoring.crt"
        
        log_success "Self-signed certificate generated"
        log_warning "Self-signed certificates are for testing only!"
        ;;
    3)
        echo ""
        log_info "Setting up Let's Encrypt..."
        read -p "Enter domain name: " DOMAIN
        read -p "Enter email for Let's Encrypt: " EMAIL
        
        if ! command_exists certbot; then
            log_warning "Installing certbot..."
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y certbot
            elif command_exists yum; then
                sudo yum install -y certbot
            else
                log_error "Please install certbot manually"
                exit 1
            fi
        fi
        
        # Generate certificate
        sudo certbot certonly --standalone -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive
        
        # Copy certificates
        sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SCRIPT_DIR/nginx/ssl/monitoring.crt"
        sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SCRIPT_DIR/nginx/ssl/monitoring.key"
        sudo chown $USER:$USER "$SCRIPT_DIR/nginx/ssl/monitoring."*
        chmod 600 "$SCRIPT_DIR/nginx/ssl/monitoring.key"
        chmod 644 "$SCRIPT_DIR/nginx/ssl/monitoring.crt"
        
        log_success "Let's Encrypt certificate obtained"
        log_warning "Remember to renew certificates before expiration!"
        ;;
    *)
        log_error "Invalid option!"
        exit 1
        ;;
esac

echo ""
print_header "✅ SSL Setup Complete!"
log_info "Certificate files:"
echo "  - nginx/ssl/monitoring.crt"
echo "  - nginx/ssl/monitoring.key"
echo ""
log_warning "Keep private key secure and do not commit to git!"
