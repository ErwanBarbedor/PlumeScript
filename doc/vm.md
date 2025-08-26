## Plume Virtual Machine Architecture

This document outlines the technical architecture of the Plume VM. It is a concise reference intended for developers familiar with compiler and virtual machine concepts.

### 1. Core Architecture: Dual-Stack Design

The Plume VM is a stack-based machine that operates on a unified bytecode stream. Its key architectural feature is the use of two distinct primary stacks:

*   **Value Stack (`ms`):** A conventional work stack. Operands are pushed here for calculations, and values are assembled by *Accumulation Blocks*.
*   **Variable Stack (`vs`):** A separate stack dedicated to storing local variables, managing lexical scope.

This separation is a core design choice that decouples value accumulation from lexical scoping. In Plume, a `while` loop creates a scope but is not an accumulation block; this design allows `LEAVE_SCOPE` to clean up the variable stack without altering the current state of a pending accumulation on the value stack.

### 2. Scope and Memory Management

#### Lexical Scopes
Scopes are managed on the variable stack via two opcodes:

*   `ENTER_SCOPE 0 X`: Saves the current variable stack pointer and reserves `X` new slots on it, initialized to `empty`.
*   `LEAVE_SCOPE`: Restores the variable stack pointer to its state before `ENTER_SCOPE`, effectively discarding all local variables for the current scope.

```bytecode
-- A `while` loop illustrates scope management without value accumulation.
:loop_start
    -- ... bytecode for condition evaluation ...
    JUMP_IF_NOT :loop_end
    ENTER_SCOPE 0 1  -- New scope for the loop body.
    -- ... loop body bytecode ...
    LEAVE_SCOPE      -- Discard loop scope.
    JUMP :loop_start
:loop_end
```

#### Static Memory
File-level static variables are handled via a dedicated memory region for each file.

*   `ENTER_FILE` / `LEAVE_FILE`: These opcodes update a global pointer to the correct static memory region. They are emitted at the entry and exit points of macros to ensure `LOAD_STATIC` and `STORE_STATIC` reference the correct file context.

### 3. The Accumulation Mechanism

The "Accumulation Block" is Plume's core evaluation model, implemented on the value stack.

1.  **Initiation:** A new block is initiated with `BEGIN_ACC`, which pushes the current value stack pointer to a frame stack (`msf`), marking the block's boundary.

2.  **Execution & Finalization:**
    *   **`TEXT` Block:** Expressions are evaluated and their results are pushed onto the value stack. `ACC_TEXT` is then called to pop all values down to the frame marker, concatenate them into a single string, and push the final result.
        ```bytecode
        -- For a block like `Hello, $name!`
        BEGIN_ACC
        LOAD_CONSTANT "Hello, " -- Pushes string onto value stack.
        LOAD_LOCAL name         -- Pushes variable's value onto value stack.
        ACC_TEXT                -- Pops both, concatenates, pushes "Hello, John!".
        ```
    *   **`TABLE` Block:** The process is more involved. `TABLE_NEW` first pushes a table to hold key-value pairs. List-style items (`- ...`) are pushed directly onto the value stack, while key-value items (`key: ...`) are added to the pre-made table. `ACC_TABLE` then pops the list items, merges them with the key-value table, and pushes the final Plume table.
        ```bytecode
        -- For a block building a table
        BEGIN_ACC
        TABLE_NEW               -- Pushes an empty table for k-v pairs.
        LOAD_CONSTANT "item1"   -- Pushes a list item onto the value stack.
        -- ... code to store a key-value pair in the table...
        ACC_TABLE               -- Pops "item1", merges it with the k-v table.
        ```

### 4. Data Transfer: LOAD/STORE Opcodes

Data is moved between stacks and the constant table using `LOAD_*` and `STORE_*` opcodes.

