/**
 * Telegram Webhook Server for Alertmanager
 * Clean, fast, and professional implementation using Fastify
 */

const fastify = require('fastify')({ logger: true });
const axios = require('axios');
const { HttpsProxyAgent } = require('https-proxy-agent');
const { register, Counter, Histogram } = require('prom-client');
const fs = require('fs');

// ============================================================================
// Configuration
// ============================================================================

const getSecret = (envVar, secretFileVar) => {
  const value = process.env[envVar];
  if (value) return value.trim();
  
  const secretFile = secretFileVar && process.env[secretFileVar];
  if (secretFile && fs.existsSync(secretFile)) {
    try {
      return fs.readFileSync(secretFile, 'utf8').trim();
    } catch (error) {
      console.error(`Error reading secret file: ${error.message}`);
    }
  }
  return null;
};

const config = {
  telegram: {
    botToken: getSecret('TELEGRAM_BOT_TOKEN', 'TELEGRAM_BOT_TOKEN_FILE'),
    chatId: getSecret('TELEGRAM_CHAT_ID', 'TELEGRAM_CHAT_ID_FILE'),
    get apiUrl() {
      return this.botToken ? `https://api.telegram.org/bot${this.botToken}` : null;
    },
  },
  proxy: process.env.HTTP_PROXY || process.env.HTTPS_PROXY || null,
  retry: { maxAttempts: parseInt(process.env.MAX_RETRIES || '3', 10), baseDelay: 1000 },
  rateLimit: { messagesPerMinute: parseInt(process.env.RATE_LIMIT_PER_MINUTE || '20', 10), windowMs: 60000 },
  server: { port: parseInt(process.env.PORT || '8080', 10), metricsPort: parseInt(process.env.METRICS_PORT || '9091', 10) },
  timeout: parseInt(process.env.TELEGRAM_TIMEOUT || '30', 10) * 1000,
};

if (config.proxy) console.log(`Using HTTP proxy: ${config.proxy}`);

// ============================================================================
// Prometheus Metrics
// ============================================================================

const metrics = {
  webhookRequests: new Counter({ name: 'telegram_webhook_requests_total', help: 'Total webhook requests', labelNames: ['status'] }),
  webhookErrors: new Counter({ name: 'telegram_webhook_errors_total', help: 'Total webhook errors' }),
  webhookDuration: new Histogram({ name: 'telegram_webhook_request_duration_seconds', help: 'Webhook duration', buckets: [0.1, 0.5, 1, 2, 5, 10] }),
  messagesSent: new Counter({ name: 'telegram_messages_sent_total', help: 'Messages sent to Telegram', labelNames: ['status'] }),
};

// ============================================================================
// Rate Limiter
// ============================================================================

class RateLimiter {
  constructor(maxRequests, windowMs) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.requests = new Map();
  }

  isAllowed(key) {
    const now = Date.now();
    const windowStart = now - this.windowMs;
    
    if (!this.requests.has(key)) this.requests.set(key, []);
    
    const timestamps = this.requests.get(key).filter(ts => ts > windowStart);
    if (timestamps.length >= this.maxRequests) return false;
    
    timestamps.push(now);
    this.requests.set(key, timestamps);
    return true;
  }
}

const rateLimiter = new RateLimiter(config.rateLimit.messagesPerMinute, config.rateLimit.windowMs);

// ============================================================================
// HTTP Client
// ============================================================================

const httpClient = axios.create({
  timeout: config.timeout,
  ...(config.proxy && {
    httpsAgent: new HttpsProxyAgent(config.proxy),
    httpAgent: new HttpsProxyAgent(config.proxy),
  }),
});

// ============================================================================
// Alert Formatter
// ============================================================================

