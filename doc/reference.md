# Plume Technical Documentation

This document provides a technical specification of the Plume programming language. It assumes the reader has prior programming experience. For a guided introduction, you may prefer to start with the dedicated tutorial (WIP).

## Core Principles

### 1. Text and Statements

Plume is designed around a text-first principle. Any sequence of characters that is not identified as a language construct is treated as literal text. This means simple text requires no special quoting or escaping.

```plume
This is a valid Plume program.
```

To distinguish control flow and logic from text, Plume recognizes a set of **statements**. A line is treated as a statement if it begins (after any leading whitespace) with one of the following keywords:

*   `if`, `elseif`, `else`, `for`, `while`, `macro`, `end`
*   `let`, `set`
*   `-` (initiates a table item)
*   `key:` (initiates a named table item, where `key` is any valid identifier)
*   `...` (expand a table)
*   `@name` (initiates a block call)

Anywhere else, these keywords are rendered as plain text.

```plume
This is another valid Plume program:
if 1 + 1 == 2
    Your CPU is okay.
else
    Your CPU needs more love!
end
```

### 2. Evaluation Contexts

By default, Plume treats input as text. To perform computations and use logic, certain parts of the code are parsed within an **evaluation context**. This occurs in two places:

1.  Inside an evaluation block: `$(...)`
2.  Following a statement that requires an expression, such as `if ...`, `elseif ...`, `while ...`, and `for varlist in ...`.

Within an evaluation context:
*   Standard operators are available: `+`, `-`, `*`, `/`, `%`, `^`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `and`, `or`, `not`.
*   Variables can be accessed directly without the `$` prefix.
*   Macros can be called using standard syntax.

```plume
let x = 5
// y will be assigned the number 6, not the string "x+1"
let y = $(x + 1)

let myMacro = macro(wing, song)
    $(wing * song)
end

// The expression is evaluated before being assigned to z
let z = $(1 + myMacro(x, y))
```

### 3. Accumulation Blocks

Every executable block in Plume (the program itself, a macro body, or a block call) implicitly builds a return value in what is known as an **accumulation block**. The type of the block is determined by its content.

There are four types of accumulation blocks:

*   **`TEXT` Block:** Contains one or more expressions but **no** table items (`-` or `key:`). All expression results are converted to strings and concatenated.
    ```plume
    // The program returns the string "Hello,World!"
    Hello,
    World!
    ```
*   **`TABLE` Block:** Contains one or more table items. A line in a `TABLE` block must be one of the following:
    *   A list item, starting with `-`.
    *   A named item, starting with `key:`.
    *   A table expansion, starting with `...` (see *Syntax > Table Expansion and Unpacking*).

    Text or `$(...)` evaluations are not allowed at the same level as table items. The block returns a table.
    ```plume
    - First item
    - Second item
    id: 123
    // Returns {"First item", "Second item", "id": "123"}
    ```
*   **`VALUE` Block:** Contains **exactly one** expression. The block returns the value of this single expression *without any type conversion*. This is essential for preserving data types like tables or numbers.
    ```plume
    let myTable = @getData
        - wing
    end

    // This block returns the table itself, not a string representation of it.
    let sameTable = $myTable 
    ```
*   **`EMPTY` Block:** Contains no expressions. The block returns the `empty` constant.

## Syntax

### Comments

Comments start with `//` and extend to the end of the line.

```plume
// This is a comment.
let x = 1 // This is also a comment.
```

### Statements

All statements must start at the beginning of a line, though they may be preceded by whitespace.

Some statements that initiate a value assignment or a data structure (`let`, `set`, `-`, `key:`) can be **chained** on the same line with a statement that produces a value (`if`, `for`, `while`, `macro`, `@name`).

```plume
// Assigning the result of an @-call to a variable
let config = @loadConfig
    port: 8080
end

// Adding a conditional item to a table
- if quill.isAdmin
    Admin Panel
  end
```

#### `if`
Executes a block of code conditionally. Note that `elseif` and `else` must also start on new lines.

```plume
if evaluation
    ...
elseif evaluation
    ...
else
    ...
end
```

#### `for`
Iterates over the elements of an expression.

```plume
for varname in evaluation
    ...
end
```

#### `while`
Executes a block of code as long as a condition is true.

```plume
while evaluation
    ...
end
```

#### `macro` and Calls
Macros are the primary way to create reusable logic in Plume.

