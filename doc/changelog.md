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