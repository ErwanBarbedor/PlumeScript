<p align="center">
    <img src="plume_logo.svg" width="400" height="200">

<p align="center"><i>
    A language where your code <b>is</b> your document
</i></p>

![Version](https://img.shields.io/badge/version-0.50-blue.svg) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Introduction


Plume is a textual programming language for complex content generation, built on a paradigm of contextual accumulation to elegantly fuse templating with imperative logic. Its goal is to let you structure content and logic as one, removing boilerplate and improving clarity.

### Core Features 🛠️

*   **Expressive DSLs via Unified Syntax:** Any function (a *macro*) can be invoked inline (`$macro(...)`) or as a block (`@macro ... end`). This duality is the foundation for creating natural and readable Domain-Specific Languages.

*   **Context-Aware Logic:** Blocks accumulate content contextually. A `for` loop will naturally generate text lines inside a string-building macro, but will produce list items when nested inside a list-building macro.

*   **Strict Scoping:** Each block creates a new, isolated scope. Variables are local by default and macros do not capture their closure, ensuring predictable behavior and preventing side-effects. A mechanism for explicitly defining file-level state is available for shared constants or helpers.

*   **Flexible Tables & Metaprogramming:** A unified data structure for lists and key-value maps. Built on a powerful object model inspired by Lua, it supports metaprogramming to create dynamic and intelligent data structures.

*   **Lightweight & Optimized VM:** Implemented as a virtual machine in Lua, with core operations optimized for efficient string and list construction, beneficing from LuaJIT performances.

### The Plume Sweet Spot 🎯

Plume is designed for the specific niche that lies at the frontier of traditional programming and templating systems:

*   For projects dominated by complex algorithms, a general-purpose language is more suitable.
*   For projects that are primarily data-driven, a simple template engine is sufficient.
*   **Plume excels where logic and content are tightly interwoven.** It is ideal for when the logic requirements are too complex for a basic template engine, but where writing boilerplate code in a general-purpose language becomes tedious.

### Project Status

*   **Status: 🌱 Active Development.** This is a new implementation, but the language design is mature and previous versions were already being used in real-world projects. (e.g., generating course materials).

### Overview

```
// A comment

// Define a variable
let x = 35
let name = John Doe // No `"` neededs!

// Insert it in a text
Hello, my name is $name! // The program will return "Hello, my name is John Doe!"

// Do computation
let sinSum = 0
let i = 0
for i in seq(0, 1000)
    set sinSum += $(math.sin(i))
end

// Define reusable code chunck
macro double(x)
    Let's double $x!\n
    $x $x
end

//And use it!
$double(Foo)

// Even with a very complex `x`
@double
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n
    Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n

    pi is $math.pi!
end

// Note: Plume will conserve only spaces between consecutives words.
// To add spaces to output, use `\n`, `\s` and `\t`
// By the way, `\` permit to escape any character

In plume, `\$(1+1)` will give `$(1+1)` // Return: "In plume, `$(1+1)` will give `2` "

// macros support named paramters
macro complex(arg1, arg2, optn: defaultValue, ?flag) 
    // in definition, ?flag is a sugar for flag: $false
    ...
end

// And you can call it... Anyway you like!
$complex(foo, bar, optn: baz, ?flag) // in call, ?flag is a sugar for flag: $true

@complex(?flag)
    - bar
    - foo
    optn: baz
end

@complex(foo, optn: baz, ?flag)
    bar // content, if text, is send as last positionnal argument
end
```



### Quickstart