#!/usr/bin/env python3
"""
HTTP Webhook Server for Telegram Alerts
Receives webhook requests from Alertmanager and forwards to Telegram
"""

import os
import json
import sys
import time
import requests
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any, Optional
from collections import defaultdict
from datetime import datetime, timedelta
from prometheus_client import Counter, Histogram, Gauge, start_http_server, generate_latest, REGISTRY

# Support both environment variables and Docker secrets
def get_secret(env_var, secret_file_var=None):
    """Get secret from environment variable or Docker secret file"""
    # Try environment variable first
    value = os.getenv(env_var)
    if value:
        return value
    
    # Try Docker secret file
    if secret_file_var:
        secret_file = os.getenv(secret_file_var)
        if secret_file and os.path.exists(secret_file):
            with open(secret_file, 'r') as f:
                return f.read().strip()
    
    return None

TELEGRAM_BOT_TOKEN = get_secret('TELEGRAM_BOT_TOKEN', 'TELEGRAM_BOT_TOKEN_FILE')
TELEGRAM_CHAT_ID = get_secret('TELEGRAM_CHAT_ID', 'TELEGRAM_CHAT_ID_FILE')
MAX_RETRIES = int(os.getenv('MAX_RETRIES', '3'))
RATE_LIMIT_PER_MINUTE = int(os.getenv('RATE_LIMIT_PER_MINUTE', '20'))

TELEGRAM_API_URL = f'https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}' if TELEGRAM_BOT_TOKEN else None

# Rate limiting: track messages per minute
rate_limit_tracker = defaultdict(list)

# Prometheus metrics for webhook monitoring
webhook_requests_total = Counter(
    'telegram_webhook_requests_total',
    'Total number of webhook requests',
    ['status']
)

webhook_errors_total = Counter(
    'telegram_webhook_errors_total',
    'Total number of webhook errors'
)

webhook_request_duration = Histogram(
    'telegram_webhook_request_duration_seconds',
    'Webhook request duration',
    buckets=[0.1, 0.5, 1, 2, 5, 10]
)

telegram_messages_sent = Counter(
    'telegram_messages_sent_total',
    'Total number of messages sent to Telegram',
    ['status']
)

def format_alert(alert: Dict[str, Any]) -> str:
    """Format a single alert for Telegram"""
    status_emoji = {
        'firing': '🔴',
        'resolved': '✅',
        'pending': '⚠️'
    }
    
    severity_emoji = {
        'critical': '🔴',
        'warning': '⚠️',
        'info': 'ℹ️'
    }
    
    status = alert.get('status', 'unknown')
    labels = alert.get('labels', {})
    annotations = alert.get('annotations', {})
    
    emoji = status_emoji.get(status, '📢')
    severity = labels.get('severity', 'unknown')
    severity_icon = severity_emoji.get(severity, '📢')
    
    alertname = labels.get('alertname', 'Unknown Alert')
    instance = labels.get('instance', 'N/A')
    service = labels.get('job', 'N/A')
    
    summary = annotations.get('summary', 'No summary')
    description = annotations.get('description', 'No description')
    
    message = f"""{emoji} <b>{alertname}</b>

{severity_icon} <b>Severity:</b> {severity.upper()}
📊 <b>Status:</b> {status.upper()}

<b>Summary:</b> {summary}
<b>Description:</b> {description}

<b>Instance:</b> {instance}
<b>Service:</b> {service}
"""
    
    if 'startsAt' in alert:
        message += f"\n<b>Started:</b> {alert['startsAt']}"
    if 'endsAt' in alert and alert.get('endsAt'):
        message += f"\n<b>Ended:</b> {alert['endsAt']}"
    
    return message

def check_rate_limit() -> bool:
    """Check if we're within rate limit"""
    now = datetime.now()
    minute_ago = now - timedelta(minutes=1)
    
    # Clean old entries
    rate_limit_tracker[TELEGRAM_CHAT_ID] = [
        ts for ts in rate_limit_tracker[TELEGRAM_CHAT_ID] 
        if ts > minute_ago
    ]
    
    # Check limit
    if len(rate_limit_tracker[TELEGRAM_CHAT_ID]) >= RATE_LIMIT_PER_MINUTE:
        return False
    
    rate_limit_tracker[TELEGRAM_CHAT_ID].append(now)
    return True

