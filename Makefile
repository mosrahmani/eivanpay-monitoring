# Eivan Pay Monitoring Stack - Production Makefile
# Management commands for Production Monitoring Stack

# Configuration
COMPOSE_FILE ?= docker-compose.yml
COMPOSE_SECRETS_FILE ?= docker-compose.secrets.yml
COMPOSE_CMD = docker compose
MONITORING_SERVICES = prometheus grafana alertmanager nginx node-exporter cadvisor postgres-exporter redis-exporter telegram-webhook

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Service argument handling
SERVICE = $(word 2,$(MAKECMDGOALS))
%:
	@:

.PHONY: help setup deploy manage monitor maintain

.DEFAULT_GOAL := help

# ============================================================================
# HELP
# ============================================================================

help: ## Show complete command help
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║    Eivan Pay Monitoring Stack - Production Management        ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📦 Initial Setup:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Setup' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🚀 Deployment:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Deploy' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🔄 Service Management:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Service' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)📋 Logs:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Log' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🏥 Monitoring & Health:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Monitor|Health' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🌐 Access:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Access|URL' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🚨 Alerts & Notifications:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Alert|Telegram' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🛠️  Maintenance:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##.*Maintain|Backup|Clean|Update' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ============================================================================
# SETUP - Initial Setup
# ============================================================================

setup: ## Complete production setup (SSL, Auth, Secrets, Domain, Deploy) - Setup
	@chmod +x scripts/production/setup-production.sh 2>/dev/null || true
	@./scripts/production/setup-production.sh

setup-ssl: ## Configure SSL certificates - Setup
	@chmod +x scripts/production/setup-ssl.sh 2>/dev/null || true
	@./scripts/production/setup-ssl.sh

setup-auth: ## Configure Nginx Basic Authentication - Setup
	@chmod +x scripts/production/setup-nginx-auth.sh 2>/dev/null || true
	@./scripts/production/setup-nginx-auth.sh

setup-secrets: ## Configure Docker Secrets - Setup
	@chmod +x scripts/production/setup-secrets.sh 2>/dev/null || true
	@./scripts/production/setup-secrets.sh

setup-domain: ## Update domain in configuration files - Setup
	@if [ -z "$(SERVICE)" ] || [ "$(SERVICE)" = "setup-domain" ]; then \
		echo "$(RED)Error: Domain name required. Example: make setup-domain monitoring.example.com$(NC)"; \
		exit 1; \
	fi
	@chmod +x scripts/production/update-domain.sh 2>/dev/null || true
	@./scripts/production/update-domain.sh $(SERVICE)

setup-telegram: ## Configure Telegram bot for alerts - Setup
	@chmod +x scripts/setup-telegram.sh 2>/dev/null || true
	@./scripts/setup-telegram.sh

setup-prometheus: ## Configure Prometheus targets from .env - Setup
	@echo "$(BLUE)Configuring Prometheus targets...$(NC)"
	@chmod +x configure-prometheus.sh 2>/dev/null || true
	@./configure-prometheus.sh

validate: ## Validate environment variables - Setup
	@chmod +x scripts/validate-env.sh 2>/dev/null || true
	@./scripts/validate-env.sh

# ============================================================================
# DEPLOY - Deployment
# ============================================================================

deploy: ## Deploy production services - Deploy
	@if [ -f $(COMPOSE_SECRETS_FILE) ]; then \
		echo "$(BLUE)Deploying with Docker Secrets...$(NC)"; \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE) -f $(COMPOSE_SECRETS_FILE) up -d; \
	else \
		echo "$(BLUE)Deploying with environment variables...$(NC)"; \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE) up -d; \
	fi
	@echo "$(GREEN)✅ Production services deployed!$(NC)"
	@echo ""
	@$(MAKE) show-urls

# ============================================================================
# SERVICE MANAGEMENT - Service Management
# ============================================================================

