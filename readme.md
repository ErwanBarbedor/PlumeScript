<p align="center"><img src="plume_logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.26-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


## Plume🪶 - An Expressive Templating Language

- ✨ **Lightweight Syntax:** Minimal special characters and indentation-based structure make Plume easy to write and read.
- 📖 **Expressive and Readable:** Inspired by YAML for lists and hashes, and common programming languages for the rest, Plume offers a clear and concise syntax.
- ⚙️ **Versatile and Extensible:** While well-suited for rich text generation with macros, Plume allows you to achieve virtually anything possible with a general-purpose programming language, with almost no special syntax. This makes it highly adaptable to various use cases.
- 🔗 **Lua Integration:** Written in and transpiling to Lua, seamlessly integrate Plume into your existing Lua projects (5.x and LuaJIT). Also, easily benefit from the decent performance of LuaJIT.

Test it now [in your browser](https://app.barbedor.bzh/plume.html)!

## Quick Start
Download `plume-engine` folder. Then, in a Lua file:

``` lua
-- Lua 5.1, 5.2 & LuaJIT
local plume = require("plume-engine/init")
-- Lua 5.3 & 5.4
local plume = require("plume-engine")

print(plume.run [[
a = 5
a is $(a)
]])

```

## Overview

*(the best way to get a feel for Plume is to follow the tutorials available on the link given above)*

Thinks of Plume as a Yaml-like langage with scripting capabilities


## Performance

On my 12600k, transpilation of a 10,000-line file takes less than 200ms; this should be more than sufficient for small projects.

Transpiled code executes at between 70% and 100% of Lua's performance. So with LuaJIT, this makes it possible to include relatively costly calculations in templates.

## Changelog
### 0.26

#### Changes
- Function `require` can load `plume` and `lua` files. Custom behavior, dont relly on lua `package`.
- Implement an error traceback.
- Error behavior rewritten to take multiple files into account.
- `macro foo()` will be transpiled to `function foo()`, not `foo = function ()`

### 0.25

#### Changes
- Remove `$a = ...` and `$a: ...`  syntax sugar
- `return` evaluate expression by default.
- Cannot anymore implicitly convert `tables` if they do not have a `__tostring` field.
- Implement the standard syntax `$a[i]/a[i] = ...` to read/write the `ith` element of the table `a`.
- Improved operation of luaTranspiler and major rewrite, removal of beautifier.lua.
- Dynamic affectation: if `a = foo`, then `$a = bar` affect `bar` to the (global) variable `foo`. Work also for hash and with expression (ex: `$("foo" .. i): bar`)

#### Bugfix
- Fixed: in certain case, item for concat will not be converted to strings
- Fixed: line not trimmed if ends with a comment
- Fixed: cannot use vararg in inline macro

### 0.24

#### Changes
- New operator "expand". Can also be used in macro call parameters.
- Call `tostring` on all items before concat.

#### Enhancement
- Rewrite vararg related code in a cleaner way

#### Bugfix
- Fix a case when wacro parameter arn't local to the macro
- Fix an error in error handling

### 0.23

#### Changes
- Use one vararg syntax `macro foo(*args)` for both positionnal and named args.
- `$a: 1+1` is a syntax sugar for `a: $(1+1)`

#### Enhancement
- New error message: invalid lua name as parameter name using text token
- New error message: check if vararg is in last position
- New error message: Code after a `return` statement

#### Bugfix
- Restore varargs
- Restore macro call (in a temp dirty way)

### 0.22
#### Changes
- `$a = 1+1` is a syntax sugar for `a = $(1+1)`
- `$return 1+1` is a syntax sugar for `return $(1+1)`
- Add compound assignment operator
- Remove number interpolation. Must now use `$a = 1` or `a = $1` to declare a number-variable.
- Rewrite macro call: all argument will be stored in a table before call (minor -1% performance lose).
- The lines are now trimmed

#### Enhancement
- New error message: invalid lua name as variable, parameter name or macro call

#### Regression
- Varargs and method calls are temporarily broken off
- Unmactched parenthesis in lua code (with string, for exemple) will cause errors.

#### Bugfix
- Fix an error occuring when add nil value to block output
- Fix an inconsistency concerning spaces before parenthesis in a macro call.

### 0.21
#### Changes
- Implement variable parameters syntax (python-like)
```
def foo(*args, **kwargs)
    ...
```
- `def` keyword replaced by `macro`
- Can call "class method" in lua way (`foo:bar()`)

#### Enhancement
- Enhance macro call transpilation in case without named parameter
- New error message: unclosed argument list

#### Bugfix
- Fix an error occuring when writting comma inside macro body
- Fix an error occuring when sending an empty argument to a macro

### 0.20 (Initial Commit)
Project restarted from scratch.