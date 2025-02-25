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

    local contains           = plume.utils.containsWord
    local STATEMENTS         = "FOR ASSIGNMENT LOCAL_ASSIGNMENT IF ELSE ELSEIF WHILE MACRO LOCAL_MACRO RETURN BREAK"

    local transpileToLua

    ---Main transpilation entry point
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

        --- Transpiles a node's children, handling different return types and value counts.
        -- @param node The node whose children are being transpiled.
        -- @param infos Table containing information about the node's children.
        -- @param valueCount The number of values being returned by the children.
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function.
        -- @return A table containing the generated Lua code snippets.
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
                insertAll(result, transpileToLua(content))
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
                elseif node.returnType ~= "NIL" and node.returnType ~= "VALUE" then
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
        ---@param node AST node to process
        ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function.
        ---@param shouldInitAccumulator boolean Whether an accumulator variable should be initialized.
        ---@param forceReturn boolean Whether to force a return statement even if not wrapped in a function.
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


        local function handlerMACRO (node, islocal, addNewline)
            local parameters = node.children[1]
            local body       = node.children[2]

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
            for i, child in ipairs(parameters.children) do
                if child.kind == "LIST_ITEM" then
                    table.insert(result, child.content)
                    if i < #parameters.children then
                        table.insert(result, ",")
                    end
                end
            end
            insert(result, ")")
            insertAll(result, transpileChildren (body, false, true, true))
            insert(result, newline())
            insert(result, "end")

            return result
        end

        -- AST node type to handler mapping
        local tokenHandlers = {
            BLOCK = function (node)
                use(node)
                local mainBlock = (node.indent or 0) >= 0
                local result = transpileChildren (node, mainBlock, true, true)

                return result
            end,

            MACRO_CALL = function (node)
                local inlineArgs   = node.children[1]
                local extendedArgs = node.children[2]

                if #inlineArgs.children==0 then
                    inlineArgs = nil
                end

                if extendedArgs and #extendedArgs.children==0 then
                    extendedArgs = nil
                end

                if not inlineArgs and not extendedArgs then
                    return {node.content, "()"}
                elseif not extendedArgs then
                    local result = {node.content, "(__plume_unpack("}
                    insert(result, newline())
                    insertAll(result, transpileChildren (inlineArgs, true, true))
                    insert(result, newline())
                    insert(result, "))")
                    return result
                elseif not inlineArgs then
                    if extendedArgs.returnType == "TABLE" then
                        local result = {node.content, "(__plume_unpack(", newline()}
                        insertAll(result, transpileChildren (extendedArgs, true, true))
                        insert(result, newline())
                        insert(result, "))")
                        return result
                    else
                        local result = {node.content, "(", newline()}
                        insertAll(result, transpileChildren (extendedArgs, true, true))
                        insert(result, newline())
                        insert(result, ")")
                        return result
                    end
                else
                    local inline   = transpileChildren (inlineArgs, true, true)
                    local extended = transpileChildren (extendedArgs, true, true)

                    local result = {newline(), node.content, "(__plume_unpack("}
                    insert(result, newline())
                    insert(result, "plume.table.merge(")
                    insert(result, newline())
                    insertAll(result, inline)
                    insert(result, ",")
                    insert(result, newline())
                    if extendedArgs.returnType == "TEXT" then
                        insert(result, "{")
                    end
                    insertAll(result, extended)
                    if extendedArgs.returnType == "TEXT" then
                        insert(result, newline())
                        insert(result, "}")
                    end

                    insert(result, newline())
                    insert(result, ")")
                    insert(result, newline())
                    insert(result, "))")

                    return  result
                    
                end
            end,

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

            -- VOID = function (node)
            --     local result = transpileChildren (node, true, true)

            --     return "__plume_void = " .. table.concat(result, "\n")
            -- end,

            MACRO = function (node)
                return handlerMACRO(node, false, true)
            end,

            LOCAL_MACRO = function (node)
                return handlerMACRO(node, true, true)
            end,

            INLINE_MACRO = function (node)
                return handlerMACRO(node)
            end,

            LIST_ITEM = function (node)
                use(node)
                return transpileChildren (node, true, true)
            end,

            HASH_ITEM = function (node)
                local result = {node.content, " = "}
                use(node)
                insertAll(result, transpileChildren (node, true, true))
                return result
            end,

            RETURN = function (node)
                local result = {newline(), "return "}
                use(node)
                insertAll(result, transpileChildren (node, true, true))
                return result
            end,

            FOR = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"for", node.content, " do"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

            WHILE = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"while", node.content, " do"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

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

            ELSE = function (node)
                local result = {newline()}
                use(node)
                insertAll(result, {"else"})
                insertAll(result, transpileChildren (node, false, false))
                insert(result, newline())
                insert(result, "end")
                return result
            end,

            BREAK = function (node)
                local result = {newline()}
                use(node)
                insert(result, "break")
                return result
            end,

            TEXT = function (node)
                use(node)
                if tonumber(node.content) then
                    return {node.content}
                else
                    return {'"', node.content:gsub('"', '\\"'), '"'}
                end
            end,

            VARIABLE = function (node)
                use(node)
                return {node.content}
            end,

            LUA_EXPRESSION = function (node)
                use(node)
                if #node.content > 0 then
                    return {node.content}
                else
                    return {"nil"}
                end
            end
        }

    
        function transpileToLua(ast)
            if tokenHandlers[ast.kind] then
                return tokenHandlers[ast.kind](ast)
            else
                error("NIY " .. ast.kind)
            end
        end

        local result = {"local __plume_concat = table.concat"}

        table.insert(result, newline())
        if contains("5.1 JIT", luaVersion) then
            table.insert(result, "local __plume_unpack = unpack")
        else
            table.insert(result, "local __plume_unpack = table.unpack")
        end

        insertAll(result, transpileToLua(ast))
        return table.concat(result), map
    end
end