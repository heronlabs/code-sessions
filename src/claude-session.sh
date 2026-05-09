#!/bin/bash

# Claude Code session launcher using tmux.
# Invoked via the ~/.claude-session.sh symlink and the start-s alias.
if [ -z "$1" ]; then
  echo "Usage: start-s <folder>"
  echo "  e.g. start-s workloads"
  exit 1
fi

# Derive a tmux-safe session name: lowercase, drop hidden components
# (e.g. '.worktrees'), join the rest with '-'.
SESSION_NAME=""
IFS='/' read -ra _parts <<< "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
for _p in "${_parts[@]}"; do
  [[ -z "$_p" || "$_p" == .* ]] && continue
  SESSION_NAME="${SESSION_NAME:+${SESSION_NAME}-}${_p//./-}"
done
WORKDIR="$HOME/Workfolder/${1}"

echo "👋 Starting Claude session '${SESSION_NAME}' in ${WORKDIR}..."

if [ ! -d "$WORKDIR" ]; then
  echo "⚠️  Folder not found: ${WORKDIR}"
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "⚡ Session '${SESSION_NAME}' already running. Resuming..."
  tmux attach -t "$SESSION_NAME"
else
  echo "🚀 Launching new session '${SESSION_NAME}' in ${WORKDIR}..."

  tmux new-session -d -s "$SESSION_NAME"
  tmux set-option -t "$SESSION_NAME" mouse on
  tmux set-option -t "$SESSION_NAME" history-limit 10000

  # Launch Claude; exit the pane (and session) when claude exits
  tmux send-keys -t "${SESSION_NAME}.0" "cd '${WORKDIR}' && claude --dangerously-skip-permissions --remote-control --name '${SESSION_NAME}'; exit" Enter

  tmux attach -t "$SESSION_NAME"
fi