*   `LOAD_CONSTANT`: Pushes a value from the constant pool (literals, native functions) onto the value stack.
*   `LOAD_LOCAL` / `STORE_LOCAL`: Accesses a variable in the current scope.
*   `LOAD_LEXICAL` / `STORE_LEXICAL`: Accesses a variable from a parent scope (closure).
*   `LOAD_STATIC` / `STORE_STATIC`: Accesses a variable in the current file's static memory.

```bytecode
-- `let new_var = old_var`
LOAD_LOCAL old_var   -- Pushes `old_var`'s value from Variable Stack to Value Stack.
STORE_LOCAL new_var  -- Pops value from Value Stack and stores it in `new_var`'s slot.
```

### 5. Macro Calls

Standard calls (`$m()`) and block calls (`@m ... end`) generate similar bytecode.

1.  **Argument Preparation:** Arguments are prepared on the value stack as if for a `TABLE` accumulation.
2.  **Invocation:** The macro object itself is pushed, followed by `ACC_CALL`.
3.  **Execution (`ACC_CALL`):** This opcode pops the macro and its arguments, performs the `ENTER_SCOPE` logic, populates the new variable frame with the arguments, saves the return instruction pointer, and jumps to the macro's code offset.

**Default Argument Handling:** Default values are evaluated inside the macro body only if an argument was not provided.

```bytecode
-- For `macro fn(arg: 1 + 2)`, where `arg` is the first local variable.
-- Start of macro body:
LOAD_LOCAL 0 1           -- Load the received value for `arg`.
JUMP_IF_NOT_EMPTY :end_default -- If it's not empty, a value was passed. Skip default.

-- Default value calculation:
LOAD_CONSTANT 1
LOAD_CONSTANT 2
OPP_ADD
STORE_LOCAL 0 1          -- Store the result in `arg`.
:end_default
-- ... rest of macro code ...
```

### 6. Control Flow & Operations

*   **Jumps:** Control flow is standard. `JUMP` is unconditional. `JUMP_IF_NOT` pops a value and jumps if it is `false` or `empty`.
*   **ALU Operations:** Standard stack machine arithmetic. Operands are pushed, and an opcode like `OPP_ADD` pops them, performs the calculation, and pushes the result.

```bytecode
-- `if x > 0 ...`
LOAD_LOCAL x
LOAD_CONSTANT 0
OPP_GT              -- Pops x and 0, pushes boolean result.
JUMP_IF_NOT :else   -- Jumps if result is false.
```

---

## Opcode Reference

The following is a complete list of public opcodes for the Plume VM.

### Load / Store

*   **`LOAD_CONSTANT`** (arg1: -, arg2: constant offset)
    > Pushes one value from the constant pool onto the main stack.

*   **`LOAD_EMPTY`** (arg1: -, arg2: -)
    > Pushes the `empty` constant onto the main stack.

*   **`LOAD_LOCAL`** (arg1: -, arg2: variable offset)
    > Pushes one value from the current variable scope onto the main stack.

*   **`LOAD_LEXICAL`** (arg1: frame offset, arg2: variable offset)
    > Pushes one value from a parent variable scope (by frame index) onto the main stack.

*   **`LOAD_STATIC`** (arg1: -, arg2: variable offset)
    > Pushes one value from the current file's static memory onto the main stack.

*   **`STORE_LOCAL`** (arg1: -, arg2: variable offset)
    > Pops one value from the main stack into a local variable in the current scope.

*   **`STORE_LEXICAL`** (arg1: frame offset, arg2: variable offset)
    > Pops one value from the main stack into a variable in a parent scope.

*   **`STORE_STATIC`** (arg1: -, arg2: variable offset)
    > Pops one value from the main stack into the current file's static memory.

### Call / Return

*   **`ACC_CALL`** (arg1: -, arg2: -)
    > Invokes a macro. Pops the macro object, its positional arguments, and a table of named arguments. Sets up a new variable scope, populates it, saves the return address, and jumps to the macro's code. Also handles native Lua functions.

