#!/bin/bash

# Usage: start-s <folder>
# Starts a Claude session inside ~/Workfolder/<folder>
if [ -z "$1" ]; then
  echo "Usage: start-s <folder>"
  echo "  e.g. start-s workloads"
  exit 1
fi

NAME="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
SESSION_NAME="claude-${NAME}"
WORKDIR="$HOME/Workfolder/${1}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEEPALIVE_SCRIPT="${SCRIPT_DIR}/.claude-keepalive.sh"

echo "👋 Starting Claude session '${SESSION_NAME}' in ${WORKDIR}..."

if [ ! -d "$WORKDIR" ]; then
  echo "⚠️  Folder not found: ${WORKDIR}"
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

  # Track session start time for statusline uptime
  date +%s > /tmp/claude_session_start

  # Create main tmux session
  tmux new-session -d -s "$SESSION_NAME" -x 220 -y 50

  # Enable mouse support for scroll (mouse wheel scrolls tmux history, not shell history)
  tmux set-option -t "$SESSION_NAME" mouse on

  # Increase scrollback buffer so you can scroll back further
  tmux set-option -t "$SESSION_NAME" history-limit 10000

  # ── Stylish status bar ──────────────────────────────────────────────
  tmux set-option -t "$SESSION_NAME" status-position bottom
  tmux set-option -t "$SESSION_NAME" status-style "bg=#1a1b26,fg=#a9b1d6"
  tmux set-option -t "$SESSION_NAME" status-interval 5

  # Left: session name with accent
  tmux set-option -t "$SESSION_NAME" status-left-length 50
  tmux set-option -t "$SESSION_NAME" status-left "#[bg=#7aa2f7,fg=#1a1b26,bold]  #S #[bg=#1a1b26,fg=#7aa2f7]"

  # Right: uptime │ memory │ date & time
  tmux set-option -t "$SESSION_NAME" status-right-length 120
  tmux set-option -t "$SESSION_NAME" status-right "#[fg=#3b4261]│ #[fg=#e0af68] Uptime: #(echo \$((\$(date +%%s)-#{session_created})) | awk '{h=int(\$1/3600);m=int((\$1%%3600)/60);printf \"%%dh %%02dm\",h,m}') #[fg=#3b4261]│ #[fg=#9ece6a] Mem: #(memory_pressure | awk '/percentage/{print \$5}') #[fg=#3b4261]│ #[fg=#bb9af7] %a %d %b #[fg=#3b4261]│ #[bg=#7aa2f7,fg=#1a1b26,bold] %H:%M "

  # Window tabs — hide to avoid duplicating session name
  tmux set-option -t "$SESSION_NAME" window-status-format ""
  tmux set-option -t "$SESSION_NAME" window-status-current-format ""
  tmux set-option -t "$SESSION_NAME" window-status-separator ""

  # Pane borders with labels
  tmux set-option -t "$SESSION_NAME" pane-border-status top
  tmux set-option -t "$SESSION_NAME" pane-border-format " #{pane_title} "
  tmux set-option -t "$SESSION_NAME" pane-border-style "fg=#3b4261"
  tmux set-option -t "$SESSION_NAME" pane-active-border-style "fg=#7aa2f7"

  # Pane 0 starts as the full window — launch keepalive here
  tmux send-keys -t "$SESSION_NAME" "bash ${KEEPALIVE_SCRIPT}" Enter

  # Split vertically: pane 0 stays on top (10%), pane 1 = Claude on bottom (90%)
  tmux split-window -v -t "${SESSION_NAME}.0" -p 90

  # Split top pane horizontally: pane 0 = keepalive (20%), new pane = shell (80%)
  # After this split, panes are: 0=keepalive (top-left), 1=shell (top-right), 2=claude (bottom)
  tmux split-window -h -t "${SESSION_NAME}.0" -p 80
  tmux send-keys -t "${SESSION_NAME}.1" "cd ${WORKDIR}" Enter

  # Launch Claude in the bottom pane
  tmux send-keys -t "${SESSION_NAME}.2" "cd ${WORKDIR}" Enter
  tmux send-keys -t "${SESSION_NAME}.2" "claude --dangerously-skip-permissions" Enter

  # Color each pane: border + label + subtle background tint
  # Keepalive (pane 0) — amber
  tmux select-pane -t "${SESSION_NAME}.0" -T "#[fg=#e0af68]⏱ keepalive" -P "bg=#1c1a16"
  tmux set-option -p -t "${SESSION_NAME}.0" pane-border-style "fg=#e0af68"
  tmux set-option -p -t "${SESSION_NAME}.0" pane-active-border-style "fg=#e0af68"

  # Shell (pane 1) — green
  tmux select-pane -t "${SESSION_NAME}.1" -T "#[fg=#9ece6a]⬢ shell" -P "bg=#1a1c16"
  tmux set-option -p -t "${SESSION_NAME}.1" pane-border-style "fg=#9ece6a"
  tmux set-option -p -t "${SESSION_NAME}.1" pane-active-border-style "fg=#9ece6a"

  # Claude (pane 2) — blue
  tmux select-pane -t "${SESSION_NAME}.2" -T "#[fg=#7aa2f7]◆ claude" -P "bg=#16181e"
  tmux set-option -p -t "${SESSION_NAME}.2" pane-border-style "fg=#7aa2f7"
  tmux set-option -p -t "${SESSION_NAME}.2" pane-active-border-style "fg=#7aa2f7,bold"

  # Focus the Claude pane
  tmux select-pane -t "${SESSION_NAME}.2"

  # Wait for Claude to initialize, then send /remote-control
  sleep 5
  tmux send-keys -t "${SESSION_NAME}.2" "/remote-control" Enter

  tmux attach -t "$SESSION_NAME"
fi