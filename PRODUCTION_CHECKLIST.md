# Production Deployment Checklist

Use this checklist before deploying to production.

## 🔐 Security Configuration

- [ ] **Change all default passwords**
  - [ ] Grafana admin password (set `GRAFANA_ADMIN_PASSWORD` in `.env`)
  - [ ] PostgreSQL password (set `POSTGRES_PASSWORD` in `.env`)
  - [ ] Redis password (set `REDIS_PASSWORD` in `.env`)
  - [ ] Nginx Basic Auth passwords (run `make setup-auth`)

- [ ] **SSL Certificates**
  - [ ] SSL certificates generated/obtained
  - [ ] Certificates placed in `nginx/ssl/` directory
  - [ ] Certificate files have correct permissions (600 for .key, 644 for .crt)
  - [ ] Test SSL: `openssl x509 -in nginx/ssl/monitoring.crt -text -noout`

- [ ] **Basic Authentication**
  - [ ] Nginx Basic Auth configured (run `make setup-auth`)
  - [ ] `.htpasswd` files created in `nginx/auth/`
  - [ ] Strong passwords used (minimum 16 characters)

- [ ] **Docker Secrets (Recommended)**
  - [ ] Docker Swarm initialized (run `make setup-secrets`)
  - [ ] All sensitive credentials stored as Docker secrets
  - [ ] `docker-compose.secrets.yml` created from example

## 🌐 Network & Domain Configuration

- [ ] **Domain Configuration**
  - [ ] Domain name updated in all configs (run `make setup-domain your-domain.com`)
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

## 📝 Environment Variables

- [ ] **`.env` file configured**
  - [ ] Copy `.env.example` to `.env`
  - [ ] All `your_*` placeholders replaced with actual values
  - [ ] Database credentials configured
  - [ ] Redis credentials configured
  - [ ] Telegram bot configured (run `make setup-telegram`)
  - [ ] External URLs configured with your domain

- [ ] **Validate environment**
  - [ ] Run `make validate` to check all required variables

## 🚀 Deployment

- [ ] **Pre-deployment checks**
  - [ ] All services stopped (if upgrading)
  - [ ] Backup existing data (if upgrading)
  - [ ] Disk space sufficient (minimum 50GB free)

- [ ] **Deploy services**
  - [ ] Run `make setup` for complete setup OR
  - [ ] Run individual setup steps:
    - [ ] `make setup-ssl`
    - [ ] `make setup-auth`
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

## 🔍 Monitoring & Alerts

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

## 🛡️ Security Hardening

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
  - [ ] Security options enabled (`no-new-privileges`)

## 📊 Maintenance Setup

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

## ✅ Final Verification

- [ ] All services running: `make status`
- [ ] All health checks passing: `make health`
- [ ] No critical alerts: `make alerts`
- [ ] SSL certificate valid (not expired)
- [ ] Domain accessible via HTTPS
- [ ] Basic Auth working
- [ ] Telegram alerts working
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards functional

## 🚨 Important Notes

1. **Never commit `.env` file** - It contains sensitive credentials
2. **Change default passwords** - Especially Grafana admin password
3. **Use Docker Secrets for production** - More secure than environment variables
4. **Keep SSL certificates updated** - Set up auto-renewal if using Let's Encrypt
5. **Monitor disk space** - Prometheus data grows over time
6. **Regular backups** - Backup Grafana dashboards and Prometheus data
7. **Test alerts** - Verify Telegram integration before relying on it

## 📞 Support

If you encounter issues:
1. Check logs: `make logs [service-name]`
2. Run health check: `make health`
3. Review troubleshooting section in README.md
4. Check service status: `make status`







