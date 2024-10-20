#!/bin/bash

STAR_DIR="$HOME/.star"
_STAR_DIR_SEPARATOR="»"

# _star_prune
# Remove all broken symlinks in the ".star" directory.
# A broken symlink corresponds to a starred directory that does not exist anymore.
_star_prune()
{
    # return if the star directory does not exist
    if [[ ! -d ${STAR_DIR} ]];then
        return
    fi

    local broken_stars_name bl
    broken_stars_name=( $(find $STAR_DIR -xtype l -printf "%f\n") )

    # return if no broken link was found
    if [[ ${#broken_stars_name[@]} -le 0 ]]; then
        return
    fi

    # else remove each broken link
    for bl in "${broken_stars_name[@]}"; do
        rm "${STAR_DIR}/${bl}" || return
    done
}

star()
{
    _star_prune

    # all variables are local except STAR_DIR and _STAR_DIR_SEPARATOR
    local positional_args star_to_store stars_to_remove star_to_load star_help mode rename_src rename_dst
    local dst_name dst_name_slash dst_basename
    local star stars_list stars_path src_dir opt current_pwd user_input force_reset
    star_help="Usage: star [NAME|OPTION]

Without OPTION:
- Add the current directory to the list of starred directories.
- The new star will be named after NAME if provided.
- NAME must be unique (among all stars).
- NAME can be anything that is not a reserved OPTION keywords (see below).
- NAME can also contain slashes /.

With OPTION:
- Will execute the feature associated with this option.
- OPTION can be one of list, load, remove, reset, help, or one of there shortnames (such as -h for help).

OPTION
    L|list
        List all starred directories, sorted according to last load (top ones are the last loaded stars).

    l|load [star]
        Navigate into the starred directory.
        Equivalent to \"star list\" when no starred directory is given.

        <star> should be the name of a starred directory 
        (one that is listed using \"star list\").

    rename <existing star> <new star name>
        Rename an existing star.

    rm|remove <star> [star] [star] [...]
        Remove one or more starred directories.

        <star> should be the name of a starred directory.

    reset [-f|--force]
        Remove the \".star\" directory (hence remove the starred directories).
        The argument -f or --force will force the reset without prompting the user.

    h|help|-h|--help
        displays this message

ALIASES
The following aliases are provided:
    sL
        corresponds to \"star list\"
    sl
        corresponds to \"star load\"
    srm
        corresponds to \"star remove\"
    unstar
        corresponds to \"star remove\"
"

    # Parse the arguments

    positional_args=()
    star_to_store="${1-}"   # default value is an empty string if $1 is unset
    stars_to_remove=()
    force_reset=0
    mode=STORE

    while [[ $# -gt 0 ]]; do
        opt="$1"
        shift

        # remove multiple stars
        if [[ ${mode} == REMOVE ]]; then
            stars_to_remove+=("${opt//\//"${_STAR_DIR_SEPARATOR}"}")
        fi

        case "$opt" in
            "--" ) break 2;;
            "-" ) break 2;;
            "reset" )
                mode=RESET
                if [[ "$1" == "-f" || "$1" == "--force" ]]; then
                    force_reset=1
                fi
                break
                ;;
            "l"|"load" )
                # load without arguments is equivalent to "star list"
                if [[ $# -eq 0 ]]; then
                    star list
                    return
                fi
                star_to_load="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                mode=LOAD
                shift
                ;;
            "rename" )
                mode=RENAME
                if [[ $# -lt 2 ]]; then
                    echo "Missing argument. Usage: star rename <existing star> <new star name>"
                    return
                fi
                rename_src="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                rename_dst="${2//\//"${_STAR_DIR_SEPARATOR}"}"
                break
                ;;
            "rm"|"remove" )
                if [[ $# -eq 0 ]]; then
                    echo "Missing argument. Usage: star remove <star> [star] [star] ..."
                    return
                fi
                stars_to_remove+=("${1//\//"${_STAR_DIR_SEPARATOR}"}")
                mode=REMOVE
                shift
                ;;
            "L"|"list" )
                mode=LIST
                # handle the "list" case immediately, no matter the other parameters
                break
                ;;
            "h"|"help"|"-h"|"--help" )
                echo "${star_help}"
                return
                ;;
            -*)
                echo >&2 "Invalid option: $opt"
                return
                ;;
            *)
                positional_args+=("$opt")
                ;;
       esac
    done

    # process the selected mode
    case ${mode} in
        STORE)
            if [[ ! -d "${STAR_DIR}" ]]; then
                mkdir "${STAR_DIR}"
            fi

            src_dir=$(pwd)

            if [[ ! "${star_to_store}" == "" ]]; then
                # replace slashes by dir separator char: a star name can contain slashes
                dst_name="${star_to_store//\//"${_STAR_DIR_SEPARATOR}"}"
            else
                dst_name=$(basename "${src_dir}")
            fi

            # do not star this directory if it is already starred (even under another name)
            stars_path=( "$(find "$STAR_DIR" -printf "%l\n")" )
            if [[ "${stars_path[*]}" =~ (^|[[:space:]])${src_dir}($|[[:space:]]) ]]; then
                echo "Directory is already starred."
                return
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
                current_pwd=$(pwd)
                while [[ -e ${STAR_DIR}/${dst_name} ]]; do
                    dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                    dst_basename=$(basename "${current_pwd%%"$dst_name_slash"}")

                    if [[ "${dst_basename}" == "/" ]]; then
                        echo -e "Directory already starred with maximum possible path: \e[36m${dst_name_slash}\e[0m"
                        return
                    fi

                    dst_name="${dst_basename}${_STAR_DIR_SEPARATOR}${dst_name}"
                done
            # When adding a new starred directory with a given name (as argument),
            # then the name should not already exist
            else
                dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                if [[ -e ${STAR_DIR}/${dst_name} ]]; then
                    echo -e "A directory is already starred with the name \"${dst_name_slash}\": $(find "${STAR_DIR}/${dst_name_slash}" -type l -printf "\33[36m%f\33[0m -> \33[34m%l\33[0m\n")"
                    return
                fi
            fi

            ln -s "${src_dir}" "${STAR_DIR}/${dst_name}" || return
            echo -e "Added new starred directory: \e[36m${dst_name//"${_STAR_DIR_SEPARATOR}"//}\e[0m -> \e[34m${src_dir}\e[0m"
            ;;
        LOAD)
            if [[ ! -d "${STAR_DIR}" ]];then
                echo "No star can be loaded, as there is not any starred directory."
                return
            fi

            if [[ ! -e ${STAR_DIR}/${star_to_load} ]]; then
                echo -e "Star \e[36m${star_to_load}\e[0m does not exist."
            else
                cd -P "${STAR_DIR}/${star_to_load}" || return
                # update access time
                touch -ah "${STAR_DIR}/${star_to_load}"
            fi
            ;;
        LIST)
            if [[ ! -d "${STAR_DIR}" ]];then
                echo "No \".star\" directory (will be created when adding new starred directories)."
            else
                # sort according to access time (last accessed is on top)
                stars_list=$(find ${STAR_DIR} -type l -printf "%As \33[36m%f\33[0m -> \33[34m%l\33[0m\n" | column -t -s " " | sort -nr | cut -d" " -f3-)
                echo "${stars_list//"${_STAR_DIR_SEPARATOR}"//}"
            fi
            ;;
        RENAME)
            if [[ -e "${STAR_DIR}/${rename_src}" ]]; then
                if [[ -e "${STAR_DIR}/${rename_dst}" ]]; then
                    echo -e "There is already a star named \e[36m${rename_dst}\e[0m."
                    return
                fi

                mv "${STAR_DIR}/${rename_src}" "${STAR_DIR}/${rename_dst}" || return
                echo -e "Renamed star \e[36m${rename_src//"${_STAR_DIR_SEPARATOR}"//}\e[0m to \e[36m${rename_dst//"${_STAR_DIR_SEPARATOR}"//}\e[0m."
            else
                echo -e "Star \e[36m${rename_src}\e[0m does not exist."
            fi
            ;;
        REMOVE)
            if [[ ! -d "${STAR_DIR}" ]];then
                echo "No star can be removed, as there is not any starred directory."
                return
            fi

            for star in "${stars_to_remove[@]}"; do
                if [[ -e "${STAR_DIR}/${star}" ]]; then
                    rm "${STAR_DIR}/${star}" || return
                    echo -e "Removed starred directory: \e[36m${star//"${_STAR_DIR_SEPARATOR}"//}\e[0m"
                else
                    echo -e "Couldn't find any starred directory with the name: \e[36m${star//"${_STAR_DIR_SEPARATOR}"//}\e[0m"
                fi
            done
            ;;
        RESET)
            if [[ ! -d "${STAR_DIR}" ]];then
                echo "No \".star\" directory to remove."
                return
            fi

            if [[ "${force_reset}" -eq 1 ]]; then
                rm -r "${STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                return
            fi

            while true; do
                echo -n "Remove the \".star\" directory? (removes all starred directories) y/N "
                read user_input
                case $user_input in
                    [Yy]*|yes )
                        rm -r "${STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                        return;;
                    # case "" corresponds to pressing enter
                    # by default, pressing enter aborts the reset
                    [Nn]*|no|"" )
                        echo "Aborting reset." 
                        return;;
                    * )
                        echo "Not a valid answer.";;
                esac
            done
            ;;
        *)
            ;;
    esac
}

