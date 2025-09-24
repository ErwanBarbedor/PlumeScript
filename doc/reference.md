# Plume Technical Documentation

This document provides a technical specification of the Plume programming language. It assumes the reader has prior programming experience. For a guided introduction, you may prefer to start with the dedicated tutorial (WIP).

## Core Principles

### 1. Text and Statements

Plume is designed around a text-first principle. Any sequence of characters that is not identified as a language construct is treated as literal text. This means simple text requires no special quoting or escaping.

```plume
This is a valid Plume program.
```

To distinguish control flow and logic from text, Plume recognizes a set of **statements**. A line is treated as a statement if it begins (after any leading whitespace) with one of the following keywords:

*   `if`, `elseif`, `else`, `for`, `while`, `macro`, `end`, `do`, `leave`
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

Every executable block in Plume (the program itself, a macro body, or a block call) implicitly builds a return value in what is known as an **accumulation block**. The type of the block is determined by its content. The `leave` statement can be used to exit the block prematurely, returning the value that has been accumulated at that point.


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
Macros are the primary way to create reusable logic in Plume. A macro is a block of code that accepts arguments and produces a return value. By default, a macro returns the final value of its implicit accumulation block. However, execution can be terminated at any point using the `leave` statement, which causes the macro to return the value accumulated up to that moment.

**Definition:**
```plume
macro name(positional, named: defaultValue, ?flag, ...variadicArgs)
    ...
end
```
A macro signature can include positional parameters, named parameters with default values, boolean flags, and a final variadic parameter.

*   `positional`: An argument must be provided positionally.
*   `named: defaultValue`: A named argument. If not provided in the call, it takes its default value.
*   `?flag`: Syntactic sugar for a boolean flag. It is equivalent to defining `flag: $false` and allows the call to use the shorthand `?flag` instead of `flag: $true`.
*   `...variadicArgs`: A variadic parameter, which must be the last parameter in the signature. It captures all arguments passed to the macro that were not assigned to another parameter. These leftover arguments are collected into a single `TABLE` variable.
    *   Positional arguments are added as list items (e.g., `- "value"`).
    *   Named arguments are added as named items (e.g., `key: "value"`).
    *   The order of items in the table respects the order in which they were provided in the call.

Macros are nearly pure: they cannot access variables from their parent scope, but they can access `static` variables defined at the file's root. The statement `macro name ...` is syntactic sugar for `let static name = macro ...`.

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
#### `leave`
Exits the current execution block (macro or file) and immediately returns the value accumulated up to that point. It provides a mechanism for an early return, similar to a `return` statement in other languages.

```plume
leave
```

The `leave` statement must appear on its own line. When executed, it stops all further processing within its block. If `leave` is executed inside a nested structure like a `for` or `while` loop, it terminates the entire macro or file, not just the loop.

The type of the returned value depends on the accumulation block's context at the time `leave` is called:
*   If the block has already been identified as a `TABLE` block (i.e., it contains at least one table item like `-` or `key:`), `leave` will return the table accumulated so far. If no items have been accumulated, it returns an empty table.
*   Otherwise, it returns accumulated text (or the `empty` constant).

```plume
macro generateList(source, limit: 100)
    let i = 0
    - for item in source
        - if i >= limit
            // Return the partially built list if limit is reached
            leave
        end
        - $processItem(item)
        set i = $(i + 1)
    end
    // This item is only added if the loop completes without 'leave' being called.
    status: Completed
end
```

#### `let`
Declares a new variable in the **current scope**.

```
let [static] [const] name [= value]
let [static] [const] name1, name2, ... from expression
```

*   **`let name`**: Declares `name` with a default value of `empty`.
*   **`let const name = value`**: Declares an immutable constant. An error is raised if no value is provided.
*   **`let static name`**: Declares a variable visible to all scopes in the file, including macros.
*   An error is raised if a variable with the same name already exists in the current scope.

