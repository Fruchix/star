
log_variable() {
    local var_name="$1"
    local var_ref="${!1}"
    echo "$var_name=$var_ref"
}
