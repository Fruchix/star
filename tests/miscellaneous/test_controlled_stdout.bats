#!/usr/bin/env bats

load ../helpers/helper_setup

setup() { setup_common; }
teardown() { teardown_common; }

@test "controlled stdout - only cd/export/unset commands are written to stdout" {
  skip "not implemented yet"
}