The `let` statement also supports a destructuring form to declare multiple variables from the keys of a table.
*   The `from` keyword must be followed by an expression that evaluates to a table. Attempting to destructure any other data type will result in an error.
*   For each name in the comma-separated list, Plume declares a new variable in the current scope and assigns it the value of the corresponding key from the source table.
*   The `static` and `const` modifiers, when used, apply to all variables declared in the statement.
*   An error is raised if any of the specified keys do not exist in the source table or if any of the new variable names already exist in the current scope.

```plume
// Assume 'configTable' is a table: { host: "localhost", port: 8080 }
let host, port from configTable

// The line above is equivalent to:
// let host = $configTable.host
// let port = $configTable.port

// Using with 'const' to declare multiple immutable variables
let const adminUser, adminId from getAdminData()
```
#### `set`
Assigns a new value to an **existing** variable.
```
set name = value
```
*   `set` searches for `name` first in the current scope, then in parent scopes, and finally in the static scope.
*   An error is raised if the variable is not found or is declared as `const`.

### Table Expansion and Unpacking (`...`)

The `...` operator serves three distinct purposes depending on its context: expanding a table's contents into another table, unpacking a table's contents into macro arguments, or defining a variadic parameter in a macro signature.

The expression following `...` in an expansion or unpacking context must evaluate to a table. Attempting to use any other data type will result in an error.

#### In Table Accumulation Blocks (Expansion)

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
    port: 9090
    ...defaults
    - paint
    host: production.server
end

// The final 'config' table will be:
// { "write", "paint", host: "production.server", port: 8000 }
```

#### In Macro Calls (Unpacking)

When used inside the argument list of a standard macro call, the `...` operator unpacks the items of a table into arguments for the call.

*   **List items** (e.g., `- value`) are passed as positional arguments.
*   **Named items** (e.g., `key: value`) are passed as named arguments.

The items are unpacked in the order they were declared in the source table. If an unpacked argument does not match any parameter in the target macro's signature, it will be captured by the macro's variadic parameter, if one is defined.

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

#### In Macro Definitions (Variadic Parameters)

When used as the final parameter in a macro definition, the `...` operator creates a **variadic parameter**. This syntax does not unpack a value but instead instructs the macro to collect all unassigned arguments from a call into a single `TABLE`. A macro definition cannot contain more than one variadic parameter.

```plume
// Defines a variadic macro that accepts any number of trailing arguments
macro wing (write, paint, song: bird, ...ink)
    for quill in ink
        // 'ink' is a table containing all unused arguments
    end
end
```
For a complete explanation, see `Syntax > macro and Calls`.


### Expressions and Value Access

*   **`$name`:** Evaluates the variable `name` and interpolates its value as text.
*   **`$(...)`:** Evaluates the code within the parentheses and returns the resulting value.
*   **Accessors:** A variable or code evaluation can be followed by accessors:
    *   **Call:** `$songMacro(write, paint)`
    *   **Index:** `$wingTable[0]`, `$wingTable[keyName]`
    *   **Member:** `$quillObject.property` (Syntactic sugar for `$quillObject["property"]`)

### Calls for Side-Effects (`do`)

By default, every expression in Plume, including macro calls, contributes its return value to the current accumulation block. This can be undesirable for macros that are executed solely for their side-effects (e.g., printing to the console, writing to a file).

To execute a macro call without its return value affecting the accumulation context, prefix the call with the `do` keyword. The `do` statement ensures the macro is executed, but its return value is discarded.

```plume
let myTable = @defineTable
    // $print returns 'empty', but 'do' prevents it from converting
    // this block into a TEXT block.
    do $print(Initializing table definition...)

    // This remains a valid TABLE block
    id: 42
    name: Plume
end
```

The `do` statement can be used with both standard and block calls:

```plume
// Standard call
do $myMacro(arg1)

// Block call
do @myMacro
    - arg1
    - arg2
end
```

Using `do` allows for imperative-style procedure calls within Plume's expression-oriented architecture, providing a clear and safe way to manage side-effects.

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