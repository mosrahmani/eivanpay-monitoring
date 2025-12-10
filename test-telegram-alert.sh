#!/bin/bash
# Simple script to test Telegram webhook

WEBHOOK_URL="http://localhost:8080/webhook"

echo "Sending test alert to Telegram webhook..."

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "4",
    "status": "firing",
    "alerts": [{
      "status": "firing",
      "labels": {
        "alertname": "TestAlert",
        "severity": "critical",
        "instance": "test-server",
        "job": "test-service"
      },
      "annotations": {
        "summary": "Test Alert - Telegram Integration",
        "description": "This is a test alert to verify Telegram webhook is working correctly"
      },
      "startsAt": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }]
  }'

echo ""
echo "✅ Test alert sent! Check your Telegram for the message."

