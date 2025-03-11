<p align="center"><img src="plume_logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.22-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


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

### Basics

``` Plume
// A comment

Hello World! // Simple text

name = John Doe // Variable assignment
Hello $name! // Variable interpolation

// Only "<identifier> = ..." will be seen as assignment
1 + 1 = ? // So this is raw text

1 + 1 = $(1+1) // Can insert the returned value of a computation
cos(0.5) = $(math.cos(0.5)) // Or any Lua expression

i = 100 // Plume sees that 100 is a number and not a string
while i>0 // Classic control structure without special syntax
    i = $(i-1)
    i is now $i.
// while, for, if, and elseif must be followed by a Lua expression

Hum, while you... // "while" isn't at the beginning of the line
// so it's seen as a simple word

// List
friends =
    - Bob
    - Clara
    - John
My best friend is $(friends[1]) // Yes, I know you love 1-based arrays

// Hash
costs =
    item_A: 50
    item_B: 120

The price of item_A is $costs.item_A

// Macro
def double(x)
    $x $x

$double(foo) // foo foo

```

### Advanced
```Plume
// Extended macro parameter: 3 ways to call ntimes
def ntimes(n, content)
    for i=1, n
        $content\n

$ntimes(4, A very long content)
$ntimes(4)
    A very long content
$ntimes()
    - 4
    - A very long content

// Lists and hashes are both Lua tables, so you can mix it
mixed =
    - item
    key: value

// "-" is not a static syntax element, but the statement "add this to the current table"
mul_table =
    local x = 3 // each indented block has its own scope
    for y=1, 10
        - $(x*y)

// Plume will ignore all newlines and will trim lines.
// So if you need spaces in the output, you can add them with:
\n // newline
\s // single space
\t // tabulation
```

### Escaping

*What do I have to do to ensure that “while” is understood as a simple word, and not a keyword?*

I haven't yet decided how to handle escaping.

Currently, `$("while")` and ` while` work, but that's not necessarily very satisfactory.

For the symbols `-`, `:`, and `=`, they can be escaped with `\`.


## Performance

On my 12600k, transpilation of a 10,000-line file takes less than 200ms; this should be more than sufficient for small projects.

Transpiled code executes at between 70% and 100% of Lua's performance. So with LuaJIT, this makes it possible to include relatively costly calculations in templates.

## Changelog
### 0.22
#### Changes
- `$a = 1+1` is a syntax sugar for `a = $(1+1)`
- `$return 1+1` is a syntax sugar for `return $(1+1)`

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