start: ## Start all services or specific service - Service
	@if [ -n "$(SERVICE)" ] && [ "$(SERVICE)" != "start" ]; then \
		echo "$(BLUE)Starting $(SERVICE) service...$(NC)"; \
		$(COMPOSE_CMD) up -d $(SERVICE); \
		echo "$(GREEN)✅ $(SERVICE) service started!$(NC)"; \
	else \
		echo "$(BLUE)Starting monitoring services...$(NC)"; \
		$(COMPOSE_CMD) up -d; \
		echo "$(GREEN)✅ Services started!$(NC)"; \
		echo "$(BLUE)Check status: make status$(NC)"; \
	fi

stop: ## Stop all services or specific service - Service
	@if [ -n "$(SERVICE)" ] && [ "$(SERVICE)" != "stop" ]; then \
		echo "$(BLUE)Stopping $(SERVICE) service...$(NC)"; \
		$(COMPOSE_CMD) stop $(SERVICE); \
		echo "$(GREEN)✅ $(SERVICE) service stopped!$(NC)"; \
	else \
		echo "$(BLUE)Stopping monitoring services...$(NC)"; \
		$(COMPOSE_CMD) down; \
		echo "$(GREEN)✅ Services stopped!$(NC)"; \
	fi

restart: ## Restart all services or specific service - Service
	@if [ -n "$(SERVICE)" ] && [ "$(SERVICE)" != "restart" ]; then \
		echo "$(BLUE)Restarting $(SERVICE) service...$(NC)"; \
		$(COMPOSE_CMD) restart $(SERVICE); \
		echo "$(GREEN)✅ $(SERVICE) service restarted!$(NC)"; \
	else \
		echo "$(BLUE)Restarting monitoring services...$(NC)"; \
		$(COMPOSE_CMD) restart; \
		echo "$(GREEN)✅ Services restarted!$(NC)"; \
	fi

status: ## Show service status - Service
	@echo "$(BLUE)Monitoring Stack Service Status:$(NC)"
	@$(COMPOSE_CMD) ps

# ============================================================================
# LOGS - Logs
# ============================================================================

logs: ## Show all service logs or specific service (live) - Log
	@if [ -n "$(SERVICE)" ] && [ "$(SERVICE)" != "logs" ]; then \
		echo "$(BLUE)$(SERVICE) Logs (live):$(NC)"; \
		$(COMPOSE_CMD) logs -f $(SERVICE); \
	else \
		$(COMPOSE_CMD) logs -f; \
	fi

logs-tail: ## Show last 100 lines of service logs - Log
	@if [ -z "$(SERVICE)" ] || [ "$(SERVICE)" = "logs-tail" ]; then \
		echo "$(RED)Error: Service name required. Example: make logs-tail prometheus$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Last 100 lines of $(SERVICE) logs:$(NC)"
	@$(COMPOSE_CMD) logs --tail=100 $(SERVICE)

# ============================================================================
# MONITORING - Monitoring & Health
# ============================================================================

health: ## Run comprehensive health check - Health
	@chmod +x scripts/health-check-full.sh 2>/dev/null || true
	@./scripts/health-check-full.sh

health-quick: ## Quick health check - Health
	@echo "$(BLUE)Quick Health Check:$(NC)"
	@$(COMPOSE_CMD) ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"
	@echo ""
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo ""); \
	if [ -n "$$DOMAIN" ] && [ "$$DOMAIN" != "monitoring.example.com" ]; then \
		echo "$(BLUE)Testing HTTPS endpoints:$(NC)"; \
		curl -sfk "https://$$DOMAIN/health" > /dev/null 2>&1 && echo "$(GREEN)✓ Nginx: Healthy$(NC)" || echo "$(RED)✗ Nginx: Unhealthy$(NC)"; \
		curl -sfk "https://$$DOMAIN/grafana/api/health" > /dev/null 2>&1 && echo "$(GREEN)✓ Grafana: Healthy$(NC)" || echo "$(RED)✗ Grafana: Unhealthy$(NC)"; \
		curl -sfk "https://$$DOMAIN/prometheus/-/healthy" > /dev/null 2>&1 && echo "$(GREEN)✓ Prometheus: Healthy$(NC)" || echo "$(RED)✗ Prometheus: Unhealthy$(NC)"; \
		curl -sfk "https://$$DOMAIN/alertmanager/-/healthy" > /dev/null 2>&1 && echo "$(GREEN)✓ Alertmanager: Healthy$(NC)" || echo "$(RED)✗ Alertmanager: Unhealthy$(NC)"; \
	fi

