# Directory in which to store the symlinks (stars)
# Will be created if it does not exist, and will be removed when resetting star
# if _STAR_HOME is already set then use this directory,
# else use $HOME/.star
export _STAR_HOME="${_STAR_HOME:-$HOME/.star}"
export _STAR_STARS_DIR="stars"

if [ -n "${BASH_SOURCE:-}" ]; then
  script_path="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  script_path="${(%):-%N}"
fi

script_dir="$( cd -- "$( dirname -- "$script_path" )" && pwd )"

if [[ $PATH != *$script_dir* ]]; then
    PATH="$script_dir/bin:$PATH"
    export PATH
fi
unset script_path
unset script_dir

if [[ ! -d "$_STAR_HOME" ]]; then
    mkdir -p "$_STAR_HOME"
fi

# Enable (yes) or disable (no) environment variables
export _STAR_EXPORT_ENV_VARIABLES="${_STAR_EXPORT_ENV_VARIABLES:-"yes"}"

# The common prefix of the environment variables created according to the star names
export _STAR_ENV_PREFIX="${_STAR_ENV_PREFIX:-"STAR_"}"

# A character used to replace slashes in the star names
# This should not be changed
export _STAR_DIR_SEPARATOR="»"

if [ -t 1 ]; then
    # Check for truecolor support
    if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ]; then
        _STAR_COLOR_STAR=${_STAR_COLOR_STAR:-"\033[38;2;255;131;0m"}
        _STAR_COLOR_PATH=${_STAR_COLOR_PATH:-"\033[38;2;1;169;130m"}
        _STAR_COLOR_RESET=${_STAR_COLOR_RESET:-"\033[0m"}
    else
        # Use 256-color approximation
        _STAR_COLOR_STAR=${_STAR_COLOR_STAR:-"\033[38;5;214m"}
        _STAR_COLOR_PATH=${_STAR_COLOR_PATH:-"\033[38;5;36m"}
        _STAR_COLOR_RESET=${_STAR_COLOR_RESET:-"\033[0m"}
    fi
else
    # No color for non-interactive sessions (not a TTY)
    _STAR_COLOR_STAR=${_STAR_COLOR_STAR:-""}
    _STAR_COLOR_PATH=${_STAR_COLOR_PATH:-""}
    _STAR_COLOR_RESET=${_STAR_COLOR_RESET:-""}
fi
export _STAR_COLOR_STAR
export _STAR_COLOR_PATH
export _STAR_COLOR_RESET

# it is strongly recommended to set the number of columns in the 'column' command (--table-columns-limit) and to put the path in the last column, 
# as a path can contain whitespaces (which is the character used by 'column' to split columns)

# if there is no format provided, then use a default one with its custom column command
# else if a format is provided but there is no column command then use a default one
if [[ -z "$_STAR_DISPLAY_FORMAT" ]]; then
    export _STAR_DISPLAY_FORMAT="<INDEX>: ${_STAR_COLOR_STAR}%f${_STAR_COLOR_RESET} -> ${_STAR_COLOR_PATH}%l${_STAR_COLOR_RESET}"
    export _STAR_DISPLAY_COLUMN_COMMAND=( command column --table --table-columns-limit 3 )
elif [[ ${#_STAR_DISPLAY_COLUMN_COMMAND[@]} -eq 0 ]]; then
    export _STAR_DISPLAY_COLUMN_COMMAND=( command column --table )
fi

_star_add_variable()
{
    local star_name=$1
    local star_path=$2
    local env_var_name

    star_name="${star_name//${_STAR_DIR_SEPARATOR}/_}"

    # convert name to a suitable environment variable name
    star_name=$(echo "$star_name" | tr ' +-.!?():,;=' '_' | tr --complement --delete "a-zA-Z0-9_" | tr '[:lower:]' '[:upper:]')

    env_var_name="${_STAR_ENV_PREFIX}${star_name}"

    if test -n "$ZSH_VERSION"; then
        shell=zsh
    elif test -n "$BASH_VERSION"; then
        shell=bash
    fi

    # do not overwrite the variable if it already exists
    case $shell in
        zsh)    [ -z "${(P)env_var_name+x}" ] || continue ;;
        bash)   [ -z "${!env_var_name+x}" ] || continue ;;
    esac

    export "$env_var_name"="$star_path"
}

_star_set_variables()
{
    if [[ $_STAR_EXPORT_ENV_VARIABLES != "yes" ]]; then
        return
    fi
    # return if the star directory does not exist
    if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]];then
        return
    fi

    local stars_list star star_name star_path line env_var_name shell

    # list of stars with format: "name path", where path can contain spaces
    stars_list=()
    while IFS= read -r line; do
        # Extract just the star name from each line
        stars_list+=("$line")
    done < <(find "${_STAR_HOME}/${_STAR_STARS_DIR}" -type l -not -xtype l -printf "%f %l\n")

    for star in "${stars_list[@]}"; do
        _star_add_variable "${star%% *}" "${star##* }"
    done
}

