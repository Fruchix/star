#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/helper_envvars

setup() {
  setup_common

  # unset all environment variables to ensure a clean test environment
  unset_envvars

  # ensure environment variables are enabled
  export __STAR_ENABLE_ENVVARS=yes
}
teardown() { teardown_common; }

@test "env vars enabled - initializing star with env vars enabled sets the environment variables for existing stars" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  # unset all environment variables to ensure a clean test environment
  unset_envvars

  # check there are no environment variables set
  run list_envvars
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]

  # re-initialize star to set the environment variables for existing stars
  init_star

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable has the correct name and value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]
}

@test "env vars enabled - initializing star with env vars enabled does not override existing environment variables" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  # unset all environment variables to ensure a clean test environment
  unset_envvars

  # check there are no environment variables set
  run list_envvars
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]

  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"

  # re-initialize star to set the environment variables for existing stars
  init_star

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable has not been overridden
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars enabled - 'star add' sets an environment variable named after the bookmark and points to its path" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo"

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable has the correct name and value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]
}

@test "env vars enabled - 'star add' does not override existing environment variables" {
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo"

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable has not been overridden
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars enabled - 'star remove' unsets the corresponding environment variable" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is set
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]

  star remove foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is unset
  [[ "$output" != "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]
}

@test "env vars enabled - 'star remove' does not unset a variable that was not set by star" {
  mkdir "$TEST_ROOT/foo"
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is set to the original value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]

  star remove foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is still set to the original value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars enabled - 'star rename' updates the environment variable name" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is set
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the old environment variable is unset and the new one is set
  [[ "$output" != "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]
  [[ "$output" == "${STAR_ENVVAR_PREFIX}BAR=$TEST_ROOT/foo" ]]
}

@test "env vars enabled - 'star rename' does not override existing environment variables" {
  mkdir "$TEST_ROOT/foo"
  export "${STAR_ENVVAR_PREFIX}BAR=/some/other/path"
  star add "$TEST_ROOT/foo" foo

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is set to the original value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}BAR=/some/other/path" ]]
}

@test "env vars enabled - 'star rename' does not unset a variable that was not set by star" {
  mkdir "$TEST_ROOT/foo"
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  star add "$TEST_ROOT/foo" foo

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is still set to the original while the renamed variable is also set
  [[ "$(echo "$output" | head -n 1)" == "${STAR_ENVVAR_PREFIX}BAR=$TEST_ROOT/foo" ]]
  [[ "$(echo "$output" | tail -n 1)" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars enabled - 'star reset' removes all environment variables" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  star reset --force

  run list_envvars
  [ "$status" -eq 0 ]
  # no environment variables should be set after reset
  [[ "$output" == "" ]]
}

@test "env vars enabled - 'star reset' does not remove environment variables that were not set by star" {
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  star reset --force

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should still be set after reset
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars enabled - any star command updates environment variables if config changes" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  export __STAR_ENABLE_ENVVARS=no
  star

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should be unset after disabling env vars
  [[ "$output" == "" ]]

  export __STAR_ENABLE_ENVVARS=yes
  star

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should be set after enabling env vars
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]
}
