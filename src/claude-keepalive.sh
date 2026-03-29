#!/bin/bash

# Keepalive — pings Anthropic API every 55s to prevent connection drops
# Runs as a background process, writes status to /tmp/claude-keepalive-status

INTERVAL=55
STATUS_FILE="/tmp/claude-keepalive-status"

echo $$ > /tmp/claude-keepalive.pid

while true; do
  HTTP_CODE=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://api.anthropic.com/ 2>/dev/null)
  if [ "$HTTP_CODE" -gt 0 ] 2>/dev/null; then
    echo "ok $(date +%s)" > "$STATUS_FILE"
  else
    echo "fail $(date +%s)" > "$STATUS_FILE"
  fi
  sleep "$INTERVAL"
done