# star <!-- omit from toc -->

star is a (slightly over-engineered) Unix command line bookmark manager. Dynamically star your favorite folders and instantly navigate (cd) to them.

It is written in Bash, but can be used with Zsh as long as there is an available Bash version (>= 3.2).

> ### Important notice
> Due to the existence of another tool called [`star`](https://linux.die.net/man/1/star), this tool will probably be renamed.  
> I would like the new name to begin with `star`, as I want to keep this "star" idea, but nothing is sure.

## Table of contents <!-- omit from toc -->

- [Features](#features)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Installing](#installing)
  - [Uninstalling](#uninstalling)
- [Configuration](#configuration)
  - [Files configuration](#files-configuration)
  - [Runtime configuration](#runtime-configuration)
- [Troubleshooting](#troubleshooting)
- [Contributions and development](#contributions-and-development)
  - [Future work](#future-work)
  - [Development](#development)
  - [Testing](#testing)
- [Contributors](#contributors)
- [License](#license)

## Features

<details>
  <summary>Dynamically add bookmarks (called "stars")</summary>

  - `star add <PATH> [NAME]`: add a star
  - `star list`: list all stars

  <div align="left">
    <img width="593" height="617" alt="dynamically-add" src="https://github.com/user-attachments/assets/5b59adb1-c9d2-461f-a6b9-1c2579c7f8a5" alt="Dynamically add bookmarks" />
  </div>
</details>

<details>
  <summary>Instantly navigate into your favorite directories</summary>

  - `star load [STAR]`: `cd` into the star's directory (the star is identified by its name or its index)
  - By default, `star load` without arguments is equivalent to `star list`, to have a single command for listing and navigating
  
  <div align="left">
    <img width="458" height="435" src="https://github.com/user-attachments/assets/1ba516e0-3baf-42f6-9059-35cc1f026232" alt="Navigate to favorite directories" />
  </div>

  > The output of `star list` is sorted according to when each element was loaded last (this can be configured).

  > Setting `__STAR_ENABLE_LOADLISTS` to `no` will make `star load` without arguments cause an error.
</details>

<details>
  <summary>Autocompletion is your friend</summary>
  <div align="left">

  Autocompletion is provided for the different modes and for the starred directories.

https://github.com/user-attachments/assets/a3917ccf-4a6a-424d-a729-24860235c83f

  </div>
</details>

<details>
  <summary>Use the generated environment variables to interact with your directories</summary>

  Those variable are prefixed with `STAR_`, and the rest is generated from the name of the star. Typing `STAR_` then pressing TAB two times will display the different variables available.

  <div align="left">
    <img width="591" height="502" alt="envvars" src="https://github.com/user-attachments/assets/096a7078-0e11-4b48-933d-44304ae480af" />
  </div>

#### More information <!-- omit from toc -->
- The environment variables are only exported if they do not overwrite an already existing environment variable that is not related to star
- This feature can be disabled using `__STAR_ENABLE_ENVVARS=no` (see [Enabling/disabling features](#enablingdisabling-features))

</details>

<details>
  <summary>Manage your stars</summary>

  - `star rename <OLD_NAME> <NEW_NAME>`: rename a star
  - `star remove <STAR_NAME> [STAR_NAME]...`: remove one or multiple stars
  - `star reset [--force]`: remove all star data
  
  <div align="left">
    <img width="466" height="434" alt="management" src="https://github.com/user-attachments/assets/c80ff5c3-9b4b-4248-86b7-1ae9e5e97f59" />
  </div>
</details>

<details>
  <summary>Use the provided aliases to speed up your workflow</summary>

  - `sta`: alias for `star add`
  - `unstar` or `strm`: aliases for `star rm`
  - `stl`: alias for `star load` (and `star list` when used without arguments and `__STAR_ENABLE_LOADLISTS=yes`)
  
  <div align="left">
    <img width="524" height="351" alt="aliases" src="https://github.com/user-attachments/assets/0ee83ce3-fc4c-4a07-9601-1d86dca45ce0" />
  </div>

#### More information <!-- omit from toc -->
- This feature can be disabled using `__STAR_ENABLE_ALIASES=no` (see [Enabling/disabling features](#enablingdisabling-features))

</details>

<details>
  <summary>Customize colors, listing and more</summary>
  <div align="left">
    <img width="593" height="718" alt="customization" src="https://github.com/user-attachments/assets/05a6030c-bb90-420a-ae33-09f6fda6226a" />
  </div>
</details>

> #### More documentation
> 
> <details>
>   <summary>Detailed usage</summary>
>   <div align="left">
> 
> ```sh
> Usage: star [MODE]
>        star [OPTION]
> 
> Dynamically bookmark and cd into directories.
> Bookmarks are called "stars".
> 
>     MODE (related to stars management)
>         add     Add a new star
>         list    List all stars
>         load    cd into a starred directory
>         rename  Change the name of a star
>         remove  Remove a star
>         reset   Delete all stars
> 
>     MODE (miscellaneous)
>         config  Edit configuration file and apply changes
>         help    Show this help message
> 
>     Get more information for each mode using:
>         star MODE --help
>         star help MODE
> 
>     OPTION
>         -h, --help          Show this help message
>         -v, --version       Show star version
>         -I, --info          Show more information about the star installation
> ```
> 
>   
>   </div>
> </details>
> 
> <details>
>   <summary>Detailed usage for each mode</summary>
>   <div align="left">
>
> #### add
> ```sh
> Usage: star add PATH [NAME]
>        star a PATH [NAME]
> 
> Add a new star.
> 
>     PATH
>         Relative path to the directory to star.
>         e.g. "star add ." will star the current directory
> 
>     NAME
>         The name of the new star if provided, otherwise it will use the name of the current directory.
>         - Must be unique (among all stars)
>         - Can contain slashes: "/"
>         - Whitespaces will be replaced by a dash: "-"
>         - Names with only numeric characters will by prefixed by "dir-"
> ```
> 
> 
> #### list
> ```sh
> Usage: star list [OPTIONS]
>        star L [OPTIONS]
> 
> List all stars, by default sorted according to last load (top ones are the last loaded stars).
> 
> Listing can be customized either by:
> - editing the environment variables in the configuration file (see 'star config' for more information)
> - using options supported by the 'star-list' helper script
> 
> Get the 'star-list' usage and options by running:
>  "${_STAR_HOME}/libexec/star/star-list" --help
> ```
> 
> 
> #### load
> ```sh
> Usage: star load [STAR]
>        star l [STAR]
> 
> Navigate (cd) into the starred directory.
> 
> By default, giving no argument will list the stars, to provide a single command for listing and navigating.
> This behavior can be disabled by setting the environment variable \`__STAR_ENABLE_LOADLISTS\` to "no".
> 
>     STAR
>         Should be the name or index of a starred directory (one that is listed using "star list").
> ```
> 
> 
> #### rename
> ```sh
> Usage: star rename <STAR> <NEW_STAR_NAME>
> 
> Rename an existing star.
> 
>     STAR
>         Should be the name of a starred directory.
> 
>     NEW_STAR_NAME
>         The new name of the star.
>         - Must be unique (among all stars)
>         - Can contain slashes /
> ```
> 
> 
> #### remove
> ```sh
> Usage: star remove <STAR> [STAR]...
>        star rm <STAR> [STAR]...
> 
> Remove one or more stars.
> 
>     STAR
>         Should be the name of a starred directory.
> ```
> 
> 
> #### reset
> ```sh
> Usage: star reset [-f|--force]
> 
> Remove all stars and the ".star" directory.
> 
>     --force, -f
>         Force reset without prompting the user.
> ```
> 
> 
> #### config
> ```sh
> Usage: star config
> 
> Open the star configuration file in a terminal text editor then apply the updated configuration.
> 
> Configuration file:
>     The configuration file is located at $_STAR_CONFIG_FILE, which is by default "$_STAR_CONFIG_HOME/star_config.sh".
>     Customizing $_STAR_CONFIG_FILE will allow you to use any file for star configuration. Keep in mind that this file will get sourced after each "star config".
> 
>     Customizing $_STAR_CONFIG_HOME will allow you to change the directory where the default configuration file is stored (star_config.sh).
>     By default, this corresponds to:
>         - "$XDG_CONFIG_HOME/star" if XDG_CONFIG_HOME is defined
>         - else "$HOME/.config/star"
> 
>     If the configuration file does not exist, star will suggest a command to create one from a provided template.
> 
>     Template location:
>         $_STAR_HOME/share/star/config/star_config.sh.template
> 
> Editor:
>     - use the one defined in the environment variable $EDITOR
>     - else use "nano" if available
>     - else use "vi" if available
> ```
>
>   </div>
> </details>

## Installation

### Requirements

> Before anything, an important note is that there already exist another CLI tool named `star`, from [Jörg Schilling's schilytools](https://codeberg.org/schilytools/schilytools). Its source code is available [here](https://codeberg.org/schilytools/schilytools/src/branch/master/star) and [here](https://github.com/Projeto-Pindorama/star).  
> Is you have installed this tool (or any other command line tool named `star`), installing this star software will shadow the other tools.  
> There is currently no clean way to make two different star software work together.

To enable `star` to work properly, ensure your system meets the requirements:
- package `GNU coreutils` (for `realpath`, `printf`, `mkdir`, `rm`, `mv`, `cp`, `echo`, etc.)
- package `GNU findutils` (for `find`)
- command `column` (uses portable options `-t` and `-s` to format the listing, so any version should work)
- `bash >= 3.2`

On MacOS, the default utils for `find`, `printf`, `echo`, etc. are not GNU versions. You can install the GNU versions using Homebrew (see below). However, MacOS comes with `bash` version 3.2 by default, and has a `column` implementation that has `-t` and `-s` options.

<details>
  <summary>Install requirements using apt</summary>

```sh
# install GNU coreutils
apt install coreutils

# install GNU findutils
apt install findutils

# install column (util-linux version)
apt install bsdmainutils
```

</details>

<details>
  <summary>Install requirements using brew</summary>

When installing GNU softwares with brew, they are prefixed with a `g` to highlight the difference with the default softwares. For example: `gfind`. To solve this, we add a special directory called `gnubin` to the PATH, which contains the default names without the `g`.

```sh
# install GNU coreutils
brew install coreutils
# add the following line to your shell configuration file to enable non g-prefixed softwares
export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"

# install GNU findutils
brew install findutils
# add the following line to your shell configuration file to enable non g-prefixed softwares
export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"

# install column (util-linux version)
brew install util-linux
# add the following line to your shell configuration file
export PATH="$(brew --prefix)/opt/util-linux/bin:$PATH"
```

</details>


### Installing

Installation can be done from source or from a release tarball. There are currently no real differences between the two, appart that the release is a bit more lightweight as it does not include documentation and tests. Either method involves two steps: running `./configure` to configure star's installation and then `./install.sh` to install the tool. Currently, `configure` is only used to set where star will be installed (but in the future, it may enable/disable features).

Installation steps are the following:
- running `configure` then `install.sh`
- add the `bin` directory (where star is installed) to the PATH if it is not alredy in it (the command to execute will be shown after installation)
- initialize star using `eval "$(command star init YOUR_SHELL_TYPE)"` (see `command star --help`)

#### Recommended user installation (from release) <!-- omit from toc -->

```sh
curl -L -o star-2.1.0.tar.gz https://github.com/Fruchix/star/releases/download/v2.1.0/star-2.1.0.tar.gz
tar xvf star-2.1.0.tar.gz
cd star-2.1.0
./configure --prefix=$HOME/.local
./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":$HOME/.local/bin:" ]] || export PATH="$HOME/.local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"
```

To quickly add those commands to your ~/.bashrc:
```sh
echo '[[ ":${PATH}:" =~ ":$HOME/.local/bin:" ]] || export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo -e '\neval "$(command star init bash)"' >> ~/.bashrc
```
or ~/.zshrc:
```sh
echo '[[ ":${PATH}:" =~ ":$HOME/.local/bin:" ]] || export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo -e '\neval "$(command star init zsh)"' >> ~/.zshrc
```

#### Recommended system installation (from release) <!-- omit from toc -->

```sh
curl -L -o star-2.1.0.tar.gz https://github.com/Fruchix/star/releases/download/v2.1.0/star-2.1.0.tar.gz
tar xvf star-2.1.0.tar.gz
cd star-2.1.0
./configure         # by default, prefix is set to: /usr/local
sudo ./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":/usr/local/bin:" ]] || export PATH="/usr/local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"

# Any user that would want to use star would have to add those commands to their ~/.bashrc or ~/.zshrc
```

To quickly add those commands to your ~/.bashrc:
```sh
echo '[[ ":${PATH}:" =~ ":/usr/local/bin:" ]] || export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
echo -e '\neval "$(command star init bash)"' >> ~/.bashrc
```
or ~/.zshrc:
```sh
echo '[[ ":${PATH}:" =~ ":/usr/local/bin:" ]] || export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
echo -e '\neval "$(command star init zsh)"' >> ~/.zshrc
```

<details>
  <summary>Installation on Nix</summary>

If you're using Nix or NixOS, you can install star using the provided flake:

```sh
# Run directly without installing
nix run github:Fruchix/star

# Install to your user profile
nix profile install github:Fruchix/star

# Or add to your flake inputs and use in your configuration
```

After installation, initialize star in your shell configuration:
```sh
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"
```

</details>

### Uninstalling

Each installation of star can be uninstalled using the provided `uninstall.sh` script. This script should be located at `$_STAR_HOME/share/star/uninstall.sh`.

The script requires a manifest file to remove all installed files. This manifest file is created at installation time. It is by default located at `$_STAR_HOME/share/star/manifest.txt`. The uninstallation script uses by default the `_STAR_HOME` variable to locate the manifest file, but if it is unset you can manually pass the manifest file using the `--input` option.

Note that the best way to uninstall star is to have it initialized in the current shell, so that `_STAR_HOME` and other variables such as `$_STAR_DATA_HOME` and `$_STAR_CONFIG_FILE` are set properly.

## Configuration

### Files configuration

star respects the [XDG base directory specification](https://specifications.freedesktop.org/basedir/latest/). By default, star's configuration file is stored in `${XDG_CONFIG_HOME}/star/`, and its data files (the stars) are stored in `${XDG_DATA_HOME}/star/`.

You can override these locations by setting the following environment variables before initializing star:
- `_STAR_CONFIG_HOME`: path to star's configuration file directory (the configuration file is named `config.sh`)
- `_STAR_CONFIG_FILE`: path to star's configuration file (overrides `_STAR_CONFIG_HOME`) (for example to use a custom named configuration file)
- `_STAR_DATA_HOME`: path to star's data files (the stars)

### Runtime configuration

The behaviour of star can be customized with environment variables. Those variables are prefixed with `__STAR_`. They can be exported anywhere, preferably before initializing star (e.g., in your shell configuration file).

However, the recommended way is to run `star config`:
- it opens the configuration file in an editor (as defined by the `EDITOR` environment variable, else in `nano`/`vi`)
- when closing the editor, star is re-initialized to apply the new configuration
- if the configuration file does not exist, star displays the command to create one from a [template](./share/star/config/star_config.sh.template)

When creating the configuration file from a [template](./share/star/config/star_config.sh.template), all variables are well documented with their possible values, default value and description.

Below is the list of the different environment variables that can be used to customize star.

#### Enabling/disabling features <!-- omit from toc -->

Some features can be enabled or disabled by setting the corresponding environment variable to `yes` or `no`.

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_ENABLE_ENVVARS` | `yes` / `no` | `yes` | Whether to dynamically set environment variables named after the bookmarks (see [Features](#features)) |
| `__STAR_ENABLE_ALIASES` | `yes` / `no` | `yes` | Whether to add aliases for common commands (`sta`, `unstar`, `strm`, `stl`) (see [Features](#features)) |
| `__STAR_ENABLE_LOADLISTS` | `yes` / `no` | `yes` | If "yes", `star load` without arguments is equivalent to `star list`, else it will cause an error (missing argument). |

Note that when updating `__STAR_ENABLE_ENVVARS`, the change will only be effective at the next invocation of star.

Note that when updating `__STAR_ENABLE_ALIASES`, the change will only be effective for the next shell.

#### Configure the colors <!-- omit from toc -->

Some terminals support 24-bits colors (aka true color), some do not and only support 256 different colors. Star will try to use 24-bits colors by default, and fallback to 256 colors.

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_COLOR_NAME` | 24-bits color with format `$'\033[...m'` | `$'\033[38;2;255;131;0m'` | Color for the name of a bookmark |
| `__STAR_COLOR_PATH` | 24-bits color with format `$'\033[...m'` | `$'\033[38;2;1;169;130m'` | Color for the path of a bookmark |
| `__STAR_COLOR_RESET` | 24-bits color with format `$'\033[...m'` | `$'\033[0m'` | The default color to use |
| `__STAR_COLOR256_NAME` | 256 color `$'\033[...m'` | `$'\033[38;5;214m'` | Fallback color for the name of a bookmark |
| `__STAR_COLOR256_PATH` | 256 color `$'\033[...m'` | `$'\033[38;5;36m'` | Fallback color for the path of a bookmark |
| `__STAR_COLOR256_RESET` | 256 color `$'\033[...m'` | `$'\033[0m'` | Fallback default color |

#### Configure the listing <!-- omit from toc -->

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_LIST_FORMAT` | string | `<INDEX>:<BR><COLNAME>%f<COLRESET><BR>-><BR><COLPATH>%l<COLRESET>` | The format of each line when listing bookmarks. Check the formatting in the [configuration file template](./share/star/config/star_config.sh.template). |
| `__STAR_LIST_COLUMN_COMMAND` | command stored as a string | `command column -t -s $'\t'` | The command into which the bookmark listing is piped, used to align columns. Note the usage of the tab character as the column separator: the <BR> placeholder is replaced by a tab. |
| `__STAR_LIST_SORT` | `loaded` / `name` / `none` | `loaded` | How to sort the bookmarks. |
| `__STAR_LIST_ORDER` | `asc` / `desc` | `desc` | The order in which to display bookmarks |
| `__STAR_LIST_INDEX` | `asc` / `desc` | `asc` | The order of the index |

See the [configuration file template](./share/star/config/star_config.sh.template) to know how to properly customize `__STAR_LIST_FORMAT` and `__STAR_LIST_COLUMN_COMMAND` (and the other variables).

## Troubleshooting

If you encounter any issues while using star, please ensure that all required dependencies are installed and accessible in your PATH.

If the problem persists, please open an issue on the [GitHub repository](https://github.com/Fruchame/star/issues).

## Contributions and development

Contributions are welcome! Please submit [issues](https://github.com/Fruchame/star/issues) or [pull requests](https://github.com/Fruchix/star/pulls) to improve star.

### Future work

#### Features  <!-- omit from toc -->
- [ ] Add a standalone script that can be sourced an have the same functionalities  
  Note: this would be a pretty ugly script with a LOT of lines, but it would be interesting to be able to have only a single script to source in some cases.
  - [ ] Maybe this script can be automatically built?
  - [ ] Standalone would not be included in classic releases, and would have a specific release archive with only the standalone
- [ ] Add setting for `star-purge`: automatically remove stars (auto), ask for user confirmation (ask), never remove stars (never)
  - [ ] Add a way to ignore some directories from being purged (e.g., using a `.starignore` file)
- [ ] Implement a pure bash version of `column` that implements options `-t` and `-s`
  - [ ] Can either be in the `bin` directory, or `libexec` (depending on if we want the user to be able to use it)
  - [ ] add a `--with-column`/`--without-column` configure option, to install and use this one (or not) by default

#### Improvements  <!-- omit from toc -->
- [ ] Replace echo -e with printf for better portability
- [ ] Output all errors into stderr instead of stdout
- [ ] Refactor the code to reduce the number of small dependency scripts (in the `libexec` directory)
- [ ] Try to put as much code as possible in the star binary (and not the function) and benchmark the difference  
  The idea would be to have a smaller wrapper function: the wrapper is usually smaller than the binary, here it is the opposite. The binary is almost only use to initialize the "wrapper" itself (hence it is not really a wrapper, just a shell function).
  - [ ] If the performance is the same, put the code in the binary
  - [ ] If the performance is worse, keep it in the star function

#### Tests  <!-- omit from toc -->
- [ ] Complete the tests for `star list` to test all options and combinations
- [ ] Add a "no pollution test" that ensures that all local variables are declared as local, and no unwanted global variables are created
- [ ] Add tests for environment variable generation
- [ ] Add shellcheck testing in CI
- [ ] Add tests for flake

### Development

Please read the [architecture documentation](./docs/architecture.md) to understand how star is structured and how to contribute effectively.

### Testing

Tests are written using [Bats](https://bats-core.readthedocs.io/en/stable/). To run the tests, ensure you have Bats installed and run the following command from the root of the repository:

```sh
bats tests/<subdirectory>

# Example: 
bats tests/core
```

To run all tests, use the following script:

```sh
./tests/run-tests.sh
```

## Contributors

Special thanks to [@PourroyJean](https://www.github.com/PourroyJean) and [@ayys](https://github.com/ayys) for contributing to this project.

## License

[Apache](./LICENSE)  
> Copyright 2025 Fruchix
