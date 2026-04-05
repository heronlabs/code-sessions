#!/bin/bash

# Usage: start-s <folder>
# Starts a Claude session inside ~/Workfolder/<folder>
# Ubuntu version — uses systemd-inhibit instead of caffeinate
if [ -z "$1" ]; then
  echo "Usage: start-s <folder>"
  echo "  e.g. start-s workloads"
  exit 1
fi

NAME="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
SESSION_NAME="claude-${NAME}"
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
  echo "🚀 Launching new session for ${NAME} in ${WORKDIR}..."

  # Prevent sleep — Ubuntu equivalent of caffeinate
  # Uses systemd-inhibit to block idle/sleep/lid-switch
  systemd-inhibit --what=idle:sleep:handle-lid-switch \
    --who="claude-session-${NAME}" \
    --why="Claude coding session '${SESSION_NAME}' active" \
    --mode=block \
    sleep infinity &
  echo $! > /tmp/claude-caffeinate-${NAME}.pid

  # Track session start time for statusline uptime
  date +%s > /tmp/claude_session_start_${NAME}

  # ── Keepalive — pings Anthropic API every 55s to prevent connection drops ──
  (
    KEEPALIVE_INTERVAL=55
    KEEPALIVE_STATUS="/tmp/claude-keepalive-status"
    while true; do
      HTTP_CODE=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://api.anthropic.com/ 2>/dev/null)
      if [ "$HTTP_CODE" -gt 0 ] 2>/dev/null; then
        echo "ok $(date +%s)" > "$KEEPALIVE_STATUS"
      else
        echo "fail $(date +%s)" > "$KEEPALIVE_STATUS"
      fi
      sleep "$KEEPALIVE_INTERVAL"
    done
  ) &
  echo $! > /tmp/claude-keepalive-${NAME}.pid

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

  # Right: uptime │ memory │ date & time (Ubuntu-adapted: uses free instead of memory_pressure)
  tmux set-option -t "$SESSION_NAME" status-right-length 140
  tmux set-option -t "$SESSION_NAME" status-right "#[fg=#3b4261]│ #(sh -c 'read s t < /tmp/claude-keepalive-status 2>/dev/null; ago=\$((\$(date +%%s)-\${t:-0})); if [ \"\$s\" = \"ok\" ] && [ \$ago -lt 120 ]; then printf \"#[fg=#9ece6a]● Keepalive\"; elif [ \"\$s\" = \"fail\" ]; then printf \"#[fg=#f7768e]● Keepalive\"; else printf \"#[fg=#e0af68]○ Keepalive\"; fi') #[fg=#3b4261]│ #[fg=#9ece6a] Mem: #(free -m | awk '/Mem:/{printf \"%%d%%%%\", (\$3/\$2)*100}') #[fg=#3b4261]│ #[fg=#bb9af7] %a %d %b #[fg=#3b4261]│ #[bg=#7aa2f7,fg=#1a1b26,bold] %H:%M "

  # Window tabs — show named windows in status bar
  tmux set-option -t "$SESSION_NAME" window-status-format " #[fg=#a9b1d6]#I:#W "
  tmux set-option -t "$SESSION_NAME" window-status-current-format "#[bg=#7aa2f7,fg=#1a1b26,bold] #I:#W "
  tmux set-option -t "$SESSION_NAME" window-status-separator ""

  # Pane borders with labels
  tmux set-option -t "$SESSION_NAME" pane-border-status top
  tmux set-option -t "$SESSION_NAME" pane-border-format " #{pane_title} "
  tmux set-option -t "$SESSION_NAME" pane-border-style "fg=#3b4261"
  tmux set-option -t "$SESSION_NAME" pane-active-border-style "fg=#7aa2f7"

  # Single window: Claude (full screen)
  tmux rename-window -t "${SESSION_NAME}:0" "session"

  # Pane 0: launch Claude
  tmux send-keys -t "${SESSION_NAME}.0" "cd ${WORKDIR} && claude --dangerously-skip-permissions --remote-control" Enter

  # Color Claude pane — blue
  tmux select-pane -t "${SESSION_NAME}.0" -T "#[fg=#7aa2f7]◆ claude" -P "bg=#16181e"
  tmux set-option -p -t "${SESSION_NAME}.0" pane-border-style "fg=#7aa2f7"
  tmux set-option -p -t "${SESSION_NAME}.0" pane-active-border-style "fg=#7aa2f7,bold"

  tmux attach -t "$SESSION_NAME"
fi
