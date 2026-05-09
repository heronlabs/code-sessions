# Claude Code Sessions

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. Works on **macOS** and **Linux** (tested on Ubuntu).

---

## How It Works

### The Workflow

```
start-s <path>       →  Creates a fresh tmux session (random name) with Claude inside
resume-s <name>      →  Reattaches to a session by its literal name
stop-s <name>        →  Kills the session by name
list-s               →  Lists all running sessions (alias for `tmux ls`)
```

Every `start-s` produces a brand-new session, even if you point it at a folder that already has one running — names never collide:

```bash
start-s workloads                             # → workloads-a3f7c2
start-s workloads                             # → workloads-9d1e4f  (second session, same dir)
start-s workloads/.worktrees/foo-bar-baz      # → workloads-foo-bar-baz-2c8b71
```

### Session names

Each session name is `<prefix>-<suffix>`:

- **prefix** is derived from the path so you can tell which folder it lives in: lowercased, hidden components (starting with `.`) dropped, remaining components joined with `-` (any `.` inside a non-hidden component also becomes `-`).
- **suffix** is six random hex chars from `openssl rand -hex 3`, regenerated every invocation.

Examples:

| Input | Example session name |
|---|---|
| `start-s workloads` | `workloads-a3f7c2` |
| `start-s workloads` (run again) | `workloads-9d1e4f` |
| `start-s workloads/.worktrees/foo-bar-baz` | `workloads-foo-bar-baz-2c8b71` |

The launcher prints the generated name on stdout and pins it to the tmux status bar (see below), so you always know which session you're in and what to pass to `resume-s` / `stop-s`.

### Status bar

Every launched session gets a customized tmux status bar:

- **Left:** full session name (`#S`).
- **Right:** current time and weekday — `HH:MM | <Day>` (e.g. `14:32 | Saturday`).

The bar is scoped to the session being launched, so it never touches your global tmux config or any other running session.

### What Happens When You Run `start-s`

1. A **tmux session** is created with a random unique name
2. The status bar is configured (session name | time | weekday)
3. **Claude Code** launches in interactive mode inside the target folder
4. When you exit Claude, the pane exits, ending tmux automatically

### Remote Access

```
Primary:   claude remote (from Claude app / phone)
Fallback:  Tailscale SSH → Termius → tmux attach -t <session>
```

Tailscale creates a private network between your devices — no port forwarding needed.

---

## Repository Structure

```
src/
└── claude-session.sh           # Session launcher (tmux)

SETUP.md                        # Setup guide (macOS + Ubuntu)
CLAUDE.md                       # Instructions for Claude Code itself
```

---

## Quick Start

Follow the unified setup guide: **[SETUP.md](SETUP.md)** (covers macOS and Ubuntu).

---

## Multi-Session Support

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

## Shell Aliases

Add to `~/.zshrc`:

```zsh
# Claude session management
alias start-s="~/.claude-session.sh"

# Each start-s invocation creates a uniquely-named session, so resume-s
# and stop-s take the literal session name (read it from the tmux status
# bar, or list with `list-s`).

resume-s() {
  if [ -z "$1" ]; then echo "Usage: resume-s <name>"; return 1; fi
  tmux attach -t "$1"
}

stop-s() {
  if [ -z "$1" ]; then echo "Usage: stop-s <name>"; return 1; fi
  tmux kill-session -t "$1" 2>/dev/null && echo "Session $1 stopped." \
    || echo "No session named $1."
}

alias list-s="tmux ls"
```

---

## How Everything Fits Together

| Layer | What it does |
|---|---|
| `tmux` | Keeps the Claude process running detached from any terminal |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| Tailscale | Private network between your devices — no port forwarding needed |
| SSH + Termius | Fallback terminal from your phone if `claude remote` stops working |
