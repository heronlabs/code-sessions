#!/bin/bash

# Usage: claude-start [name]
NAME=${1:-"default"}
SESSION_NAME="claude-$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"
WORKDIR="$HOME/Workfolder/workloads"
KEEPALIVE_SCRIPT="$HOME/.claude-keepalive.sh"
REMOTE_MONITOR_SCRIPT="$HOME/.claude-remote-monitor.sh"

echo "👋 Hey ${NAME}! Starting your Claude session..."

if [ ! -d "$WORKDIR" ]; then
  echo "⚠️  Workdir not found: ${WORKDIR}"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "⚡ Session '${SESSION_NAME}' already running. Resuming..."
  tmux attach -t "$SESSION_NAME"
else
  echo "🚀 Launching new session for ${NAME} in ${WORKDIR}..."

  # Prevent sleep — works with lid closed, no GUI dependency
  caffeinate -dims &
  echo $! > /tmp/claude-caffeinate.pid

  # Create main tmux session
  tmux new-session -d -s "$SESSION_NAME" -x 220 -y 50
  tmux rename-window -t "$SESSION_NAME" "claude-${NAME}"
  tmux set-option -t "$SESSION_NAME" status-left-length 40
  tmux set-option -t "$SESSION_NAME" status-left "#[fg=green]#{session_name} "

  # Window: keepalive (pings Anthropic API to maintain connection)
  tmux new-window -t "$SESSION_NAME" -n "keepalive"
  tmux send-keys -t "${SESSION_NAME}:keepalive" "bash ${KEEPALIVE_SCRIPT}" Enter

  # Window: remote-monitor (watches and restarts remote access if it drops)
  tmux new-window -t "$SESSION_NAME" -n "remote"
  tmux send-keys -t "${SESSION_NAME}:remote" "bash ${REMOTE_MONITOR_SCRIPT}" Enter

  # Back to main window
  tmux select-window -t "${SESSION_NAME}:claude-${NAME}"
  tmux send-keys -t "$SESSION_NAME" "cd ${WORKDIR}" Enter

  # Launch Claude interactive session with auto-approve
  tmux send-keys -t "$SESSION_NAME" "claude --dangerously-skip-permissions" Enter

  tmux attach -t "$SESSION_NAME"
fi