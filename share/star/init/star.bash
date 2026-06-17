star() {
    if [[ "$COLORTERM" = "truecolor" || "$COLORTERM" = "24bit" ]]; then
        # Use true color (=24 bits colors)
        export __STAR_COLOR_NAME=${__STAR_COLOR_NAME-$'\033[38;2;255;131;0m'}
        export __STAR_COLOR_PATH=${__STAR_COLOR_PATH-$'\033[38;2;1;169;130m'}
        export __STAR_COLOR_RESET=${__STAR_COLOR_RESET-$'\033[0m'}
    else
        # Fallback to 256-color codes
        export __STAR_COLOR_NAME=${__STAR_COLOR256_NAME-$'\033[38;5;214m'}
        export __STAR_COLOR_PATH=${__STAR_COLOR256_PATH-$'\033[38;5;36m'}
        export __STAR_COLOR_RESET=${__STAR_COLOR256_RESET-$'\033[0m'}
    fi

    local output
    output="$(command star "$@")"
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        return $ret
    fi

    local line
    while IFS= read -r line; do
        case "$line" in

            # cd -P path
            cd\ -P\ *)
                if [[ "$line" =~ ^cd[[:space:]]+-P[[:space:]]+(.+)$ ]]; then
                    builtin cd -P "${BASH_REMATCH[1]}"
                else
                    builtin echo "$line"
                fi
                ;;

            # export VAR=value
            export\ *)
                if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
                    local var="${BASH_REMATCH[1]}"
                    local val="${BASH_REMATCH[2]}"
                    builtin printf -v "$var" "%s" "$val"
                    export "$var"
                else
                    builtin echo "$line"
                fi
                ;;

            # unset VAR
            unset\ *)
                if [[ "$line" =~ ^unset[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)$ ]]; then
                    builtin unset "${BASH_REMATCH[1]}"
                else
                    builtin echo "$line"
                fi
                ;;

            "")
                ;;

            *)
                builtin echo -e "$line"
                ;;
        esac
    done <<< "$output"
}

# very important line: we check that star has been initialized according to weither a star function has been exported in the environment.
export -f star