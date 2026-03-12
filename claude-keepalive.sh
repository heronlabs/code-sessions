#!/bin/bash

# Keepalive — pings Anthropic API every 55s to prevent connection drops
# Runs in its own tmux window — do not kill manually

INTERVAL=55

echo "💓 Keepalive started (PID $$)"

while true; do
  if curl -s --max-time 10 -o /dev/null -w "" https://api.anthropic.com/ 2>&1; then
    echo "$(date '+%H:%M:%S') 💓 ping OK"
  else
    echo "$(date '+%H:%M:%S') ⚠️  ping failed"
  fi
  sleep "$INTERVAL"
done