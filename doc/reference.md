# Plume Technical Documentation

This document provides a technical specification of the Plume programming language. It assumes the reader has prior programming experience. For a guided introduction, you may prefer to start with the dedicated tutorial (WIP).

## Core Principles

### 1. Text and Statements

Plume is designed around a text-first principle. Any sequence of characters that is not identified as a language construct is treated as literal text. This means simple text requires no special quoting or escaping.

```plume
This is a valid Plume program.
```

To distinguish control flow and logic from text, Plume recognizes a set of **statements**. A line is treated as a statement if it begins (after any leading whitespace) with one of the following keywords:

*   `if`, `elseif`, `else`, `for`, `while`, `macro`, `end`, `do`, `leave`, `break`, `continue`
*   `let`, `set`, `use`
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
Iterates over the elements of a collection. The loop variable can be a single identifier or a list of identifiers for positional unpacking.

```plume
for varname in evaluation
    ...
end

// Positional unpacking
for index, item in enumerationTable
    ...
end
```

If multiple variables are provided (e.g., `for x, y in list`), Plume expects each item in the evaluated expression to be a table (or list). The items of that sub-table are unpacked positionally into the defined variables.
*   Extra items in the sub-table are ignored.
*   An error is raised if the sub-table has fewer items than the number of declared variables.

#### `while`
Executes a block of code as long as a condition is true.

```plume
while evaluation
    ...
end
```

#### `break` and `continue`
The `break` and `continue` statements provide fine-grained control over the execution of `for` and `while` loops. They only affect the innermost loop in which they are placed.

*   **`break`**
    The `break` statement immediately terminates the execution of the innermost `for` or `while` loop. Program execution resumes at the statement following the loop's `end`.

    ```plume
    // Search for a specific user ID
    let foundUser = for user in userList
        if user.id == targetId
            $user
            // User found, no need to continue looping
            break
        end
    end
    ```

*   **`continue`**
    The `continue` statement immediately stops the current iteration of the loop and proceeds to the next one.
    *   In a `for` loop, it advances to the next element in the sequence.
    *   In a `while` loop, it jumps back to the condition evaluation.

    ```plume
    // Process only positive numbers
    for number in dataSet
        if number <= 0
            // Skip this item and move to the next
            continue
        end
        do $process(number)
    end
    ```

Both `break` and `continue` must appear on their own lines. Using either statement outside of a `for` or `while` loop will result in an error.

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
Declares new variables in the **current scope**.

```plume
// 1. Multiple Declaration
let [static] [const] name1, name2, ...

// 2. Positional Destructuring
let [static] [const] name1, name2, ... = expression

// 3. Named Destructuring (from)
let [static] [const] key1, sourceKey as alias, key: default, ... from expression

// 4. Parameter Declaration
let param name [= value]
```

**1. Multiple Declaration**
Declares one or more variables without assigning values immediately. They are initialized to `empty`.
```plume
let x, y, z
// x, y, and z are defined and set to empty
```

**2. Positional Destructuring (`=`)**
Assigns values based on the result of an expression.
*   If a **single variable** is declared, it receives the result of the expression directly.
*   If **multiple variables** are declared, the expression must evaluate to a `TABLE`. Plume unpacks the list items of the table into the variables in order.
    *   **Error:** An error is raised if the table contains fewer items than the number of variables.
    *   **Excess:** If the table contains more items than variables, the excess items are ignored.

```plume
let coord = $table(10, 20, 30)

// 'z' is ignored here
let x, y = $coord 

// Error: 'coord' only has 3 items, but 4 variables are requested
let a, b, c, d = $coord
```

**3. Named Destructuring (`from`)**
Extracts values from a table based on specific keys. The `from` keyword must be followed by an expression that evaluates to a table. This syntax supports **renaming** and **default values**, promoting a robust, structured approach to data extraction.

The general pattern for an item is: `SourceKey [as AliasVariable] [: DefaultValue]`.

*   **`name`**: Tries to retrieve `$table["name"]`. If missing, `name` is set to `empty`.
*   **`name: default`**: Tries to retrieve `$table["name"]`. If missing or `empty`, assigns `default` to variable `name`. **Note:** If the `default` value contains spaces, it must be enclosed in parentheses, e.g., `name: (Default Value)`.
*   **`key as alias`**: Tries to retrieve `$table["key"]` and assigns it to variable `alias`.
*   **`key as alias: default`**: The ultimate combo. Retrieves `$table["key"]`. If missing, uses `default`. The result is stored in variable `alias`.

