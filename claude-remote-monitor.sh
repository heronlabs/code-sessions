#!/bin/bash

# Remote Access Monitor
# Starts Claude remote access and restarts it if it stops
# Runs in its own tmux window — do not kill manually

LOG="/tmp/claude-remote.log"
CHECK_INTERVAL=120  # seconds between health checks

echo "🔍 Remote monitor started (PID $$)" | tee "$LOG"

while true; do
  echo "$(date '+%H:%M:%S') 📡 Starting Claude remote access..." | tee -a "$LOG"
  claude remote-control 2>&1 | tee -a "$LOG"
  echo "$(date '+%H:%M:%S') ⚠️  Remote access exited — restarting in ${CHECK_INTERVAL}s..." | tee -a "$LOG"
  sleep "$CHECK_INTERVAL"
done