#!/bin/bash

# session-name.sh — Library for deriving tmux session prefixes from paths.
# Source this file, then call session_prefix <path> to get a prefix string.

# session_prefix takes a filesystem path and echoes a lowercased,
# dash-joined prefix with hidden components dropped and dots replaced.
# Examples:
#   session_prefix "workloads"              → "workloads"
#   session_prefix "workloads/sub/leaf"     → "workloads-sub-leaf"
#   session_prefix "workloads/.wt/foo-bar"  → "workloads-foo-bar"
#   session_prefix "Foo.Bar/MyProject"      → "foo-bar-myproject"
session_prefix() {
  local path="$1"
  local prefix=""
  local _p
  IFS='/' read -ra _parts <<< "$(echo "$path" | tr '[:upper:]' '[:lower:]')"
  for _p in "${_parts[@]}"; do
    [[ -z "$_p" || "$_p" == .* ]] && continue
    prefix="${prefix:+${prefix}-}${_p//./-}"
  done
  echo "$prefix"
}
