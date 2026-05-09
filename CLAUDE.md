# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A toolkit for running persistent Claude Code sessions via tmux, with remote access fallback through Tailscale SSH. The script handles session lifecycle (start/resume/stop).

## Repository Structure

- `src/claude-session.sh` — Session launcher. Creates a tmux session, runs `claude` interactively in the target folder, and exits the pane (and session) when Claude exits.
- `README.md` — Workflow overview and setup guide links.

## Setup

The session script is symlinked from `src/` to `~/`:
```
~/.claude-session.sh  ->  ~/Workfolder/code-sessions/src/claude-session.sh
```

Shell aliases (`start-s`, `resume-s`, `stop-s`, `list-s`) are defined in `~/.zshrc`. `start-s` takes a folder path under `~/Workfolder/`; `resume-s` / `stop-s` take a literal session name (read from the tmux status bar or `list-s`). Examples:

- `start-s workloads` → runs Claude in `~/Workfolder/workloads`, session like `workloads-a3f7c2`
- `start-s workloads/.worktrees/foo-bar-baz` → runs in that worktree, session like `workloads-foo-bar-baz-2c8b71`
- `resume-s workloads-a3f7c2` → reattaches to that specific session
- `stop-s workloads-a3f7c2` → kills that specific session
- `list-s` → lists all running sessions

## Key Conventions

- Each session name is `<prefix>-<suffix>`. The prefix is derived from the path (lowercased, hidden components starting with `.` dropped, remaining components joined with `-`; any `.` inside a non-hidden component also becomes `-`). The suffix is six random hex chars from `openssl rand -hex 3`, regenerated every invocation, so two `start-s` calls on the same path always create two distinct sessions.
  - `workloads` → e.g. `workloads-a3f7c2`
  - `workloads/.worktrees/foo-bar-baz` → e.g. `workloads-foo-bar-baz-2c8b71`
  - `workloads/sub/leaf` → e.g. `workloads-sub-leaf-9d1e4f`
- Every launched session disables the tmux status bar (`tmux set-option -t <name> status off`). The setting is scoped per-session, so it never touches the user's global tmux config or any other running session.
- The launcher only manages tmux (and the per-session status bar). No sleep inhibitor, no platform branching — keep it that way.
