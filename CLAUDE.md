# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. The scripts handle session lifecycle (start/resume/stop), sleep prevention (`caffeinate`), and API keepalive pings.

## Repository Structure

- `src/claude-session.sh` — Main session launcher. Creates a tmux session with a single full-screen pane running Claude interactive. Prevents machine sleep via `caffeinate -dims`. Use `/spawn-terminal` inside Claude to toggle an on-demand shell pane (30% bottom split).
- `src/claude-keepalive.sh` — Pings `api.anthropic.com` every 55s to prevent connection drops. Runs as a background process.
- `README.md` — Full manual setup guide (symlinks, aliases, Tailscale, Termius).

## Setup

Scripts are symlinked from `src/` to `~/`:
```
~/.claude-session.sh  ->  ~/Workfolder/code-sessions/src/claude-session.sh
~/.claude-keepalive.sh -> ~/Workfolder/code-sessions/src/claude-keepalive.sh
```

Shell aliases (`start-s`, `resume-s`, `stop-s`) are defined in `~/.zshrc`. The argument is a folder name under `~/Workfolder/` (e.g., `start-s workloads` runs Claude in `~/Workfolder/workloads`).

## Key Conventions

- Session names are lowercased and prefixed with `claude-` (e.g., `claude-steve`).
- `caffeinate` PID is stored at `/tmp/claude-caffeinate.pid` and cleaned up on stop.
- The keepalive script resolves its path relative to `claude-session.sh` via `SCRIPT_DIR`, so both scripts must stay in the same directory.