def send_to_telegram(message: str, disable_notification: bool = False) -> bool:
    """Send message to Telegram with retry logic"""
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        telegram_messages_sent.labels(status='error').inc()
        print("ERROR: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set", file=sys.stderr)
        return False
    
    # Check rate limit
    if not check_rate_limit():
        print("WARNING: Rate limit exceeded, skipping message", file=sys.stderr)
        return False
    
    url = f'{TELEGRAM_API_URL}/sendMessage'
    data = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': message,
        'parse_mode': 'HTML',
        'disable_notification': disable_notification
    }
    
    for attempt in range(MAX_RETRIES):
        try:
            response = requests.post(url, json=data, timeout=10)
            response.raise_for_status()
            telegram_messages_sent.labels(status='success').inc()
            return True
        except requests.exceptions.RequestException as e:
            if attempt < MAX_RETRIES - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                print(f"WARNING: Failed to send (attempt {attempt + 1}/{MAX_RETRIES}), retrying in {wait_time}s: {e}", file=sys.stderr)
                time.sleep(wait_time)
            else:
                telegram_messages_sent.labels(status='error').inc()
                print(f"ERROR: Failed to send to Telegram after {MAX_RETRIES} attempts: {e}", file=sys.stderr)
                return False
    
    return False

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests from Alertmanager"""
        start_time = time.time()
        
        if self.path != '/webhook':
            webhook_requests_total.labels(status='404').inc()
            self.send_response(404)
            self.end_headers()
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode('utf-8'))
            
            version = data.get('version', '4')
            group_key = data.get('groupKey', '')
            status = data.get('status', 'unknown')
            alerts = data.get('alerts', [])
            
            if not alerts:
                self.send_response(200)
                self.end_headers()
                return
            
            # Determine notification settings based on severity
            has_critical = any(
                alert.get('labels', {}).get('severity') == 'critical' 
                for alert in alerts
            )
            disable_notification = not has_critical and status != 'firing'
            
            # Group alerts by severity
            critical_alerts = [a for a in alerts if a.get('labels', {}).get('severity') == 'critical']
            warning_alerts = [a for a in alerts if a.get('labels', {}).get('severity') == 'warning']
            other_alerts = [a for a in alerts if a not in critical_alerts and a not in warning_alerts]
            
            # Send critical alerts individually
            for alert in critical_alerts:
                message = format_alert(alert)
                send_to_telegram(message, disable_notification=False)
            
            # Send warning alerts as a group
            if warning_alerts:
                message = f"⚠️ <b>Warning Alerts ({len(warning_alerts)})</b>\n\n"
                for alert in warning_alerts[:5]:  # Limit to 5 alerts
                    message += format_alert(alert) + "\n\n"
                if len(warning_alerts) > 5:
                    message += f"... and {len(warning_alerts) - 5} more alerts"
                send_to_telegram(message, disable_notification=True)
            
            # Send other alerts
            for alert in other_alerts:
                message = format_alert(alert)
                send_to_telegram(message, disable_notification=True)
            
            duration = time.time() - start_time
            webhook_request_duration.observe(duration)
            webhook_requests_total.labels(status='200').inc()
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'success'}).encode())
            
        except json.JSONDecodeError as e:
            webhook_errors_total.inc()
            webhook_requests_total.labels(status='400').inc()
            print(f"ERROR: Invalid JSON: {e}", file=sys.stderr)
            self.send_response(400)
            self.end_headers()
        except Exception as e:
            webhook_errors_total.inc()
            webhook_requests_total.labels(status='500').inc()
            print(f"ERROR: {e}", file=sys.stderr)
            self.send_response(500)
            self.end_headers()
    
    def do_GET(self):
        """Health check and metrics endpoints"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'healthy'}).encode())
        elif self.path == '/metrics':
            # Prometheus metrics endpoint
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; version=0.0.4')
            self.end_headers()
            self.wfile.write(generate_latest(REGISTRY).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Override to reduce log noise"""
        pass

def main():
    """Start the webhook server"""
    port = int(os.getenv('PORT', '8080'))
    metrics_port = int(os.getenv('METRICS_PORT', '9091'))
    
    # Start Prometheus metrics server
    start_http_server(metrics_port)
    print(f'Prometheus metrics server started on port {metrics_port}')
    
    # Start webhook server
    server = HTTPServer(('0.0.0.0', port), WebhookHandler)
    print(f'Telegram webhook server started on port {port}')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down server...')
        server.shutdown()

if __name__ == '__main__':
    main()

