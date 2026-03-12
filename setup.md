# Claude Session Setup — Manual Steps

Follow these steps in order. Everything here requires your confirmation before running.

---

## 1. Create symbolic links

Instead of copying files, link them so `~/Workfolder/claude-sessions/` stays the single source of truth.
Edit the scripts there and the links pick up changes automatically.

```bash
ln -sf ~/Workfolder/claude-sessions/claude-session.sh ~/.claude-session.sh
ln -sf ~/Workfolder/claude-sessions/claude-keepalive.sh ~/.claude-keepalive.sh
ln -sf ~/Workfolder/claude-sessions/claude-remote-monitor.sh ~/.claude-remote-monitor.sh
chmod +x ~/Workfolder/claude-sessions/*.sh
```

Verify the links are correct:

```bash
ls -la ~/.claude-session.sh ~/.claude-keepalive.sh ~/.claude-remote-monitor.sh
```

You should see `-> ~/Workfolder/claude-sessions/...` next to each file.

---

## 2. Copy CLAUDE.md to your workdir

```bash
cp ~/Workfolder/claude-sessions/CLAUDE.md ~/Workfolder/workloads/CLAUDE.md
```

> This one is a copy, not a symlink — Claude reads it from the workdir at runtime.

---

## 3. Add aliases to your zshrc

Open `~/.zshrc` and add this block manually:

```zsh
# Claude session management
alias claude-start="~/.claude-session.sh"

claude-resume() {
  local name="${1:-default}"
  tmux attach -t "claude-$(echo "$name" | tr '[:upper:]' '[:lower:]')"
}

claude-stop() {
  local name="${1:-default}"
  local session="claude-$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  tmux kill-session -t "$session" 2>/dev/null
  pkill -f "claude remote" 2>/dev/null
  if [ -f /tmp/claude-caffeinate.pid ]; then
    kill "$(cat /tmp/claude-caffeinate.pid)" 2>/dev/null
    rm /tmp/claude-caffeinate.pid
  fi
  echo "✅ Session ${session} stopped."
}

claude-remote-log() {
  tail -f /tmp/claude-remote.log
}
```

Then reload:

```bash
source ~/.zshrc
```

---

## 4. Verify everything works

```bash
claude-start steve
```

Once inside tmux you'll see 3 windows in the status bar:
- `claude-steve` — your interactive Claude session
- `keepalive` — silent background ping loop
- `remote` — remote access monitor with live status

```bash
# Watch remote access log from any terminal
claude-remote-log

# Detach from tmux (keeps everything running):
# Press Ctrl+B, then D

# Resume from another terminal or after opening lid:
claude-resume steve

# Stop everything cleanly:
claude-stop steve
```

---

## How lid-close persistence works

| Mechanism | What it does |
|---|---|
| `caffeinate -dims` | Prevents display sleep, idle sleep, and disk sleep |
| `tmux` | Keeps all processes running detached from the terminal |
| `keepalive` window | Pings Anthropic API every 55s to prevent connection drops |
| `remote` window | Starts `claude remote` and restarts it automatically if it drops |
| `CLAUDE.md` | Tells Claude to compact context silently without prompting |

> No LaunchAgent needed. After a full reboot, just run `claude-start steve` again.
> To update any script, edit it directly in `~/Workfolder/claude-sessions/` — no re-linking needed.