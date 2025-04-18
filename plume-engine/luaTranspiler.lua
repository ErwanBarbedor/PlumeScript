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

return function(plume)

    local contains   = plume.utils.containsWord
    local STATEMENTS = "FOR ASSIGNMENT LOCAL_ASSIGNMENT IF ELSE ELSEIF WHILE MACRO LOCAL_MACRO RETURN BREAK COMMAND_EXPAND"

    local transpileToLua

    -- Dirty temp function waiting for a full script parsing
    local function editLuaCode(code)
        code = code:gsub('([a-zA-Z_][a-zA-Z_0-9%.]*):([a-zA-Z_][a-zA-Z_0-9]*)%s*(%b())', function(f, m, p)
            if #p>2 then
                p = ", " .. p:sub(2, -2)
            else
                p = ""
            end
            return f .. "." .. m .. "(" .. f .. p .. ")"
        end)

        code = code:gsub('([a-zA-Z_][a-zA-Z_0-9]*)%s*(%b())', function(f, p)
            return f .. " {" .. p:sub(2, -2) .. "}"
        end)

        return code
    end

    ---Main transpilation entry point - converts an AST to Lua code
    ---@param ast table Abstract Syntax Tree to transpile
    ---@param luaVersion string Optional Lua version to target. If nil, detects from environment
    ---@return string Transpiled Lua code
    ---@return table Mapping information for the generated code
    plume.transpileToLua = function(ast, luaVersion)

        local luaVersion
        if not luaVersion then
            if jit then
                luaVersion = "JIT"
            else
                luaVersion = _VERSION:match('%S+$')
            end
        end

        local map    = {{}}
        local result = {}

        local builder = plume.Builder (map)
        --- Inserts a new line in the map.
        ---@return string New line character.
        local function newline ()
            table.insert(map, {})
            return "\n"
        end

        --- Adds a token to the current line of the map.
        ---@param token any The token to add.
        local function use (token)
            table.insert(map[#map], token)
        end

        ---Parses the children of a given node.
        ---@param node table The node whose children are to be parsed.
        ---@return table result A table containing the parsed children. Each element can be a node or a list of nodes.
        ---@return boolean onlyValues True if all children are values, false otherwise.
        ---@return number valueCount The number of value children, or -1 if counting is disabled (e.g., inside control structures).
        local function parseChildren (node)
            local result = {}

            local onlyValues      = true
            local firstValueFound = false
            local valueCount = 0
            local acc        = {}

            for _, child in ipairs(node.children) do
                local isStatement = contains(STATEMENTS, child.kind)
                if child.returnType == "NIL" or isStatement then
                    onlyValues = false

                    if not firstValueFound then
                        if #acc > 0 or isStatement then
                            table.insert(result, {store=true, kind="nodeList", content=acc})
                            firstValueFound = true
                        end
                    end

                    table.insert(result, {store=false, kind="node", content=child})

                    -- Cannot count inside control structure
                    if contains("IF ELSEIF ELSE FOR WHILE COMMAND_EXPAND", child.kind) then
                        valueCount = -1    
                    end

                elseif not firstValueFound then
                    if valueCount ~= -1 then
                        valueCount = valueCount+1
                    end
                    table.insert(acc, child)
                else
                    if valueCount ~= -1 then
                        valueCount = valueCount+1
                    end
                    table.insert(result, {store=true, kind="node", content=child})
                end
            end

            if not firstValueFound then
                if #acc > 0 then
                    table.insert(result, {store=true, kind="nodeList", content=acc})
                end
            end

            if #result == 0 then
                onlyValues = false
            end

            return result, onlyValues, valueCount
        end

        --- Transpiles a node's children when they only contain values.
        ---@param node table The node whose children are being transpiled
        ---@param infos table Information about the node's children
        ---@param valueCount number Number of values being returned
        ---@param forceReturn boolean Whether to force a return statement
        ---@return table A table containing Lua code fragments
        local function transpileChildrenOnlyValuesCase(node, infos, valueCount, forceReturn)
            local wrapInTable  = (node.returnType == "TABLE") or valueCount>2
            local concat       = (node.returnType == "TEXT") and valueCount>2
            local directConcat = (node.returnType == "TEXT") and valueCount==2

            if forceReturn then
                builder:emitRETURN()
            end

            if concat then
                builder:write("__plume_concat ")
            end

            if wrapInTable then
                builder:emitOPEN("{")
            end

            if directConcat then
                builder:emitOPEN("(")
            end

            for i, content in ipairs(infos[1].content) do
                if (directConcat or concat) and content.kind ~= "TEXT" then
                    builder:write("__plume_check(")
                end
                transpileToLua(content)
                if (directConcat or concat) and content.kind ~= "TEXT" then
                    builder:write(")")
                end

                if i < #infos[1].content then
                    if directConcat then     
                        builder:newline()
                        builder:write(".. ")
                    else
                        builder:write(", ")
                        builder:newline()
                    end
                end
            end

            if directConcat then
                builder:emitCLOSE(")")
            end

            if wrapInTable then
                builder:emitCLOSE("}")
            end
        end

        local transpileChildren

        --- Transpiles mixed-case children of a node to Lua code.
        ---@param node table The AST node whose children are being transpiled.
        ---@param infos table A table containing information about the children to transpile.
        ---@param valueCount number The expected number of values to be generated. -1 indicates an unknown number.
        ---@param shouldInitAccumulator boolean Whether an accumulator variable should be initialized.
        ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function.
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function.
        ---@return table A table containing the generated Lua code strings.
        local function transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)

            local concat = (node.returnType == "TEXT")

            -- Wrap the output in a function if required
            if wrapInFunction then
                builder:emitOPEN("(function()")
            end

            local firstValueFound = false
            local alreadyReturn   = false

            for index, info in ipairs(infos) do
                -- Check if the child should be stored (i.e., represents a value)
                if info.store then
                    local values = info.content
                    if info.kind == "node" then
                        values = {values}
                    end

                    -- Handle single value case with accumulator initialization
                    if valueCount == 1 and shouldInitAccumulator and #values > 0 then
                        -- Return statement for last value
                        if index == #infos then
                            alreadyReturn = true
                            builder:emitRETURN()
                        -- Initialize accumulator variable if not the last value and not a simple "VALUE" return type
                        elseif node.returnType ~= "VALUE" then
                            builder:emitASSIGNMENT(nil, "__plume_temp", nil, true)
                        end

                        -- Wrap in table constructor if return type is "TABLE"
                        if node.returnType == "TABLE" then
                            builder:emitOPEN("{")
                        end
                        
                        transpileToLua(values[1])

                        if node.returnType == "TABLE" then
                            builder:emitCLOSE("}")
                        end
                    -- Handle multiple values
                    else
                        -- Append values to accumulator table
                        if firstValueFound or (not shouldInitAccumulator) then
                            for _, value in ipairs(values) do
                                builder:newline()
                                if info.content.kind == "HASH_ITEM" then
                                    builder:emitASSIGNMENT(info.content,
                                        "__plume_temp[\"" .. info.content.content .. "\"]",
                                        nil
                                    )
                                    transpileChildren(info.content, false, true, false)
                                else
                                    builder:emitOPEN("__plume_insert (__plume_temp, ")
                                    if concat and value.kind ~= "TEXT" then
                                        builder:emitOPEN("__plume_check(")
                                    end
                                    transpileToLua(value)
                                    if concat and value.kind ~= "TEXT" then
                                        builder:emitCLOSE(")")
                                    end
                                    builder:emitCLOSE(")")
                                end
                            end
                        -- Initialize accumulator table with first set of values
                        elseif #values > 0 then
                            firstValueFound = true
                            builder:emitASSIGNMENT(nil, "__plume_temp", nil, true)
                            builder:emitOPEN("{")
                            for _, value in ipairs(values) do
                                if concat and value.kind ~= "TEXT" then
                                    builder:emitOPEN("__plume_check(")
                                end
                                transpileToLua(value)
                                if concat and value.kind ~= "TEXT" then
                                    builder:emitCLOSE(")")
                                end
                                builder:write(", ")
                            end
                            builder:emitCLOSE("}")
                        -- Initialize empty accumulator if necessary
                        elseif valueCount ~= 0 and (valueCount == -1 or #values > 0) then
                            firstValueFound = true
                            if node.returnType ~= "VALUE" then
                                builder:newline()
                                builder:insert("local __plume_temp = {}")
                            end
                        end
                    end

                -- special case: expand
                elseif info.content.kind == "COMMAND_EXPAND" then
                    builder:chunckEXPAND(info.content.content)
                    
                -- If it is not a stored value then recursively call transpileToLua 
                else
                    transpileToLua(info.content)
                end
            end

            -- Add return statement if needed
            if (wrapInFunction or forceReturn) and not alreadyReturn then
                -- Handle TEXT return type
                if node.returnType == "TEXT" and (valueCount ~= 1 or not shouldInitAccumulator) then
                    builder:newline()
                    if valueCount == 0 then
                        builder:insert("return \"\"")
                    else
                        builder:insert("return __plume_concat (__plume_temp)") -- Concatenate text values
                    end
                -- Handle other return types (except NIL and VALUE)
                elseif node.returnType == "NIL" then
                    if forceReturn then
                        builder:newline()
                        builder:insert("return nil")
                    end
                elseif node.returnType ~= "VALUE" then
                    builder:newline()
                    if valueCount == 0 then
                        builder:insert("return {}")
                    else
                        builder:insert("return __plume_temp") -- Return accumulated values
                    end
                end
            end

            -- Close the wrapping function if necessary
            if wrapInFunction then
                builder:emitCLOSE("end)()")
            end
        end

        ---Transpiles child nodes of an AST element into executable Lua code
        ---Handles value accumulation and control flow wrapping
        ---@param node table AST node to process
        ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function
        ---@param shouldInitAccumulator boolean Whether an accumulator variable should be initialized
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function
        ---@return table List of generated code lines
        function transpileChildren (node, wrapInFunction, shouldInitAccumulator, forceReturn)

            if #node.children == 0 then
                if contains("LIST_ITEM HASH_ITEM TEXT VALUE RETURN ", node.kind) then
                    return {'""'}
                elseif contains("ASSIGNMENT LOCAL_ASSIGNMENT", node.kind) then
                    return
                end
            end

            local infos, onlyValues, valueCount = parseChildren(node)

            if onlyValues and shouldInitAccumulator then
                transpileChildrenOnlyValuesCase(node, infos, valueCount, forceReturn)
            else
                transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)
            end        
        end

        ---Handles macro definition transpilation
        ---@param node table The macro definition node
        ---@param islocal boolean Whether this is a local macro
        ---@param addNewline boolean Whether to add a newline at the beginning
        ---@return table Transpiled Lua code fragments
        local function handleMacroDefinition (node, islocal, inline)

            local parameters = node.children[1]
            local body       = node.children[2]
            
            local parametersList = {}
            local namedParameterValues  =  {}
            local vararg = false
            for _, param in ipairs(parameters.children) do
                if param.kind == "LIST_ITEM" then
                    table.insert(parametersList, param.children[1])
                    if param.children[1].kind == "VARARG" then
                        vararg = true
                    end
                else
                    table.insert(parametersList, param)
                    namedParameterValues[param.content] =  param
                end
            end

            builder:emitDEFINITION(node, node.content, islocal, inline)

            local pos = 0
            for i, arg in ipairs(parametersList) do
                argName = arg.content
                if arg.kind == "VARARG" then
                    builder:chunckINIT_VARARG(argName, pos)
                elseif namedParameterValues[argName] then
                    builder:chunckINIT_NAMED_PARAM(argName, function()
                        transpileChildren(namedParameterValues[argName], false, true)
                    end)
                else
                    pos = pos + 1
                    builder:chunckINIT_PARAM(argName, pos, vararg)
                end
            end

            transpileChildren (body, false, true, true)
            builder:emitEND()
        end

        -- AST node type to handler mapping
        local tokenHandlers = {
            ---Handles block nodes, which contain multiple statements
            ---@param node table The block node to process
            BLOCK = function (node)
                -- use(node)
                local mainBlock = (node.indent or 0) >= 0
                transpileChildren (node, mainBlock, true, true)
            end,

            ---Handles macro calls, processing both inline and extended arguments
            ---@param node table The macro call node to process
            MACRO_CALL = function (node)
                -- Dirty temp fix
                local t, name = node.content:match('^(.-):([^:]*)$')
                if t then
                    name = t .. "." .. name
                else
                    name = node.content
                end

                local inlineArgs   = node.children[1]
                local extendedArgs = node.children[2] or {children={}}

                local argList = {}

                plume.insertAll(argList, inlineArgs.children)
                plume.insertAll(argList, extendedArgs.children)

                builder:emitCALL(node, name)
                if #extendedArgs.children == 0 and #inlineArgs.children == 0 then
                    builder:emitEMPTY_ARGS(node, t)
                else
                    if t then
                        insert(children, {kind="LIST_ITEM", children={{kind="TEXT", t}}})
                    end
                    builder:write('(')
                    transpileChildren({kind="TABLE", children=argList, returnType="TABLE"}, true, true)
                    builder:write(')')
                end
            end,

            ---Handles variable assignment
            ---@param node table The assignment node to process
            ASSIGNMENT = function (node)
                local variable = node.content

                if node.sourceToken.eval then
                    variable = "_G[" .. variable .. "]"
                end

                if node.sourceToken.index then
                    variable = variable .. "[" .. editLuaCode (node.sourceToken.index) .. "]"
                end

                builder:emitASSIGNMENT(node, variable, node.sourceToken.compound_operator, false)

                transpileChildren (node, true, true)
            end,

            ---Handles local variable assignment
            ---@param node table The local assignment node to process
            LOCAL_ASSIGNMENT = function (node)
                local variable
                if node.sourceToken.index then
                    variable = node.content .. "[" .. editLuaCode (node.sourceToken.index) .. "]"
                else
                    variable = node.content
                end

                builder:emitASSIGNMENT(node, variable, node.sourceToken.compound_operator, true)

                transpileChildren (node, true, true)
            end,

            ---Handles macro definition
            ---@param node table The macro definition node to process
            MACRO_DEFINITION = function (node)
                handleMacroDefinition(node)
            end,

            ---Handles inline macro definition
            ---@param node table The inline macro definition node to process
            INLINE_MACRO_DEFINITION = function (node)
                handleMacroDefinition(node, false, true)
            end,

            ---Handles list items (positional arguments/parameters)
            ---@param node table The list item node to process
            LIST_ITEM = function (node)
                use(node)
                transpileChildren (node, true, true)
            end,

            ---Handles hash items (named arguments/parameters)
            ---@param node table The hash item node to process
            HASH_ITEM = function (node)
                local name = node.content

                if node.sourceToken and node.sourceToken.eval then
                    name = "[" .. name .. "]"
                end

                builder:emitASSIGNMENT(node, name)

                transpileChildren (node, true, true)
            end,

            ---Handles return statements
            ---@param node table The return node to process
            RETURN = function (node)
                builder:emitRETURN()
                use(node)
                transpileChildren (node, true, true)
            end,

            ---Handles for loops
            ---@param node table The for loop node to process
            FOR = function (node)
                builder:emitFOR(node, editLuaCode(node.content))
                transpileChildren (node, false, false)
                builder:emitEND()
            end,

            ---Handles while loops
            ---@param node table The while loop node to process
            WHILE = function (node)
                builder:emitWHILE(node, editLuaCode(node.content))
                transpileChildren (node, false, false)
                builder:emitEND()
            end,

            ---Handles if statements
            ---@param node table The if statement node to process
            IF = function (node)
                builder:emitIF(node, editLuaCode(node.content))
                transpileChildren (node, false, false)
                if not node.noend then
                    builder:emitEND()
                end
            end,

            ---Handles elseif statements
            ---@param node table The elseif statement node to process
            ELSEIF = function (node)
                builder:emitELSEIF(node, editLuaCode(node.content))
                transpileChildren (node, false, false)
                if not node.noend then
                    builder:emitEND()
                end
            end,

            ---Handles else statements
            ---@param node table The else statement node to process
            ELSE = function (node)
                builder:emitELSE()
                transpileChildren (node, false, false)
                builder:emitEND()
            end,

            ---Handles break statements
            ---@param node table The break statement node to process
            BREAK = function (node)
                builder:emitBREAK()
            end,

            ---Handles text literals
            ---@param node table The text node to process
            TEXT = function (node)
                builder:emitTEXT(node, node.content)
            end,

            ---Handles variable references
            ---@param node table The variable node to process
            VARIABLE = function (node)
                local variable
                if node.sourceToken.index then
                    variable = node.content .. "[" .. editLuaCode (node.sourceToken.index) .. "]"
                else
                    variable = node.content
                end
                builder:emitVARIABLE(node, variable)
            end,

            COMMAND_EXPAND = function (node)
                builder:emitVARIABLE(node, node.content)
            end,

            ---Handles raw Lua expressions
            ---@param node table The Lua expression node to process
            LUA_EXPRESSION = function (node)
                use(node)
                builder:emitLUA(node, editLuaCode (node.content))
            end
        }
    
        ---Main transpilation function for individual AST nodes
        ---@param ast table AST node to transpile
        ---@return table Transpiled code fragments
        function transpileToLua(ast)
            if tokenHandlers[ast.kind] then
                tokenHandlers[ast.kind](ast)
            else
                error("NIY " .. (ast.kind or "???"))
            end
        end

        builder:insert("local __plume_check = plume.checkConcat")
        builder:newline()
        builder:insert("local __plume_concat = __lua.table.concat")
        builder:newline()
        builder:insert("local __plume_insert = __lua.table.insert")
        builder:newline()
        builder:insert("local __plume_remove = __lua.table.remove")

        builder:newline()
        if contains("5.1 JIT", luaVersion) then
            builder:insert("local __plume_unpack = __lua.unpack")
        else
            builder:insert("local __plume_unpack = __lua.table.unpack")
        end

        transpileToLua(ast)
        return table.concat(builder.code), map
    end
end