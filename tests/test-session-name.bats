#!/usr/bin/env bats

setup() {
  load "$(dirname "$BATS_TEST_FILENAME")/../src/session-name.sh"
}

@test "flat path: workloads → workloads" {
  result="$(session_prefix "workloads")"
  [ "$result" = "workloads" ]
}

@test "nested path: workloads/sub/leaf → workloads-sub-leaf" {
  result="$(session_prefix "workloads/sub/leaf")"
  [ "$result" = "workloads-sub-leaf" ]
}

@test "hidden components dropped: workloads/.worktrees/foo-bar-baz → workloads-foo-bar-baz" {
  result="$(session_prefix "workloads/.worktrees/foo-bar-baz")"
  [ "$result" = "workloads-foo-bar-baz" ]
}

@test "dots replaced: foo.bar/baz.qux → foo-bar-baz-qux" {
  result="$(session_prefix "foo.bar/baz.qux")"
  [ "$result" = "foo-bar-baz-qux" ]
}

@test "uppercase lowered: Workloads/MyProject → workloads-myproject" {
  result="$(session_prefix "Workloads/MyProject")"
  [ "$result" = "workloads-myproject" ]
}

@test "single component: project → project" {
  result="$(session_prefix "project")"
  [ "$result" = "project" ]
}

@test "empty/hidden-only: .hidden/.also-hidden → empty string" {
  result="$(session_prefix ".hidden/.also-hidden")"
  [ -z "$result" ]
}
