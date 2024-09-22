# star

star is a CLI tool that allows you to bookmark your favorite folders and instantly navigate to them.

## Installation

Clone the repo and source the file [`star.sh`](./star.sh):
```bash
git clone https://github.com/Fruchix/star.git
cd star
. star.sh           # equivalent of "source star.sh"s
```

Also source the file in your `.bashrc` or `.zshrc`:
```
. /path/to/star.sh
```

## Usage

```
star [NAME|OPTION]
```
Without `OPTION`:
- Add the current directory to the list of starred directories.
- The new star will be named after `NAME` if provided.
- `NAME` must be unique (among all stars).
- `NAME` can be anything that is not a reserved `OPTION` keywords (see below).
- `NAME` can also contain slashes `/`.

With `OPTION`:
- Will execute the feature associated with this option.
- `OPTION` can be one of `list`, `load`, `remove`, `reset`, `help`, or one of there shortnames (such as `-h` for `help`). Use `star help` for more information on short parameters and aliases.


---
```
star list
```
List all starred directories, sorted according to last load (top ones are the last loaded stars).

---
```
star load [star]
```
Navigate into the starred directory.
Equivalent to "star list" when no starred directory is provided.

`[star]` should be the name of a starred directory (one that is listed using "star list").

> Also updates the last accessed time (used to sort stars when listing them).
---
```
star rename <existing star> <new star name>
```
Rename an existing star.

---
```
star remove <star> [star] [star] [...]
```
Remove one or more starred directories.

`<star>` should be the name of a starred directory.

---
```
star reset
```
Remove the ".star" directory (thus remove the starred directories).

---
```
star help
```
Get more information.

## Faster Usage

> Use `star help` for all options and aliases.

The following aliases are provided to make your life easier:
- `sL` = star list
- `sl` = star load (which is the same as "star list" when no argument is provided)
- `unstar` = star remove
- `srm` = star remove

## Example

```bash
fruchix@debian:~/Documents/star$ star list
No ".star" directory (will be created when adding new starred directories).

fruchix@debian:~/Documents/star$ star
Added new starred directory: star -> /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ star list
star  ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ cd ..

fruchix@debian:~/Documents$ star my/docs
Added new starred directory: my/docs -> /home/fruchix/Documents

fruchix@debian:~/Documents$ sl
my/docs  ->  /home/fruchix/Documents
star     ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents$ cd

fruchix@debian:~$ sl star

fruchix@debian:~/Documents/star$ sl my/docs

fruchix@debian:~/Documents$ unstar my/docs
Removed starred directory: my/docs
```

## License

[Apache](./LICENSE)  
> Copyright 2024 Fruchix
