# Eivan Pay Monitoring Stack - Production

پروژه مانیتورینگ حرفه‌ای و استاندارد برای سرویس‌های Eivan Pay با قابلیت ارسال الرت‌های مهم به تلگرام.

**این پروژه برای محیط Production طراحی شده است.**

## ✨ Features

- ✅ **Prometheus**: Metrics collection and storage
- ✅ **Grafana**: Professional dashboards and visualization
- ✅ **Alertmanager**: Alert management and routing
- ✅ **Telegram Integration**: Critical alerts sent to Telegram
- ✅ **Traefik Integration**: SSL/TLS and routing via Traefik reverse proxy
- ✅ **Docker Secrets**: Secure credential management
- ✅ **Node Exporter**: System monitoring
- ✅ **cAdvisor**: Container monitoring
- ✅ **PostgreSQL Exporter**: Database monitoring
- ✅ **Redis Exporter**: Cache monitoring
- ✅ **Production-Ready**: Security and stability prioritized

## 📋 Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+) or macOS
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **RAM**: Minimum 4GB (8GB recommended)
- **Disk Space**: Minimum 50GB free space (for Prometheus data retention)
- **CPU**: 2+ cores recommended
- **Network**: Ports 80 and 443 available

### Required Software

```bash
# Check Docker installation
docker --version        # Should be 20.10+
docker compose version  # Should be 2.0+

# Check other required tools
git --version          # For cloning repository
openssl version        # For SSL certificate management
```

### Installation of Prerequisites

**Ubuntu/Debian:**
```bash
# Update package list
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Install additional tools
sudo apt-get install -y git openssl curl wget

# Add user to docker group (to run without sudo)
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
```

**CentOS/RHEL:**
```bash
# Install Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install additional tools
sudo yum install -y git openssl curl wget

# Add user to docker group
sudo usermod -aG docker $USER
```

**macOS:**
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Docker Compose is included with Docker Desktop

# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install additional tools
brew install git openssl curl wget
```

### Network Requirements

- **Port 80 (HTTP)**: Must be open for HTTP to HTTPS redirect
- **Port 443 (HTTPS)**: Must be open for HTTPS access
- **Internal Network**: Services communicate via Docker network (no external ports needed)
- **Firewall**: Configure to allow ports 80 and 443

**Firewall Configuration (Ubuntu/Debian with UFW):**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
sudo ufw status
```

**Firewall Configuration (CentOS/RHEL with firewalld):**
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-services
```

### Access Requirements

- **Root or sudo access**: Required for SSL certificate setup and Basic Authentication
- **Domain name**: For HTTPS access (e.g., `monitoring.example.com`)
- **DNS access**: Domain must point to server IP address
- **Eivan Pay services**: Access to API and Gateway servers for metrics scraping
- **Telegram account**: Recommended for receiving alerts (optional but highly recommended)

## 🚀 Quick Start

### Prerequisites Check

Before starting, run this comprehensive check:

```bash
# Check Docker
echo "=== Docker Check ==="
docker --version  # Should be 20.10+
docker compose version  # Should be 2.0+
docker ps > /dev/null 2>&1 && echo "✅ Docker daemon is running" || echo "❌ Docker daemon is not running"

# Check disk space (minimum 50GB recommended)
echo ""
echo "=== Disk Space Check ==="
df -h . | tail -1
AVAILABLE=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 50 ] 2>/dev/null; then
    echo "✅ Sufficient disk space available"
else
    echo "⚠️  Low disk space - minimum 50GB recommended"
fi

# Check ports availability
echo ""
echo "=== Port Availability Check ==="
if sudo netstat -tulpn 2>/dev/null | grep -E ':(80|443)' > /dev/null; then
    echo "⚠️  Ports 80 or 443 are in use:"
    sudo netstat -tulpn | grep -E ':(80|443)'
else
    echo "✅ Ports 80 and 443 are available"
fi

# Check required commands
echo ""
echo "=== Required Commands Check ==="
for cmd in git openssl curl wget; do
    if command -v $cmd > /dev/null 2>&1; then
        echo "✅ $cmd is installed"
    else
        echo "❌ $cmd is not installed"
    fi
done

# Check user permissions
echo ""
echo "=== Permissions Check ==="
if groups | grep -q docker; then
    echo "✅ User is in docker group"
else
    echo "⚠️  User is not in docker group (may need sudo for docker commands)"
fi

# Check network connectivity
echo ""
echo "=== Network Check ==="
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet connectivity available"
else
    echo "⚠️  No internet connectivity"
fi
```

### Complete Production Setup (Recommended)

**Quick Setup (Interactive):**
```bash
# Run the complete setup script
make setup
```

This command interactively performs all steps:
1. Docker Secrets setup (optional)
2. Domain update
3. Environment validation
4. Service deployment

**What the setup script does:**
- Optionally configures Docker Secrets
- Updates domain name in configuration files
- Validates environment variables
- Deploys all services

**Note**: SSL/TLS and authentication are handled by Traefik reverse proxy. Ensure Traefik is configured with proper SSL certificates and middleware for authentication.

**After setup completes:**
- Services will be running
- Access URLs will be displayed
- You'll need to verify DNS points to your server
- Test alerts will be sent to Telegram (if configured)

### Detailed Step-by-Step Setup

#### Step 1: Clone and Prepare

```bash
# Clone repository
git clone <repository-url>
cd eivan-pay-monitoring

