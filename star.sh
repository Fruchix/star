#!/bin/bash

STAR_DIR="$HOME/.star"

# _star_prune
# Remove all broken symlinks in the ".star" directory.
# A broken symlink corresponds to a starred directory that does not exist anymore.
_star_prune()
{
    # return if the star directory does not exist
    if [[ ! -d ${STAR_DIR} ]];then
        return
    fi

    local broken_stars_name broken_stars_path
    broken_stars_name=( $(find $STAR_DIR -xtype l -printf "%f\n") )
    broken_stars_path=( $(find $STAR_DIR -xtype l -printf "%l\n") )

    # return if no broken link was found
    if [[ ${#broken_stars_name[@]} -le 0 ]]; then
        return
    fi

    # else remove each broken link
    for i in $(seq 0 $(("${#broken_stars_name[@]}"-1)) ); do
        rm "${STAR_DIR}/${broken_stars_name[$i]}" || return
        # echo -e "Pruned broken star: \e[36m${broken_stars_name[$i]}\e[0m -> \e[34m${broken_stars_path[$i]}\e[0m."
    done
}

star()
{
    _star_prune
    # all variables are local except STAR_DIR
    local star_dir_name positional_args stars_to_remove star_to_load dst_name dst_name_slash dst_basename dir_separator star_help

    star_help="Usage: star [OPTION]

Without option: add the current directory to the list of starred directories.

OPTION
    L|list
        list all starred directories

    l|load [star]
        change directory into the starred directory.
        Equivalent to \"star list\" when no starred directory is given.

        <star> should be the name of a starred directory 
        (one that is listed using \"star list\").

    rm|remove <star> [star] [star] [...]
        remove a starred directory.

        <star> should be the name of a starred directory.

    reset
        completely remove the \".star\" directory
        (hence remove the starred directories).

    h|help|--help
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

    star_dir_name=".star"
    dir_separator="»"

    # Parse the arguments

    positional_args=()
    stars_to_remove=()
    MODE=STORE

    while [[ $# -gt 0 ]]; do
        opt="$1"
        shift
        if [[ ${MODE} == REMOVE ]]; then
            stars_to_remove+=("$opt")
        fi
        case "$opt" in
            "--" ) break 2;;
            "-" ) break 2;;
            "reset" )
                while true; do
                    read -p "Remove all starred directories and the \".star\" directory? y/n " yn
                    case $yn in
                        [Yy]* )
                            if [[ -d ${STAR_DIR} ]];then
                                rm -r "${STAR_DIR}"
                            fi
                            return;;
                        [Nn]* ) return;;
                        * )
                            echo "Not a valid answer.";;
                    esac
                done
                ;;
            "l"|"load" )
                # load without arguments is equivalent to "star list"
                if [[ $# -eq 0 ]]; then
                    star list
                    return
                fi
                star_to_load=$1
                MODE=LOAD
                shift
                ;;
            "rm"|"remove" )
                if [[ $# -eq 0 ]]; then
                    echo "Missing argument. Usage: star remove <star> [star] [star] ..."
                    return
                fi
                stars_to_remove+=("$1")
                MODE=REMOVE
                shift
                ;;
            "L"|"list" )
                # handle the "list" case while reading arguments to stop the program immediately,
                # no matter the other parameters

                if [[ -d ${STAR_DIR} ]];then
                    # sorting according to the absolute path that the star refers to
                    find ${STAR_DIR} -type l -printf "\33[36m%f\33[0m -> \33[34m%l\33[0m\n" | column -t -s " " | sort -t">" -k2
                else
                    echo "No \".star\" directory (will be created when adding new starred directories)."
                fi
                return
                ;;
            "h"|"help"|"--help" )
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

    if [[ ! -d "${STAR_DIR}" ]];then
        mkdir "${STAR_DIR}"
    fi

    # process the selected mode, in
    #   - STORE: add a new starred directory
    #   - LOAD: move to a starred directory
    #   - REMOVE: remove a starred directory
    case ${MODE} in
        STORE)
            SRC_DIR=$(pwd)
            dst_name=$(basename "${SRC_DIR}")

            stars_path=( $(find $STAR_DIR -printf "%l\n") )
            [[ $stars_path =~ (^|[[:space:]])${SRC_DIR}($|[[:space:]]) ]] && echo "Directory is already starred."; return

            PWD=$(pwd)
            while [[ -e ${STAR_DIR}/${dst_name} ]]; do
                dst_name_slash=${dst_name//"${dir_separator}"/\/}
                dst_basename=$(basename "${PWD%%"$dst_name_slash"}")

                if [[ "${dst_basename}" == "/" ]]; then
                    echo -e "Directory already starred with maximum possible path: \e[36m${dst_name}\e[0m"
                    return
                fi

                dst_name="${dst_basename}${dir_separator}${dst_name}"
            done

            ln -s "${SRC_DIR}" "${STAR_DIR}/${dst_name}" || return
            echo -e "Added new starred directory: \e[36m${dst_name}\e[0m -> \e[34m${SRC_DIR}\e[0m"
            ;;
        LOAD)
            if [[ ! -e ${STAR_DIR}/${star_to_load} ]]; then
                echo -e "Star \e[36m${star_to_load}\e[0m does not exist."
            else
                cd -P "${STAR_DIR}/${star_to_load}" || return
            fi
            ;;
        REMOVE)
            for star in "${stars_to_remove[@]}"; do
                if [[ -e "${STAR_DIR}/${star}" ]]; then
                    rm "${STAR_DIR}/${star}" || return
                    echo -e "Removed starred directory: \e[36m${star}\e[0m"
                else
                    echo -e "Couldn't find any starred directory with the name: \e[36m${star}\e[0m"
                fi
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
    local cur prev opts first_cw second_cw
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="load remove list reset help"

    # first and second comp words
    first_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD]}"
    second_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD+1]}"

    # in REMOVE mode: suggest all starred directories, even after selecting a first star to remove
    if [[ "${first_cw}" == "srm" || "${first_cw}" == "unstar" || "${second_cw}" == "remove" || "${second_cw}" == "rm" ]]; then
        # suggest all starred directories
        COMPREPLY=( $(compgen -W "$(find ${STAR_DIR} -type l -printf "%f ")" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        load|l|sl)
            # suggest all starred directories
            COMPREPLY=( $(compgen -W "$(find ${STAR_DIR} -type l -printf "%f ")" -- ${cur}) )
            return 0
            ;;
        star)
            # only suggest options when star is the first comp word
            # to prevent suggesting options in case a starred directory is named "star"
            [ "${COMP_CWORD}" -eq 1 ] && COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
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
