# 📟 code-sessions — Persistent Claude Code tmux Sessions

[![CI](https://github.com/heronlabs/code-sessions/actions/workflows/continuous-integration.yml/badge.svg)](https://github.com/heronlabs/code-sessions/actions/workflows/continuous-integration.yml)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

A toolkit for running persistent [Claude Code](https://claude.ai/code) sessions via tmux through the [Headroom](https://github.com/lucaslacerda/headroom) compression proxy with DeepSeek models. Works on **macOS** and **Linux** (tested on Ubuntu).

---

## Table of Contents

- [How It Works](#how-it-works)
- [Install](#install)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## How It Works

### The Workflow

Every `start-s` produces a brand-new session, even if you point it at a folder that already has one running — names never collide:

```bash
start-s workloads                             # → workloads-a3f7c2
start-s workloads                             # → workloads-9d1e4f  (second session, same dir)
start-s workloads/.worktrees/foo-bar-baz      # → workloads-foo-bar-baz-2c8b71
```

Each session name is `<prefix>-<suffix>`:

- **Prefix** is derived from the path so you can tell which folder it lives in: lowercased, hidden components (starting with `.`) dropped, remaining components joined with `-` (any `.` inside a non-hidden component also becomes `-`).
- **Suffix** is six random hex chars from `openssl rand -hex 3`, regenerated every invocation.

| Input | Example session name |
|---|---|
| `start-s workloads` | `workloads-a3f7c2` |
| `start-s workloads` (run again) | `workloads-9d1e4f` |
| `start-s workloads/.worktrees/foo-bar-baz` | `workloads-foo-bar-baz-2c8b71` |

The launcher prints the generated name on stdout, so you always know which session you're in and what to pass to `resume-s` / `stop-s`.

### What Happens When You Run `start-s`

1. A **tmux session** is created with a random unique name.
2. Per-session tmux options are set: status bar disabled, mouse on, history-limit 10000.
3. **Claude Code** launches via `headroom wrap` with DeepSeek settings, inside the target folder.
4. When you exit Claude, the pane exits, ending tmux automatically.

### Remote Access

Access your tmux sessions from any device via Tailscale SSH:

```
Tailscale SSH → Termius → tmux attach -t <session>
```

> **Tailscale creates a private network between your devices** — no port forwarding needed.

---

## Install

### Prerequisites

| Requirement | Purpose |
|---|---|
| `tmux` | Terminal multiplexer for persistent sessions |
| `claude` | Claude Code CLI (`npm i -g @anthropic-ai/claude-code`) |
| `headroom` | Compression proxy for Claude API calls |
| `openssl` | Generating random session name suffixes |
| Tailscale (optional) | Remote access from other devices |

### Setup

The session script is symlinked from `src/` to `~/`:

```bash
ln -sf ~/Workfolder/code-sessions/src/claude-session.sh ~/.claude-session.sh
```

Add the shell aliases to `~/.zshrc` (see [Commands](#commands) for the full definitions). Then source your config or open a new terminal:

```bash
source ~/.zshrc
```

---

## Quick Start

```bash
# Start a session in the workloads folder
start-s workloads

# Resume a specific session by name
resume-s workloads-a3f7c2

# List all running sessions
list-s

# Stop a specific session
stop-s workloads-9d1e4f
```

See the full setup guide for macOS and Ubuntu: **[SETUP.md](SETUP.md)**.

---

## Commands

| Command | Description |
|---|---|
| `start-s <path>` | Create a fresh tmux session (random name) with Claude inside |
| `resume-s <name>` | Reattach to a session by its literal name |
| `stop-s <name>` | Kill the session by name |
| `list-s` | List all running sessions (alias for `tmux ls`) |

### Shell Aliases

Add to `~/.zshrc`:

```bash
# Claude session management
alias start-s="~/.claude-session.sh"

# Resume a session by its literal name (read from tmux status bar or list-s)
resume-s() {
  if [ -z "$1" ]; then echo "Usage: resume-s <name>"; return 1; fi
  tmux attach -t "$1"
}

# Stop a session by name
stop-s() {
  if [ -z "$1" ]; then echo "Usage: stop-s <name>"; return 1; fi
  tmux kill-session -t "$1" 2>/dev/null && echo "Session $1 stopped." \
    || echo "No session named $1."
}

# List all sessions
alias list-s="tmux ls"
```

### Multi-Session Support

Because every `start-s` creates a uniquely-named session, you can run as many in parallel as you like — including multiple in the same folder:

```bash
start-s workloads                             # → workloads-a3f7c2
start-s workloads                             # → workloads-9d1e4f
start-s workloads/.worktrees/foo-bar-baz      # → workloads-foo-bar-baz-2c8b71

list-s
# workloads-a3f7c2: 1 windows (created ...)
# workloads-9d1e4f: 1 windows (created ...) (attached)
# workloads-foo-bar-baz-2c8b71: 1 windows (created ...)

resume-s workloads-a3f7c2
stop-s   workloads-9d1e4f       # only stops that one; the others keep running
```

---

## Configuration

| Layer | What it does |
|---|---|
| `tmux` | Keeps Claude running detached from any terminal |
| `headroom` | Compression proxy between Claude and the API (47–92% input token savings) |
| `CLAUDE.md` | Project-level instructions for Claude when working on this repo |
| Tailscale | Private network between your devices — no port forwarding needed |
| SSH + Termius | Terminal access from your phone to attach to tmux sessions |

### Per-Session tmux Options

Every launched session sets:

```bash
tmux set-option -t <name> status off      # Per-session, never touches global config
tmux set-option -t <name> mouse on
tmux set-option -t <name> history-limit 10000
```

> **All settings are scoped per-session**, so they never interfere with your global tmux config or any other running session.

---

## Architecture

```
code-sessions/
├── src/
│   ├── claude-session.sh      # Session launcher (tmux + headroom)
│   └── session-name.sh        # Library for deriving session prefixes from paths
├── tests/
│   └── test-session-name.bats # BATS tests for session name logic
├── CLAUDE.md                  # Instructions for Claude Code
├── README.md                  # This file
└── SETUP.md                   # Installation guide (macOS + Ubuntu)
```

### Session Launcher (`src/claude-session.sh`)

Creates a tmux session, sets per-session options, and launches `headroom wrap claude` in the target directory. The pane exits when Claude exits, cleaning up the tmux session automatically.

### Prefix Library (`src/session-name.sh`)

A shared bash library that derives a tmux session prefix from any path. Used by the launcher and tested independently with BATS.

---

## Contributing

```bash
make test    # run BATS tests (tests/)
make lint    # shellcheck src/*.sh AND tests/*.bats
```

### Commit Convention

Conventional Commits:

```
feat: add mysql backup engine support
fix: handle edge case with dots only in session path
test: cover empty path in session prefix
```

- All work branches from `main`; PRs target `main`. Never commit directly to `main`.

---

## License

MIT — see [LICENSE](LICENSE).

---

Built by [HeronLabs](https://github.com/heronlabs)