# Verify you're in the correct directory
pwd  # Should show: .../eivan-pay-monitoring

# Make all scripts executable
find scripts -name "*.sh" -type f -exec chmod +x {} \;
chmod +x configure-prometheus.sh

# Verify scripts are executable
ls -la scripts/**/*.sh | head -5
ls -la configure-prometheus.sh

# Create necessary directories (if they don't exist)
mkdir -p backups/grafana

# Set proper permissions
chmod 755 scripts
```

**Verify Directory Structure:**
```bash
# Check that all required directories exist
ls -la | grep -E "alertmanager|prometheus|grafana|scripts"
```

#### Step 2: Configure Environment Variables

```bash
# Copy environment template
cp .env.example .env

# Verify .env file was created
ls -la .env

# Edit .env file with your values
nano .env  # or use your preferred editor (vim, code, etc.)

# Set secure permissions on .env file
chmod 600 .env

# Verify .env is not tracked by git (should be in .gitignore)
git check-ignore .env && echo "✅ .env is properly ignored" || echo "⚠️  .env should be in .gitignore"
```

**Required variables to update in `.env`:**

```bash
# Database Configuration (REQUIRED)
POSTGRES_HOST=your_postgres_host          # e.g., postgres-server.internal
POSTGRES_PORT=5432
POSTGRES_USER=eivan_pay_user
POSTGRES_PASSWORD=your_secure_postgres_password  # ⚠️ Change this!
POSTGRES_DB=eivan_pay

# Redis Configuration (REQUIRED)
REDIS_HOST=your_redis_host                # e.g., redis-server.internal
REDIS_PORT=6379
REDIS_PASSWORD=your_secure_redis_password  # ⚠️ Change this!

# Telegram Bot Configuration (REQUIRED for alerts)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token  # Get from @BotFather
TELEGRAM_CHAT_ID=your_telegram_chat_id      # Your Telegram chat ID

# Grafana Configuration (REQUIRED)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_secure_grafana_password  # ⚠️ Change this! (min 32 chars)
GRAFANA_ROOT_URL=https://your-domain.com/grafana/    # ⚠️ Update with your domain

# Prometheus Configuration (REQUIRED)
PROMETHEUS_EXTERNAL_URL=https://your-domain.com/prometheus  # ⚠️ Update with your domain

# Alertmanager Configuration (REQUIRED)
ALERTMANAGER_EXTERNAL_URL=https://your-domain.com/alertmanager  # ⚠️ Update with your domain

# Application Service Hosts (REQUIRED for Prometheus scraping)
API_HOST=your_api_host                     # e.g., api-server.internal or IP
API_PORT=3000
GATEWAY_HOST=your_gateway_host             # e.g., gateway-server.internal or IP
GATEWAY_PORT=3003

# Prometheus API Key (REQUIRED for scraping application metrics)
# This key must match the one configured in your application .env files
# Minimum 32 characters recommended for security
PROMETHEUS_API_KEY=your_secure_prometheus_api_key_here_min_32_characters
```

**Important Notes:**
- Replace ALL `your_*` placeholders with actual values
- Use strong passwords (minimum 32 characters recommended)
- Domain URLs must match your actual domain name
- Service hosts can be IP addresses or internal DNS names
- SSL/TLS and authentication are handled by Traefik reverse proxy

#### Step 3: Update Domain Configuration

```bash
make setup-domain your-actual-domain.com
```

Replace `your-actual-domain.com` with your actual domain name.

This updates:
- Docker Compose external URLs
- Environment variables

**Manual Domain Update:**
```bash
# Update docker-compose.yml
sed -i 's|monitoring.example.com|your-domain.com|g' docker-compose.yml

# Update .env file
sed -i 's|monitoring.example.com|your-domain.com|g' .env
```

#### Step 4: Configure Prometheus Targets

```bash
make setup-prometheus
```

This generates `prometheus/prometheus.yml` from template using your `.env` variables.

**Verify targets are configured:**
```bash
# After deployment, check targets
make targets
```

#### Step 5: Configure Telegram Bot (Recommended)

```bash
make setup-telegram
```

This interactive script will:
1. Guide you through creating a Telegram bot via @BotFather
2. Help you get your chat ID
3. Test the connection
4. Update your `.env` file

**Manual Telegram Setup:**
1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow instructions
3. Copy the bot token
4. Start a chat with your bot and send any message
5. Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
6. Find your chat ID in the response
7. Add to `.env`:
   ```bash
   TELEGRAM_BOT_TOKEN=your_bot_token_here
   TELEGRAM_CHAT_ID=your_chat_id_here
   ```

#### Step 6: Configure Docker Secrets (Optional but Recommended)

```bash
make setup-secrets
```

This will:
1. Initialize Docker Swarm (if not already)
2. Create Docker secrets for sensitive credentials
3. Guide you through creating `docker-compose.secrets.yml`

**Manual Docker Secrets Setup:**
```bash
# Initialize Docker Swarm
docker swarm init

# Create secrets
echo "your_postgres_password" | docker secret create postgres_password -
echo "your_redis_password" | docker secret create redis_password -
echo "your_telegram_bot_token" | docker secret create telegram_bot_token -
echo "your_telegram_chat_id" | docker secret create telegram_chat_id -
echo "your_grafana_admin_password" | docker secret create grafana_admin_password -

