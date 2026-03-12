# Claude Session Setup — Manual Steps

Follow these steps in order. Everything here requires your confirmation before running.

---

## 1. Create symbolic links

Instead of copying files, link them so `~/Workfolder/claude-sessions/src/` stays the single source of truth.
Edit the scripts there and the links pick up changes automatically.

```bash
ln -sf ~/Workfolder/claude-sessions/src/claude-session.sh ~/.claude-session.sh
chmod +x ~/Workfolder/claude-sessions/src/*.sh
```

Verify the link is correct:

```bash
ls -la ~/.claude-session.sh
```

You should see `-> ~/Workfolder/claude-sessions/src/...` next to the file.

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
  if [ -f /tmp/claude-caffeinate.pid ]; then
    kill "$(cat /tmp/claude-caffeinate.pid)" 2>/dev/null
    rm /tmp/claude-caffeinate.pid
  fi
  echo "Session ${session} stopped."
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

Once inside tmux you'll see 2 panes:
- Left: your interactive Claude session
- Right: keepalive ping loop

```bash
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
| `keepalive` pane | Pings Anthropic API every 55s to prevent connection drops |
| `CLAUDE.md` | Tells Claude to compact context silently without prompting |

> No LaunchAgent needed. After a full reboot, just run `claude-start steve` again.
> To update any script, edit it directly in `~/Workfolder/claude-sessions/src/` — no re-linking needed.
