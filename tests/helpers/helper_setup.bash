
load ../helpers/helper_log

detect_shell_type() {
  if [ -n "$BASH_VERSION" ]; then
    echo "bash"
  elif [ -n "$ZSH_VERSION" ]; then
    echo "zsh"
  else
    echo "unknown"
  fi
}

setup_tmpdir() {
  export TEST_ROOT="$(realpath "$(mktemp -d)")"
}

teardown_tmpdir() {
  rm -rf "$TEST_ROOT"
}

# load star function from the star script
init_star() {
  local current_shell_type
  current_shell_type="$(detect_shell_type)"

  if [[ "$current_shell_type" == "unknown" ]]; then
    echo "Error: could not determine shell type." >&2
    return 1
  fi

  eval "$(command $TEST_STAR init "${current_shell_type}")"
}

setup_common() {
  # create tmp dir and set $TEST_ROOT
  setup_tmpdir

  export PATH="$PWD/bin:$PATH"
  export _STAR_DATA_HOME=$TEST_ROOT

  # override the config file to avoid using the default one
  export _STAR_CONFIG_FILE="/dev/null"

  export __STAR_LIST_FORMAT="<INDEX><BR><COLNAME>%f<COLRESET><BR>-><BR><COLPATH>%l<COLRESET>"
  # export __STAR_LIST_FORMAT="<COLNAME>%f<COLRESET><BR>-><BR><COLPATH>%l<COLRESET>"

  export CURRENT_TEST_DATA_DIR="${_STAR_DATA_HOME}/stars"

  export TEST_STAR="${TEST_STAR:-star}"

  # load star function
  init_star
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
    find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%As %f %l\n"
    echo "========================================"
    echo
  fi

  teardown_tmpdir
}