# Copy secrets example
cp docker-compose.secrets.yml.example docker-compose.secrets.yml
```

#### Step 7: Validate Configuration

```bash
# Validate environment variables
make validate
```

This checks:
- All required environment variables are set
- No placeholder values remain (`your_*` placeholders)
- Domain configuration is correct

**Manual Validation:**
```bash
# Check .env file has all required variables
grep -E "POSTGRES_|REDIS_|TELEGRAM_|GRAFANA_|PROMETHEUS_|ALERTMANAGER_|API_HOST|GATEWAY_HOST" .env

# Verify no placeholder values remain
grep -E "your_|example\.com" .env && echo "⚠️  Found placeholder values!" || echo "✅ No placeholders found"
```

#### Step 8: Deploy Services

**Before deploying, verify:**
```bash
# Check Docker is running
docker ps

# Check disk space (minimum 50GB recommended)
df -h .

# Check ports are available
sudo netstat -tulpn | grep -E ':(80|443)' || echo "✅ Ports 80 and 443 are available"

# Verify .env file exists and has correct permissions
test -f .env && echo "✅ .env file exists" || echo "❌ .env file missing"
test -r .env && echo "✅ .env file is readable" || echo "❌ .env file not readable"
```

**Deploy:**
```bash
# Deploy using Makefile (recommended)
make deploy
```

**Or deploy manually:**
```bash
# With Docker Secrets (recommended for production)
docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d

# Without Docker Secrets (using .env)
docker compose -f docker-compose.yml up -d

# Verify services are starting
docker compose ps
```

**If deployment fails:**
```bash
# Check logs for errors
docker compose logs

# Check specific service logs
docker compose logs prometheus
docker compose logs grafana
docker compose logs alertmanager

# Verify configuration
docker compose config
```

#### Step 11: Verify Deployment

```bash
# Check service status
make status

# Run health check
make health

# Check Prometheus targets
make targets

# Test Telegram alerts
make test-alert

# Show access URLs
make show-urls
```

### Post-Deployment Verification

1. **Access Grafana**: `https://your-domain.com/grafana/`
   - Login with Basic Auth credentials
   - Verify dashboards are loaded
   - Check data sources are connected

2. **Access Prometheus**: `https://your-domain.com/prometheus/`
   - Login with Basic Auth credentials
   - Go to Status → Targets
   - Verify all targets are UP

3. **Access Alertmanager**: `https://your-domain.com/alertmanager/`
   - Login with Basic Auth credentials
   - Verify webhook receiver is configured

4. **Test Telegram Alerts**:
   ```bash
   make test-alert
   ```
   - Check your Telegram for the test message

5. **Verify Metrics Collection**:
   ```bash
   make targets
   make metrics
   ```

## 🛠️ Available Commands

### Service Management

```bash
make help          # Show all available commands
make start         # Start all services
make stop          # Stop all services
make restart       # Restart all services
make status        # Show service status
```

### Logs

```bash
make logs                    # Show all service logs (live)
make logs prometheus         # Show specific service logs
make logs-tail prometheus    # Show last 100 lines
```

### Monitoring & Health

```bash
make health          # Comprehensive health check
make health-quick     # Quick health check
make targets         # Show Prometheus targets status
make alerts          # Show active Prometheus alerts
make reload          # Reload Prometheus configuration
make rules           # Validate Prometheus alert rules
make metrics         # Show available metrics endpoints
```

### Access

```bash
make show-urls       # Show access URLs for all services
make show-domain     # Show configured domain
```

### Alerts

```bash
make setup-telegram  # Configure Telegram bot for alerts
make test-alert      # Send test alert to Telegram
```

### Maintenance

```bash
make backup          # Backup Grafana dashboards and configs
make update          # Update and rebuild services
make pull            # Pull latest Docker images
make rebuild         # Rebuild all Docker images
make clean           # Clean up resources (containers)
make clean-all       # Clean up everything (including volumes) - ⚠️ Destructive!
```

## 📊 Access URLs

**All services are accessible via Traefik reverse proxy with SSL/TLS:**

- **Grafana**: `https://your-domain.com/grafana/`
- **Prometheus**: `https://your-domain.com/prometheus/`
- **Alertmanager**: `https://your-domain.com/alertmanager/`

**Note**: Service ports are not publicly accessible and can only be accessed via Traefik. Authentication and SSL/TLS are handled by Traefik middleware.

## 🔒 Security

This project is designed with security as a priority:

### Container Security
- ✅ **Non-root users**: All services run as non-root
  - Prometheus: `user: "nobody"`
  - Grafana: `user: "472"`
  - Alertmanager: `user: "nobody"`
  - Telegram Webhook: `user: "webhook"`
- ✅ **Read-only filesystems**: Prometheus, Alertmanager, Webhook
- ✅ **Security options**: `no-new-privileges:true` on all services
- ✅ **Resource limits**: CPU and memory limits on all services
- ✅ **Version pinning**: All Docker images pinned to specific versions

### Network Security
- ✅ **No public ports**: Services accessible only via Traefik
- ✅ **Internal network**: All services in isolated `monitoring-network`
- ✅ **Exporters**: Only exposed internally, not publicly

### Authentication & Encryption
- ✅ **Authentication**: Handled via Traefik middleware (Basic Auth or other)
- ✅ **HTTPS only**: SSL/TLS termination via Traefik
- ✅ **Security headers**: Configured via Traefik middleware
- ✅ **Rate limiting**: Configured via Traefik middleware

