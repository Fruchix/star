#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "star list - __STAR_LIST_FORMAT variable can be used to set the format" {
  mkdir -p "$TEST_ROOT/dir"
  star add "$TEST_ROOT/dir" "name"

  export __STAR_LIST_FORMAT="%f<BR>%l"
  run star list
  [[ "$status" -eq 0 ]]
  # default command "column" produces a two whitespaces separation
  [[ "$output" == "name  $TEST_ROOT/dir" ]]

  export __STAR_LIST_FORMAT="%f<BR>-<BR>%l"
  run star list
  [[ "$status" -eq 0 ]]
  [[ "$output" == "name  -  $TEST_ROOT/dir" ]]
}

@test "star list - __STAR_LIST_FORMAT variable can contain an <INDEX> placeholder" {
  mkdir -p "$TEST_ROOT/dir1"
  mkdir -p "$TEST_ROOT/dir2"

  star add "$TEST_ROOT/dir1" "name1"
  star add "$TEST_ROOT/dir2" "name2"

  export __STAR_LIST_FORMAT="<INDEX>"
  run star list
  [[ "$status" -eq 0 ]]
  [[ "$(echo "$output" | head -n 1)" == "1" ]]
  [[ "$(echo "$output" | tail -n 1)" == "2" ]]
}

# TODO: check with variables ORDER, SORT, etc.

@test "star list - list shows bookmarks" {
  skip "not implemented yet"
}

@test "star list - list order can be changed with config" {
  skip "not implemented yet"
}
