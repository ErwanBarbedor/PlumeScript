<p align="center"><img src="plume_logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.42-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


## Plume🪶 - An Expressive Templating Language

- ✨ **Lightweight Syntax:** Minimal special characters and indentation-based structure make Plume easy to write and read.
- 📖 **Expressive and Readable:** Inspired by YAML for lists and hashes, and common programming languages for the rest, Plume offers a clear and concise syntax.
- ⚙️ **Versatile and Extensible:** While well-suited for rich text generation with macros, Plume allows you to achieve virtually anything possible with a general-purpose programming language, with almost no special syntax. This makes it highly adaptable to various use cases.

Test it now [in your browser](https://app.barbedor.bzh/plume.html)! *older version waiting for update*


## Installation

Unzip archive corresponding to your OS in a PATH location (for exemple, `/usr/bin` on Linux).

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
    plume --update
        BROKEN FOR NOW. Download new plume version from github
    plume --remove-cache
        Delete all cached file
    plume --no-cache
        Dont read nor write caching informations
    
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

On my 12600k, transpilation of a 100ko file takes less than 200ms, up to 2s for a 1Mo file. This should be more than sufficient for small projects: small file (<5ko) take a few ms compile, and loaded files are cached.

According some quick benchmark simulating standard use-cases, transpiled code executes at between 80% and 100% of Lua's performance. So with LuaJIT, this makes it possible to include relatively costly calculations in templates.

## Changelog
### 0.42 (last version)

#### Changes
- New builtin function `table`. _Used to declare empty tables, declaring inline tables or merge tables._
- New builtin function `len`. _Replace the lua `#`_
- Can now iterate directly on table: `for x in t`
- Replace `ipairs` by `enumerate`.
- Remove `pairs`, partially replaced by `items`. Iteration order is deterministic. *Unlike `pairs`, `items` does not iterate over numeric keys.*
- If an element is the only one in its text block, it is converted to a string instead of being returned as is.

#### Internal Changes
- Rewrite transpiler from scratch. _The new structure is more verbose, less optimized for specific cases, but also simplier and closer to the structure of Plume code and should therefore be easier to maintain. Enhance mapping too._

[Older versions](doc/changelog.md)