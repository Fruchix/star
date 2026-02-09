
# Project Architecture and workflow

## Project Architecture

### Sources architecture

```sh
star
├── bin/            # where the main star executable is located
├── docs/           # contains documentation destined to developers
├── libexec/        # contains all scripts/files that are USED BY star, but not directly available to the user
├── share/          # contains all software data that is not user-dependent
├── tests/          # tests for star, using BATS
├── configure
├── install.sh
├── LICENSE
└── README.md
```

### Software architecture

```sh
star
├── bin/                                # where the main star executable is located
│   └── star
├── libexec/                            # contains all scripts/files that are USED BY star, but not directly available to the user
│   └── star/                               # everything is in a "star" directory, to not overwrite or pollute other software's libexec scripts
│       ├── star-deps
│       ├── star-help
│       ├── star-list
│       ├── star-prune
│       └── star-setcolors.sh                   # *.sh: sould be sourced, not executed
└── share/                              # contains all software data that is not user-dependent
    └── star/                               # everything is in a "star" directory, to not overwrite or pollute other software's share scripts
        ├── completion/                         # scripts to be sourced to enable completion
        │   └── star.bash
        ├── config/
        │   └── star_config.sh.template
        ├── init/                               # scripts to be sourced to enable (initialize) star (add the 'star' function to the shell environment)
        │   └── star.bash
        └── VERSION                             # contains the version of star
```

#### Workflow summary

- `bin/star`: main executable script is primarily used to load the `star` function into the environment, along with autocompletion
- `libexec/star/*`: sub-scripts that can be called by `star`
- `share/star/*`: data for star software that is shared accross architectures

#### Workflow details

The workflow of star is the following:
- there is a main `star` function in the user's environment, that is used to change directories (only a shell function can change the directory of the current process).
- this `star` function is added to the shell environment by sourcing `${_STAR_HOME}/share/star/init/star.bash`, with the file extension depending on the shell 
  - `.bash` can also be used by zsh, as long as there is a `bash >= 3.2` installation available


**Problem**: if this file is not sourced, the user cannot know if nor where `star` is installed:
- This is solved by providing a main `star` script, that will be shadowed by the function once the file is sourced
  - The script should be located in a "bin" directory that is in the user's PATH
- This `star` script is used to initialize the star function, using the `eval` command:
  - `eval "$(command star init bash)"` or `eval "$(command star init zsh)"`
  - This is a common way of adding a function to the shell environment (e.g.: zoxide)
- Later, if the user wants to specifically invoke the script (as `star` will invoke the function), it can be done by using `command star`

How `star init` works:
- outputs the main `star` functions to stdout (along with a few other utils functions) (`cat share/star/init/star.bash`)
- outputs the autocompletion for star to stdout (in `share/star/completion/star.bash`)
- running `eval` on those outputs will evaluate the functions and add them to the shell's current environment

And then:
- `star` (either function or script) can call sub scripts in the `libexec/star` directory. Those scripts provide additional functionalities.
  - Having multiple scripts makes the code easier to develop and maintain
  - Those scripts are stored in `libexec` and not `lib` because the user shall not execute them directly, only `star` will execute them
  - Files with an `*.sh` extension are meant to be sourced (e.g.: `star-setcolors.sh` sets colors in the current shell environment)

## Environment variables

There are a few environment variables that describe star's installation (the software structure), and some others that are used to configure star at run-time. Those environment variables are not to be confused with the dynamicaly set environment variables, which is a feature of star (see [README](../README.md)'s features).

### Environment variables for star's installation

Those variables are prefixed by `_STAR_` (single underscore at the beginning).

- `_STAR_HOME`: the root directory of the star installation
  - should contain the directories `bin`, `libexec` and `share` described above
- `_STAR_DATA_HOME`: where to search for all data of the star software (i.e. mainly bookmarks)
- `_STAR_CONFIG_HOME`: where to search for the configuration file
- `_STAR_CONFIG_FILE`: the path to the configuration file

### Environment variables for star's configuration