### Credential Management
- ✅ **Environment variables**: Sensitive data in `.env` file
- ✅ **Docker Secrets**: Support for production secrets management
- ✅ **`.gitignore`**: All sensitive files excluded from version control

### Important Security Notes
- Never commit credentials to version control
- Use Docker Secrets for production
- Configure SSL/TLS via Traefik
- Configure authentication via Traefik middleware
- Configure firewall to limit access
- Use strong passwords (minimum 32 characters)
- Rotate passwords regularly

### Security Considerations

**cAdvisor Privileged Mode**: cAdvisor requires `privileged: true` for container metrics. This is acceptable because:
- Runs in isolated network
- Only exposes metrics endpoint internally
- For production, consider alternatives if needed

## 📈 Metrics

### Infrastructure Metrics

**Node Exporter**:
- `node_cpu_seconds_total`: CPU usage
- `node_memory_MemTotal_bytes`: Total memory
- `node_memory_MemAvailable_bytes`: Available memory
- `node_filesystem_size_bytes`: Disk size
- `node_filesystem_avail_bytes`: Available disk space
- `node_network_receive_bytes_total`: Network traffic in
- `node_network_transmit_bytes_total`: Network traffic out

**cAdvisor**:
- `container_cpu_usage_seconds_total`: Container CPU usage
- `container_memory_usage_bytes`: Container memory usage
- `container_network_receive_bytes_total`: Container network traffic

### Database Metrics

**PostgreSQL Exporter**:
- `pg_up`: PostgreSQL connection status
- `pg_stat_database_numbackends`: Active connections
- `pg_stat_database_xact_commit`: Committed transactions
- `pg_stat_database_xact_rollback`: Rolled back transactions
- `pg_database_size_bytes`: Database size
- `pg_stat_statements_mean_exec_time_seconds`: Average query execution time

### Cache Metrics

**Redis Exporter**:
- `redis_up`: Redis connection status
- `redis_connected_clients`: Connected clients
- `redis_memory_used_bytes`: Used memory
- `redis_keyspace_hits`: Keyspace hits
- `redis_keyspace_misses`: Keyspace misses
- `redis_commands_processed_total`: Processed commands

### Application Metrics

These metrics should be added to your NestJS application:

**HTTP/gRPC Metrics**:
- `http_requests_total`: Total HTTP requests (labels: `method`, `route`, `status`, `service`)
- `http_request_duration_seconds`: HTTP request duration (labels: `method`, `route`, `status`, `service`)
- `grpc_requests_total`: Total gRPC requests (labels: `method`, `status`, `service`)
- `grpc_request_duration_seconds`: gRPC request duration (labels: `method`, `status`, `service`)

**Business Metrics** (Critical):
- `eivan_pay_loan_requests_total`: Total loan requests (labels: `status`, `channel`)
- `eivan_pay_loan_requests_amount_total`: Total loan request amount (labels: `status`)
- `eivan_pay_loans_total`: Total established loans
- `eivan_pay_loans_total_amount`: Total loan amount
- `eivan_pay_purchases_total`: Total purchases (labels: `status`, `vendor`)
- `eivan_pay_purchases_amount_total`: Total purchase amount
- `eivan_pay_wallets_balance_total`: Total wallet balance
- `eivan_pay_settlements_total`: Total settlements (labels: `status`)

See `examples/nestjs-metrics-integration.ts` for complete implementation example.

## 🚨 Alerts

Alert rules are defined in `prometheus/rules/`:

- `alerts.yml` - Infrastructure and Business alerts
- `monitoring-stack.yml` - Monitoring stack alerts
- `webhook-alerts.yml` - Webhook service alerts

### Alert Severities

- **Critical**: Immediate notification (e.g., service down, high error rate)
- **Warning**: Grouped notifications (e.g., high latency, resource usage)
- **Info**: Informational alerts

### Configuring Telegram Alerts

```bash
make setup-telegram
```

This will guide you through:
1. Creating a Telegram bot via @BotFather
2. Getting your chat ID
3. Testing the connection

#### Proxy Support for Telegram (Required if Telegram is Filtered)

If Telegram API is blocked or filtered in your region, you can configure a proxy by adding the following to your `.env` file:

```bash
HTTP_PROXY=http://proxy.example.com:8080
HTTPS_PROXY=http://proxy.example.com:8080
```

**Supported Proxy Types:**

The webhook server supports the following proxy protocols:

1. **HTTP Proxy** - `http://proxy.example.com:8080`
   - Standard HTTP proxy using CONNECT method
   - Most common proxy type
   - Example: `HTTP_PROXY=http://proxy.example.com:8080`

2. **HTTPS Proxy** - `https://proxy.example.com:8080`
   - HTTPS proxy with TLS encryption
   - More secure than HTTP proxy
   - Example: `HTTPS_PROXY=https://proxy.example.com:8080`

**Configuration Notes:**
- The webhook server automatically uses `HTTP_PROXY` or `HTTPS_PROXY` environment variables if set
- If both are set, `HTTPS_PROXY` takes precedence
- Both HTTP and HTTPS requests to Telegram API will go through the proxy
- Leave these variables empty if no proxy is needed
- The proxy URL format: `http://host:port` or `https://host:port`
- Supports authentication: `http://username:password@proxy.example.com:8080`

