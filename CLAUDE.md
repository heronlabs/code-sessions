# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. The scripts handle session lifecycle (start/resume/stop), sleep prevention (`caffeinate`), and API keepalive pings.

## Repository Structure

- `src/mac-claude-session.sh` — macOS session launcher. Creates a tmux session with Claude interactive, prevents sleep via `caffeinate -dims`, and runs an inline keepalive that pings `api.anthropic.com` every 55s.
- `src/ubuntu-claude-session.sh` — Ubuntu session launcher. Same as Mac but uses `systemd-inhibit` for sleep prevention and `free -m` for memory.
- `src/windows-claude-session.sh` — Windows (WSL2) session launcher. Same as Ubuntu but uses `powercfg` for sleep prevention.
- `README.md` — Workflow overview and setup guide links for all platforms.

## Setup

The platform session script is symlinked from `src/` to `~/`:
```
~/.claude-session.sh  ->  ~/Workfolder/code-sessions/src/mac-claude-session.sh   # (or ubuntu- or windows-)
```

Shell aliases (`start-s`, `resume-s`, `stop-s`) are defined in `~/.zshrc`. The argument is a folder name under `~/Workfolder/` (e.g., `start-s workloads` runs Claude in `~/Workfolder/workloads`).

## Key Conventions

- Session names are lowercased and prefixed with `claude-` (e.g., `claude-steve`).
- `caffeinate` PID is stored at `/tmp/claude-caffeinate-<name>.pid` (per session) and cleaned up on stop.
- The keepalive loop is inlined in each platform's session script — no separate keepalive file needed.