_star_unset_variables()
{
    # return if the star directory does not exist
    if [[ ! -d ${_STAR_HOME}/${_STAR_STARS_DIR} ]]; then
        return
    fi

    local variables_list variable env_var_name line star_path

    # get all the environment variables starting with _STAR_ENV_PREFIX
    # format: <NAME>=<VALUE>
    variables_list=()
    while IFS= read -r line; do
        variables_list+=("$line")
    done < <(env | grep "^${_STAR_ENV_PREFIX}")

    for variable in "${variables_list[@]}"; do
        # unset the variable only if its value corresponds to an existing star path (absolute path of a starred directory)
        star_path="$(echo "$variable" | cut -d"=" -f2)"
        if ! find "${_STAR_HOME}/${_STAR_STARS_DIR}" -type l -not -xtype l -printf "%l\n" | grep "^${star_path}$" &> /dev/null ; then
            continue
        fi
        env_var_name="$(echo "$variable" | cut -d"=" -f1)"
        unset "$env_var_name"
    done
}

star()
{
    # all variables are local to prevent environment pollution
    local star_to_store stars_to_remove star_to_load mode rename_src rename_dst
    local dst_name dst_name_slash dst_basename
    local star stars_list stars_path src_dir opt user_input force_reset
    local existing_star existing_star_display target_path line
    
    # Color codes for consistent styling
    # Cast global variables into locals to enable potential reformat without
    # having to rename all variables inside the function
    local COLOR_STAR="${_STAR_COLOR_STAR}"
    local COLOR_PATH="${_STAR_COLOR_PATH}"
    local COLOR_RESET="$_STAR_COLOR_RESET"
    local DISPLAY_FORMAT="${_STAR_DISPLAY_FORMAT}"
    local DISPLAY_COLUMN_COMMAND=("${_STAR_DISPLAY_COLUMN_COMMAND[@]}")

    # Parse the arguments
    star_to_store=""
    stars_to_remove=()
    force_reset=0
    mode=HELP

    while [[ $# -gt 0 ]]; do
        opt="$1"
        shift

        # remove multiple stars
        if [[ ${mode} == REMOVE ]]; then
            stars_to_remove+=("${opt//\//${_STAR_DIR_SEPARATOR}}")
            continue
        fi

        case "$opt" in
            "--" ) break 2;;
            "-" ) break 2;;
            "add" )
                mode=STORE

                # first argument has to be the relative path
                if [[ $# -lt 1 ]]; then
                    echo -e "star add: missing PATH argument.\n"
                    star-help --mode=add
                    return 1
                fi
                src_dir=$(realpath "$1")
                shift
                if [[ ! -d $src_dir ]]; then
                    echo -e "Directory does not exist: '$src_dir'.\n"
                    return 2
                fi

                # If there's another argument then use it as star name,
                # else the star name will be created from the name of the directory
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    star_to_store="$1"
                    shift
                fi
                break
                ;;
            "L"|"list" )
                mode=LIST
                # handle the "list" case immediately, no matter the other parameters
                break
                ;;
            "l"|"load" )
                # first argument should be the name or the index of the star to load
                if [[ $# -lt 1 ]]; then
                    echo -e "star load: missing STAR argument.\n"
                    star-help --mode=load
                    return 1
                fi
                star_to_load="${1//\//${_STAR_DIR_SEPARATOR}}"
                mode=LOAD
                shift
                ;;
            "rename" )
                mode=RENAME
                if [[ $# -lt 2 ]]; then
                    echo -e "star rename: missing argument(s).\n"
                    star-help --mode=rename
                    return 1
                fi
                rename_src="${1//\//${_STAR_DIR_SEPARATOR}}"
                rename_dst="${2//\//${_STAR_DIR_SEPARATOR}}"
                break
                ;;
            "rm"|"remove" )
                if [[ $# -lt 1 ]]; then
                    echo -e "star remove: missing argument(s).\n"
                    star-help --mode=remove
                    return 1
                fi
                stars_to_remove+=("${1//\//${_STAR_DIR_SEPARATOR}}")
                mode=REMOVE
                shift
                ;;
            "reset" )
                mode=RESET
                if [[ "$1" == "-f" || "$1" == "--force" ]]; then
                    force_reset=1
                fi
                break
                ;;
            "h"|"help"|"-h"|"--help" )
                mode=HELP
                break 2
                ;;
            *)
                echo -e "Invalid mode: $opt\n"
                star-help
                return 2
                ;;
       esac
    done

    # process the selected mode
    case ${mode} in
        STORE)
            if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]]; then
                mkdir "${_STAR_HOME}/${_STAR_STARS_DIR}"
            fi

            if [[ ! "${star_to_store}" == "" ]]; then
                # replace slashes by dir separator char: a star name can contain slashes
                dst_name="${star_to_store//\//${_STAR_DIR_SEPARATOR}}"
            else
                # else get the star name from the name of the directory
                dst_name=$(basename "${src_dir}")
            fi

            # get the paths of all starred directories
            stars_path=()
            while IFS= read -r line; do
                stars_path+=("$line")
            done < <(find "${_STAR_HOME}/${_STAR_STARS_DIR}" -type l -not -xtype l -printf "%l\n")

            # do not star this directory if it is already starred (even under another name)
            if [[ "${stars_path[*]}" =~ (^|[[:space:]])${src_dir}($|[[:space:]]) ]]; then
                # Find the star name for this directory's path
                existing_star=$(star-list "${_STAR_HOME}/${_STAR_STARS_DIR}" --get-name="$src_dir")
                existing_star_display="${existing_star//${_STAR_DIR_SEPARATOR}//}"
                echo -e "Directory ${COLOR_PATH}${src_dir}${COLOR_RESET} is already starred as ${COLOR_STAR}${existing_star_display}${COLOR_RESET}."
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
            # As it is not possible to use slashes in file names, we use the special char _STAR_DIR_SEPARATOR to split "bar" and "config", 
            # that will be replaced by a slash when printing the star name or suggesting completion.
            # The variable _STAR_DIR_SEPARATOR must not be manualy changed, as it would cause the non-recognition of previously starred directories (their star name could contain that separator).
            if [[ "${star_to_store}" == "" ]]; then
                # need to store the whitespace-free name in a temporary variable in order to keep the existing path
                local tmp_name
                tmp_name=$(echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

                while [[ -e ${_STAR_HOME}/${_STAR_STARS_DIR}/${tmp_name} ]]; do
                    dst_name_slash="${dst_name//${_STAR_DIR_SEPARATOR}//}"
                    dst_basename=$(basename "${src_dir%%"$dst_name_slash"}")

                    if [[ "${dst_basename}" == "/" ]]; then
                        echo -e "Directory already starred with maximum possible path: ${COLOR_STAR}${dst_name_slash}${COLOR_RESET}."
                        return 2
                    fi

                    dst_name="${dst_basename}${_STAR_DIR_SEPARATOR}${dst_name}"
                    # update the temporary name in order to check if it exists in the star names
                    tmp_name=$(echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')
                done
                # replace whitespaces with a single dash (needs to be done AFTER looping over paths, to keep the existing paths)
                dst_name=$( echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

            # When adding a new starred directory with a given name (as argument),
            # then the name should not already exist
            else
                # replace whitespaces with a single dash
                dst_name=$( echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

                dst_name_slash="${dst_name//${_STAR_DIR_SEPARATOR}//}"
                if [[ -e ${_STAR_HOME}/${_STAR_STARS_DIR}/${dst_name} ]]; then
                    # Get the path associated with star name
                    target_path=$(star-list "${_STAR_HOME}/${_STAR_STARS_DIR}" --get-path="${dst_name//\//${_STAR_DIR_SEPARATOR}}")

                    echo -e "A directory is already starred with the name \"${dst_name_slash}\": ${COLOR_STAR}${dst_name_slash}${COLOR_RESET} -> ${COLOR_PATH}${target_path}${COLOR_RESET}."
                    return 2
                fi
            fi

            # if name is purely numeric, add a prefix in order to not mix with index based navigation
            if [[ "${dst_name}" =~ ^[0-9]+$ ]]; then
                dst_name="dir-${dst_name}"
            fi

            if ! ln -s "${src_dir}" "${_STAR_HOME}/${_STAR_STARS_DIR}/${dst_name}"; then
                local res=$?
                echo -e "Failed to add a new starred directory: ${COLOR_STAR}${dst_name//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."
                return $res
            fi
            echo -e "Added new starred directory: ${COLOR_STAR}${dst_name//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."

            # update environment variables
            _star_add_variable "${dst_name}" "${src_dir}"
            ;;
        LOAD)
            if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]]; then
                echo "No star can be loaded because there are no starred directories."
                return 0
            fi

            # Check if argument is purely numeric
            if [[ "${star_to_load}" =~ ^[0-9]+$ ]]; then
                # Get the list of star names
                stars_list=()
                while IFS= read -r line; do
                    stars_list+=("$line")
                done < <(star-list "${_STAR_HOME}/${_STAR_STARS_DIR}" --names) # TODO: pass sorting parameters to star-list

                # Check if the index is valid
                if [[ "${star_to_load}" -lt 1 || "${star_to_load}" -gt "${#stars_list[@]}" ]]; then
                    echo -e "Invalid index: ${COLOR_STAR}${star_to_load}${COLOR_RESET}. Valid range is 1-${#stars_list[@]}."
                    return 2
                fi

                # Use shell detection to handle both bash and zsh
                if [[ -n "${ZSH_VERSION}" ]]; then
                    star_to_load="${stars_list[$star_to_load]}"
                else
                    star_to_load="${stars_list[$((star_to_load-1))]}"
                fi
            fi

            if [[ ! -e ${_STAR_HOME}/${_STAR_STARS_DIR}/${star_to_load} ]]; then
                echo -e "Star ${COLOR_STAR}${star_to_load}${COLOR_RESET} does not exist."
            else
                if ! cd -P "${_STAR_HOME}/${_STAR_STARS_DIR}/${star_to_load}"; then
                    # get path according to name
                    local star_to_load_path
                    star_to_load_path=$(star-list "${_STAR_HOME}/${_STAR_STARS_DIR}" --get-path="${star_to_load}")

                    if [[ ! -d "$star_to_load_path" ]]; then
                        echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\": associated directory \"${COLOR_PATH}${star_to_load_path}${COLOR_RESET}\" does not exist."
                        return 2
                    else
                        echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\"."
                        return 2
                    fi
                fi
                # update access time
                touch -ah "${_STAR_HOME}/${_STAR_STARS_DIR}/${star_to_load}"
            fi
            ;;
        LIST)
            if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]];then
                return 0
            else
                local stars_list_str
                # TODO: pass sorting parameters to star-list
                stars_list_str=$(star-list "${_STAR_HOME}/${_STAR_STARS_DIR}" --format="$DISPLAY_FORMAT")
                echo "${stars_list_str//${_STAR_DIR_SEPARATOR}//}" | "${DISPLAY_COLUMN_COMMAND[@]}"
            fi
            ;;
        RENAME)
            # remove the environment variable corresponding to the old name
            # (easier to remove all environment variables)
            _star_unset_variables

            if [[ -e "${_STAR_HOME}/${_STAR_STARS_DIR}/${rename_src}" ]]; then
                if [[ -e "${_STAR_HOME}/${_STAR_STARS_DIR}/${rename_dst}" ]]; then
                    echo -e "There is already a star named ${COLOR_STAR}${rename_dst}${COLOR_RESET}."
                    return 0
                fi

                if ! mv "${_STAR_HOME}/${_STAR_STARS_DIR}/${rename_src}" "${_STAR_HOME}/${_STAR_STARS_DIR}/${rename_dst}"; then
                    local res=$?
                    echo -e "Failed to rename star ${COLOR_STAR}${rename_src//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET}."
                    return $res
                fi
                echo -e "Renamed star ${COLOR_STAR}${rename_src//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET}."
            else
                echo -e "Star ${COLOR_STAR}${rename_src}${COLOR_RESET} does not exist."
            fi

            # update environment variables
            _star_set_variables
            ;;
        REMOVE)
            if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]];then
                echo "There are no starred directories to remove."
                return 0
            fi

            # remove all env variables while their paths are still known
            _star_unset_variables

            for star in "${stars_to_remove[@]}"; do
                if [[ -e "${_STAR_HOME}/${_STAR_STARS_DIR}/${star}" ]]; then
                    if ! command rm "${_STAR_HOME}/${_STAR_STARS_DIR}/${star}"; then
                        local res=$?
                        echo -e "Failed to remove starred directory: ${COLOR_STAR}${star//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET}."
                        return $res
                    fi
                    echo -e "Removed starred directory: ${COLOR_STAR}${star//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET}."
                else
                    echo -e "Couldn't find any starred directory with the name: ${COLOR_STAR}${star//${_STAR_DIR_SEPARATOR}//}${COLOR_RESET}."
                fi
            done
            # re create the other environment variables
            _star_set_variables
            ;;
        RESET)
            if [[ ! -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]];then
                echo "There are no starred directories to remove."
                return 0
            fi

            if [[ "${force_reset}" -eq 1 ]]; then
                # remove all env variables while their paths are still known
                _star_unset_variables

                local ret
                command rm -r "${_STAR_HOME}/${_STAR_STARS_DIR}"
                ret=$?
                [[ "$ret" -eq 0 ]] && echo "All stars have been removed." || echo "Failed to remove all the stars."
                return $ret
            fi

            while true; do
                echo -n "Remove all starred directories? [y/N] "
                read user_input
                case $user_input in
                    [Yy]*|yes )
                        # remove all env variables while their paths are still known
                        _star_unset_variables

                        local ret
                        command rm -r "${_STAR_HOME}/${_STAR_STARS_DIR}"
                        ret=$?
                        [[ "$ret" -eq 0 ]] && echo "All stars have been removed." || echo "Failed to remove all the stars."
                        return $ret
                        ;;
                    # case "" corresponds to pressing enter
                    # by default, pressing enter aborts the reset
                    [Nn]*|no|"" )
                        echo "Aborting reset." 
                        return 0
                        ;;
                    * )
                        echo "Not a valid answer.";;
                esac
            done
            ;;
        HELP)
            star-help
            return 0
            ;;
        *)
            ;;
    esac
}

