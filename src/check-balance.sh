#!/bin/bash
set -euo pipefail

# check-balance.sh — Check DeepSeek API balance from the settings file.
# Reads the auth token from claude-api-settings.json (resolved relative
# to the script's own directory) and calls GET /user/balance.
#
# Usage:
#   ./check-balance.sh           # prints $X.XX
#   ./check-balance.sh --dry-run # prints the curl command (for testing)

# Resolve the real script directory (follow symlinks).
_script="$0"
[ -L "$_script" ] && _script="$(readlink "$_script")"
SCRIPT_DIR="$(cd "$(dirname "$_script")" && pwd)"

# Settings file path — overridable via CHECK_BALANCE_SETTINGS env var for tests.
SETTINGS_FILE="${CHECK_BALANCE_SETTINGS:-$SCRIPT_DIR/claude-api-settings.json}"

# Parse --dry-run flag.
DRY_RUN=false
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=true && break
done

# Read auth token from settings file.
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Error: settings file not found: $SETTINGS_FILE" >&2
  exit 1
fi

TOKEN="$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$SETTINGS_FILE")"
if [ -z "$TOKEN" ]; then
  echo "Error: ANTHROPIC_AUTH_TOKEN not found in $SETTINGS_FILE" >&2
  exit 1
fi

URL="https://api.deepseek.com/user/balance"

if [ "$DRY_RUN" = true ]; then
  echo "curl -sS --fail-with-body '$URL' -H 'Authorization: Bearer $TOKEN'"
  exit 0
fi

# Make the API call.
RESPONSE=""
if ! RESPONSE="$(curl -sS --fail-with-body "$URL" -H "Authorization: Bearer $TOKEN")"; then
  echo "Error: failed to fetch balance from DeepSeek API" >&2
  [ -n "$RESPONSE" ] && echo "$RESPONSE" >&2
  exit 1
fi

# Parse the balance from the JSON response.
BALANCE="$(echo "$RESPONSE" | jq -r '.balance_infos[0].total_balance // empty' 2>/dev/null || true)"
if [ -z "$BALANCE" ]; then
  echo "Error: unexpected response format — could not extract balance" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

# Use LC_ALL=C awk for locale-safe number formatting.  On systems where the
# locale uses comma as decimal separator, bash's printf and bare awk would
# interpret periods as thousands separators and produce wrong output.
LC_ALL=C awk -v b="$BALANCE" 'BEGIN { printf "$%.2f\n", b }'