**Not Currently Supported:**
- SOCKS4/SOCKS5 proxies (socks4://, socks5://)
- PAC (Proxy Auto-Config) files

After configuring the proxy, restart the telegram-webhook service:
```bash
make restart telegram-webhook
```

## 📝 Project Structure

```
eivan-pay-monitoring/
├── alertmanager/          # Alertmanager + Telegram webhook
│   ├── alertmanager.yml   # Main Alertmanager config
│   ├── templates/         # Alert templates
│   ├── webhook-server.py  # Telegram webhook server
│   └── Dockerfile         # Webhook server Dockerfile
│
├── prometheus/            # Prometheus config + rules
│   ├── prometheus.yml     # Main Prometheus config
│   └── rules/             # Alert rules
│       ├── alerts.yml
│       ├── monitoring-stack.yml
│       └── webhook-alerts.yml
│
├── grafana/              # Grafana dashboards
│   ├── provisioning/     # Auto-provisioning configs
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/       # Dashboard JSON files
│
├── scripts/               # Utility scripts
│   ├── lib/              # Common functions
│   │   ├── common.sh
│   │   ├── constants.sh
│   │   └── init.sh
│   └── production/       # Production setup scripts
│       ├── setup-production.sh
│       ├── setup-secrets.sh
│       └── update-domain.sh
│
├── examples/              # Code examples
│   └── nestjs-metrics-integration.ts
│
├── docker-compose.yml     # Main Docker Compose config
├── docker-compose.secrets.yml.example  # Docker Secrets example
├── .env.example          # Environment variables template
├── Makefile              # Management commands
└── README.md             # This file
```

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Required variables:
- `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `REDIS_HOST`, `REDIS_PASSWORD`
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`
- `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD`
- `GRAFANA_ROOT_URL`, `PROMETHEUS_EXTERNAL_URL`, `ALERTMANAGER_EXTERNAL_URL`
- `API_HOST`, `GATEWAY_HOST` (for Prometheus scraping)
- `PROMETHEUS_API_KEY` (for authenticating Prometheus scraping requests - min 32 chars)

### SSL/TLS and Authentication

SSL/TLS and authentication are handled by Traefik reverse proxy. Ensure Traefik is configured with:
- SSL certificates (Let's Encrypt or custom)
- Authentication middleware (Basic Auth or other)
- Proper routing rules for monitoring services

### Docker Secrets (Production)

For production, use Docker Secrets instead of environment variables:

```bash
make setup-secrets
```

This will:
1. Initialize Docker Swarm
2. Create secrets for passwords and tokens
3. Configure services to use secrets

## 🔧 Troubleshooting

### Services won't start

**Symptoms**: Services fail to start or exit immediately

**Solutions**:
```bash
# Check logs for errors
make logs [service-name]

# Check service status
make status

# Check health
make health

# Common issues:
# 1. Missing .env file
cp .env.example .env
# Edit .env with your values

# 2. Missing SSL certificates
make setup-ssl

# 3. Port conflicts
sudo netstat -tulpn | grep -E ':(80|443)'
# Stop conflicting services

# 4. Insufficient permissions
sudo chown -R $USER:$USER .
chmod 600 .env
```

### SSL/TLS or Authentication issues

**Symptoms**: SSL errors in browser, authentication not working, 401 errors

**Solutions**:
```bash
# SSL/TLS and authentication are handled by Traefik reverse proxy
# Verify Traefik is properly configured:

# Check Traefik logs (adjust path to your Traefik compose file)
docker compose -f ../traefik/docker-compose.yml logs traefik

# Verify services are accessible via Traefik
curl -I https://your-domain.com/grafana/api/health
curl -I https://your-domain.com/prometheus/-/healthy
curl -I https://your-domain.com/alertmanager/-/healthy

# Ensure Traefik has:
# - SSL certificates configured (Let's Encrypt or custom)
# - Authentication middleware configured (Basic Auth or other)
# - Proper routing rules for monitoring services
```


### Telegram not working

**Symptoms**: No alerts received, test alert fails

**Solutions**:
```bash
# Test connection
make test-alert

# Check bot token
echo $TELEGRAM_BOT_TOKEN

# Check chat ID
echo $TELEGRAM_CHAT_ID

# Test manually
curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
  -d "chat_id=$TELEGRAM_CHAT_ID" \
  -d "text=Test message"

# Reconfigure
make setup-telegram

# Check webhook service logs
make logs telegram-webhook

# Restart webhook service
make restart telegram-webhook
```

### Prometheus targets down

**Symptoms**: Targets show as DOWN in Prometheus UI

**Solutions**:
```bash
# Check targets status
make targets

# Verify targets are configured
grep -A 5 "job_name:" prometheus/prometheus.yml

# Check network connectivity
docker exec prometheus ping -c 3 your_api_host

# Verify service hosts in .env
grep -E "API_HOST|GATEWAY_HOST" .env

# Reconfigure Prometheus
make setup-prometheus

# Reload Prometheus config
make reload

# Check Prometheus logs
make logs prometheus
```

### Grafana not accessible

**Symptoms**: Can't access Grafana, 502/503 errors

**Solutions**:
```bash
# Check Grafana service
make status grafana

# Check Grafana logs
make logs grafana

# Verify Grafana is running
docker exec grafana wget -qO- http://localhost:3000/api/health

# Restart services
make restart grafana
```

### Domain not resolving

**Symptoms**: Can't access via domain, DNS errors

**Solutions**:
```bash
# Check DNS resolution
nslookup your-domain.com
dig your-domain.com

# Verify domain in configs
grep -r "your-domain.com" docker-compose.yml

# Update domain
make setup-domain your-domain.com

# Check firewall
sudo ufw status
# Allow ports 80 and 443
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### High memory/CPU usage

**Symptoms**: System slow, containers restarting

**Solutions**:
```bash
# Check resource usage
docker stats

# Check Prometheus data size
du -sh prometheus_data/

# Adjust resource limits in docker-compose.yml
# Reduce Prometheus retention if needed

# Clean old data
docker exec prometheus promtool tsdb clean --retention.time=30d
```

### Can't connect to database/Redis

**Symptoms**: Exporters show errors, metrics not collected

**Solutions**:
```bash
# Verify credentials in .env
grep -E "POSTGRES_|REDIS_" .env

# Test database connection
docker exec postgres-exporter wget -qO- http://localhost:9187/metrics | grep pg_up

# Test Redis connection
docker exec redis-exporter wget -qO- http://localhost:9121/metrics | grep redis_up

# Check network connectivity
docker exec postgres-exporter ping -c 3 $POSTGRES_HOST
docker exec redis-exporter ping -c 3 $REDIS_HOST

# Verify hosts are reachable from monitoring network
```

## 📋 Production Checklist

Before deploying to production, complete this checklist:

### 🔐 Security Configuration

- [ ] **Change all default passwords**
  - [ ] Grafana admin password set in `.env` (minimum 32 characters)
  - [ ] PostgreSQL password set in `.env`
  - [ ] Redis password set in `.env`
  - [ ] Nginx Basic Auth passwords created (run `make setup-auth`)

- [ ] **SSL Certificates**
  - [ ] SSL certificates obtained/generated
  - [ ] Certificates placed in `nginx/ssl/` directory
  - [ ] Certificate files have correct permissions:
    ```bash
    chmod 600 nginx/ssl/*.key
    chmod 644 nginx/ssl/*.crt
    ```
  - [ ] Test SSL: `openssl x509 -in nginx/ssl/monitoring.crt -text -noout`

- [ ] **Basic Authentication**
  - [ ] Nginx Basic Auth configured (run `make setup-auth`)
  - [ ] `.htpasswd` files created in `nginx/auth/`
  - [ ] Strong passwords used (minimum 16 characters)

- [ ] **Docker Secrets (Recommended)**
  - [ ] Docker Swarm initialized (run `make setup-secrets`)
  - [ ] All sensitive credentials stored as Docker secrets
  - [ ] `docker-compose.secrets.yml` created from example

### 🌐 Network & Domain Configuration

- [ ] **Domain Configuration**
  - [ ] Domain name updated (run `make setup-domain your-domain.com`)
  - [ ] DNS records point to server IP
  - [ ] Domain updated in:
    - [ ] `nginx/conf.d/*.conf` files
    - [ ] `docker-compose.yml` (external URLs)
    - [ ] `.env` file (GRAFANA_ROOT_URL, PROMETHEUS_EXTERNAL_URL, ALERTMANAGER_EXTERNAL_URL)

- [ ] **Firewall Configuration**
  - [ ] Port 80 (HTTP) open
  - [ ] Port 443 (HTTPS) open
  - [ ] Other ports blocked or restricted

- [ ] **Prometheus Targets**
  - [ ] API host configured (update `API_HOST` and `API_PORT` in `.env`)
  - [ ] Gateway host configured (update `GATEWAY_HOST` and `GATEWAY_PORT` in `.env`)
  - [ ] Nginx host configured (update `NGINX_HOST` and `NGINX_PORT` in `.env`)
  - [ ] Run `make setup-prometheus` to update Prometheus config
  - [ ] Verify targets are reachable: `make targets`

### 📝 Environment Variables

- [ ] **`.env` file configured**
  - [ ] Copy `.env.example` to `.env` completed
  - [ ] All `your_*` placeholders replaced with actual values
  - [ ] Database credentials configured
  - [ ] Redis credentials configured
  - [ ] Telegram bot configured (run `make setup-telegram`)
  - [ ] External URLs configured with your domain

- [ ] **Validate environment**
  - [ ] Run `make validate` - all checks pass

### 🚀 Deployment

- [ ] **Pre-deployment checks**
  - [ ] All services stopped (if upgrading)
  - [ ] Backup existing data (if upgrading)
  - [ ] Disk space sufficient (minimum 50GB free)

- [ ] **Deploy services**
  - [ ] Run `make setup` for complete setup OR
  - [ ] All individual setup steps completed
  - [ ] Run `make deploy`

- [ ] **Post-deployment verification**
  - [ ] Check service status: `make status` - all services running
  - [ ] Run health check: `make health` - all checks pass
  - [ ] Test access URLs: `make show-urls` - all accessible
  - [ ] Test Telegram alerts: `make test-alert` - message received
  - [ ] Verify Prometheus targets: `make targets` - all UP
  - [ ] Check for active alerts: `make alerts` - no critical alerts

### 🔍 Monitoring & Alerts

- [ ] **Grafana**
  - [ ] Access Grafana: `https://your-domain.com/grafana/`
  - [ ] Login with admin credentials successful
  - [ ] Dashboards are loaded
  - [ ] Data sources are connected

- [ ] **Prometheus**
  - [ ] Access Prometheus: `https://your-domain.com/prometheus/`
  - [ ] All targets are UP
  - [ ] Metrics are being collected

- [ ] **Alertmanager**
  - [ ] Access Alertmanager: `https://your-domain.com/alertmanager/`
  - [ ] Webhook receiver is configured
  - [ ] Alert routing verified

- [ ] **Telegram Integration**
  - [ ] Bot token configured
  - [ ] Chat ID configured
  - [ ] Test alert sent successfully
  - [ ] Alerts are received in Telegram

### 🛡️ Security Hardening

- [ ] **File Permissions**
  - [ ] `.env` file: `chmod 600 .env`
  - [ ] SSL keys: `chmod 600 nginx/ssl/*.key`
  - [ ] SSL certs: `chmod 644 nginx/ssl/*.crt`
  - [ ] Auth files: `chmod 644 nginx/auth/*.htpasswd`

- [ ] **Git Security**
  - [ ] Verify `.env` is in `.gitignore`
  - [ ] Verify SSL files are in `.gitignore`
  - [ ] Verify auth files are in `.gitignore`
  - [ ] No sensitive data committed to git

- [ ] **Container Security**
  - [ ] All services run as non-root users
  - [ ] Read-only filesystems where applicable
  - [ ] Resource limits configured
  - [ ] Security options enabled

### 📊 Maintenance Setup

- [ ] **Backup Strategy**
  - [ ] Grafana backup configured: `make backup`
  - [ ] Backup schedule planned
  - [ ] Backup location secured

- [ ] **Log Management**
  - [ ] Log rotation configured
  - [ ] Log retention policy defined

- [ ] **Update Strategy**
  - [ ] Update process documented
  - [ ] Rollback plan prepared

### ✅ Final Verification

- [ ] All services running: `make status`
- [ ] All health checks passing: `make health`
- [ ] No critical alerts: `make alerts`
- [ ] SSL certificate valid (not expired)
- [ ] Domain accessible via HTTPS
- [ ] Basic Auth working
- [ ] Telegram alerts working
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards functional

**See the Production Deployment section below for detailed checklist.**

## 📞 Support & Common Issues

### Getting Help

If you encounter issues:

1. **Check documentation**: Review this README and the Production Deployment section
2. **Run health check**: `make health` - shows overall system status
3. **Check logs**: `make logs [service-name]` - shows detailed error messages
4. **Review troubleshooting**: See troubleshooting section above
5. **Check service status**: `make status` - shows all services

### Common Setup Issues

**Issue**: "GRAFANA_ADMIN_PASSWORD not set"
- **Solution**: Set `GRAFANA_ADMIN_PASSWORD` in `.env` file

**Issue**: "Domain not updated"
- **Solution**: Run `make setup-domain your-domain.com`

**Issue**: "Prometheus targets are DOWN"
- **Solution**: Update `API_HOST`, `GATEWAY_HOST` in `.env` and run `make setup-prometheus`

**Issue**: "Telegram alerts not working"
- **Solution**: Run `make setup-telegram` and verify bot token/chat ID

### Quick Reference

```bash
# Most common commands
make help              # Show all commands
make setup             # Complete setup (interactive)
make deploy            # Deploy services
make status            # Check service status
make health            # Health check
make logs [service]    # View logs
make show-urls         # Show access URLs
make test-alert        # Test Telegram alerts
```

### Emergency Procedures

**All services down:**
```bash
make stop              # Stop all services
make logs              # Check logs for errors
# Fix issues
make start             # Start all services
```

**Need to reset everything:**
```bash
make stop
make clean-all         # ⚠️ WARNING: Deletes all data!
# Re-run setup
make setup
```


## 📋 Complete Setup Checklist

Before deploying to production, ensure you have completed:

### Initial Setup
- [ ] Prerequisites installed (Docker, Docker Compose, required tools)
- [ ] Repository cloned
- [ ] Scripts made executable (`chmod +x scripts/**/*.sh`)
- [ ] Directories created (`backups/grafana`)
- [ ] Permissions set correctly

### Configuration
- [ ] `.env` file created from `.env.example`
- [ ] All `your_*` placeholders replaced with actual values
- [ ] Strong passwords set (minimum 32 characters)
- [ ] Domain name configured
- [ ] Traefik configured with SSL certificates
- [ ] Traefik configured with authentication middleware
- [ ] Prometheus targets configured (`make setup-prometheus`)
- [ ] Telegram bot configured (`make setup-telegram`)
- [ ] Docker Secrets configured (optional but recommended)

### Pre-Deployment
- [ ] Environment validated (`make validate`)
- [ ] Disk space sufficient (minimum 50GB)
- [ ] Ports 80 and 443 available
- [ ] Firewall configured
- [ ] DNS records point to server IP

### Deployment
- [ ] Services deployed (`make deploy`)
- [ ] All services running (`make status`)
- [ ] Health checks passing (`make health`)
- [ ] Access URLs working
- [ ] Telegram alerts tested (`make test-alert`)

## 📋 Production Deployment Checklist

Before deploying to production, complete this checklist:

### 🔐 Security Configuration

- [ ] **Change all default passwords**
  - [ ] Grafana admin password (set `GRAFANA_ADMIN_PASSWORD` in `.env`)
  - [ ] PostgreSQL password (set `POSTGRES_PASSWORD` in `.env`)
  - [ ] Redis password (set `REDIS_PASSWORD` in `.env`)

- [ ] **Traefik Configuration**
  - [ ] SSL certificates configured in Traefik
  - [ ] Authentication middleware configured (Basic Auth or other)
  - [ ] Security headers configured via Traefik middleware
  - [ ] Rate limiting configured via Traefik middleware

- [ ] **Docker Secrets (Recommended)**
  - [ ] Docker Swarm initialized (run `make setup-secrets`)
  - [ ] All sensitive credentials stored as Docker secrets
  - [ ] `docker-compose.secrets.yml` created from example

### 🌐 Network & Domain Configuration

- [ ] **Domain Configuration**
  - [ ] Domain name updated (run `make setup-domain your-domain.com`)
  - [ ] DNS records point to server IP
  - [ ] Domain updated in:
    - [ ] `docker-compose.yml` (external URLs)
    - [ ] `.env` file (GRAFANA_ROOT_URL, PROMETHEUS_EXTERNAL_URL, ALERTMANAGER_EXTERNAL_URL)

- [ ] **Firewall Configuration**
  - [ ] Port 80 (HTTP) open
  - [ ] Port 443 (HTTPS) open
  - [ ] Other ports blocked or restricted

- [ ] **Prometheus Targets**
  - [ ] API host configured (update `API_HOST` and `API_PORT` in `.env`)
  - [ ] Gateway host configured (update `GATEWAY_HOST` and `GATEWAY_PORT` in `.env`)
  - [ ] Run `make setup-prometheus` to update Prometheus config
  - [ ] Verify targets are reachable: `make targets`

### 📝 Environment Variables

- [ ] **`.env` file configured**
  - [ ] Copy `.env.example` to `.env`
  - [ ] All `your_*` placeholders replaced with actual values
  - [ ] Database credentials configured
  - [ ] Redis credentials configured
  - [ ] Telegram bot configured (run `make setup-telegram`)
  - [ ] External URLs configured with your domain

- [ ] **Validate environment**
  - [ ] Run `make validate` to check all required variables

### 🚀 Deployment

- [ ] **Pre-deployment checks**
  - [ ] All services stopped (if upgrading)
  - [ ] Backup existing data (if upgrading)
  - [ ] Disk space sufficient (minimum 50GB free)

- [ ] **Deploy services**
  - [ ] Run `make setup` for complete setup OR
  - [ ] Run individual setup steps:
    - [ ] `make setup-secrets` (optional)
    - [ ] `make setup-domain your-domain.com`
    - [ ] `make setup-prometheus`
    - [ ] `make setup-telegram`
  - [ ] Run `make deploy`

- [ ] **Post-deployment verification**
  - [ ] Check service status: `make status`
  - [ ] Run health check: `make health`
  - [ ] Test access URLs: `make show-urls`
  - [ ] Test Telegram alerts: `make test-alert`
  - [ ] Verify Prometheus targets: `make targets`
  - [ ] Check for active alerts: `make alerts`

### 🔍 Monitoring & Alerts

- [ ] **Grafana**
  - [ ] Access Grafana: `https://your-domain.com/grafana/`
  - [ ] Login with admin credentials
  - [ ] Verify dashboards are loaded
  - [ ] Check data sources are connected

- [ ] **Prometheus**
  - [ ] Access Prometheus: `https://your-domain.com/prometheus/`
  - [ ] Verify all targets are UP
  - [ ] Check metrics are being collected

- [ ] **Alertmanager**
  - [ ] Access Alertmanager: `https://your-domain.com/alertmanager/`
  - [ ] Verify webhook receiver is configured
  - [ ] Test alert routing

- [ ] **Telegram Integration**
  - [ ] Bot token configured
  - [ ] Chat ID configured
  - [ ] Test alert sent successfully: `make test-alert`
  - [ ] Verify alerts are received in Telegram

### 🛡️ Security Hardening

- [ ] **File Permissions**
  - [ ] `.env` file: `chmod 600 .env`

- [ ] **Git Security**
  - [ ] Verify `.env` is in `.gitignore`
  - [ ] No sensitive data committed to git

- [ ] **Container Security**
  - [ ] All services run as non-root users
  - [ ] Read-only filesystems where applicable
  - [ ] Resource limits configured
  - [ ] Security options enabled (`no-new-privileges`)

### 📊 Maintenance Setup

- [ ] **Backup Strategy**
  - [ ] Grafana backup configured: `make backup`
  - [ ] Backup schedule planned
  - [ ] Backup location secured

- [ ] **Log Management**
  - [ ] Log rotation configured
  - [ ] Log retention policy defined
  - [ ] Log monitoring setup

- [ ] **Update Strategy**
  - [ ] Update process documented
  - [ ] Rollback plan prepared
  - [ ] Testing procedure defined

### ✅ Final Verification

- [ ] All services running: `make status`
- [ ] All health checks passing: `make health`
- [ ] No critical alerts: `make alerts`
- [ ] SSL certificate valid (not expired)
- [ ] Domain accessible via HTTPS
- [ ] Authentication working via Traefik
- [ ] Telegram alerts working
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards functional

### 🚨 Important Notes

1. **Never commit `.env` file** - It contains sensitive credentials
2. **Change default passwords** - Especially Grafana admin password
3. **Use Docker Secrets for production** - More secure than environment variables
4. **Keep SSL certificates updated** - Ensure Traefik has valid SSL certificates
5. **Monitor disk space** - Prometheus data grows over time
6. **Regular backups** - Backup Grafana dashboards and Prometheus data
7. **Test alerts** - Verify Telegram integration before relying on it

## 📄 License

This project is for internal use by Eivan Pay.

## 🙏 Acknowledgments

- Prometheus Community
- Grafana Labs
- Docker Community
