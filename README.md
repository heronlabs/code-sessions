# Claude Code Sessions

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. Works on **macOS** and **Linux** (tested on Ubuntu).

---

## How It Works

### The Workflow

```
start-s <path>       →  Creates a named tmux session with Claude running inside
resume-s <path>      →  Reattaches to an existing session
stop-s <path>        →  Kills the session
```

Each session is fully independent. You can run multiple projects in parallel:

```bash
start-s frontend                              # → tmux session: frontend
start-s backend                               # → tmux session: backend
start-s workloads/.worktrees/foo-bar-baz      # → tmux session: workloads-foo-bar-baz
```

### Session naming

The launcher derives a tmux-safe session name from the path you pass:

1. Lowercase the input.
2. Split on `/`, drop hidden components (anything starting with `.`).
3. Replace remaining `.` with `-` and join the components with `-`.

Examples:

| Input | Session name |
|---|---|
| `workloads` | `workloads` |
| `workloads/.worktrees/foo-bar-baz` | `workloads-foo-bar-baz` |
| `workloads/sub/leaf` | `workloads-sub-leaf` |

This means each git worktree gets its own session automatically — no manual naming needed.

### What Happens When You Run `start-s`

1. A **tmux session** is created (named via the rule above)
2. **Claude Code** launches in interactive mode inside the target folder
3. When you exit Claude, the pane exits, ending tmux automatically

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

The launcher supports running multiple projects (and worktrees) in parallel. Each session is its own independent tmux instance:

```bash
start-s frontend                              # session: frontend
start-s backend                               # session: backend
start-s workloads/.worktrees/foo-bar-baz      # session: workloads-foo-bar-baz

stop-s frontend       # only stops 'frontend'; the others keep running
```

List all active sessions:

```bash
tmux ls
```

---

## Shell Aliases

Add to `~/.zshrc`:

```zsh
# Claude session management
alias start-s="~/.claude-session.sh"

# Same derivation rule as the launcher: lowercase, drop hidden path
# components, replace '.' with '-', join with '-'.
_claude_session_name() {
  local input session="" part
  input="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  while [[ -n "$input" ]]; do
    part="${input%%/*}"
    if [[ "$input" == *"/"* ]]; then
      input="${input#*/}"
    else
      input=""
    fi
    [[ -z "$part" || "$part" == .* ]] && continue
    session="${session:+${session}-}${part//./-}"
  done
  echo "$session"
}

resume-s() {
  if [ -z "$1" ]; then echo "Usage: resume-s <path>"; return 1; fi
  tmux attach -t "$(_claude_session_name "$1")"
}

stop-s() {
  if [ -z "$1" ]; then echo "Usage: stop-s <path>"; return 1; fi
  local session="$(_claude_session_name "$1")"
  tmux kill-session -t "$session" 2>/dev/null && echo "Session ${session} stopped." \
    || echo "No session named ${session}."
}
```

---

## How Everything Fits Together

| Layer | What it does |
|---|---|
| `tmux` | Keeps the Claude process running detached from any terminal |
| `CLAUDE.md` | Instructs Claude to compact context silently and never pause for approval |
| Tailscale | Private network between your devices — no port forwarding needed |
| SSH + Termius | Fallback terminal from your phone if `claude remote` stops working |
