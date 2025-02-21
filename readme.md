<p align="center"><img src="logo.svg" width="600" height="300"></p>

![Version](https://img.shields.io/badge/version-0.20-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# Plume🪶 - A Minimalist Templating Language

Plume is a lightweight and expressive templating language that transpiles to Lua. It's designed for clear syntax and seamless Lua integration, making it ideal for generating text-based output, such as HTML, configuration files, or documents. Plume leverages indentation for structure and minimizes special characters, resulting in clean and readable templates.


## Introduction

Plume offers several key advantages:

* **Minimalist Syntax:** Reduces boilerplate and visual clutter for improved readability. Indentation defines code blocks, eliminating the need for braces or other delimiters.
* **Seamless Lua Integration:** Leverages the power and flexibility of Lua directly within templates.
* **Clear and Concise:** Designed for clarity and ease of use, making template creation and maintenance straightforward.

## Quick Start


## Syntax and Features

### Text Output

By default, text written in a Plume file is treated as raw text and will be output directly.

Comments are delimited with `//`.

```plume
// A comment
Hello World
```
Output `Hello World`

### Indentation

All sucessives lines with the same indentation level as teated as a `block`. Almost* all block have it's own scope and return value. (see [Return values](#blocks-with-return-values))

\* Except control structures block, see [Control Structures](#Control-Structures).

### Variables

```plume
a = Foo
local b =
    Foo
    Bar
    Baz
```

### Whitespace

Except for spaces between expressions, Plume does not preserve whitespace.

To add whitespace in the output, use `\n` for a newline, `\t` for a tab, and `\s` for a single space.

### Interpolation

The `$` symbol is used for interpolating Lua values. `$(Lua expression)` evaluates the expression and returns the result. `$name` is a shortcut for `$(name)`.

```plume
a = $(1+2)
The value of a is $a //-> The value of a is 3
```

### Macros

Macros are defined using `def macro_name(parameters)`. The indented block following the definition forms the macro's body. Use `$macro_name(...)` to call it.

```plume
def double(x)
    $x $x

$double(Hello) //-> Hello Hello
```

### Multiline Macro Arguments

Indentation allows function arguments to be written on multiple lines, enhancing readability.

```plume
def double(x)
    $x $x

$double()
    Foo
```

```plume
def concat(x, y)
    $x$y

$concat()
    - First argument
    - Second argument
```

### Control Structures

Plume uses the keywords `if`, `elseif`, `else`, `for`, `while`, and `break`. Except for `else` and `break`, these keywords must be followed by a Lua expression.

```plume
for i=1, 10
    This line will be repeated 10 times

if 1+1 == 2
    The computer is good at math
else
    The computer is bad at math
```

### Blocks with Return Values

Each indented block has a return value of `NIL`, `TEXT`, `TABLE`, or `VALUE`. The return type is implicitly determined by the block's content.

```plume
text_variable =
    Hello
    a = 5 // you can write any statement inside the block
    World

table_variable =
    for i=1, 10
        - item $i // for, while, if, and elseif blocks do not have a return value;
                  // they add content to the parent block
    - A last item
    key: value

value_variable =
    local i = 5
    return $(i*2)
```

## Performance

On my i5 12600k, transpilation of a 10,000-line file takes less than 200ms.

Transpiled code executes at between 70% and 100% of Lua's performance.