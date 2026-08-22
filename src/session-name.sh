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
  local _p _parts
  IFS='/' read -ra _parts <<< "$(echo "$path" | tr '[:upper:]' '[:lower:]')"
  for _p in "${_parts[@]}"; do
    [[ -z "$_p" || "$_p" == .* ]] && continue
    prefix="${prefix:+${prefix}-}${_p//./-}"
  done
  echo "$prefix"
}

# session_prefix_from_dir takes an absolute directory and echoes a prefix
# derived from the path relative to ~/Workfolder (falling back to ~, then
# the full path), so cwd-based launches match the start-s <folder> naming.
# Examples (with HOME=/Users/me):
#   session_prefix_from_dir "/Users/me/Workfolder/workloads"  → "workloads"
#   session_prefix_from_dir "/Users/me/other/proj"            → "other-proj"
#   session_prefix_from_dir "/opt/foo"                        → "opt-foo"
session_prefix_from_dir() {
  local dir="$1"
  dir="${dir#"$HOME/Workfolder/"}"
  dir="${dir#"$HOME/"}"
  session_prefix "$dir"
}
