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

return function (plume)
    local insert = table.insert

    local builder = {}

    --- Initializes a Builder instance.
    ---@param map table The table to store source mapping information.
    ---@return table self The initialized Builder instance.
    function builder:init (map)
        self.code = {}  -- Stores the generated Lua code as a list of strings.
        self.map  = map -- Reference to the source map table, where each inner table collects nodes for a line.
        self.deep = 0   -- Current indentation level.
        self.temp = 0   -- to make unique temp variables/labels

        self.newlineCount = {}

        self.forceBreak = false -- Flag to indicate if the next write should start on a new line.
        return self
    end

    function builder:getTempVarName()
        self.temp = self.temp + 1
        return "__plume_temp_u" .. self.temp
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
        if #self.newlineCount > 0 then
            for i=1, #self.newlineCount do
                self.newlineCount[i] = self.newlineCount[i]+1
            end
        end 
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
    ---@param jump boolean True if a linebreak is needed
    ---@return nil
    function builder:emitASSIGNMENT(node, variable, compound, islocal, jump)
        self:newline()
        if node then self:use(node) end

        if islocal then
            self:write("local ")
        end

        self:write(variable)
        
        if jump then
            self:newline()
        end
        
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
    function builder:emitDEFINITION(node, name, islocal, inline)
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
    end

    --- Emits a function call (the function name part).
    ---@param node any The AST node for source mapping.
    ---@param name string The name of the function to call.
    ---@return nil
    function builder:emitCALL(node, name)
        self:write(name)
        if node then self:use(node) end
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
    function builder:emitWHILE(node, condition, label)
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

    --- Emits a 'continue' statement.
    ---@return nil
    function builder:emitCONTINUE(label)
        self:newline()
        self:write("goto " .. label)
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
        table.insert(self.newlineCount, 0)
    end

    --- Emits a closing character (e.g., ')', '}') on a new line.
    ---@param char string The closing character (e.g. ")", "}").
    ---@return nil
    function builder:emitCLOSE(char)
        self.deep = self.deep - 1
        
        local nlc = table.remove(self.newlineCount)
        if nlc == 1 then -- if only one lineBreak, it's emitOPEN. Remove it
            for i = #self.code, 1, -1 do
                if self.code[i] == "\n" then
                    table.remove(self.code, i)
                    table.remove(self.code, i) -- remove indent

                    -- Rebuild map
                    for _, node in ipairs(self.map[#self.map]) do
                        table.insert(self.map[#self.map-1], node)
                    end
                    table.remove(self.map)
                    break
                end
            end
        elseif nlc == 0 then
            self.forceBreak = false
        else
            self:newline() -- Ensures the closing character is on its own, correctly indented line.
        end

        self:write(char)  
    end

    -- Predefined chunks of commonly used Lua code for Plume's specific runtime conventions

    ---@param positionalArgs table List of positional arguments.
    ---@param namedArgs table List of named arguments nodes
    function builder:chunkINIT_PARAM(positionalArgs, namedArgs, varargPos, varargNamed)
        local stringPositionalArgs = table.concat(positionalArgs, ", ")
        
        local stringNamedArgs = {}
        for _, node in ipairs(namedArgs) do
            table.insert(stringNamedArgs, node.content)
        end
        stringNamedArgs = table.concat(stringNamedArgs, ", ")

        local stringVarargCheckPos, stringVarargCheckNamed
        if varargPos then
            stringVarargCheckPos = "true"
        else
            stringVarargCheckPos = "false"
        end
        if varargNamed then
            stringVarargCheckNamed = "true"
        else
            stringVarargCheckNamed = "false"
        end

        --- Start generating code for parameter initialization.
        self:newline()
        self:insert("local self")
        if #stringPositionalArgs > 0 then
            self:insert(", ")
            self:insert(stringPositionalArgs)
        end
        if #namedArgs > 0 then
            self:insert(", ")
            self:insert(stringNamedArgs)
        end
        if varargPos then
            self:insert(", ")
            self:insert(varargPos)
        end
        if varargNamed then
            self:insert(", ")
            self:insert(varargNamed)
        end

        self:insert(" = ")
        self.deep = self.deep + 1
        self:newline()
        --- Call the __plume_init_args helper function.
        self:insert("__plume_init_args(")
            self:insert("__plume_args, ")
            self:insert(#positionalArgs)
            self:insert(", ")
            self:insert("{") -- Start of named arguments table.
            self.deep = self.deep + 1
            --- Insert named argument information into the table.
            for i, node in ipairs(namedArgs) do
                self:insert("{")
                self:insert("'"..node.content.."'")
                self:insert(", ")
                -- Transpile default values.
                self.transpileChildren(node, true, true) 
                self:insert("}")
                if i < #namedArgs then
                    self:insert(", ")
                end
                
            end
            self:insert("}") -- End of named arguments table.
            self:insert(", ")
            self:insert(stringVarargCheckPos)
            self:insert(", ")
            self:insert(stringVarargCheckNamed)
        self.deep = self.deep - 1
        self:insert(")")
        self.deep = self.deep - 1
    end

    --- Generates code to expand a table's array part into `__plume_temp`.
    ---@param callback function The function that emits the table expression to expand.
    function builder:chunkEXPAND_LIST(callback)
        self:newline()
        -- Emits the call to __plume_expand_list, which handles the array part expansion.
        self:emitOPEN("__plume_expand_list(__plume_temp, ")
        callback()
        self:emitCLOSE(")")
    end

    --- Generates code to expand a table's hash part into `__plume_temp`.
    ---@param callback function The function that emits the table expression to expand.
    function builder:chunkEXPAND_HASH(callback)
        self:newline()
        -- Emits the call to __plume_expand_hash, which handles the hash part expansion.
        self:emitOPEN("__plume_expand_hash(__plume_temp, ")
        callback()
        self:emitCLOSE(")")
    end

    function builder:getUniqueLabel(name)
        self.temp = self.temp + 1
        return "label" .. self.temp .. "_" .. name
    end

    return builder
end