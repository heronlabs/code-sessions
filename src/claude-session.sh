#!/bin/bash

# Claude Code session launcher using tmux.
# Invoked via the ~/.claude-session.sh symlink and the start-s alias.
if [ -z "$1" ]; then
  echo "Usage: start-s <folder>"
  echo "  e.g. start-s workloads"
  exit 1
fi

# Build a session name with two parts:
#   prefix  — derived from the path so you can tell which folder it lives in:
#             lowercased, hidden components dropped, joined with '-'.
#   suffix  — six random hex chars so every invocation is unique.
PREFIX=""
IFS='/' read -ra _parts <<< "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
for _p in "${_parts[@]}"; do
  [[ -z "$_p" || "$_p" == .* ]] && continue
  PREFIX="${PREFIX:+${PREFIX}-}${_p//./-}"
done
SUFFIX="$(openssl rand -hex 3)"
SESSION_NAME="${PREFIX}-${SUFFIX}"
WORKDIR="$HOME/Workfolder/${1}"

if [ ! -d "$WORKDIR" ]; then
  echo "⚠️  Folder not found: ${WORKDIR}"
  exit 1
fi

echo "🚀 Launching new session '${SESSION_NAME}' in ${WORKDIR}..."

tmux new-session -d -s "$SESSION_NAME"
tmux set-option -t "$SESSION_NAME" mouse on
tmux set-option -t "$SESSION_NAME" history-limit 10000

tmux set-option -t "$SESSION_NAME" status off

# Launch Claude; exit the pane (and session) when claude exits
tmux send-keys -t "${SESSION_NAME}.0" "cd '${WORKDIR}' && claude --dangerously-skip-permissions --remote-control '${SESSION_NAME}' --name '${SESSION_NAME}'; exit" Enter

tmux attach -t "$SESSION_NAME"
