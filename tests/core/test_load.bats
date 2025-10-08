#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/helper_log

setup() { setup_common; }
teardown() { teardown_common; }

star_load_and_echo_pwd() {
  cd /
  star load "$1"
  echo "$PWD"
}

@test "star load - requires at least one argument" {
  run star load
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "star load - load without any starred directories fails" {
  run star load 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"no starred directories"* ]]
}

@test "star load - load by index navigates to correct dir" {
  mkdir "$TEST_ROOT/foo_index"
  star add "$TEST_ROOT/foo_index"

  cd /

  # cannot use bats' "run" command as it creates a subshell
  if ! star load 1; then
    return 1
  fi
  log_variable PWD
  [ "$PWD" = "$TEST_ROOT/foo_index" ]
}

@test "star load - does not accept invalid indexes" {
  mkdir "$TEST_ROOT/foo_index"
  star add "$TEST_ROOT/foo_index"
  
  run star load 2
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid index"* ]]

  # we do not test negative numbers as it is not relevant 
  # and a star could be named "-N" with N being a number
}

@test "star load - load by name navigates to correct dir" {
  mkdir "$TEST_ROOT/foo_name"
  star add "$TEST_ROOT/foo_name" NAME_FOO

  cd /

  # cannot use bats' "run" command as it creates a subshell
  if ! star load NAME_FOO; then
    return 1
  fi
  log_variable PWD
  [ "$PWD" = "$TEST_ROOT/foo_name" ]
}

@test "star load - load by name containing slashes" {
  mkdir "$TEST_ROOT/foo_slash"
  star add "$TEST_ROOT/foo_slash" FOO/SLASH

  cd /

  # cannot use bats' "run" command as it creates a subshell
  if ! star load FOO/SLASH; then
    return 1
  fi
  log_variable PWD
  [ "$PWD" = "$TEST_ROOT/foo_slash" ]
}

@test "star load - load updates the access time" {
  mkdir "$TEST_ROOT/foo_A"
  star add "$TEST_ROOT/foo_A"
  mkdir "$TEST_ROOT/foo_B"
  star add "$TEST_ROOT/foo_B"

  cd /

  # TODO: set STAR SORT to sort according to access time

  # need to sleep else the updated time would be the same as the creation time
  sleep 1

  star list
  find "$_STAR_HOME/$_STAR_STARS_DIR" -type l -not -xtype l -printf "%As %f %l\n"

  # cannot use bats' "run" command as it creates a subshell
  if ! star load 2; then
    return 1
  fi
  log_variable PWD
  [ "$PWD" = "$TEST_ROOT/foo_A" ]

  sleep 1

  star list
  find "$_STAR_HOME/$_STAR_STARS_DIR" -type l -not -xtype l -printf "%As %f %l\n"

  # cannot use bats' "run" command as it creates a subshell
  if ! star load 2; then
    return 1
  fi
  log_variable PWD
  [ "$PWD" = "$TEST_ROOT/foo_B" ]
}
