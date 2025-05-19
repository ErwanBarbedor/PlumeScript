<p align="center"><img src="plume_logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.34-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


## Plume🪶 - An Expressive Templating Language

- ✨ **Lightweight Syntax:** Minimal special characters and indentation-based structure make Plume easy to write and read.
- 📖 **Expressive and Readable:** Inspired by YAML for lists and hashes, and common programming languages for the rest, Plume offers a clear and concise syntax.
- ⚙️ **Versatile and Extensible:** While well-suited for rich text generation with macros, Plume allows you to achieve virtually anything possible with a general-purpose programming language, with almost no special syntax. This makes it highly adaptable to various use cases.
- 🔗 **Lua Integration:** Written in and transpiling to Lua, seamlessly integrate Plume into your existing Luajit projects.

Test it now [in your browser](https://app.barbedor.bzh/plume.html)! *older version waiting for update*


## Installation

### Linux

You must have luajit installed.

``` sh
git clone https://github.com/ErwanBarbedor/PlumeScript
cd PlumeScript
chmod +x plume
./plume --install
```

## Usage
```
Usage: 
    INPUT
    plume file.plume
        Executes the given script.
    plume [-s --string] "..."
        Executes the given string.
    
    OUTPUT
    plume INPUT [-o --output] file.txt
        Saves the output to file.txt.
        Warning: The result is converted using 'tostring'.
        So if the script returns a table, the output in the file might not be directly usable.
    plume INPUT [-p --print]
        Print the output to the console.

    PLUME MANAGEMENT
    plume --install
    plume --install directory
        Install plume in the given directory (~/.local/bin by default)
    plume --remove
        Remove plume installation
    plume --update
        Download new plume version from github
    
    OTHER
    plume [-h --help]
        Displays this help message.
    plume [-v --version]
        Displays current Plume version
```
## Overview

*(the best way to get a feel for Plume is to follow the tutorials available on the link given above)*

Thinks of Plume as a Yaml-like langage with scripting capabilities


## Performances

On my 12600k, transpilation of a 100ko file takes less than 200ms, up to 2s for a 1Mo file. This should be more than sufficient for small projects: small file (<5ko) take a few ms compile, and loaded files are cached (okay, the cache is not yet implemented, but planned).

According some quick benchmark simulating standard use-cases, transpiled code executes at between 80% and 100% of Lua's performance. So with LuaJIT, this makes it possible to include relatively costly calculations in templates.

## Changelog
### 0.34 (last version)

### CLI
- Addition of a test suite for the CLI.
- New CLI option `-v --version`
- New CLI option `--install`
- New CLI option `--remove`
- New CLI option `--update`

[Older versions](doc/changelog.md)