```plume
// Assume user = { id: 450, role: "admin" } (name is missing)
let user = $getUser()

// 1. Simple extraction
// let id = $user.id
let id from $user

// 2. Renaming
// Extracts 'role', but names the variable 'group'
let role as group from $user

// 3. Default values
// 'name' is missing in the table, so it takes the default value "Anonymous"
let name: Anonymous from $user

// 4. If the default value contains spaces, parentheses are required
let status: (Not Available) from $user

// 5. Combined (Renaming + Default)
// Tries to get 'avatar', rename it to 'icon', doubles back to "default.png" if missing
let avatar as icon: default.png from $user

// All in one line:
let id, role as group, name: Anonymous from $user
```

**4. Parameters declaration**
Variables can be declared as module parameters using the `param` keyword. A `param` variable is automatically `static` and `const`.

```plume
let param varname [= defaultValue]
```
These variables are intended to be populated by the caller during an `import`. If no value is provided during the import and no `defaultValue` is specified, the variable defaults to `empty`.


**Common Rules:**
*   **Modifiers:** `static` and `const` apply to all variables declared in the statement.
*   **Validation:** An error is raised if a variable with the same name already exists in the current scope, or if a `const` variable is declared without a value (in the standard declaration form).

#### `set`
Assigns new values to **existing** variables. `set` searches for each variable first in the current scope, then in parent scopes, and finally in the static scope.

```plume
// 1. Single Assignment
set name = value

// 2. Positional Destructuring
set name1, name2, ... = expression

// 3. Named Destructuring (from)
set key1, sourceKey as alias, key: default, ... from expression
```

**General Rules:**
For all forms of `set`, an error is raised if any specified target variable:
*   Cannot be found in any active scope.
*   Was declared as `const`.

**1. Single Assignment / Positional Destructuring (`=`)**
Updates variables based on the result of an expression.
*   If a **single variable** is specified (`set x = 1`), it takes the value directly.
*   If **multiple variables** are specified (`set x, y = $coords`), the expression must evaluate to a `TABLE`. Values are unpacked data positionally.
    *   **Error:** An error is raised if the table contains fewer items than the number of variables to update.
    *   **Excess:** If the table contains more items, the extras are ignored.

```plume
// Assume x and y exist
set x, y = $(10, 20)
```

**2. Named Destructuring (`from`)**
Updates variables by extracting values from a table using specific keys. The syntax matches `let`, allowing usage of `as` for renaming source keys to target variables, and `:` for default values if the source key is missing.

```plume
// Assume 'host' exists, and 'port' is a variable used for the connection
let config = @table
    host: 127.0.0.1
    // 'p' is defined in config, but not 'port'
    p: 8080
end

// We assume 'host', 'port' and 'protocol' are already declared variables.

// - Update 'host' with config["host"]
// - Update variable 'port' with config["p"] (Renaming)
// - If config["protocol"] is missing, use "http" (Default value)
set host, p as port, protocol: http from config
```

### Table Expansion and Unpacking (`...`)

Plume provides a `...` operator to expand or unpack a table's contents into another structure. This is applicable in two contexts: table accumulation blocks and macro calls.

The expression following `...` must evaluate to a table. Attempting to expand any other data type (number, string, etc.) will result in an error.

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

### Context Injection (`use`)

The `use` directive allows injecting the keys of a table returned by a module directly into the current file’s scope as `static const` variables.

**Syntax:**
```plume
use path
```

**Implementation Details:**
*   **Compilation-time Directive:** `use` is a compiler directive, not a function. It is executed during the compilation phase to resolve symbols. Consequently, `path` must be a literal string; it **cannot** be a dynamic expression evaluated at runtime.
*   **Namespace Impact:** Because `use` injects all keys from the target module into the local namespace, it can lead to "namespace pollution." It should be used sparingly.
*   **Scope:** All keys from the table returned by the file at `path` are made available in the current file as if they were declared locally.

```plume
// math.plume
pi: 3.14

// main.plume
use math
// pi is now directly accessible
The value is $pi
```
### Choosing Between `import` and `use`

While both mechanisms allow code reuse, they serve different purposes:

| Feature | `import` | `use` |
| :--- | :--- | :--- |
| **Execution** | Runtime | Compilation time |
| **Flexibility** | High (dynamic paths, parameters) | Low (literal paths only) |
| **Namespace** | Clean (returns a value) | Polluted (injects all keys) |
| **Type** | Macro | Compiler Directive |

**When to use `import` (Recommended):**
This should be your default reflex. It is safer, supports parameters, and allows you to control exactly how the imported data is accessed (e.g., `let math = $import(math)`).

