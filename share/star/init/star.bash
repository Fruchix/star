# Check that all required environment variables are set
if [[ -z "${_STAR_HOME}" ]]; then
    command echo "Error: _STAR_HOME is not set. Please run 'eval \"\$(command star init bash)\"' to load star." >&2
    return 1
fi

if [[ -z "${_STAR_DATA_HOME}" ]]; then
    command echo "Error: _STAR_DATA_HOME is not set. Please run 'eval \"\$(command star init bash)\"' to load star." >&2
    return 1
fi

if [[ -z "${_STAR_CONFIG_FILE}" ]]; then
    command echo "Error: _STAR_CONFIG_FILE is not set. Please run 'eval \"\$(command star init bash)\"' to load star." >&2
    return 1
fi

# check that all required dependencies are installed
"${_STAR_HOME}"/libexec/star/star-deps || {
    err "Dependency check failed, cannot run star."
    err "See above messages for more details, or visit https://github.com/Fruchix/star for installation instructions."
    return 1
}

# load configuration file if it exists
if [[ -f "${_STAR_CONFIG_FILE}" ]]; then
    # shellcheck source=/dev/null
    . "${_STAR_CONFIG_FILE}"
else
    # Adjust colors depending on terminal capabilities.
    # This is usually done in the configuration file, but if the file does not exist then do it here.
    # shellcheck source=/dev/null
    . "${_STAR_HOME}/libexec/star/star-setcolors.sh"
fi

# Enable (yes) or disable (no) environment variables
export __STAR_ENABLE_ENVVARS="${__STAR_ENABLE_ENVVARS:-"yes"}"

# Enable (yes) or disable (no) the aliases
export __STAR_ENABLE_ALIASES="${__STAR_ENABLE_ALIASES:-"yes"}"

# Enable (yes) or disable (no) whether "star load" with no arguments is equivalent to "star list" or causes an error
export __STAR_ENABLE_LOADLISTS="${__STAR_ENABLE_LOADLISTS:-"yes"}"

_star_add_variable()
{
    local star_name=$1
    local star_path=$2
    local env_var_name
    # character used to replace slashes in the star names
    local star_dir_separator="»"
    local star_env_var_prefix="STAR_"

    star_name="${star_name//${star_dir_separator}/_}"

    # convert name to a suitable environment variable name
    star_name=$(command echo "$star_name" | command tr ' +-.!?():,;=' '_' | command tr --complement --delete "a-zA-Z0-9_" | command tr '[:lower:]' '[:upper:]')

    env_var_name="${star_env_var_prefix}${star_name}"

    if command env | command grep "^${env_var_name}=" >& /dev/null; then
        return
    fi

    export "$env_var_name"="$star_path"
}

