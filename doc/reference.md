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
*   `@name` (initiates a block call)

Anywhere else, these keywords are rendered as plain text.

```plume
This is another valid Plume program:
if 1 + 1 == 2
	Your CPU is okay.
else
	Your CPU need more love!
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
\\ y will be assigned the number 6, not the string "x+1"
let y = $(x + 1)

let myMacro = macro(a, b)
    $(a * b)
end

\\ The expression is evaluated before being assigned to z
let z = $(1 + myMacro(x, y))
```

### 3. Accumulation Blocks

Every executable block in Plume (the program itself, a macro body, or a block call) implicitly builds a return value in what is known as an **accumulation block**. The type of the block is determined by its content.

There are four types of accumulation blocks:

*   **`TEXT` Block:** Contains one or more expressions but **no** table items (`-` or `key:`). All expression results are converted to strings and concatenated.
    ```plume
    \\ The program returns the string "Hello,World!"
    Hello,
    World!
    ```
*   **`TABLE` Block:** Contains one or more table items (`-` or `key:`). Text or `$(...)` evaluations are not allowed at the same level. The block returns a table.
    ```plume
    - First item
    - Second item
    id: 123
    \\ Returns {"First item", "Second item", "id": "123"}
    ```
*   **`VALUE` Block:** Contains **exactly one** expression. The block returns the value of this single expression *without any type conversion*. This is essential for preserving data types like tables or numbers.
    ```plume
    let my_table = @get_data
        - Foo
    end

    \\ This block returns the table itself, not a string representation of it.
    let same_table = $my_table 
    ```
*   **`EMPTY` Block:** Contains no expressions. The block returns the `empty` constant.

## Syntax

### Comments

Comments start with `\\` and extend to the end of the line.

```plume
\\ This is a comment.
let x = 1 \\ This is also a comment.
```

### Statements

All statements must start at the beginning of a line, though they may be preceded by whitespace.

Some statements that initiate a value assignment or a data structure (`let`, `set`, `-`, `key:`) can be **chained** on the same line with a statement that produces a value (`if`, `for`, `while`, `macro`, `@name`).

```plume
\\ Assigning the result of an @-call to a variable
let config = @load_config
    port: 8080
end

\\ Adding a conditional item to a table
- if user.is_admin
    "Admin Panel"
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
Iterates over the elements of an expression. The `varlist` is a comma-separated list of identifiers.

```plume
for varlist in evaluation
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
macro name(positional1, named: default_value, ?flag)
	...
end

\\ The `?flag` syntax is sugar for:
\\ - `flag: $false` in a definition
\\ - `flag: $true` in a call
```
Macros are nearly pure: they cannot access variables from their parent scope, but they **can** access `static` variables defined at the file's root. The statement `macro name ...` is syntactic sugar for `let static name = macro ...`.

**Calls:**
Given the following macro:
```plume
macro build_tag(name, id, class: default, ?active)
	...
end
```
The following call formats are available:

1.  **Standard Call:** Arguments are passed in a parenthesized list.
    ```plume
    $build_tag("div", "main-content", class: "container", ?active)
    ```
2.  **Block Call (`@`)**: Arguments are passed as an accumulation block.
    ```plume
    @build_tag
        - div
        - main-content
        class: container
        active: $true
    end
    ```
3.  **Mixed Block Call**: Some arguments are passed positionally, and the rest are provided in the block.
    ```plume
    @build_tag(div, class: container)
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

### Expressions and Value Access

*   **`$name`:** Evaluates the variable `name` and interpolates its value as text.
*   **`$(...)`:** Evaluates the code within the parentheses and returns the resulting value.
*   **Accessors:** A variable or code evaluation can be followed by accessors:
    *   **Call:** `$my_macro(arg1, arg2)`
    *   **Index:** `$my_table[0]`, `$my_table[key_name]`
    *   **Member:** `$my_object.property` (Syntactic sugar for `$my_object["property"]`)

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