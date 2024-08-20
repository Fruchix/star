# star

> star allows you to bookmark your favorite folders and instantly navigate to them.

## Installation

Clone the repo and source the file [`star.sh`](./star.sh):
```bash
git clone git@github.com:Fruchix/star.git
cd star
. star.sh           # equivalent of "source star.sh"s
```

Also source the file in your `.bashrc` or `.zshrc`:
```
. /path/to/star.sh
```

## Usage

```
star [OPTION]
```
Without option: add the current directory to the list of starred directories.

---
```
star list
```
List all starred directories.

---
```
star load [star]
```
Navigate into the starred directory.
Equivalent to "star list" when no starred directory is provided.

`[star]` should be the name of a starred directory (one that is listed using "star list").

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
Remove all starred directories and the ".star" directory.

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

fruchix@debian:~/Documents/star$ star
Added new starred directory: star -> /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ star list
star  ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ cd ..

fruchix@debian:~/Documents$ star
Added new starred directory: Documents -> /home/fruchix/Documents

fruchix@debian:~/Documents$ sl
Documents  ->  /home/fruchix/Documents
star       ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents$ cd

fruchix@debian:~$ sl star

fruchix@debian:~/Documents/star$ sl Documents

fruchix@debian:~/Documents$ unstar Documents
Removed starred directory: Documents
```


## License

[Apache](./LICENSE)  
> Copyright 2024 Fruchix
