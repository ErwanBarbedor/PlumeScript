### 0.39
- Remove `_LUA`. *In Lua, it is possible to adapt to the Plume calling convention. The reverse is not possible in a simple way, and basically letting Lua handle `_PLUME` is enough to allow the two languages to exchange without the need for `_LUA`.*
- (`lua`) New function `plume.require`, that mimic the `plume` `require`.
- New macro `$file.Write`.
- Implement meta-field. *A plume equivalent to lua meta table*
```
t =
    - item
    key: value
    @tostring: macro()
        my_table
$t // return "my_table" instead of raising an error
```

For now, only: `add call index le len lt mul newindex tostring unm`
- Implement an optional argument validator:
```
macro add(number x, number y)
    ...
// Quite similar to
macro add(x, y)
    if not __plume_validator_number(x)
        error()
    if not __plume_validator_number(y)
        error()
```
Builtin: `number string table`.

### 0.38
#### Changes
- Move utils functions used by transpiled code from `plume` to `_G`.
- Move `_VERSION` from `plume` to `_G`.
- New `_LUA_VERSION` and `_LUAJIT_VERSION`.
- New `_PLUME_DIR`.
- Remove field `__lua`.
- Severely restricts the standard lua methods available to the user.
- These methods are availables from lua files.
- `lua` and `plume` don't run anymore in the same env. *Since call conventions are different in Plume and lua, it's best to separate them explicitly.*
- Add field `_LUA` (for `plume` files) and `_PLUME` (for `lua` files).

#### Internal changes
- Reorganize std functions

### 0.37

#### Changes
- More flexible syntax (for exemple, `a = b = c` will not raise an error, but affect string `b = c` to variable `a`).
- Add `macro` in reserved word list.
- Implement `continue` keyword.
- Remove `;` as an equivalent to `\n`.
- `BREAK` and `ELSE` must ends the line.

### 0.36

#### Changes
- Made Plume compatible with Windows.
- Enhance transpiler output.
- Remove ending `/` from `_DIR`.
- Cleaner filename.

#### CLI changes
- Remove `--install` and `--remove` options.

#### Internal changes
- Use `lfs` for all files-related opperations.
- Add `os` into transpiled infos.

### 0.35

#### CLI
- New CLI option `--remove-cache`.
- New CLI option `--no-cache`.

#### Changes
- Implement a caching system for transpiled files.
- `void` cannot anymore be used as a variable name.
- Add `[plume install dir]/lib` to file searching path.
- Add `[name]/init.plume` to file searching path.
- New variables `_FILE` and `_DIR`, containing current script path and parent directory.

#### Enhancement
- Argument check in `require`.

### 0.34

### CLI
- Addition of a test suite for the CLI.
- New CLI option `-v --version`
- New CLI option `--install`
- New CLI option `--remove`
- New CLI option `--update`

### 0.33

#### Changes
- Add a CLI tools to run plume
- Remove all compatibility with Lua 5.2+.

#### Bugfix
- Change `not tonumber(x)` to `type(x) ~= "number"` to check if a variable is a number.
- Correctly map `expand` code.
- Correctly map `call` code.
- Correction of a case where the transpiled code is ambiguous (situation like `a = bar (function () ... end)` using the command `void`)
- Extending a macro call within a macro definition will behave correctly.

#### Enhancement
- New error message when trying to expand a non-table variable.
- The error message indicates exactly which element caused the error, rather than the entire line.
Exemple:
```
Syntax error: expected parameter name, not "$".
File <string_1>, line n°1:
    macro foo(x, $)
                 ^
```
Instead of
```
Syntax error: expected parameter name, not "$".
File <string_1>, line n°1:
    macro foo(x, $)
```

#### Internal changes
- Transpiler divides the assignment into two lines, so not more that one token is retained for each transpiled Lua line.

### 0.32

#### Changes
- Split vararg into `*positional` and `**named`. *Lua lets you use list and hash in the same object. But mixing the two leads to the fact that if a macro accepts a dynamic number of positional arguments (without using the excedent named arguments), Plume will not raise an error in the event of misuse of the named arguments, which is detrimental to the user experience.*
- Split expand too between `*expand_list` and `**expand_hash`
- Can now expand result of chained access (e.g. `*a.foo[1].bar`)
- Can now expand result of a call (e.g. `*foo()` instead of `local temp = $foo() ... *temp`)
- `self` cannot be use as variable name

#### Internal changes
- For readability and maintainability, use utils functions instead of inline functions in transpiled code.
- For readability, implement smarter indentation in transpiled file.

### 0.31

#### Changes
- Can now chain table access without limit (ex: `$foo[1].bar.baz[2]`).
- Can now chain table access and call it (ex: `$foo[1].bar.baz[2] ()`). Note: cannot access field or index _after_ the call, like `$foo().bar`. 
- `$1` is no longer considered as a variable.
- It is no longer possible to use several arguments with the same name in a macro call.
- New command `void`, more or less a syntax sugar for `local useless_temp_variable = ...`

#### Internal changes
- Enhance patterns lib.

#### Bugfix
- If a `LIST_ITEM` is followed by text AND an open block, the leading text is correctly considered as the first line of the block.

### 0.30

#### Changes
- Macro named parameters default value can be empty.
- With a few exceptions, it is now impossible to have a command that is followed by both text AND an indented block.
- `break` can no longer be used outside a loop.
- When using one-line macro definition, trim macro body.
- Instead of the first one detected, Plume takes now the smallest indentation in the file. Raises an error if tab and space are mixed.
- New syntax sugar for giving flags to macro call `$foo(:flag)` -> `$foo(flag: $true)`.

#### Bugfix
- Fixed a bug where each line of an extended call was considered as an individual argument.
- Fixed a bug where the dynamic table key was not transpiled correctly in certains cases.

### 0.29

#### Changes
- Calling a macro with the wrong number of arguments or incorrectly named arguments will now raise an error.
- In the code `a = 1`, `1` will be interpreted as a number.

#### Bugfix
- Correct parsing of the lua expression following a `return` statement.

#### Internal changes
- A lot of code cleaning, commentary writting, code re-organisation...

### 0.28

#### Changes
- Transpile to `return` instead of `return nil` in most cases.
- New `plume.importLuaFunction`.
- When transpiling, avoid lua tailcall. Loss of situational optimization for more precise error messages.
- Replace `in function ...` by `in macro ...` in error traceback.

#### Bugfix
- Fixed an error occurring when declaring empty variable.
- Fixed an error occurring when calling a macro declaration, causing the parameters of the sub-macro to be taken into account as arguments to the parent macro.
- Fixed an error that caused the default value of some parameters to be concatenated with `""`.
- `local foo` is not anymore a text block, but a variable declaration.

#### Enhancement
- New error message is case of missing parameter name in macro declaration.
- Full traceback given in case of error, even the calling function.

### 0.27

#### Changes
- Temporarily remove compatibility with lua 5.2+ to focus on development.
- When a `nil value` error is raised, Plume will suggest valid variable names.
- Plume will only suggest variables of a type consistent with the error.
- All method called as table field will get access to this class by the variable `self`.

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