targets: ## Show Prometheus targets status - Monitor
	@echo "$(BLUE)Prometheus Targets Status:$(NC)"
	@echo ""
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo ""); \
	if [ -n "$$DOMAIN" ] && [ "$$DOMAIN" != "monitoring.example.com" ]; then \
		curl -sfk "https://$$DOMAIN/prometheus/api/v1/targets" | python3 -m json.tool 2>/dev/null || \
		curl -sfk "https://$$DOMAIN/prometheus/api/v1/targets" | jq '.' 2>/dev/null || \
		echo "$(YELLOW)Prometheus not accessible or jq/python3 not installed$(NC)"; \
	else \
		curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool 2>/dev/null || \
		curl -s http://localhost:9090/api/v1/targets | jq '.' 2>/dev/null || \
		echo "$(YELLOW)Prometheus not accessible or jq/python3 not installed$(NC)"; \
	fi

reload: ## Reload Prometheus configuration - Monitor
	@echo "$(BLUE)Reloading Prometheus configuration...$(NC)"
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo ""); \
	if [ -n "$$DOMAIN" ] && [ "$$DOMAIN" != "monitoring.example.com" ]; then \
		curl -X POST -k "https://$$DOMAIN/prometheus/-/reload" 2>/dev/null && \
		echo "$(GREEN)✅ Prometheus configuration reloaded!$(NC)" || \
		echo "$(RED)❌ Failed to reload Prometheus configuration$(NC)"; \
	else \
		curl -X POST http://localhost:9090/-/reload 2>/dev/null && \
		echo "$(GREEN)✅ Prometheus configuration reloaded!$(NC)" || \
		echo "$(RED)❌ Failed to reload Prometheus configuration$(NC)"; \
	fi

rules: ## Validate Prometheus alert rules - Monitor
	@echo "$(BLUE)Validating Prometheus alert rules...$(NC)"
	@if command -v promtool > /dev/null 2>&1; then \
		promtool check rules prometheus/rules/*.yml && \
		echo "$(GREEN)✅ Alert rules are valid!$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  promtool not installed. Skipping validation.$(NC)"; \
		echo "$(YELLOW)Install Prometheus: https://prometheus.io/download/$(NC)"; \
	fi

metrics: ## Show available metrics endpoints - Monitor
	@echo "$(BLUE)Available Metrics Endpoints:$(NC)"
	@echo ""
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo "monitoring.example.com"); \
	echo "$(GREEN)Prometheus:$(NC)    https://$$DOMAIN/prometheus/metrics"; \
	echo "$(GREEN)Node Exporter:$(NC) http://localhost:9100/metrics"; \
	echo "$(GREEN)cAdvisor:$(NC)      http://localhost:8080/metrics"; \
	echo "$(GREEN)PostgreSQL:$(NC)    http://localhost:9187/metrics"; \
	echo "$(GREEN)Redis:$(NC)         http://localhost:9121/metrics"; \
	echo ""

# ============================================================================
# ACCESS - Access
# ============================================================================

show-urls: ## Show access URLs for all services - Access
	@echo "$(BLUE)Monitoring Stack Access URLs (Production):$(NC)"
	@echo ""
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo "monitoring.example.com"); \
	echo "$(GREEN)Grafana:$(NC)      https://$$DOMAIN/grafana/"; \
	echo "$(GREEN)Prometheus:$(NC)    https://$$DOMAIN/prometheus/"; \
	echo "$(GREEN)Alertmanager:$(NC) https://$$DOMAIN/alertmanager/"; \
	echo ""; \
	echo "$(YELLOW)Note: All services require Basic Authentication$(NC)"; \
	echo "$(YELLOW)Note: Access via Nginx reverse proxy only$(NC)"

show-domain: ## Show configured domain - Access
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo "Not configured"); \
	echo "$(BLUE)Configured Domain:$(NC) $$DOMAIN"

# ============================================================================
# ALERTS - Alerts & Notifications
# ============================================================================

alerts: ## Show active Prometheus alerts - Alert
	@echo "$(BLUE)Active Prometheus Alerts:$(NC)"
	@echo ""
	@DOMAIN=$$(grep -E '^[^#]*server_name [^;]+;' nginx/conf.d/*.conf 2>/dev/null | head -1 | sed 's/.*server_name \([^;]*\);.*/\1/' | tr -d ' ' || echo ""); \
	if [ -n "$$DOMAIN" ] && [ "$$DOMAIN" != "monitoring.example.com" ]; then \
		curl -sfk "https://$$DOMAIN/prometheus/api/v1/alerts" | python3 -m json.tool 2>/dev/null || \
		curl -sfk "https://$$DOMAIN/prometheus/api/v1/alerts" | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, severity: .labels.severity}' 2>/dev/null || \
		echo "$(YELLOW)Prometheus not accessible or jq/python3 not installed$(NC)"; \
	else \
		curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool 2>/dev/null || \
		curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state, severity: .labels.severity}' 2>/dev/null || \
		echo "$(YELLOW)Prometheus not accessible or jq/python3 not installed$(NC)"; \
	fi

