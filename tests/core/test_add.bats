#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "star add - requires at least one argument" {
  run star add
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "star add - adding star without name uses basename" {
  mkdir "$TEST_ROOT/foo_basename"
  run star add "$TEST_ROOT/foo_basename"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/foo_basename" ]]
  [ "$(readlink -f "$_STAR_HOME/$_STAR_STARS_DIR/foo_basename")" = "$TEST_ROOT/foo_basename" ]
}

@test "star add - starring current directory without name uses basename" {
  mkdir "$TEST_ROOT/foo_current"
  cd "$TEST_ROOT/foo_current"
  run star add .
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/foo_current" ]]
  [ "$(readlink -f "$_STAR_HOME/$_STAR_STARS_DIR/foo_current")" = "$TEST_ROOT/foo_current" ]
}

@test "star add - using a star name with slashes is allowed (slashes are replaced by \"${_STAR_DIR_SEPARATOR}\")" {
  mkdir "$TEST_ROOT/foo_slash"
  run star add "$TEST_ROOT/foo_slash" "slash/path"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/slash${_STAR_DIR_SEPARATOR}path" ]]
}

@test "star add - using a star name with spaces is allowed (spaces are replaced by \"-\")" {
  mkdir "$TEST_ROOT/foo_space"
  run star add "$TEST_ROOT/foo_space" " my star "
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/-my-star-" ]]
}

@test "star add - multiple spaces in star name are replaced by one dash only" {
  mkdir "$TEST_ROOT/foo_multiple_spaces"
  run star add "$TEST_ROOT/foo_multiple_spaces" "   my    dir  "
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/-my-dir-" ]]
}

@test "star add - adding star with a basename containing spaces is allowed" {
  mkdir "$TEST_ROOT/my dir"
  run star add "$TEST_ROOT/my dir"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/my-dir" ]]
}

@test "star add - using a star name with numbers is allowed" {
  mkdir "$TEST_ROOT/foo_number"
  run star add "$TEST_ROOT/foo_number" "abc123"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/abc123" ]]

  mkdir "$TEST_ROOT/foo_basename_321"
  run star add "$TEST_ROOT/foo_basename_321"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/foo_basename_321" ]]
}

@test "star add - adding star with a basename containing only numbers is allowed but it adds a dir- prefix" {
  mkdir "$TEST_ROOT/456"
  run star add "$TEST_ROOT/456"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/dir-456" ]]
}

@test "star add - cannot star a directory that does not exist" {
  run star add "$TEST_ROOT/missing"
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "star add - cannot star a directory that is already starred (without providing a different name)" {
  mkdir "$TEST_ROOT/foo_already_starred"
  star add "$TEST_ROOT/foo_already_starred"
  run star add "$TEST_ROOT/foo_already_starred"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already starred"* ]]
}

@test "star add - cannot star a directory that is already starred (even if providing a different name)" {
  mkdir "$TEST_ROOT/foo"
  star add "$TEST_ROOT/foo" "foo"
  run star add "$TEST_ROOT/foo" "bar"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already starred"* ]]
}

@test "star add - cannot use the same star name twice (when passing it as argument to star add)" {
  mkdir "$TEST_ROOT/a" "$TEST_ROOT/b"
  star add "$TEST_ROOT/a" "same_name"
  run star add "$TEST_ROOT/b" "same_name"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already starred"* ]]
}

@test "star add - conflicting star name when using basename resolves to parent/basename" {
  mkdir -p "$TEST_ROOT/foo/config" "$TEST_ROOT/bar/config"
  run star add "$TEST_ROOT/foo/config"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/config" ]]

  run star add "$TEST_ROOT/bar/config"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/bar${_STAR_DIR_SEPARATOR}config" ]]

  mkdir -p "$TEST_ROOT/foo/config/bar/config"
  run star add "$TEST_ROOT/foo/config/bar/config"
  [ "$status" -eq 0 ]
  [[ -L "$_STAR_HOME/$_STAR_STARS_DIR/config${_STAR_DIR_SEPARATOR}bar${_STAR_DIR_SEPARATOR}config" ]]
}