# https://askubuntu.com/questions/68175/how-to-create-script-with-auto-complete
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
#
# https://unix.stackexchange.com/questions/273948/bash-completion-for-user-without-access-to-etc
# https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases

# _star_completion
# Provides completion for this "star" tool, and for its different aliases (see aliases below).
_star_completion()
{
    _star_prune
    local cur prev opts first_cw second_cw stars_list
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="load rename remove list reset help"

    # first and second comp words
    first_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD]}"
    second_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD+1]}"

    # get list of stars only if ".star" directory exists
    stars_list=$([[ -d "${STAR_DIR}" ]] && find ${STAR_DIR} -type l -printf "%f ")

    # in REMOVE mode: suggest all starred directories, even after selecting a first star to remove
    if [[ "${first_cw}" == "srm" \
        || "${first_cw}" == "unstar" \
        || "${second_cw}" == "remove" \
        || "${second_cw}" == "rm" \
    ]]; then
        # suggest all starred directories
        COMPREPLY=( $(compgen -W "${stars_list//"${_STAR_DIR_SEPARATOR}"/\/}" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        load|l|sl|rename)
            # suggest all starred directories
            COMPREPLY=( $(compgen -W "${stars_list//"${_STAR_DIR_SEPARATOR}"/\/}" -- ${cur}) )
            return 0
            ;;
        star)
            # only suggest options when star is the first comp word
            # to prevent suggesting options in case a starred directory is named "star"
            [ "${COMP_CWORD}" -eq 1 ] && COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        reset)
            COMPREPLY=( $(compgen -W "-f --force" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
}

# create useful aliases
alias sl="star l"       # star load
alias sL="star L"       # star list
alias srm="star rm"     # star remove
alias unstar="star rm"  # star remove

# activate completion for this program and the aliases
complete -F _star_completion star
complete -F _star_completion sl
complete -F _star_completion srm
complete -F _star_completion unstar

# remove broken symlinks directly when sourcing this file
_star_prune