const formatAlert = (alert) => {
  const statusEmoji = { firing: '🔴', resolved: '✅', pending: '⚠️' };
  const severityEmoji = { critical: '🔴', warning: '⚠️', info: 'ℹ️' };
  
  const status = alert.status || 'unknown';
  const labels = alert.labels || {};
  const annotations = alert.annotations || {};
  
  const emoji = statusEmoji[status] || '📢';
  const severity = labels.severity || 'unknown';
  const severityIcon = severityEmoji[severity] || '📢';
  
  const escape = (text) => String(text || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  
  let message = `${emoji} <b>${escape(labels.alertname || 'Unknown Alert')}</b>

${severityIcon} <b>Severity:</b> ${severity.toUpperCase()}
📊 <b>Status:</b> ${status.toUpperCase()}

<b>Summary:</b> ${escape(annotations.summary || 'No summary')}
<b>Description:</b> ${escape(annotations.description || 'No description')}

<b>Instance:</b> ${escape(labels.instance || 'N/A')}
<b>Service:</b> ${escape(labels.job || 'N/A')}`;
  
  if (alert.startsAt) message += `\n<b>Started:</b> ${alert.startsAt}`;
  if (alert.endsAt) message += `\n<b>Ended:</b> ${alert.endsAt}`;
  
  return message;
};

const formatGroup = (alerts, title, maxAlerts = 5) => {
  let message = `${title}\n\n`;
  alerts.slice(0, maxAlerts).forEach(alert => {
    message += formatAlert(alert) + '\n\n';
  });
  if (alerts.length > maxAlerts) message += `... and ${alerts.length - maxAlerts} more alerts`;
  return message;
};

// ============================================================================
// Telegram Service
// ============================================================================

const sendToTelegram = async (message, disableNotification = false) => {
  if (!config.telegram.botToken || !config.telegram.chatId) {
    metrics.messagesSent.inc({ status: 'error' });
    fastify.log.error('Telegram not configured');
    return false;
  }
  
  if (!rateLimiter.isAllowed(config.telegram.chatId)) {
    fastify.log.warn('Rate limit exceeded');
    return false;
  }
  
  const url = `${config.telegram.apiUrl}/sendMessage`;
  const payload = { chat_id: config.telegram.chatId, text: message, parse_mode: 'HTML', disable_notification: disableNotification };
  
  for (let attempt = 0; attempt < config.retry.maxAttempts; attempt++) {
    try {
      await httpClient.post(url, payload);
      metrics.messagesSent.inc({ status: 'success' });
      return true;
    } catch (error) {
      if (attempt === config.retry.maxAttempts - 1) {
        metrics.messagesSent.inc({ status: 'error' });
        fastify.log.error(`Failed after ${config.retry.maxAttempts} attempts: ${error.message}`);
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, config.retry.baseDelay * Math.pow(2, attempt)));
    }
  }
  return false;
};

// ============================================================================
// Routes
// ============================================================================

fastify.post('/webhook', async (request, reply) => {
  const startTime = Date.now();
  
  try {
    const { alerts = [], status } = request.body;
    
    if (!alerts.length) {
      metrics.webhookRequests.inc({ status: '200' });
      return { status: 'success' };
    }
    
    const hasCritical = alerts.some(a => a.labels?.severity === 'critical');
    const disableNotification = !hasCritical && status !== 'firing';
    
    const critical = alerts.filter(a => a.labels?.severity === 'critical');
    const warning = alerts.filter(a => a.labels?.severity === 'warning');
    const other = alerts.filter(a => a.labels?.severity !== 'critical' && a.labels?.severity !== 'warning');
    
    for (const alert of critical) {
      await sendToTelegram(formatAlert(alert), false);
    }
    
    if (warning.length) {
      await sendToTelegram(formatGroup(warning, `⚠️ <b>Warning Alerts (${warning.length})</b>`), true);
    }
    
    for (const alert of other) {
      await sendToTelegram(formatAlert(alert), true);
    }
    
    const duration = (Date.now() - startTime) / 1000;
    metrics.webhookDuration.observe(duration);
    metrics.webhookRequests.inc({ status: '200' });
    
    return { status: 'success' };
  } catch (error) {
    metrics.webhookErrors.inc();
    metrics.webhookRequests.inc({ status: '500' });
    fastify.log.error(error);
    reply.code(500).send({ error: 'Internal server error' });
  }
});

fastify.get('/health', async () => ({
  status: 'healthy',
  timestamp: new Date().toISOString(),
}));

fastify.get('/metrics', async (request, reply) => {
  reply.type('text/plain');
  return register.metrics();
});

// ============================================================================
// Start Server
// ============================================================================

const start = async () => {
  try {
    // Start metrics server
    require('http').createServer(async (req, res) => {
      if (req.url === '/metrics') {
        res.setHeader('Content-Type', register.contentType);
        res.end(await register.metrics());
      } else {
        res.statusCode = 404;
        res.end('Not found');
      }
    }).listen(config.server.metricsPort, '0.0.0.0', () => {
      console.log(`Metrics server on port ${config.server.metricsPort}`);
    });
    
    // Start main server
    await fastify.listen({ host: '0.0.0.0', port: config.server.port });
    console.log(`Webhook server on port ${config.server.port}`);
  } catch (error) {
    fastify.log.error(error);
    process.exit(1);
  }
};

start();

