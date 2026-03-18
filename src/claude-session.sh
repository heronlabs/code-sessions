#!/bin/bash

# Usage: session-start [name]
NAME=${1:-"default"}
SESSION_NAME="claude-$(echo "$NAME" | tr '[:upper:]' '[:lower:]')"
WORKDIR="$HOME/Workfolder/workloads"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEEPALIVE_SCRIPT="${SCRIPT_DIR}/.claude-keepalive.sh"

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

  # Enable mouse support for scroll (mouse wheel scrolls tmux history, not shell history)
  tmux set-option -t "$SESSION_NAME" mouse on

  # Increase scrollback buffer so you can scroll back further
  tmux set-option -t "$SESSION_NAME" history-limit 10000

  tmux rename-window -t "$SESSION_NAME" "claude-${NAME}"
  tmux set-option -t "$SESSION_NAME" status-left-length 40
  tmux set-option -t "$SESSION_NAME" status-left "#[fg=green]#{session_name} "

  # Top pane: keepalive at 10% height
  tmux send-keys -t "$SESSION_NAME" "bash ${KEEPALIVE_SCRIPT}" Enter

  # Split below: Claude gets the remaining 90%
  tmux split-window -v -t "$SESSION_NAME" -p 75

  # Focus the bottom pane and launch Claude
  tmux select-pane -t "$SESSION_NAME".1
  tmux send-keys -t "$SESSION_NAME" "cd ${WORKDIR}" Enter
  tmux send-keys -t "$SESSION_NAME" "claude --dangerously-skip-permissions" Enter

  # Wait for Claude to initialize, then send /remote-control
  sleep 5
  tmux send-keys -t "${SESSION_NAME}.1" "/remote-control" Enter

  tmux attach -t "$SESSION_NAME"
fi