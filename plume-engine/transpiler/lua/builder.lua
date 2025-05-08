--[[This file is part of Plume

Plume🪶 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume🪶 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume🪶.
If not, see <https://www.gnu.org/licenses/>.
]]

-- This file defines a `Builder` object responsible for constructing Lua code
-- programmatically. It facilitates the generation of syntactically correct Lua
-- by offering methods to emit various language constructs, manage indentation,
-- and integrate source mapping information.

return function ()
    local insert = table.insert

    local builder = {}

    --- Initializes a Builder instance.
    ---@param map table The table to store source mapping information.
    ---@return table self The initialized Builder instance.
    function builder:init (map)
        self.code = {}  -- Stores the generated Lua code as a list of strings.
        self.map  = map -- Reference to the source map table, where each inner table collects nodes for a line.
        self.deep = 0   -- Current indentation level.

        self.forceBreak = false -- Flag to indicate if the next write should start on a new line.
        return self
    end


    -- Helper functions for managing the code buffer

    --- Inserts all elements from a given table into the code buffer.
    ---@param t table A list of strings to insert.
    function builder:insertAll(t)
        for i = 1, #t do
            insert(self.code, t[i])
        end
    end

    --- Inserts a single string into the code buffer.
    ---@param x string The string to insert.
    function builder:insert(x)
        insert(self.code, x)
    end

    --- Associates a source node with the current line in the source map.
    --- The current line is the last table entry in `self.map`.
    ---@param node any The AST node or source information to map.
    function builder:use (node)
        insert(self.map[#self.map], node)
    end

    --- Adds a newline character to the code buffer and starts a new line in the source map.
    -- Applies current indentation after the newline.
    ---@return nil
    function builder:newline()
        self.forceBreak = false -- Reset forceBreak as a newline is explicitly handled.
        insert(self.map, {}) -- Create a new entry for the new line in the source map.
        self:insert("\n")
        self:insert(("  "):rep(self.deep)) -- Apply indentation based on current depth (2 spaces per level).
    end

    --- Writes a string of code to the output buffer.
    -- If `forceBreak` is true, a newline is inserted before the code.
    ---@param code string The Lua code snippet to write.
    ---@return nil
    function builder:write(code)
        if self.forceBreak then
            self:newline()
        end
        insert(self.code, code)
    end

    -- Functions to emit specific Lua code constructs

    --- Emits an assignment statement.
    ---@param node any The AST node for source mapping.
    ---@param variable string The name of the variable being assigned.
    ---@param compound string|nil The compound assignment operator
    ---@param islocal boolean True if the assignment is for a local variable.
    ---@return nil
    function builder:emitASSIGNMENT(node, variable, compound, islocal)
        self:newline()
        if node then self:use(node) end

        if islocal then
            self:write("local ")
        end

        self:write(variable)
        
        if compound then
            self:write(" = ")
            self:write(variable)
            self:write(" ")
            self:write(compound) -- The operator for compound assignment e.g. "+", "-", ...
            self:write(" ")
        else
            self:write(" = ")
        end
    end

    --- Emits a function definition.
    -- Includes argument count checking boilerplate specific to Plume's calling convention.
    ---@param node any The AST node for source mapping.
    ---@param name string|nil The name of the function. Nil for anonymous functions.
    ---@param islocal boolean True if the function is local.
    ---@param inline boolean True if the function definition is inline (affects newline before "function").
    ---@param nargs number The number of expected arguments.
    ---@param vararg boolean True if the function is variadic (accepts `...` after named/positional arguments).
    ---@return nil
    function builder:emitDEFINITION(node, name, islocal, inline, nargs, vararg)
        if not inline then
            self:newline()
        end

        if node then self:use(node) end

        if islocal then
            self:write("local ")
        end

        -- All Plume functions receive their arguments in a single table named `__plume_args`.
        self:write("function " .. (name or "") .. "(__plume_args)") 
        self.deep = self.deep + 1

        -- Argument count check:
        -- If vararg, we expect at least 'nargs' (for fixed part).
        -- If not vararg, we expect exactly 'nargs'.
        if vararg then
            self:emitIF(node, " #__plume_args < " .. nargs)
        else
            self:emitIF(node, " #__plume_args ~= " .. nargs)
        end
        self:newline()
        -- Report error with level 2, so error points to the caller of the Plume function, not internal Plume code.
        self:write(" __lua.error('Wrong number of arguments, ' .. #__plume_args .. ' instead of " .. nargs .. ".', 2)")
        self:emitEND()
    end

    --- Emits a function call (the function name part).
    ---@param node any The AST node for source mapping.
    ---@param name string The name of the function to call.
    ---@return nil
    function builder:emitCALL(node, name)
        if node then self:use(node) end
        self:write(name)
    end

    --- Emits an argument table, typically empty or with a 'self' field for method calls.
    --- Used for Plume's function calling convention where arguments are passed in a table.
    ---@param selfValue string|nil If provided, emits `self = selfValue` field in the table. This is the value for the `self` key.
    ---@return nil
    function builder:emitEMPTY_ARGS(selfValue)
        self:write('{')
        if selfValue then
            self:write("self = ")
            self:write(selfValue)
        end
        self:write('}')
    end

    --- Emits an 'if' statement.
    ---@param node any The AST node for source mapping.
    ---@param condition string The condition for the if statement.
    ---@return nil
    function builder:emitIF(node, condition)
        self:newline()
        if node then self:use(node) end
        self:write("if")
        self:write(condition)
        self:write(" then")
        self.deep = self.deep + 1
    end

    --- Emits an 'elseif' statement.
    ---@param node any The AST node for source mapping.
    ---@param condition string The condition for the elseif statement.
    ---@return nil
    function builder:emitELSEIF(node, condition)
        self.deep = self.deep - 1
        self:newline()
        if node then self:use(node) end
        self:write("elseif")
        self:write(condition)
        self:write(" then")
        self.deep = self.deep + 1
    end

    --- Emits a 'for' loop statement.
    ---@param node any The AST node for source mapping.
    ---@param iteration string The iteration part of the for loop (e.g., "i=1,10" or "k,v in pairs(t)").
    ---@return nil
    function builder:emitFOR(node, iteration)
        self:newline()
        if node then self:use(node) end
        self:write("for")
        self:write(iteration)
        self:write(" do")
        self.deep = self.deep + 1
    end

    --- Emits a 'while' loop statement.
    ---@param node any The AST node for source mapping.
    ---@param condition string The condition for the while loop.
    ---@return nil
    function builder:emitWHILE(node, condition)
        self:newline()
        if node then self:use(node) end
        self:write("while")
        self:write(condition)
        self:write(" do")
        self.deep = self.deep + 1
    end

    --- Emits an 'else' keyword for if/elseif blocks.
    ---@return nil
    function builder:emitELSE()
        self.deep = self.deep - 1
        self:newline()
        self:write("else")
        self.deep = self.deep + 1
    end

    --- Emits a 'break' statement.
    ---@return nil
    function builder:emitBREAK()
        self:newline()
        self:write("break")
    end

    --- Emits a 'return' statement.
    ---@return nil
    function builder:emitRETURN()
        self:newline()
        self:write("return ")
    end

    --- Emits an 'end' keyword to close a block (if, for, while, function, etc.).
    ---@return nil
    function builder:emitEND()
        self.deep = self.deep - 1
        self:newline()
        self:write("end")
    end

    --- Emits a string literal, escaping double quotes within the text.
    -- The input text should not contain literal newlines;
    ---@param node any The AST node for source mapping.
    ---@param text string The text content of the string.
    ---@return nil
    function builder:emitTEXT(node, text)
        text = text:gsub('"', '\\"') -- Escape double quotes.

        if node then self:use(node) end
        self:write('"')
        self:write(text)
        self:write('"')
    end

    --- Emits raw Lua code.
    -- Wraps non-empty code in parentheses to enhance syntax error localisation.
    -- Emits 'nil' for empty code string.
    ---@param node any The AST node for source mapping.
    ---@param code string The raw Lua code to emit.
    ---@return nil
    function builder:emitLUA(node, code)
        if node then self:use(node) end

        if #code > 0 then
            self:write('(')
            self:write(code)
            self:write(')')
        else
            self:write("nil")
        end
    end

    --- Emits a variable name (or any identifier).
    ---@param node any The AST node for source mapping.
    ---@param variable string The name of the variable.
    ---@return nil
    function builder:emitVARIABLE(node, variable)
        if node then self:use(node) end
        self:write(variable)
    end

    --- Emits an opening character (e.g., '(', '{') and increases indentation.
    ---@param char string The opening character (e.g. "(", "{").
    ---@return nil
    function builder:emitOPEN(char)
        self:write(char)
        self.deep = self.deep + 1
        self.forceBreak = true -- Suggests that content immediately following this opening char can start on a new, indented line.
    end

    --- Emits a closing character (e.g., ')', '}') on a new line.
    ---@param char string The closing character (e.g. ")", "}").
    ---@return nil
    function builder:emitCLOSE(char)
        self.deep = self.deep - 1
        self:newline() -- Ensures the closing character is on its own, correctly indented line.
        self:write(char)   
    end

    -- Predefined chunks of commonly used Lua code for Plume's specific runtime conventions

    --- Generates code to initialize a local variable to hold all varargs passed in `__plume_args`.
    ---@param argName string The name for the local variable that will store the `__plume_args` table.
    ---@param argCount number The formal count of varargs; current implementation assigns the whole `__plume_args` table. This parameter is noted as potentially unused.
    ---@return nil
    function builder:chunkINIT_VARARG(argName, argCount)
        -- This boilerplate does not usually map to a specific user source node, so 'node' is nil.
        self:emitASSIGNMENT(nil, argName, nil, true) 
        self:write("__plume_args")
    end

    --- Generates code to initialize a named parameter.
    -- It retrieves the parameter from `__plume_args.argName`. If not found, it uses a default value generated by the callback.
    -- The parameter is then removed from `__plume_args`.
    ---@param argName string The name of the parameter.
    ---@param callback function A function that, when called, uses the builder to emit the code for the default value.
    ---@return nil
    function builder:chunkINIT_NAMED_PARAM(argName, callback)
        self:emitASSIGNMENT(nil, argName, nil, true)
        self:write("__plume_args.")
        self:write(argName)

        self:emitIF(nil, " " .. argName .. " == nil") -- Check if the parameter was supplied in the __plume_args table.
        self:emitASSIGNMENT(nil, argName)
        callback() -- Generate the default value if the parameter was not supplied.
        self:emitELSE()
        self:emitASSIGNMENT(nil, "__plume_args." .. argName) -- Remove the parameter from __plume_args...
        self:write("nil")                                   -- ...to prevent it from being treated as an extra unnamed argument later.
        self:emitEND()
    end

    --- Generates code to initialize a 'self' parameter from `__plume_args.self`.
    -- The `self` field is then removed from `__plume_args`.
    ---@return nil
    function builder:chunkINIT_SELF_PARAM()
        self:emitASSIGNMENT(nil, "self", nil, true)
        self:write("__plume_args.self")
        self:emitASSIGNMENT(nil, "__plume_args.self") -- Remove 'self' from __plume_args after fetching it.
        self:write("nil")
    end

    --- Generates code to initialize a positional parameter from `__plume_args`.
    ---@param argName string The name of the local variable for the parameter.
    ---@param pos number The 1-based position of the parameter in `__plume_args` array part.
    ---@param vararg boolean If true, uses `__plume_remove(__plume_args, 1)` to get the parameter, effectively consuming it from the front (useful when processing varargs sequentially after fixed args). If false, uses direct indexed access `__plume_args[pos]`.
    ---@return nil
    function builder:chunkINIT_PARAM(argName, pos, vararg)
        self:emitASSIGNMENT(nil, argName, nil, true)
        if vararg then
            -- For varargs or when consuming arguments sequentially, `__plume_remove` is used.
            -- It's assumed `__plume_remove` retrieves the element and shifts others or handles consumption.
            self:write("__plume_remove(__plume_args, 1)") 
        else
            -- For fixed positional arguments, access directly by index.
            self:write("__plume_args[")
            self:write(tostring(pos))
            self:write("]")
        end
    end

    --- Generates code to expand a table's contents into `__plume_temp`.
    -- This involves copying both the array part (integer keys) and the hash part (string keys)
    -- from the table `name` into a temporary table `__plume_temp`.
    -- This is typically used for argument spreading or table construction.
    ---@param name string The name of the variable holding the table to expand.
    ---@return nil
    function builder:chunkEXPAND(name)
        -- Copy array part using __lua.ipairs and a Plume-specific insert function.
        self:emitFOR(nil, " k, v in __lua.ipairs(" .. name .. ")") -- Iterate over the array part of the source table.
            self:newline()
            self:write("__plume_insert(__plume_temp, v)") -- Insert elements into the array part of __plume_temp.
        self:emitEND()

        -- Copy named fields (hash part) using __lua.pairs.
        self:emitFOR(nil, " k, v in __lua.pairs(" .. name .. ")") -- Iterate over all key-value pairs in the source table.
            self:emitIF(nil,  " not __lua.tonumber(k)") -- Process only if the key is not a number (array elements already handled by ipairs).
                self:newline()
                self:write("__plume_temp[k] = v") -- Copy named fields to the __plume_temp table.
            self:emitEND()
        self:emitEND()
    end

    function builder:chunckCHECK_UNUSED_NAMED_PARAM(parameterNames)
        local t = {}
        for name, _ in pairs(parameterNames) do
            table.insert(t, name .. ' = true' )
        end
        local tnames = "{" .. table.concat(t, ", ") .. "}"

        self:emitFOR(nil, " name, _ in __lua.pairs(__plume_args)")
            self:emitIF(nil,  " not __lua.tonumber(name)")
                self:newline()
                self:insert("__lua.raiseWrongParameterName(name, " .. tnames .. ")")
            self:emitEND()
        self:emitEND()
    end

    return builder
end