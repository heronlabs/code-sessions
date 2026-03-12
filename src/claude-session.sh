#!/bin/bash

# Usage: claude-start [name]
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
  tmux rename-window -t "$SESSION_NAME" "claude-${NAME}"
  tmux set-option -t "$SESSION_NAME" status-left-length 40
  tmux set-option -t "$SESSION_NAME" status-left "#[fg=green]#{session_name} "

  # Split right: keepalive (pings Anthropic API to maintain connection)
  tmux split-window -h -t "$SESSION_NAME" -p 50
  tmux send-keys -t "$SESSION_NAME" "bash ${KEEPALIVE_SCRIPT}" Enter

  # Focus back to main (left) pane and launch Claude
  tmux select-pane -t "$SESSION_NAME".0
  tmux send-keys -t "$SESSION_NAME" "cd ${WORKDIR}" Enter
  tmux send-keys -t "$SESSION_NAME" "claude --dangerously-skip-permissions" Enter

  # Wait for Claude to initialize, then send /remote-control
  sleep 5
  tmux send-keys -t "${SESSION_NAME}.0" "/remote-control" Enter

  tmux attach -t "$SESSION_NAME"
fi