*   **`RETURN`** (arg1: -, arg2: -)
    > Returns from a macro. Pops the return address from the call stack, leaves the current variable scope, and jumps to the return address.

### Accumulation

*   **`BEGIN_ACC`** (arg1: -, arg2: -)
    > Initiates an accumulation block by pushing the current main stack pointer to the frame stack.

*   **`ACC_TEXT`** (arg1: -, arg2: -)
    > Finalizes a `TEXT` block. Pops all values within the current frame, concatenates them into a string, and pushes the result.

*   **`ACC_TABLE`** (arg1: -, arg2: -)
    > Finalizes a `TABLE` block. Consumes list items from the stack and merges them with a table of key-value pairs (also on the stack) to produce a final Plume table.

*   **`ACC_EMPTY`** (arg1: -, arg2: -)
    > Finalizes an `EMPTY` block. Pushes the `empty` constant onto the stack and closes the current frame.

### Table Manipulation

*   **`TABLE_NEW`** (arg1: hint, arg2: -)
    > Pushes a new, empty table onto the main stack, used for collecting named arguments.

*   **`TABLE_ADD`** (arg1: -, arg2: -)
    > _(Currently unused/placeholder)_

*   **`TABLE_INDEX`** (arg1: -, arg2: -)
    > Pops a table and a key, then pushes the corresponding value `table[key]`.

*   **`TABLE_SET`** (arg1: -, arg2: -)
    > Pops a table, a key, and a value, then performs `table[key] = value`.

*   **`TABLE_SET_ACC`** (arg1: -, arg2: -)
    > Pops a key and a value, and sets the pair in a table assumed to be at the base of the current accumulation frame. Used for `key: value` syntax inside table literals.

### Arithmetic and Logic Unit (ALU)

*   **`OPP_ADD`**, **`OPP_SUB`**, **`OPP_MUL`**, **`OPP_DIV`**, **`OPP_MOD`**, **`OPP_POW`**
    > Pops two numeric values, performs the operation, and pushes the result.

*   **`OPP_NEG`**
    > Pops one numeric value, negates it, and pushes the result.

*   **`OPP_GTE`**, **`OPP_LTE`**, **`OPP_GT`**, **`OPP_LT`**, **`OPP_EQ`**, **`OPP_NEQ`**
    > Pops two values, performs the comparison, and pushes the boolean result.

*   **`OPP_AND`**, **`OPP_OR`**
    > Pops two values, performs the logical operation, and pushes the result.

*   **`OPP_NOT`**
    > Pops one value, performs logical negation, and pushes the result.

### Jumps

*   **`JUMP`** (arg1: -, arg2: target offset)
    > Sets the instruction pointer to an absolute offset unconditionally.

*   **`JUMP_IF`** (arg1: -, arg2: target offset)
    > Pops a value; if it is truthy, jumps to the target offset.

*   **`JUMP_IF_NOT`** (arg1: -, arg2: target offset)
    > Pops a value; if it is falsy (`false` or `empty`), jumps to the target offset.

*   **`JUMP_IF_NOT_EMPTY`** (arg1: -, arg2: target offset)
    > Pops a value; if it is not the `empty` constant, jumps to the target offset. Used for default argument logic.

### Scope Management

*   **`ENTER_SCOPE`** (arg1: pre-allocated vars, arg2: total vars)
    > Creates a new lexical scope on the variable stack.

*   **`LEAVE_SCOPE`** (arg1: -, arg2: -)
    > Destroys the current lexical scope on the variable stack.

*   **`ENTER_FILE`** (arg1: -, arg2: file ID)
    > Sets the static memory context to the specified file ID.

*   **`LEAVE_FILE`** (arg1: -, arg2: -)
    > Restores the previous static memory context.

### Miscellaneous

*   **`NULL`** (arg1: -, arg2: -)
    > No operation. Often used as a placeholder or for debugging.