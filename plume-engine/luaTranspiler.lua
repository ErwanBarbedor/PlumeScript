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
    local STATEMENTS = "FOR ASSIGNMENT LOCAL_ASSIGNMENT IF ELSE ELSEIF WHILE MACRO LOCAL_MACRO RETURN BREAK"

    local transpileToLua

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

        local map = {{}}

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

        --- Inserts all elements from t2 into t1.
        ---@param t1 table The table to insert into.
        ---@param t2 table The table to insert from.
        local insertAll


        -- table.move is more efficient, but not available in all versions
        if table.move then
            function insertAll(t1, t2)
                table.move(t2, 1, #t2, #t1 + 1, t1)
            end
        else
            function insertAll(t1, t2)
                for i = 1, #t2 do
                    table.insert(t1, t2[i])
                end
            end
        end

        local insert = table.insert

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
                    if contains("IF ELSEIF ELSE FOR WHILE", child.kind) then
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
            local result = {}
            local wrapInTable  = (node.returnType == "TABLE") or valueCount>2
            local concat       = (node.returnType == "TEXT") and valueCount>2
            local directConcat = (node.returnType == "TEXT") and valueCount==2

            if forceReturn then
                insert(result, newline())
                insert(result, "return ")
            end

            if concat then
                insert(result, "__plume_concat ")
            end

            if wrapInTable then
                insert(result, "{")
            end

            if directConcat then
                insert(result, "(")
                insert(result, newline())
            end

            if wrapInTable then
                insert(result, newline())
            end

            for i, content in ipairs(infos[1].content) do
                if directConcat and content.kind ~= "TEXT" then
                    insert(result, "(")
                end
                insertAll(result, transpileToLua(content))
                if directConcat and content.kind ~= "TEXT" then
                    insert(result, " or \"\")")
                end

                if i < #infos[1].content then
                    if directConcat then     
                        insert(result, newline())
                        insert(result, ".. ")
                    else
                        insert(result, ", ")
                        insert(result, newline())
                    end
                end
            end

            if directConcat then
                insert(result, newline())
                insert(result, ")")
             end

            if wrapInTable then
                insert(result, newline())
                insert(result, "}")
            end

            return result
        end

        --- Transpiles mixed-case children of a node to Lua code.
        ---@param node table The AST node whose children are being transpiled.
        ---@param infos table A table containing information about the children to transpile.
        ---@param valueCount number The expected number of values to be generated. -1 indicates an unknown number.
        ---@param shouldInitAccumulator boolean Whether an accumulator variable should be initialized.
        ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function.
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function.
        ---@return table A table containing the generated Lua code strings.
        local function transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)
            local result = {}

            -- Wrap the output in a function if required
            if wrapInFunction then
                insert(result, "(function()")
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
                            insert(result, newline())
                            insert(result, "return ")
                        -- Initialize accumulator variable if not the last value and not a simple "VALUE" return type
                        elseif node.returnType ~= "VALUE" then
                            insert(result, newline())
                            insert(result, "local __plume_temp = ")
                        end

                        -- Wrap in table constructor if return type is "TABLE"
                        if node.returnType == "TABLE" then
                            insert(result, "{")
                            insert(result, newline())
                        end

                        insertAll(result, transpileToLua(values[1]))

                        if node.returnType == "TABLE" then
                            insert(result, newline())
                            insert(result, "}")
                        end
                    -- Handle multiple values
                    else
                        -- Append values to accumulator table
                        if firstValueFound or (not shouldInitAccumulator) then
                            for _, value in ipairs(values) do
                                insert(result, newline())
                                insert(result, "table.insert(__plume_temp, ")
                                insertAll(result, transpileToLua(value))
                                insert(result, ")")
                            end
                        -- Initialize accumulator table with first set of values
                        elseif #values > 0 then
                            firstValueFound = true
                            insert(result, newline())
                            insert(result, "local __plume_temp = {")
                            for _, value in ipairs(values) do
                                insert(result, newline())
                                insertAll(result, transpileToLua(value))
                                insert(result, ", ")
                            end
                            insert(result, newline())
                            insert(result, "}")
                        -- Initialize empty accumulator if necessary
                        elseif valueCount ~= 0 and (valueCount == -1 or #values > 0) then
                            firstValueFound = true
                            if node.returnType ~= "VALUE" then
                                insert(result, newline())
                                insert(result, "local __plume_temp = {}")
                            end
                        end
                    end
                  -- If it is not a stored value then recursively call transpileToLua 
                else
                    insertAll(result, transpileToLua(info.content))
                end
            end

            -- Add return statement if needed
            if (wrapInFunction or forceReturn) and not alreadyReturn then
                -- Handle TEXT return type
                if node.returnType == "TEXT" and (valueCount ~= 1 or not shouldInitAccumulator) then
                    insert(result, newline())
                    if valueCount == 0 then
                        insert(result, "return \"\"")
                    else
                        insert(result, "return __plume_concat (__plume_temp)") -- Concatenate text values
                    end
                -- Handle other return types (except NIL and VALUE)
                elseif node.returnType == "NIL" then
                    if forceReturn then
                        insert(result, newline())
                        insert(result, "return nil")
                    end
                elseif node.returnType ~= "VALUE" then
                    insert(result, newline())
                    if valueCount == 0 then
                        insert(result, "return {}")
                    else
                        insert(result, "return __plume_temp") -- Return accumulated values
                    end
                end
            end

            -- Close the wrapping function if necessary
            if wrapInFunction then
                insert(result, newline())
                insert(result, "end)()")
            end

            return result
        end

        ---Transpiles child nodes of an AST element into executable Lua code
        ---Handles value accumulation and control flow wrapping
        ---@param node table AST node to process
        ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function
        ---@param shouldInitAccumulator boolean Whether an accumulator variable should be initialized
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function
        ---@return table List of generated code lines
        local function transpileChildren (node, wrapInFunction, shouldInitAccumulator, forceReturn)

            if #node.children == 0 then
                if contains("LIST_ITEM HASH_ITEM TEXT VALUE RETURN ", node.kind) then
                    return {'""'}
                elseif contains("ASSIGNMENT LOCAL_ASSIGNMENT", node.kind) then
                    return
                end
            end

            local infos, onlyValues, valueCount = parseChildren(node)

            if onlyValues and shouldInitAccumulator then
                return transpileChildrenOnlyValuesCase(node, infos, valueCount, forceReturn)
            else
                return transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)
            end        
        end

        ---Handles macro definition transpilation
        ---@param node table The macro definition node
        ---@param islocal boolean Whether this is a local macro
        ---@param addNewline boolean Whether to add a newline at the beginning
        ---@return table Transpiled Lua code fragments
        local function handleMacroDefinition (node, islocal, addNewline)

            local parameters = node.children[1]
            local body       = node.children[2]
        
            local parametersList = {}
            local parametersHash =  {}

            for _, param in ipairs(parameters.children) do
                if param.kind == "LIST_ITEM" then
                    table.insert(parametersList, param.children[1].content)

                else
                    table.insert(parametersList, param.content)
                    table.insert(parametersHash, param)
                end
            end

            local result = {}
            
            if addNewline then
                insert(result, newline())
            end

            use(node)

            if islocal then
                insert(result, "local ")
            end

            if node.content and #node.content > 0 then
                insert(result, node.content)
                insert(result, " = ")
            end

            insert(result, "function (")
            for i, argName in ipairs(parametersList) do
                insert(result, argName)
                if i < #parametersList then
                    insert(result, ", ")
                end
            end
            insert(result, ")")

            if #parametersHash > 0 then
                for _, param in ipairs(parametersHash) do
                    insertAll(result, {
                        newline(),
                        "if ", param.content, " == nil then",
                        newline(),
                        param.content, " = "
                    })

                    insertAll(result, transpileChildren(param, false, true, false))
                    insert(result, newline())
                    insert(result, "end")
                end
            end

            insertAll(result, transpileChildren (body, false, true, true))
            insert(result, newline())
            insert(result, "end")

            if node.content and #node.content > 0 then
                insert(result, newline())
                insert(result, "plume.store.f[")
                insert(result, node.content)
                insert(result, "] = {")
                insert(result, newline())
                insert(result, "pos = {")
                for i, param in ipairs(parameters.children) do
                    if param.kind == "HASH_ITEM" then
                        insert(result, newline())
                        insert(result, param.content)
                        insert(result, " = ")
                        insert(result, i)
                        insert(result, ", ")
                    end
                end
                if #parameters.children > 0 then
                    insert(result, newline())
                end
                insert(result, "},")
                insert(result, newline())
                insert(result, "n = ")
                insert(result, #parametersList)
                insert(result, newline())
                insert(result, "}")
            end
            

            return result
        end

        ---Handles macro call without extended arguments
        ---@param node table The macro call node
        ---@return table Transpiled Lua code fragments
        local function handleMacroCallWithoutExtension(node)
            local result = {}
            argList = node.children[1].children
            
            insert(result, newline())
            for index, arg in ipairs(argList) do
                insertAll(result, transpileToLua(arg))

                if index < #argList then
                    insert(result, ",")
                    insert(result, newline())
                end
            end

            insert(result, newline())
            insert(result, ")")

            return result
        end

        ---Handles macro arguments, supporting both positional and named parameters
        ---@param node table The macro call node
        ---@param argList table List of arguments to process
        ---@return table Transpiled Lua code fragments
        local function handleMacroArguments(node, argList)
            local result = {}

            insert(result, newline())
            insert(result, "(function ()")
                insert(result, newline())
                insert(result, "local __plume_args = {}")
                insert(result, newline())
                insert(result, "local __plume_infos = plume:getFunctionInfo(")
                insert(result, node.content)
                insert(result, ")")

                for i, arg in ipairs(argList) do
                    if arg.kind == "LIST_ITEM" or arg.kind == "TEXT" then
                        insert(result, newline())
                        insert(result, "__plume_args[")
                        insert(result, i)
                        insert(result, "] = ")
                        insertAll(result, transpileToLua(arg))
                    else
                        insert(result, newline())
                        insert(result, "__plume_args[__plume_infos.pos.")
                        insert(result, arg.content)
                        insert(result, "] = ")

                        if arg.kind == "HASH_ITEM" then
                            insertAll(result, transpileChildren(arg, false, true))
                        else
                            insertAll(result, transpileToLua(arg))
                        end
                    end
                end

            insert(result, newline())
            insert(result, "return __plume_unpack(__plume_args, 1, __plume_infos.n)")
            insert(result, newline())
            insert(result, "end)()")
            insert(result, newline())
            insert(result, ")")

            return result
        end

        -- AST node type to handler mapping
        local tokenHandlers = {
            ---Handles block nodes, which contain multiple statements
            ---@param node table The block node to process
            BLOCK = function (node)
                use(node)
                local mainBlock = (node.indent or 0) >= 0
                local result = transpileChildren (node, mainBlock, true, true)

                return result
            end,

            ---Handles macro calls, processing both inline and extended arguments
            ---@param node table The macro call node to process
            MACRO_CALL = function (node)
                local inlineArgs   = node.children[1]
                local extendedArgs = node.children[2] or {children={}}
                use(node)
                local result = {node.content, "("}
                local argList = {}

                insertAll(argList, inlineArgs.children)
                insertAll(argList, extendedArgs.children)

                if #extendedArgs.children == 0 and #inlineArgs.children == 0 then
                    insert(result, ")")
                else
                    insertAll(result, handleMacroArguments(node, argList))
                end
                
                return result
            end,

            ---Handles variable assignment
            ---@param node table The assignment node to process
            ASSIGNMENT = function (node)
                local result = {newline(), node.content, " = "}
                use(node)

                local value = transpileChildren (node, true, true)

                if value then
                    insertAll(result, value)
                else
                    insert(result, "nil")
                end

                return result
            end,

            ---Handles local variable assignment
            ---@param node table The local assignment node to process
            LOCAL_ASSIGNMENT = function (node)
                local result = {newline(), "local ", node.content}
                use(node)

                local value = transpileChildren (node, true, true)

                if value then
                    insert(result, " = ")
                    insertAll(result, value)
                end

                return result
            end,

            ---Handles macro definition
            ---@param node table The macro definition node to process
            MACRO_DEFINITION = function (node)
                return handleMacroDefinition(node, false, true)
            end,

            ---Handles inline macro definition
            ---@param node table The inline macro definition node to process
            INLINE_MACRO_DEFINITION = function (node)
                return handleMacroDefinition(node)
            end,

            ---Handles list items (positional arguments/parameters)
            ---@param node table The list item node to process
            LIST_ITEM = function (node)
                use(node)
                return transpileChildren (node, true, true)
            end,

            ---Handles hash items (named arguments/parameters)
            ---@param node table The hash item node to process
            HASH_ITEM = function (node)
                local result = {node.content, " = "}
                use(node)
                insertAll(result, transpileChildren (node, true, true))
                return result
            end,

            ---Handles return statements
            ---@param node table The return node to process
            RETURN = function (node)
                local result = {newline(), "return "}
                use(node)
                insertAll(result, transpileChildren (node, true, true))
                return result
            end,

            ---Handles for loops
            ---@param node table The for loop node to process
            FOR = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"for", node.content, " do"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

            ---Handles while loops
            ---@param node table The while loop node to process
            WHILE = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"while", node.content, " do"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

            ---Handles if statements
            ---@param node table The if statement node to process
            IF = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"if", node.content, " then"})
                insertAll(result, transpileChildren (node, false, false))
                if not node.noend then
                    insert(result, newline())
                    insert(result, "end")
                end
                return result
            end,

            ---Handles elseif statements
            ---@param node table The elseif statement node to process
            ELSEIF = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"elseif", node.content, " then"})
                insertAll(result, transpileChildren (node, false, false))
                if not node.noend then
                    insert(result, newline())
                    insert(result, "end")
                end
                return result
            end,

            ---Handles else statements
            ---@param node table The else statement node to process
            ELSE = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"else"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

            ---Handles break statements
            ---@param node table The break statement node to process
            BREAK = function (node)
                local result = {newline()}
                use(node)
                insert(result, "break")
                return result
            end,

            ---Handles text literals
            ---@param node table The text node to process
            TEXT = function (node)
                use(node)
                if tonumber(node.content) then
                    return {node.content}
                else
                    return {'"', node.content:gsub('"', '\\"'), '"'}
                end
            end,

            ---Handles variable references
            ---@param node table The variable node to process
            VARIABLE = function (node)
                use(node)
                return {node.content}
            end,

            ---Handles raw Lua expressions
            ---@param node table The Lua expression node to process
            LUA_EXPRESSION = function (node)
                use(node)
                if #node.content > 0 then
                    -- Parenthesis force Lua to give the
                    -- good error message in cas of syntax error
                    return {"(", node.content, ")"}
                else
                    return {"nil"}
                end
            end
        }
    
        ---Main transpilation function for individual AST nodes
        ---@param ast table AST node to transpile
        ---@return table Transpiled code fragments
        function transpileToLua(ast)
            if tokenHandlers[ast.kind] then
                return tokenHandlers[ast.kind](ast)
            else
                error("NIY " .. (ast.kind or "???"))
            end
        end

        local result = {"local __plume_concat = table.concat"}

        insert(result, newline())
        if contains("5.1 JIT", luaVersion) then
            insert(result, "local __plume_unpack = unpack")
        else
            insert(result, "local __plume_unpack = table.unpack")
        end

        insertAll(result, transpileToLua(ast))
        return table.concat(result), map
    end
end