Those variables are prefixed by `__STAR_` (double underscore at the beginning). A complete explanation of those variables and their allowed values is available in the config file template [share/star/config/star_config.sh.template](../share/star/config/star_config.sh.template).

Variables to toggle features:
- `__STAR_ENABLE_ENVVARS`: whether to dynamicaly set environment variables named after the bookmarks.  
  Note that the environment variable `___STAR_ENABLE_ENVVARS_CURRENT_STATUS` (triple underscore) is used internally to track the current status of this feature. If the two variables are not the same (it means the configuration was updated), then the environment variables are set or unset accordingly (and current status variable is updated).
- `__STAR_ENABLE_ALIASES`: whether to add aliases for common commands:
  - `sta`: alias for `star add`
  - `unstar` and `strm`: alias for `star remove`
  - `stl`: alias for `star load` (and `star list` when used without arguments and `__STAR_ENABLE_LOADLISTS=yes`)
- `__STAR_ENABLE_LOADLISTS`: change the behaviour of `star load`:
  - when set to `yes`, `star load` without arguments will list the stars, to provide a single command for listing and navigating.
  - when set to `no`, `star load` without arguments will cause an error and display usage information.

Variables to configure the colors:
- `__STAR_COLOR_NAME`: 24-bits color for the name of a bookmark
- `__STAR_COLOR_PATH`: 24-bits color for the path of a bookmark
- `__STAR_COLOR_RESET`: the default color to use
- `__STAR_COLOR256_NAME`: fallback 256 color
- `__STAR_COLOR256_PATH`: fallback 256 color
- `__STAR_COLOR256_RESET`: fallback 256 color

Some terminals support 24-bits colors (aka true color), some do not and only support 256 different colors.

Variables to configure the listing:
- `__STAR_LIST_FORMAT`: the format of each line when listing bookmarks
- `__STAR_LIST_COLUMN_COMMAND`: the command into which the bookmark listing is piped, that is used to align columns
- `__STAR_LIST_SORT`: how to sort the bookmarks
- `__STAR_LIST_ORDER`: in which order to display (ascending/descending)
- `__STAR_LIST_INDEX`: the order of the index (ascending/descending)

## Installation

The installation of star is inspired from the autotools workflow, that uses `configure` then `make` and finally `make install`.
We removed the dependency to `autotools` and `make`, and we removed the `make` step, only keeping two steps (one script per step):

```sh
./configure
./install.sh
```

The installation script `install.sh` has a `.sh` extension even though it is not meant to be sourced, because there is already a Unix command named `install`, whereas `configure` does not have this extension because it is meant to be used as an executable, not sourced.

Both scripts can be executed from another directory than theirs.
e.g.:
```sh
# here, star has been downloaded into the ~/Downloads directory
$HOME/Downloads/star/configure --prefix=$PWD
$HOME/Downloads/star/install.sh
```

### configure

This file is used to configure (no way!) how star will be installed. Currently, it only supports the `--prefix` option (which is a common option for configure executables) that allows the user to set where star will be installed.

It does not perform any system modification, and will create a file named `config.sh` in the current directory of the user.
This file will be sourced by `install.sh` to use the environment variables defined by configure.

In the future, more options could be added, for example to:
- enable/disable completion
- enable/disable bash or zsh support
- just install a standalone bash/zsh script

> Why is this script useful?  
> It enables a deterministic installation, where a specific installation can be reproduced by just using the config.sh file.

### install.sh

This file will install star according to the settings produced by `configure`. It will search for a `config.sh` file in the current directory of the user and source it if it finds it. It has a few options (see `./install.sh --help`).

To perform a system installation, or at least install in a location that requires sudo privilege, juste run `sudo ./install.sh`.

