#!/usr/bin/env bats

# test-claude-session.bats — Tests for src/claude-session.sh
#
# Uses mock tmux and openssl binaries on PATH so no real session is
# created and the random suffix is deterministic ("abc123").  HOME is
# pointed at a temporary directory with a Workfolder/ fixture so path
# resolution can be asserted without touching the real home.

setup() {
  # Worktree root (two levels up from tests/)
  ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CLAUDE_SESSION="$ROOT/src/claude-session.sh"

  # --- temporary directory for mock binaries ---
  MOCK_DIR="$(mktemp -d)"

  # Mock tmux that logs each invocation (one line per call) and succeeds.
  cat > "$MOCK_DIR/tmux" <<'MOCKEOF'
#!/bin/bash
echo "$*" >> "$TMUX_LOG"
exit 0
MOCKEOF
  chmod +x "$MOCK_DIR/tmux"

  # Mock openssl with a deterministic suffix.
  cat > "$MOCK_DIR/openssl" <<'MOCKEOF'
#!/bin/bash
echo "abc123"
MOCKEOF
  chmod +x "$MOCK_DIR/openssl"

  # Prepend the mock dir to PATH so our mocks shadow the real binaries.
  PATH="$MOCK_DIR:$PATH"

  export TMUX_LOG="$MOCK_DIR/tmux.log"

  # --- fake HOME with a Workfolder fixture ---
  # Resolved to the physical path (macOS mktemp returns /var/... which is
  # a symlink to /private/var/...) so $PWD in the child script matches.
  MOCK_HOME="$(cd "$(mktemp -d)" && pwd -P)"
  mkdir -p "$MOCK_HOME/Workfolder/workloads" "$MOCK_HOME/other/proj"
  export HOME="$MOCK_HOME"
}

teardown() {
  rm -rf "$MOCK_DIR" "$MOCK_HOME" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# No-argument default: current working directory
# ---------------------------------------------------------------------------

@test "no argument from dir under Workfolder uses cwd with relative prefix" {
  cd "$MOCK_HOME/Workfolder/workloads" || return
  run "$CLAUDE_SESSION"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "workloads-abc123"
  echo "$output" | grep -qF "$MOCK_HOME/Workfolder/workloads"
  grep -q "new-session -d -s workloads-abc123" "$TMUX_LOG"
  grep -qF "cd '$MOCK_HOME/Workfolder/workloads'" "$TMUX_LOG"
}

@test "no argument from dir outside Workfolder strips HOME prefix" {
  cd "$MOCK_HOME/other/proj" || return
  run "$CLAUDE_SESSION"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "other-proj-abc123"
  grep -q "new-session -d -s other-proj-abc123" "$TMUX_LOG"
  grep -qF "cd '$MOCK_HOME/other/proj'" "$TMUX_LOG"
}

# ---------------------------------------------------------------------------
# Explicit path: unchanged behavior
# ---------------------------------------------------------------------------

@test "explicit path resolves under ~/Workfolder" {
  run "$CLAUDE_SESSION" workloads
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "workloads-abc123"
  grep -q "new-session -d -s workloads-abc123" "$TMUX_LOG"
  grep -qF "cd '$MOCK_HOME/Workfolder/workloads'" "$TMUX_LOG"
}

@test "explicit path to missing folder exits non-zero" {
  run "$CLAUDE_SESSION" does-not-exist
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "Folder not found"
}
