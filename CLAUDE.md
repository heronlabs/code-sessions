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

Shell aliases (`start-s`, `resume-s`, `stop-s`) are defined in `~/.zshrc`. The argument is a folder path under `~/Workfolder/`. Examples:

- `start-s workloads` → runs Claude in `~/Workfolder/workloads`
- `start-s workloads/.worktrees/foo-bar-baz` → runs Claude in that nested worktree

## Key Conventions

- Session names are derived from the path: lowercased, hidden components (starting with `.`) dropped, remaining components joined with `-`. Any remaining `.` inside a non-hidden component is also replaced with `-`.
  - `workloads` → tmux session `workloads`
  - `workloads/.worktrees/foo-bar-baz` → tmux session `workloads-foo-bar-baz`
  - `workloads/sub/leaf` → tmux session `workloads-sub-leaf`
- The launcher only manages tmux. There is no sleep inhibitor, no status bar, no platform branching — keep it that way.
