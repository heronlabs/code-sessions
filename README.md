# Claude Code Sessions

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. Works on **macOS**, **Ubuntu**, and **Windows (WSL2)**.

---

## How It Works

### The Workflow

```
start-s <project>     →  Creates a named tmux session with Claude running inside
resume-s <project>    →  Reattaches to an existing session
stop-s <project>      →  Kills the session and cleans up background processes
```

Each session is fully independent. You can run multiple projects in parallel:

```bash
start-s frontend      # → tmux session: claude-frontend
start-s backend       # → tmux session: claude-backend
start-s infra         # → tmux session: claude-infra
```

### What Happens When You Run `start-s`

1. **Sleep prevention** starts — keeps the machine awake even with the lid closed
2. A **tmux session** is created (named `claude-<project>`)
3. A **keepalive** background process pings `api.anthropic.com` every 55s
4. **Claude Code** launches in interactive mode inside the project folder

### The Interface

```
┌──────────────────────────────────────────────────────────┐
│ #[fg=#7aa2f7]◆ claude                                    │
│                                                          │
│  Claude Code interactive session                         │
│  Working directory: ~/Workfolder/<project>               │
│                                                          │
│                                                          │
│                                                          │
│                                                          │
│                                                          │
├──────────────────────────────────────────────────────────┤
│  session │ ● Keepalive │  Mem: 45% │  Sat 05 Apr │ 14:30│
└──────────────────────────────────────────────────────────┘
```

- **Full-screen pane**: Claude Code interactive session
- **Status bar (bottom)**: session name, keepalive status, memory usage, date/time

### Remote Access

```
Primary:   claude remote (from Claude app / phone)
Fallback:  Tailscale SSH → Termius → tmux attach -t claude-<project>
```

Tailscale creates a private network between your devices — no port forwarding needed.

---

## Repository Structure

```
src/
├── mac-claude-session.sh       # macOS session launcher (includes keepalive)
├── ubuntu-claude-session.sh    # Ubuntu session launcher (includes keepalive)
└── windows-claude-session.sh   # Windows (WSL2) session launcher (includes keepalive)

SETUP_MAC.md                    # Full setup guide for macOS
SETUP_UBUNTU.md                 # Full setup guide for Ubuntu
SETUP_WINDOWS.md                # Full setup guide for Windows (WSL2)
CLAUDE.md                       # Instructions for Claude Code itself
```

---

## Quick Start

Pick your platform and follow the setup guide:

| Platform | Guide | Session Script |
|---|---|---|
| **macOS** | [SETUP_MAC.md](SETUP_MAC.md) | `mac-claude-session.sh` |
| **Ubuntu** | [SETUP_UBUNTU.md](SETUP_UBUNTU.md) | `ubuntu-claude-session.sh` |
| **Windows (WSL2)** | [SETUP_WINDOWS.md](SETUP_WINDOWS.md) | `windows-claude-session.sh` |

---

## Multi-Session Support

All session scripts support running multiple projects in parallel. Each session gets its own:

- tmux session (`claude-frontend`, `claude-backend`, etc.)
- Sleep inhibitor PID file (`/tmp/claude-caffeinate-frontend.pid`)
- Keepalive PID file (`/tmp/claude-keepalive-frontend.pid`)
- Keepalive status file (`/tmp/claude-keepalive-status-frontend`)
- Session start timestamp (`/tmp/claude_session_start_frontend`)

Stopping one session does not affect others:

```bash
start-s frontend      # Start project A
start-s backend       # Start project B — independent of A

stop-s frontend       # Only stops frontend, backend keeps running
```

List all active sessions:

```bash
tmux ls
```

---

## Platform Differences

| Feature | macOS | Ubuntu | Windows (WSL2) |
|---|---|---|---|
| Sleep prevention | `caffeinate -dims` | `systemd-inhibit` | `powercfg` via PowerShell |
| Memory in status bar | `memory_pressure` | `free -m` | `free -m` |
| Package manager | Homebrew | APT | APT (inside WSL) |
| SSH server | System Settings toggle | `openssh-server` | Windows OpenSSH |
| Shell | Zsh (default) | `chsh -s $(which zsh)` | `chsh -s $(which zsh)` in WSL |

---

## Shell Aliases (All Platforms)

Add to `~/.zshrc`:

```zsh
# Claude session management
alias start-s="~/.claude-session.sh"

resume-s() {
  if [ -z "$1" ]; then echo "Usage: resume-s <folder>"; return 1; fi
  tmux attach -t "claude-$(echo "$1" | tr '[:upper:]' '[:lower:]')"
}

stop-s() {
  if [ -z "$1" ]; then echo "Usage: stop-s <folder>"; return 1; fi
  local name="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  local session="claude-${name}"
  tmux kill-session -t "$session" 2>/dev/null
  if [ -f /tmp/claude-caffeinate-${name}.pid ]; then
    kill "$(cat /tmp/claude-caffeinate-${name}.pid)" 2>/dev/null
    rm /tmp/claude-caffeinate-${name}.pid
  fi
  if [ -f /tmp/claude-keepalive-${name}.pid ]; then
    kill "$(cat /tmp/claude-keepalive-${name}.pid)" 2>/dev/null
    rm /tmp/claude-keepalive-${name}.pid
  fi
  rm -f /tmp/claude_session_start_${name}
  rm -f /tmp/claude-keepalive-status-${name}
  echo "Session ${session} stopped."
}

alias claude-remote-log="tail -f /tmp/claude-remote.log"
```

> **Note:** The `stop-s` alias uses per-session PID files, so stopping one session never affects another.

---

## How Everything Fits Together

| Layer | What it does |
|---|---|
| Sleep inhibitor | Prevents idle/display/lid-close sleep while a session is active |
| `tmux` | Keeps all processes running detached from any terminal |
| Keepalive (background) | Pings Anthropic API every 55s to prevent connection drops |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| Tailscale | Private network between your devices — no port forwarding needed |
| SSH + Termius | Fallback terminal from your phone if `claude remote` stops working |
