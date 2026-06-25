#!/bin/bash

# Claude Code session launcher using tmux.
# Invoked via the ~/.claude-session.sh symlink and the start-s alias.
# Resolve the real script directory (follow symlinks — this script is
# invoked via ~/.claude-session.sh which is a symlink into this repo).
_script="$0"
[ -L "$_script" ] && _script="$(readlink "$_script")"
SCRIPT_DIR="$(cd "$(dirname "$_script")" && pwd)"
source "$SCRIPT_DIR/session-name.sh"

if [ -z "$1" ]; then
  echo "Usage: start-s <folder>"
  echo "  e.g. start-s workloads"
  exit 1
fi

# Build a session name with two parts:
#   prefix  — derived from the path so you can tell which folder it lives in:
#             lowercased, hidden components dropped, joined with '-'.
#   suffix  — six random hex chars so every invocation is unique.
PREFIX="$(session_prefix "$1")"
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
tmux send-keys -t "${SESSION_NAME}.0" "cd '${WORKDIR}' && headroom wrap claude --dangerously-skip-permissions --settings ~/.claude/claude-deepseek-settings.json; exit" Enter

# Only attach when running in an interactive terminal (not from systemd/cron)
if [ -t 0 ]; then
    tmux attach -t "$SESSION_NAME"
fi