A staged install can be done using the `--destdir` option (or the `DESTDIR` environment variable), as the [GNU's DESTDIR standards](https://www.gnu.org/prep/standards/html_node/DESTDIR.html) is implemented in `install.sh`.

## Creating a release

A release can be created using:
```sh
./configure --prefix=
./install.sh --release

# Produces an archive 'star-v2.0.0.tar.gz' containing:
#
# star-v2.0.0
# ├── bin
# ├── libexec
# ├── share
# ├── install.sh
# ├── LICENSE
# ├── manifest.txt
# └── README.md
```

This will install star in a temporary build directory (named `release/star-v$VERSION`, in star's top-level directory), then create an archive based on those files.

If a release should already contain the root directories, like the absolute paths of the final installation, the prefix can be changed, e.g.:
```sh
./configure --prefix=/usr/local
./install.sh

# Produces an archive 'star-v2.0.0.tar.gz' containing:
#
# star-v2.0.0
# └── usr
#     └── local
#         ├── bin
#         ├── libexec
#         ├── share
#         ├── install.sh
#         ├── LICENSE
#         ├── manifest.txt
#         └── README.md
```


# Code conventions and principles

## Naming conventions

### Environment variables

All environment variables should be in upper snake case.

Environment variables used by the star program such as the path to installation, color codes, etc. must follow the following conventions:
- MUST NEVER be prefixed with `$STAR_*`. This is reserved to dynamically set environment variables, which is a feature designed for the user
- should be prefixed with `$_STAR_*` for variables related to the software installation (e.g. `$_STAR_DATA_HOME`)
- should be prefixed with `$__STAR_*` for variables related to the software configuration (e.g. `$__STAR_COLOR_NAME`) (this should cover all other cases).

### Program variables

When working with functions that will be put in the user's environment, all variables should be declared local and in lower snake case. Not declaring as local will make it available in the user's environment, i.e. polluting it.

```bash
local variable_example
```


# Writing the README.md

## Images

We use the Breeze color scheme, which is the default Konsole theme. On Iterm2: https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/Breeze.itermcolors

Then, we use a docker container to run the commands (to have a proper environment each time)

```sh
./docs/docker-devel/build.sh
./docs/docker-devel/run.sh
```

Dynamically add and manage bookmarks (called "stars")
```sh
star reset -f
tree -L 3
star add Documents/projects/dotfiles
star add Documents/work/LibFabric libfabric
star add /tmp/mounts/google-drive
star list
```

Instantly navigate to those stars
```sh
star list
star load libfabric
star list
# order is changed according to last accessed element (can be configured)
star load 2
star list
# no argument = star list
star load
```

Autocompletion is your friend
```sh
cd
star <TAB><TAB>
star do<TAB> d<TAB>
```

Use the generated environment variables to interract with your directories
```sh
star list
env | grep "^STAR_" --color=never
ls $STAR_GOOGLE_DRIVE
cat $STAR_GOOGLE_DRIVE/project.md
cp $STAR_GOOGLE_DRIVE/project.md $STAR_DOTFILES/
ls
```

Use the provided aliases to speed up your workflow
```sh
cd

sta ~/Documents/tools mytools
stl
unstar mytools
stl
stl dotfiles
```

Manage your stars
```sh
star list
star remove libfabric
star rename google-drive gdrive
star list
echo $STAR_GDRIVE
star reset
star list
```

Customize colors, listing and more
```sh
# setup
mkdir -p "$HOME/custom/"{lorem,ipsum,dolor,sit,amet}
tree "$HOME/custom"
star add "$HOME/custom/amet"
sleep 0.5
star add "$HOME/custom/sit"
sleep 0.5
star add "$HOME/custom/dolor"
sleep 0.5
star add "$HOME/custom/ipsum"
sleep 0.5
star add "$HOME/custom/lorem"
sleep 0.5
export COLORTERM="truecolor"
cd

star list
export __STAR_LIST_FORMAT="\033[33m<INDEX><BR><COLNAME>%f<COLRESET><BR><COLPATH>%l<COLRESET>"
star list
export __STAR_COLOR_NAME=$'\033[95m'
export __STAR_COLOR_PATH=$'\033[90m'
star add custom/amet newname
star list
__STAR_LIST_SORT=name star list
```