_star_set_variables()
{
    export ___STAR_ENABLE_ENVVARS_CURRENT_STATUS="$__STAR_ENABLE_ENVVARS"
    if [[ $__STAR_ENABLE_ENVVARS != "yes" ]]; then
        return
    fi
    # return if the star directory does not exist
    if [[ ! -d "${_STAR_DATA_HOME}/stars" ]];then
        return
    fi

    local star_name_and_path env_var_name

    # list of stars with format: "name path", where path can contain spaces
    local stars_list=()
    while IFS= read -r; do
        stars_list+=("$REPLY")
    done < <(command find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%f %l\n")

    for star_name_and_path in "${stars_list[@]}"; do
        _star_add_variable "${star_name_and_path%% *}" "${star_name_and_path##* }"
    done
}

_star_unset_variables()
{
    export ___STAR_ENABLE_ENVVARS_CURRENT_STATUS="$__STAR_ENABLE_ENVVARS"
    # return if the star directory does not exist
    if [[ ! -d "${_STAR_DATA_HOME}/stars" ]]; then
        return
    fi

    local variables_list variable env_var_name star_path
    local star_env_var_prefix="STAR_"

    # get all the environment variables starting with STAR_
    # format: <NAME>=<VALUE>
    variables_list=()
    while IFS= read -r; do
        variables_list+=("$REPLY")
    done < <(command env | command grep "^${star_env_var_prefix}")

    for variable in "${variables_list[@]}"; do
        # unset the variable only if its value corresponds to an existing star path (absolute path of a starred directory)
        star_path="$(command echo "$variable" | command cut -d"=" -f2)"
        if ! command find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%l\n" | command grep "^${star_path}$" &> /dev/null ; then
            continue
        fi
        env_var_name="$(command echo "$variable" | command cut -d"=" -f1)"
        unset "$env_var_name"
    done
}

star()
{
    # all variables are local to prevent environment pollution

    # character used to replace slashes in the star names
    local star_dir_separator="»"
    
    # Color codes for consistent styling
    # Cast global variables into locals to enable potential reformat without
    # having to rename all variables inside the function
    local COLOR_STAR="${__STAR_COLOR_NAME}"
    local COLOR_PATH="${__STAR_COLOR_PATH}"
    local COLOR_RESET="$__STAR_COLOR_RESET"

    # set environment variables if the status has changed
    if [[ "$__STAR_ENABLE_ENVVARS" != "$___STAR_ENABLE_ENVVARS_CURRENT_STATUS" ]]; then
        if [[ "$__STAR_ENABLE_ENVVARS" == "yes" ]]; then
            _star_set_variables
        else
            _star_unset_variables
        fi
    fi

    if [[ $# -eq 0 ]]; then
        "${_STAR_HOME}/libexec/star/star-help"
        return 0
    fi

    # parse the mode
    local mode
    local arg_mode=$1
    shift
    case $arg_mode in
        add)        mode=STORE  ;;
        L|list)     mode=LIST   arg_mode=list   ;;
        l|load)     mode=LOAD   arg_mode=load   ;;
        rename)     mode=RENAME ;;
        rm|remove)  mode=REMOVE arg_mode=remove ;;
        reset)      mode=RESET  ;;
        config)     mode=CONFIG ;;
        h|help|-h|--help)
            if [[ $# -gt 0 ]]; then
                "${_STAR_HOME}/libexec/star/star-help" --mode="$1"
            else
                "${_STAR_HOME}/libexec/star/star-help"
            fi
            return 0
            ;;
        -v|--version|-I|--info)
            command star "${arg_mode}" "$@"
            return 0
            ;;
        *)
            command echo "star: invalid mode '$arg_mode'"
            "${_STAR_HOME}/libexec/star/star-help"
            return 1
            ;;
    esac

    # handle "star MODE --help" immediately
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        "${_STAR_HOME}/libexec/star/star-help" --mode="$arg_mode"
        return 0
    fi

    # Parse the arguments associated to the selected mode
    case ${mode} in
        STORE)
            # first argument has to be the relative path
            if [[ $# -lt 1 ]]; then
                command echo "star add: missing PATH argument."
                "${_STAR_HOME}/libexec/star/star-help" --mode=add
                return 1
            fi
            local src_dir
            src_dir=$(command realpath "$1")
            shift
            if [[ ! -d $src_dir ]]; then
                command echo "Directory does not exist: '$src_dir'."
                return 2
            fi

            local star_to_store=""

            # If there's another argument then use it as star name,
            # else the star name will be created from the name of the directory
            if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                star_to_store="$1"
                shift
            fi
            ;;
        LIST)
            # handle the "list" case immediately
            "${_STAR_HOME}/libexec/star/star-list" "$@"
            return $?
            ;;
        LOAD)
            # first argument should be the name or the index of the star to load
            if [[ $# -lt 1 ]]; then
                # if the following option is enabled, using star load without argument is equivalent to star list
                if [[ "$__STAR_ENABLE_LOADLISTS" == "yes" ]]; then
                    "${_STAR_HOME}/libexec/star/star-list"
                    return $?
                fi

                command echo "star load: missing argument."
                "${_STAR_HOME}/libexec/star/star-help" --mode=load
                return 1
            fi
            local star_to_load="${1//\//${star_dir_separator}}"
            shift
            ;;
        RENAME)
            if [[ $# -lt 2 ]]; then
                command echo "star rename: missing argument(s)."
                "${_STAR_HOME}/libexec/star/star-help" --mode=rename
                return 1
            fi
            local rename_src rename_dst
            rename_src="${1//\//${star_dir_separator}}"
            rename_dst="${2//\//${star_dir_separator}}"
            ;;
        REMOVE)
            if [[ $# -lt 1 ]]; then
                command echo "star remove: missing argument(s)."
                "${_STAR_HOME}/libexec/star/star-help" --mode=remove
                return 1
            fi
            local stars_to_remove=()
            # remove multiple stars
            while [[ $# -gt 0 ]]; do
                stars_to_remove+=("${1//\//${star_dir_separator}}")
                shift
            done
            ;;
        RESET)
            mode=RESET
            local force_reset=0
            if [[ "$1" == "-f" || "$1" == "--force" ]]; then
                force_reset=1
            fi
            ;;
    esac

    # in case there are more arguments and it happens to be help option
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            "${_STAR_HOME}/libexec/star/star-help" --mode="$arg_mode"
            return 0
        fi
        shift
    done

    # process the selected mode
    case ${mode} in
        STORE)
            local dst_name dst_name_slash dst_basename existing_star existing_star_display

            if [[ ! -d "${_STAR_DATA_HOME}/stars" ]]; then
                command mkdir -p "${_STAR_DATA_HOME}/stars"
            fi

            if [[ ! "${star_to_store}" == "" ]]; then
                # replace slashes by dir separator char: a star name can contain slashes
                dst_name="${star_to_store//\//${star_dir_separator}}"
            else
                # else get the star name from the name of the directory
                dst_name=$(command basename "${src_dir}")
            fi

            # get the paths of all starred directories
            local stars_path=()
            while IFS= read -r; do
                stars_path+=("$REPLY")
            done < <(command find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%l\n")

            # do not star this directory if it is already starred (even under another name)
            if [[ "${stars_path[*]}" =~ (^|[[:space:]])${src_dir}($|[[:space:]]) ]]; then
                # Find the star name for this directory's path
                existing_star=$("${_STAR_HOME}/libexec/star/star-list" --get-name="$src_dir")
                existing_star_display="${existing_star//${star_dir_separator}//}"
                command echo -e "Directory ${COLOR_PATH}${src_dir}${COLOR_RESET} is already starred as ${COLOR_STAR}${existing_star_display}${COLOR_RESET}."
                return 2
            fi

            # star names have to be unique: When adding a new starred directory using the basename of the path,
            # if the name is already taken then it will try to concatenate the previous folder from the path,
            # and will do this until the names are different or when there is no previous folder (root folder)
            # example:
            # in ~/foo/config:
            #   star would add a new star called "config" that refers to the absolute path to ~/foo/config
            # then in ~/bar/config:
            #   star would try to add a new star called "config", but there would be a conflict, so it would
            # add a new star called "bar/config"
            # 
            # As it is not possible to use slashes in file names, we use the special char '»' to split "bar" and "config", 
            # that will be replaced by a slash when printing the star name or suggesting completion.
            # The variable 'star_dir_separator' must not be manually changed, as it would cause the non-recognition of previously starred directories (their star name could contain that separator).
            if [[ "${star_to_store}" == "" ]]; then
                # need to store the whitespace-free name in a temporary variable in order to keep the existing path
                local tmp_name
                tmp_name=$(command echo "${dst_name}" | command tr --squeeze-repeats ' ' | command tr ' ' '-')

                while [[ -e "${_STAR_DATA_HOME}/stars/${tmp_name}" ]]; do
                    dst_name_slash="${dst_name//${star_dir_separator}//}"
                    dst_basename=$(command basename "${src_dir%%"$dst_name_slash"}")

                    if [[ "${dst_basename}" == "/" ]]; then
                        command echo -e "Directory already starred with maximum possible path: ${COLOR_STAR}${dst_name_slash}${COLOR_RESET}."
                        return 2
                    fi

                    dst_name="${dst_basename}${star_dir_separator}${dst_name}"
                    # update the temporary name in order to check if it exists in the star names
                    tmp_name=$(command echo "${dst_name}" | command tr --squeeze-repeats ' ' | command tr ' ' '-')
                done
                # replace whitespaces with a single dash (needs to be done AFTER looping over paths, to keep the existing paths)
                dst_name=$(command echo "${dst_name}" | command tr --squeeze-repeats ' ' | command tr ' ' '-')

            # When adding a new starred directory with a given name (as argument),
            # then the name should not already exist
            else
                # replace whitespaces with a single dash
                dst_name=$(command echo "${dst_name}" | command tr --squeeze-repeats ' ' | command tr ' ' '-')

                dst_name_slash="${dst_name//${star_dir_separator}//}"
                if [[ -e "${_STAR_DATA_HOME}/stars/${dst_name}" ]]; then
                    # Get the path associated with star name
                    local target_path
                    target_path=$("${_STAR_HOME}/libexec/star/star-list" --get-path="${dst_name//\//${star_dir_separator}}")

                    command echo -e "A directory is already starred with the name \"${dst_name_slash}\": ${COLOR_STAR}${dst_name_slash}${COLOR_RESET} -> ${COLOR_PATH}${target_path}${COLOR_RESET}."
                    return 2
                fi
            fi

            # if name is purely numeric, add a prefix in order to not mix with index based navigation
            if [[ "${dst_name}" =~ ^[0-9]+$ ]]; then
                dst_name="dir-${dst_name}"
            fi

            if ! command ln -s "${src_dir}" "${_STAR_DATA_HOME}/stars/${dst_name}"; then
                local res=$?
                command echo -e "Failed to add a new starred directory: ${COLOR_STAR}${dst_name//${star_dir_separator}//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."
                return $res
            fi
            command echo -e "Added new starred directory: ${COLOR_STAR}${dst_name//${star_dir_separator}//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."

            # update environment variables
            if [[ "$__STAR_ENABLE_ENVVARS" == "yes" ]]; then
                _star_add_variable "${dst_name}" "${src_dir}"
            fi
            ;;
        LOAD)
            if [[ ! -d "${_STAR_DATA_HOME}/stars" ]]; then
                command echo "No star can be loaded because there are no starred directories."
                return 0
            fi

            # Check if argument is purely numeric
            if [[ "${star_to_load}" =~ ^[0-9]+$ ]]; then
                # Get the list of star names
                local stars_list=()
                while IFS= read -r; do
                    stars_list+=("$REPLY")
                done < <("${_STAR_HOME}/libexec/star/star-list" --names) # TODO: pass sorting parameters to star-list

                # Check if the index is valid
                if [[ "${star_to_load}" -lt 1 || "${star_to_load}" -gt "${#stars_list[@]}" ]]; then
                    command echo -e "Invalid index: ${COLOR_STAR}${star_to_load}${COLOR_RESET}. Valid range is 1-${#stars_list[@]}."
                    return 2
                fi

                # revert the indexes on descending index
                # (the end of the list corresponds to index 1)
                if [[ "$__STAR_LIST_INDEX" == "desc" ]]; then
                    star_to_load=$(( ${#stars_list[@]} - star_to_load + 1 ))
                fi

                # Use shell detection to handle both bash and zsh
                if [[ -n "${ZSH_VERSION}" ]]; then
                    star_to_load="${stars_list[$star_to_load]}"
                else
                    star_to_load="${stars_list[$((star_to_load-1))]}"
                fi
            fi

            if [[ ! -e "${_STAR_DATA_HOME}/stars/${star_to_load}" ]]; then
                command echo -e "Star ${COLOR_STAR}${star_to_load//${star_dir_separator}//}${COLOR_RESET} does not exist."
            else
                # not using "command" before cd in case user has customized its cd,
                # and has shadowed the original cd command
                if ! cd -P "${_STAR_DATA_HOME}/stars/${star_to_load}"; then
                    # get path according to name
                    local star_to_load_path
                    star_to_load_path=$("${_STAR_HOME}/libexec/star/star-list" --get-path="${star_to_load}")

                    if [[ ! -d "$star_to_load_path" ]]; then
                        command echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\": associated directory \"${COLOR_PATH}${star_to_load_path}${COLOR_RESET}\" does not exist."
                        return 2
                    else
                        command echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\"."
                        return 2
                    fi
                fi
                # update access time
                command touch -ah "${_STAR_DATA_HOME}/stars/${star_to_load}"
            fi
            ;;
        RENAME)
            # remove the environment variable corresponding to the old name
            # (easier to remove all environment variables)
            _star_unset_variables

            local res
            if [[ -e "${_STAR_DATA_HOME}/stars/${rename_src}" ]]; then
                # if names are the same except for case then try to bypass using temporary rename
                # case sensitive renaming can fail because of file systems, or even mv resolving symlinks instead of renaming them
                if [[ "$(echo "${rename_src}" | tr '[:upper:]' '[:lower:]')" == "$(echo "${rename_dst}" | tr '[:upper:]' '[:lower:]')" ]]; then
                    # try to find a random temporary name that does not exist without using tools like mktemp (less dependencies)
                    local random_suffix_attempts=3
                    local random_suffix="$RANDOM"
                    while [[ -e "${_STAR_DATA_HOME}/stars/${rename_dst}.${random_suffix}" && $random_suffix_attempts -gt 0 ]]; do
                        random_suffix="$random_suffix$RANDOM"
                        ((random_suffix_attempts--))
                    done

                    # temporary rename
                    if ! command mv "${_STAR_DATA_HOME}/stars/${rename_src}" "${_STAR_DATA_HOME}/stars/${rename_dst}.${random_suffix}"; then
                        res=$?
                        command echo -e "Failed to rename star ${COLOR_STAR}${rename_src//${star_dir_separator}//}${COLOR_RESET} to temporary name ${COLOR_STAR}${rename_dst//${star_dir_separator}//}.${random_suffix}${COLOR_RESET}."
                        command echo -e "This temporary name is because the two names are the same except for case, and would have been renamed to the final name ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                        return $res
                    fi

                    # final rename
                    if ! command mv "${_STAR_DATA_HOME}/stars/${rename_dst}.${random_suffix}" "${_STAR_DATA_HOME}/stars/${rename_dst}"; then
                        res=$?
                        # if final rename failed, try to revert it
                        if ! command mv "${_STAR_DATA_HOME}/stars/${rename_dst}.${random_suffix}" "${_STAR_DATA_HOME}/stars/${rename_src}"; then
                            res=$?
                            command echo -e "Failed to rename star from temporary name ${COLOR_STAR}${rename_dst//${star_dir_separator}//}.${random_suffix}${COLOR_RESET} to final name ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                            command echo -e "This temporary rename was used because the two names were the same except for the case. The temporary rename worked, but the final rename AND it revert to original name both failed."
                            command echo -e "Good luck, bye!"
                            return $res
                        else
                            command echo -e "Failed to rename star ${COLOR_STAR}${rename_src//${star_dir_separator}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                            return $res
                        fi
                    fi

                    command echo -e "Renamed star ${COLOR_STAR}${rename_src//${star_dir_separator}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                    return 0
                fi

                if [[ -e "${_STAR_DATA_HOME}/stars/${rename_dst}" ]]; then
                    command echo -e "There is already a star named ${COLOR_STAR}${rename_dst}${COLOR_RESET}."
                    return 2
                fi

                if ! command mv "${_STAR_DATA_HOME}/stars/${rename_src}" "${_STAR_DATA_HOME}/stars/${rename_dst}"; then
                    res=$?
                    command echo -e "Failed to rename star ${COLOR_STAR}${rename_src//${star_dir_separator}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                    return $res
                fi
                command echo -e "Renamed star ${COLOR_STAR}${rename_src//${star_dir_separator}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${star_dir_separator}//}${COLOR_RESET}."
                return 0
            else
                command echo -e "Star ${COLOR_STAR}${rename_src}${COLOR_RESET} does not exist."
                return 1
            fi

            # update environment variables
            _star_set_variables
            ;;
        REMOVE)
            local star_name
            if [[ ! -d "${_STAR_DATA_HOME}/stars" || -z "$(command ls -A "${_STAR_DATA_HOME}/stars" )" ]];then
                command echo "There are no starred directories to remove."
                return 1
            fi

            # remove all env variables while their paths are still known
            _star_unset_variables

            for star_name in "${stars_to_remove[@]}"; do
                if [[ -e "${_STAR_DATA_HOME}/stars/${star_name}" ]]; then
                    if ! command rm "${_STAR_DATA_HOME}/stars/${star_name}"; then
                        local res=$?
                        command echo -e "Failed to remove starred directory: ${COLOR_STAR}${star_name//${star_dir_separator}//}${COLOR_RESET}."
                        return $res
                    fi
                    command echo -e "Removed starred directory: ${COLOR_STAR}${star_name//${star_dir_separator}//}${COLOR_RESET}."
                else
                    command echo -e "Could not find any starred directory with the name: ${COLOR_STAR}${star_name//${star_dir_separator}//}${COLOR_RESET}."
                    return 1
                fi
            done
            # re create the other environment variables
            _star_set_variables
            ;;
        RESET)
            if [[ ! -d "${_STAR_DATA_HOME}/stars" || -z "$(command ls -A "${_STAR_DATA_HOME}/stars" )" ]];then
                command echo "There are no starred directories to remove."
                return 1
            fi

            # if not forcing the reset, ask user for confirmation
            if [[ "${force_reset}" -ne 1 ]]; then
                # case "" corresponds to pressing enter
                # by default, pressing enter aborts the reset
                while true; do
                    command echo -n "Remove all starred directories? [y/N] "
                    read -r
                    case $REPLY in
                        [Yy]*|yes ) break ;;
                        [Nn]*|no|"" ) command echo "Aborting reset." && return 0 ;;
                        * ) command echo "Not a valid answer." ;;
                    esac
                done  
            fi

            # remove all env variables while their paths are still known
            _star_unset_variables

            local ret
            command rm -r "${_STAR_DATA_HOME}/stars"
            ret=$?
            if [[ "$ret" -eq 0 ]]; then
                command echo "All stars have been removed."
            else
                command echo "Failed to remove all the stars."
                return $ret
            fi

            # remove the entire star data directory if empty
            rmdir "${_STAR_DATA_HOME}" 2>/dev/null || true
            ;;
        CONFIG)
            local editor
            if [[ -n "${EDITOR}" ]]; then
                editor="${EDITOR}"
            elif command -v nano >/dev/null 2>&1; then
                editor="nano"    
            elif command -v vi >/dev/null 2>&1; then
                editor="vi"
            else
                command echo "No suitable text editor found (tried: nano, vi)."
                command echo "Try setting the EDITOR environment variable to your preferred terminal text editor."
                return 3
            fi

            if [[ -f "${_STAR_CONFIG_FILE}" ]]; then
                "${editor}" "${_STAR_CONFIG_FILE}"
            else
                command echo "No configuration file found. Should be located at: ${_STAR_CONFIG_FILE}"
                if [[ -e "${_STAR_HOME}/share/star/config/star_config.sh.template" ]]; then
                    command echo
                    command echo "You can create a new configuration file with the following commands (copies a provided template):"
                    command echo "  mkdir -p \"$(command dirname "${_STAR_CONFIG_FILE}")\""
                    command echo "  cp \"${_STAR_HOME}/share/star/config/star_config.sh.template\" \"${_STAR_CONFIG_FILE}\""
                fi
                command echo
                command echo "Note that configuration can also be done by setting environment variables, without the need of a configuration file."
            fi
            eval "$(command star init "${__STAR_SHELL}")"
            return $?
            ;;
    esac
}

# remove broken symlinks directly when sourcing this file
"${_STAR_HOME}/libexec/star/star-prune"

# set environment variables
if [[ "$__STAR_ENABLE_ENVVARS" == "yes" ]]; then
    _star_set_variables
else
    _star_unset_variables
fi

if [[ "$__STAR_ENABLE_ALIASES" == "yes" ]]; then
    alias sta="star add"        # star add
    alias unstar="star remove"  # star remove
    alias strm="star remove"    # star remove
    alias stl="star load"       # star load
fi
