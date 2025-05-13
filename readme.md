<p align="center"><img src="plume_logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.32-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


## Plume🪶 - An Expressive Templating Language

- ✨ **Lightweight Syntax:** Minimal special characters and indentation-based structure make Plume easy to write and read.
- 📖 **Expressive and Readable:** Inspired by YAML for lists and hashes, and common programming languages for the rest, Plume offers a clear and concise syntax.
- ⚙️ **Versatile and Extensible:** While well-suited for rich text generation with macros, Plume allows you to achieve virtually anything possible with a general-purpose programming language, with almost no special syntax. This makes it highly adaptable to various use cases.
- 🔗 **Lua Integration:** Written in and transpiling to Lua, seamlessly integrate Plume into your existing Lua projects (5.1 and LuaJIT). Also, easily benefit from the decent performance of LuaJIT.

Test it now [in your browser](https://app.barbedor.bzh/plume.html)!

**Warning:** currently only compatible with `luajit`. Compatibility with `5.2+`  under consideration.

## Quick Start
Download `plume-engine` folder. Then, in a Lua file:

``` lua
local plume = require("plume-engine/init")

print(plume.run [[
a = 5
a is $(a)
]])

```

## Overview

*(the best way to get a feel for Plume is to follow the tutorials available on the link given above)*

Thinks of Plume as a Yaml-like langage with scripting capabilities


## Performances

On my 12600k, transpilation of a 100ko file takes less than 200ms, up to 2s for a 1Mo file. This should be more than sufficient for small projects: small file (<5ko) take a few ms compile, and loaded files are cached (okay, the cache is not yet implemented, but planned).

According some quick benchmark simulating standard use-cases, transpiled code executes at between 80% and 100% of Lua's performance. So with LuaJIT, this makes it possible to include relatively costly calculations in templates.

## Changelog
### 0.32 (last version)

#### Changes
- Can now expand result of chained access (e.g. `*a.foo[1].bar`)
- Can now expand result of a call (e.g. `*foo()` instead of `local temp = $foo() ... *temp`)

#### Internal changes
- For readability, use utils functions instead of inline functions in transpiled code.

[Older versions](doc/changelog.md)