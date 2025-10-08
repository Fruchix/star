
load ../helpers/helper_log

setup_tmpdir() {
  export TEST_ROOT="$(realpath "$(mktemp -d)")"
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}

setup_common() {
  # create tmp dir and set $TEST_ROOT
  setup_tmpdir

  export _STAR_HOME="$TEST_ROOT/.star"
  export _STAR_DISPLAY_FORMAT="<INDEX>: ${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  export _STAR_EXPORT_ENV_VARIABLES=yes
  # export _STAR_DISPLAY_FORMAT="${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  # export _STAR_EXPORT_ENV_VARIABLES=no

  source star_2_0_0.bash
}

teardown_common() {
  if [ "$BATS_TEST_COMPLETED" != "1" ]; then
    echo
    echo "========================================"
    echo "Test '${BATS_TEST_NAME}' failed. Debugging:"
    echo "----------"
    log_variable status
    echo "----------"
    log_variable output
    echo "----------"
    tree -a "$TEST_ROOT"
    echo "----------"
    find "$_STAR_HOME/$_STAR_STARS_DIR" -type l -not -xtype l -printf "%As %f %l\n"
    echo "========================================"
    echo
  fi

  teardown_tmpdir
}
