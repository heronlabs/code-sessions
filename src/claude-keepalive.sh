#!/bin/bash

# Keepalive — pings Anthropic API every 55s to prevent connection drops
# Runs in its own tmux window — do not kill manually

INTERVAL=55

echo "[keepalive] started (PID $$)"

while true; do
  HTTP_CODE=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://api.anthropic.com/ 2>/dev/null)
  if [ "$HTTP_CODE" -gt 0 ] 2>/dev/null; then
    echo "$(date '+%H:%M:%S') [ok] ping"
  else
    echo "$(date '+%H:%M:%S') [!!] ping failed"
  fi
  sleep "$INTERVAL"
done