**When to use `use`:**
Only use this when you need to import a large number of symbols that are central to the current file's logic, and where prefixing every call would be detrimental to readability. A typical use case is a **Domain Specific Language (DSL)**, such as a module providing all HTML tags as macros:

```plume
// This avoids writing $tags.div, $tags.span, etc.
use html

@div
    style: @table
        background: red
    end

    - $span(Hello World)
end
```

### Escaping

Any character can be escaped with a backslash (`\`) to be treated as a literal. Special escape sequences exist for whitespace:

*   `\n`: Newline
*   `\t`: Tab
*   `\s`: Space

### Whitespace Handling

The Plume parser ignores the following whitespace by default:

*   Leading spaces and tabs at the beginning of a line.
*   Spaces and the newline character at the end of a line.
*   Spaces surrounding operators or argument separators (`,`) in an evaluation context.

To explicitly insert whitespace characters, use the escape sequences `\s`, `\t`, and `\n`.

## Standard Library

Plume provides a set of built-in macros to handle common tasks such as I/O, table manipulation, and iteration.

### Basic Functions

*   `print(...items)`: A wrapper for the underlying lua `print` function.
*   `type(x)`: Returns the type of `x` as a string: `"empty"`, `"table"`, `"number"`, or `"string"`.
*   `tostring(x)`: Converts the value `x` to its string representation.
*   `len(table)`: Returns the number of items in a table.

### Table Manipulation

*   `table(...items)`: Explicitly creates and returns a table containing the provided items.
*   `append(table, item)`: Adds `item` to the end of the specified `table`.
*   `remove(table)`: Removes and returns the last item from the `table`.
*   `join(sep: "", ...items)`: Returns a string produced by concatenating `items`, optionally separated by `sep`.

### Iterators

*   `seq(start, stop)` or `seq(stop)`: Returns an inclusive iterator from `start` to `stop`. If only one argument is provided, `start` defaults to `1`.
*   `enumerate(table)`: Returns an iterator yielding pairs of `(index, value)` for each list item in the table.
*   `items(table)`: Returns an iterator yielding `(key, value)` pairs for all non-numeric entries in the table.

### Module System and Imports

#### `import(path, ...params)`
The `import` function is the **default mechanism** for modularity in Plume. It executes a Plume file at runtime and returns its final accumulated value. 

**Key Features:**
*   **Runtime Evaluation:** Unlike `use`, `import` is called during execution. This means the `path` can be a dynamic expression (e.g., `$import(./configs/$(env).plume)`).
*   **Parameter Passing:** It allows passing values to variables declared with `let param` in the target file.
*   **Encapsulation:** The returned value (usually a table) is contained within the variable it is assigned to, keeping the local namespace clean.

**Path Resolution Logic:**
The `import` statement follows a specific lookup order to locate files:
1.  **Relative Search:** If `path` starts with `./` or `../`, Plume searches for the file relative to the directory of the currently executing file.
2.  **Breadth Search:** Otherwise, it searches from the root file's directory and then through the directories listed in `plume_path`.
3.  **File Patterns:** For any given directory, Plume looks for `[path].plume` and `[path]/init.plume`

**Environment and Path Management:**
*   The initial `plume_path` is populated from the `PLUME_PATH` environment variable (paths are separated by commas).
*   `setPlumePath(path)`: Replaces the current `plume_path` with a new value.
*   `addToPlumePath(path)`: Appends a new directory to the existing `plume_path`.

### File System I/O

Unlike `import`, the following functions do not use the `plume_path` resolution logic and expect direct file system paths.

*   `read(path)`: Reads the content of the file at `path` and returns it as a string.
*   `write(path, ...items)`: Writes the concatenated string representation of `items` to the file at `path`.

### Lua Integration

Plume provides a `lua` static variable that acts as a bridge to the underlying Lua environment. This variable contains wrappers for essential Lua functions and libraries, allowing for advanced operations not covered by the Plume standard library.

The `lua` table includes:
*   **Module Loading**: `lua.require(path)` (used to load Lua modules, use same Path resolution as `import`).
*   **System functions**: `lua.error`, `lua.assert`.
*   **Libraries**:
    *   `lua.string.*` (string manipulation)
    *   `lua.math.*` (mathematical constants and functions)
    *   `lua.os.*` (operating system facilities)
    *   `lua.io.*` (input and output)

**Important Note on Type Stability:**
The automatic type conversion between Plume and Lua is currently considered **unstable**. This applies particularly to:
*   **Tables**: Mapping between Plume tables and Lua tables.
*   **Functionality**: Mapping between Plume macros and Lua functions.

As a result, some features or data transfers may be entirely non-functional or unusable in the current version.