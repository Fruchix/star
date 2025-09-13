
setup_common() {
  source star_2_0_0.bash
}

setup_tmpdir() {
  export TEST_ROOT="$(mktemp -d)"
  export _STAR_HOME="$TEST_ROOT/.star"
  export _STAR_DISPLAY_FORMAT="<INDEX>: ${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  export _STAR_EXPORT_ENV_VARIABLES=yes
  # export _STAR_DISPLAY_FORMAT="${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
  # export _STAR_EXPORT_ENV_VARIABLES=no

  setup_common
}

teardown_tmpdir() {
  tree -a "$TEST_ROOT"
  rm -rf "$TEST_ROOT"
}
