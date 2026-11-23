#!/usr/bin/env bats

load ../helpers/helper_setup
load ../helpers/helper_envvars

setup() {
  setup_common

  # unset all environment variables to ensure a clean test environment
  unset_envvars

  # ensure environment variables are disabled
  export __STAR_ENABLE_ENVVARS=no
}
teardown() { teardown_common; }

@test "env vars disabled - initializing star with env vars disabled does not set the environment variables for existing stars" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  # unset all environment variables to ensure a clean test environment
  unset_envvars

  # check there are no environment variables set
  run list_envvars
  [ "$status" -eq 0 ]
  [[ "$output" == "" ]]

  # re-initialize star
  init_star

  run list_envvars
  [ "$status" -eq 0 ]
  # check that there are still no environment variables set
  [[ "$output" == "" ]]
}

@test "env vars disabled - initializing star with env vars disabled does not override existing environment variables" {
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

@test "env vars disabled - 'star add' does not set an environment variable named after the bookmark and points to its path" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo"

  run list_envvars
  [ "$status" -eq 0 ]
  # check that there are still no environment variables set
  [[ "$output" == "" ]]
}

@test "env vars disabled - 'star add' does not override existing environment variables" {
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo"

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable has not been overridden
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars disabled - 'star remove' unsets the corresponding environment variable if it was still set" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # environment variable should not be set since env vars are disabled
  [[ "$output" == "" ]]

  # manually set the environment variable to the same name and value
  export "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo"

  star remove foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is unset
  [[ "$output" == "" ]]
}

@test "env vars disabled - 'star remove' does not unset a variable that was not set by star" {
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

@test "env vars disabled - 'star rename' does not set a new environment variable and unsets the old one if it corresponds to the star env var format" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is not set
  [[ "$output" == "" ]]

  # manually set the environment variable to the same name and value
  export "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo"

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # old environment variable should be unset and new one should not be set
  [[ "$output" == "" ]]
}

@test "env vars disabled - 'star rename' does not override existing environment variables" {
  mkdir "$TEST_ROOT/foo"
  export "${STAR_ENVVAR_PREFIX}BAR=/some/other/path"
  star add "$TEST_ROOT/foo" foo

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is set to the original value
  [[ "$output" == "${STAR_ENVVAR_PREFIX}BAR=/some/other/path" ]]
}

@test "env vars disabled - 'star rename' does not unset a variable that was not set by star" {
  mkdir "$TEST_ROOT/foo"
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  export "${STAR_ENVVAR_PREFIX}BAR=/some/other/path"
  star add "$TEST_ROOT/foo" foo

  star rename foo bar

  run list_envvars
  [ "$status" -eq 0 ]
  # check that the environment variable is still set to the original while the renamed variable is also set
  [[ "$(echo "$output" | head -n 1)" == "${STAR_ENVVAR_PREFIX}BAR=/some/other/path" ]]
  [[ "$(echo "$output" | tail -n 1)" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars disabled - 'star reset' removes all environment variables if they correspond to star env var format" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  run list_envvars
  [ "$status" -eq 0 ]
  # no environment variables should be set
  [[ "$output" == "" ]]

  # manually set the environment variable to the same name and value
  export "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo"

  star reset --force

  run list_envvars
  [ "$status" -eq 0 ]
  # no environment variables should be set after reset
  [[ "$output" == "" ]]
}

@test "env vars disabled - 'star reset' does not remove environment variables that were not set by star" {
  export "${STAR_ENVVAR_PREFIX}FOO=/some/other/path"
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  star reset --force

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should still be set after reset
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=/some/other/path" ]]
}

@test "env vars disabled - any star command updates environment variables if config changes" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" foo

  export __STAR_ENABLE_ENVVARS=yes
  star

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should be set after enabling env vars
  [[ "$output" == "${STAR_ENVVAR_PREFIX}FOO=$TEST_ROOT/foo" ]]

  export __STAR_ENABLE_ENVVARS=no
  star

  run list_envvars
  [ "$status" -eq 0 ]
  # the environment variable should be unset after disabling env vars
  [[ "$output" == "" ]]
}
