#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "star rename - requires two arguments" {
  run star rename
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]

  run star rename foo
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "star rename - rename works with new unique name" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" "name1"

  run star rename name1 name2
  [ "$status" -eq 0 ]
  [[ -L "${CURRENT_TEST_DATA_DIR}/name2" ]]
  [ "$(readlink -f "${CURRENT_TEST_DATA_DIR}/name2")" = "$TEST_ROOT/foo" ]
}

@test "star rename - rename is case sensitive" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" "FOO"

  run star rename FOO foo
  [ "$status" -eq 0 ]
  [[ -L "${CURRENT_TEST_DATA_DIR}/foo" ]]
  [ "$(readlink -f "${CURRENT_TEST_DATA_DIR}/foo")" = "$TEST_ROOT/foo" ]
}

@test "star rename - rename fails if new name exists" {
  mkdir "$TEST_ROOT/foo"
  mkdir "$TEST_ROOT/bar"
  star add "$TEST_ROOT/foo"
  star add "$TEST_ROOT/bar"

  run star rename foo bar
  [ "$status" -ne 0 ]
}

@test "star rename - cannot rename a star that does not exist" {
  run star rename foo bar
  [ "$status" -ne 0 ]
}
