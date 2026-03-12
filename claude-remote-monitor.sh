#!/bin/bash

# Remote Access Monitor
# Starts Claude remote access and restarts it if it stops
# Runs in its own tmux window — do not kill manually

LOG="/tmp/claude-remote.log"
CHECK_INTERVAL=120  # seconds between health checks

start_remote() {
  echo "$(date '+%H:%M:%S') 📡 Starting Claude remote access..." | tee -a "$LOG"
  claude remote start >> "$LOG" 2>&1 &
  echo $! > /tmp/claude-remote.pid
  sleep 3
}

is_remote_running() {
  # Check if the remote process is alive
  if [ -f /tmp/claude-remote.pid ]; then
    local pid
    pid=$(cat /tmp/claude-remote.pid)
    if kill -0 "$pid" 2>/dev/null; then
      return 0  # running
    fi
  fi
  # Fallback: check by process name
  pgrep -f "claude remote" > /dev/null 2>&1
}

echo "🔍 Remote monitor started (PID $$)" | tee "$LOG"
start_remote

while true; do
  sleep "$CHECK_INTERVAL"

  if is_remote_running; then
    echo "$(date '+%H:%M:%S') ✅ Remote access OK" | tee -a "$LOG"
  else
    echo "$(date '+%H:%M:%S') ⚠️  Remote access down — restarting..." | tee -a "$LOG"
    start_remote
  fi
done