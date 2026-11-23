
list_envvars() {
    # need to define the prefix inside the function to ensure it is available when the function is called
    STAR_ENVVAR_PREFIX="STAR_"

    env | grep "^${STAR_ENVVAR_PREFIX}" | sort
}

unset_envvars() {
    # need to define the prefix inside the function to ensure it is available when the function is called
    STAR_ENVVAR_PREFIX="STAR_"

    local var_name
    while IFS= read -r; do
        var_name=$(echo "$REPLY" | cut -d= -f1)
        unset "$var_name"
        echo "Unsetting environment variable: $var_name"
    done < <(env | grep "^${STAR_ENVVAR_PREFIX}")
}