# # https://askubuntu.com/questions/68175/how-to-create-script-with-auto-complete
# # https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# # https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
# #
# # https://unix.stackexchange.com/questions/273948/bash-completion-for-user-without-access-to-etc
# # https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases

# # _star_completion
# # Provides completion for this "star" tool, and for its different aliases (see aliases below).
# _star_completion()
# {
#     _star_prune
#     local cur prev opts first_cw second_cw stars_list
#     COMPREPLY=()
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
#     opts="add load rename remove list reset help"

#     # first and second comp words
#     first_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD]}"
#     second_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD+1]}"

#     # get list of stars only if their directory exists
#     stars_list=$([[ -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]] && find "${_STAR_HOME}/${_STAR_STARS_DIR}" -type l -printf "%f ")

#     # in REMOVE mode: suggest all starred directories, even after selecting a first star to remove
#     if [[ "${first_cw}" == "srm" \
#         || "${first_cw}" == "unstar" \
#         || "${second_cw}" == "remove" \
#         || "${second_cw}" == "rm" \
#     ]]; then
#         # suggest all starred directories
#         COMPREPLY=( $(compgen -W "${stars_list//${_STAR_DIR_SEPARATOR}/\/}" -- ${cur}) )
#         return 0
#     fi

#     case "${prev}" in
#         load|l|sl|rename)
#             # suggest all starred directories
#             COMPREPLY=( $(compgen -W "${stars_list//${_STAR_DIR_SEPARATOR}/\/}" -- ${cur}) )
#             return 0
#             ;;
#         star)
#             # only suggest options when star is the first comp word
#             # to prevent suggesting options in case a starred directory is named "star"
#             [ "${COMP_CWORD}" -eq 1 ] && COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
#             return 0
#             ;;
#         reset)
#             COMPREPLY=( $(compgen -W "-f --force" -- ${cur}) )
#             return 0
#             ;;
#         *)
#             ;;
#     esac
# }

# # create useful aliases
# alias sl="star l"       # star load
# alias sL="star L"       # star list
# alias srm="star rm"     # star remove
# alias unstar="star rm"  # star remove
# alias sa="star add"     # star add
# alias sah="star add"    # star add

# # activate completion for this program and the aliases
# complete -F _star_completion star
# complete -F _star_completion sl
# complete -F _star_completion srm
# complete -F _star_completion unstar
# complete -F _star_completion sah

# remove broken symlinks directly when sourcing this file
[[ -d "${_STAR_HOME}/${_STAR_STARS_DIR}" ]] && star-prune "${_STAR_HOME}/${_STAR_STARS_DIR}"

# set environment variables
_star_set_variables