test-alert: ## Send test alert to Telegram - Telegram
	@echo "$(BLUE)Sending test alert to Telegram...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)Error: .env file not found. Run 'make setup-telegram' first.$(NC)"; \
		exit 1; \
	fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
	curl -s -X POST "https://api.telegram.org/bot$$TELEGRAM_BOT_TOKEN/sendMessage" \
		-d "chat_id=$$TELEGRAM_CHAT_ID" \
		-d "text=🧪 <b>Test Alert from Eivan Pay Monitoring</b>%0A%0AThis is a test message to verify Telegram alerts are working correctly.%0A%0ATime: $$(date)" \
		-d "parse_mode=HTML" > /dev/null && \
	echo "$(GREEN)✅ Test alert sent to Telegram!$(NC)" || \
	echo "$(RED)❌ Failed to send test alert. Check your Telegram configuration.$(NC)"

# ============================================================================
# MAINTENANCE - Maintenance
# ============================================================================

backup: ## Backup Grafana dashboards and configs - Backup
	@chmod +x scripts/backup-grafana.sh 2>/dev/null || true
	@./scripts/backup-grafana.sh

update: ## Update and rebuild services - Update
	@echo "$(BLUE)Updating services...$(NC)"
	@$(COMPOSE_CMD) pull
	@$(COMPOSE_CMD) build --no-cache
	@$(COMPOSE_CMD) up -d
	@echo "$(GREEN)✅ Services updated!$(NC)"

pull: ## Pull latest Docker images - Update
	@echo "$(BLUE)Pulling latest Docker images...$(NC)"
	@$(COMPOSE_CMD) pull
	@echo "$(GREEN)✅ Images pulled!$(NC)"

rebuild: ## Rebuild all Docker images - Update
	@echo "$(BLUE)Rebuilding Docker images...$(NC)"
	@$(COMPOSE_CMD) build --no-cache
	@echo "$(GREEN)✅ Images rebuilt!$(NC)"

clean: ## Clean up resources (containers) - Clean
	@echo "$(BLUE)Cleaning up resources...$(NC)"
	@$(COMPOSE_CMD) down
	@docker system prune -f
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

clean-all: ## Clean up everything (including volumes) - ⚠️ Destructive! - Clean
	@echo "$(RED)⚠️  WARNING: This will remove all containers, volumes, and data!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(COMPOSE_CMD) down -v; \
		docker system prune -af; \
		echo "$(GREEN)✅ All resources cleaned!$(NC)"; \
	else \
		echo "$(YELLOW)Cleanup cancelled.$(NC)"; \
	fi

