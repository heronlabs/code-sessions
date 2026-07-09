#!/usr/bin/env bats

# test-check-balance.bats — Tests for src/check-balance.sh
#
# Uses a mock curl on PATH to intercept HTTP calls without hitting the
# real DeepSeek API.  The settings file path is overridden via the
# CHECK_BALANCE_SETTINGS environment variable so each test can use a
# controlled fixture.

setup() {
  # Worktree root (two levels up from tests/)
  ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CHECK_BALANCE="$ROOT/src/check-balance.sh"

  # --- temporary directory for mock curl ---
  MOCK_DIR="$(mktemp -d)"

  # Mock curl that validates the request and returns a configurable response.
  # Environment variables read by the mock:
  #   MOCK_RESPONSE    — JSON body to return (default: valid balance)
  #   MOCK_EXIT_CODE   — exit code for curl (default: 0)
  cat > "$MOCK_DIR/curl" <<'MOCKEOF'
#!/bin/bash
MOCK_EXIT_CODE="${MOCK_EXIT_CODE:-0}"
VALID_URL="https://api.deepseek.com/user/balance"

# Verify the request URL is correct.
FOUND_URL=false
for arg in "$@"; do
  if [ "$arg" = "$VALID_URL" ]; then
    FOUND_URL=true
    break
  fi
done
if [ "$FOUND_URL" = false ]; then
  echo "mock curl: expected URL '$VALID_URL' not found in arguments" >&2
  exit 1
fi

if [ "$MOCK_EXIT_CODE" != "0" ]; then
  echo "Connection error (simulated)" >&2
  exit "$MOCK_EXIT_CODE"
fi

echo "$MOCK_RESPONSE"
MOCKEOF
  chmod +x "$MOCK_DIR/curl"

  # Prepend the mock dir to PATH so our mock shadows the real curl.
  PATH="$MOCK_DIR:$PATH"

  # --- temporary settings file ---
  MOCK_SETTINGS="$(mktemp)"
  cat > "$MOCK_SETTINGS" <<JSONEOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-test-token-for-tests-only"
  }
}
JSONEOF

  export CHECK_BALANCE_SETTINGS="$MOCK_SETTINGS"
  export MOCK_RESPONSE='{"is_available":true,"balance_infos":[{"currency":"USD","total_balance":"2.52","granted_balance":"0.00","topped_up_balance":"2.52"}]}'
  export MOCK_EXIT_CODE=0
}

teardown() {
  rm -rf "$MOCK_DIR" "$MOCK_SETTINGS" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Success cases
# ---------------------------------------------------------------------------

@test "successful balance response prints \$X.XX" {
  run "$CHECK_BALANCE"
  [ "$status" -eq 0 ]
  [ "$output" = "\$2.52" ]
}

@test "zero balance prints \$0.00" {
  MOCK_RESPONSE='{"is_available":true,"balance_infos":[{"currency":"USD","total_balance":"0.00","granted_balance":"0.00","topped_up_balance":"0.00"}]}'
  run "$CHECK_BALANCE"
  [ "$status" -eq 0 ]
  [ "$output" = "\$0.00" ]
}

@test "balance with single decimal prints \$X.X0" {
  MOCK_RESPONSE='{"is_available":true,"balance_infos":[{"currency":"USD","total_balance":"2.5","granted_balance":"0.00","topped_up_balance":"2.5"}]}'
  run "$CHECK_BALANCE"
  [ "$status" -eq 0 ]
  [ "$output" = "\$2.50" ]
}

# ---------------------------------------------------------------------------
# Error cases
# ---------------------------------------------------------------------------

@test "network error exits non-zero and prints error message" {
  export MOCK_EXIT_CODE=1
  run "$CHECK_BALANCE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "error"
}

@test "missing settings file exits non-zero and prints error message" {
  export CHECK_BALANCE_SETTINGS="/tmp/nonexistent-settings-XXXXXXXXXX.json"
  run "$CHECK_BALANCE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "error"
}

@test "missing token in settings file exits non-zero" {
  cat > "$MOCK_SETTINGS" <<JSONEOF
{
  "env": {}
}
JSONEOF
  run "$CHECK_BALANCE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "token"
}

@test "bad JSON response exits non-zero and prints error" {
  MOCK_RESPONSE='not valid json'
  run "$CHECK_BALANCE"
  [ "$status" -ne 0 ]
  echo "$output" | grep -qi "error"
}

# ---------------------------------------------------------------------------
# Dry-run mode
# ---------------------------------------------------------------------------

@test "--dry-run prints the curl command with URL and auth header" {
  run "$CHECK_BALANCE" --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "api.deepseek.com/user/balance"
  echo "$output" | grep -q "Authorization: Bearer"
}