**Definition:**
```plume
macro name(positional, named: defaultValue, ?flag)
    ...
end

// The `?flag` syntax is sugar for:
// - `flag: $false` in a definition
// - `flag: $true` in a call
```
Macros are nearly pure: they cannot access variables from their parent scope, but they **can** access `static` variables defined at the file's root. The statement `macro name ...` is syntactic sugar for `let static name = macro ...`.

**Calls:**
Given the following macro:
```plume
macro buildTag(name, id, class: default, ?active)
    ...
end
```
The following call formats are available:

1.  **Standard Call:** Arguments are passed in a parenthesized list. This format supports positional arguments, named arguments, and table unpacking using the `...` operator (see *Syntax > Table Expansion and Unpacking*).
    ```plume
    $buildTag(div, mainContent, ...default)
    ```
2.  **Block Call (`@`)**: Arguments are passed as an accumulation block.
    ```plume
    @buildTag
        - div
        - main-content
        class: container
        active: $true
    end
    ```
3.  **Mixed Block Call**: Some arguments are passed positionally, and the rest are provided in the block.
    ```plume
    @buildTag(div, class: container)
        - main-content
        active: $true
    end
    ```

#### `let`
Declares a new variable in the **current scope**.
```
let [static] [const] name [= value]
```
*   `let name`: Declares `name` with a default value of `empty`.
*   `let const name = value`: Declares an immutable constant. An error is raised if no value is provided.
*   `let static name`: Declares a variable visible to all scopes in the file, including macros.
*   An error is raised if a variable with the same name already exists in the current scope.

#### `set`
Assigns a new value to an **existing** variable.
```
set name = value
```
*   `set` searches for `name` first in the current scope, then in parent scopes, and finally in the static scope.
*   An error is raised if the variable is not found or is declared as `const`.

### Table Expansion and Unpacking (`...`)

Plume provides a `...` operator to expand or unpack a table's contents into another structure. This is applicable in two contexts: table accumulation blocks and macro calls.

The expression following `...` must evaluate to a table. Attempting to expand any other data type (number, string, etc.) will result in an error.

#### In Table Accumulation Blocks

When used inside a `TABLE` accumulation block, the `...` operator inserts all items (list and named) from the specified table into the table being constructed.

The items are inserted at the position of the `...` statement. If there are key collisions, the principle of "last write wins" applies:

*   If a key is defined in the block *before* being expanded from another table, the value from the expanded table will overwrite it.
*   If a key from an expanded table is later redefined in the block, the final value will be the one defined last.

```plume
let defaults = @table
    host: localhost
    port: 8000
    - write
end

let config = @table
    port: 9090 // This will be overwritten by the value from 'defaults'
    ...defaults
    - paint
    host: "production.server" // This overwrites the value from 'defaults'
end

// The final 'config' table will be:
// { 9090, "write", "paint", host: "production.server", port: 8000 }
// Note: The integer-keyed items are ordered as they appear. The final port value is 8000
// because the conflicting definition (9090) appeared before the expansion.
// The final host value is "production.server" as it appeared after.
```

#### In Macro Calls

When used inside the argument list of a standard macro call, the `...` operator unpacks the items of a table into arguments.

*   **List items** (e.g., `- value`) are passed as positional arguments.
*   **Named items** (e.g., `key: value`) are passed as named arguments.

The items are unpacked in the order they were declared in the source table.

```plume
let myMacro = macro(write, paint, namedArg: "default", ?flag)
    // ...
end

let params = @table
    - quill
    flag: $true
end

// This call:
$myMacro(song, ...params, namedArg: override)

// Is equivalent to:
$myMacro(song, quill, ?flag, namedArg: override)
```

### Expressions and Value Access

*   **`$name`:** Evaluates the variable `name` and interpolates its value as text.
*   **`$(...)`:** Evaluates the code within the parentheses and returns the resulting value.
*   **Accessors:** A variable or code evaluation can be followed by accessors:
    *   **Call:** `$songMacro(write, paint)`
    *   **Index:** `$wingTable[0]`, `$wingTable[keyName]`
    *   **Member:** `$quillObject.property` (Syntactic sugar for `$quillObject["property"]`)

### Escaping

Any character can be escaped with a backslash (`\`) to be treated as a literal. Special escape sequences exist for whitespace:

*   `\n`: Newline
*   `\t`: Tab
*   `\s`: Space

### Whitespace Handling

The Plume parser ignores the following whitespace by default:

*   Leading spaces and tabs at the beginning of a line.
*   The newline character at the end of a line.
*   Spaces surrounding operators or argument separators (`,`) in an evaluation context.

To explicitly insert whitespace characters, use the escape sequences `\s`, `\t`, and `\n`.