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

    local INITIAL_DECLARATION = "local __plume_concat = table.concat\n"

    local contains           = plume.utils.containsWord
    local STATEMENTS         = "FOR ASSIGNMENT LOCAL_ASSIGNMENT IF ELSE ELSEIF WHILE MACRO LOCAL_MACRO RETURN VOID"

    ---Main transpilation entry point
    plume.transpileToLua = function(ast)

        local map = {{}}

        local function newline ()
            table.insert(map, {})
            return "\n"
        end

        local function countStaticExpressions (node)
            local staticExpressionCount = 0
            for _, child in ipairs(node.children) do
                if not contains(STATEMENTS, child.kind) then
                    staticExpressionCount = staticExpressionCount + 1
                end
            end
            return staticExpressionCount
        end

        local function parseChildren (node)
            local result = {}

            local onlyValues      = true
            local firstValueFound = false
            local valueCount = 0
            local acc        = {}

            for _, child in ipairs(node.children) do
                local isStatement = contains(STATEMENTS, child.kind)
                local content = plume.transpileToLua(child)

                if child.returnType == "NIL" or isStatement then
                    onlyValues = false

                    if not firstValueFound then
                        if #acc > 0 or isStatement then
                            table.insert(result, {store=true, kind="nodeList", content=acc})
                            firstValueFound = true
                        end
                    end

                    table.insert(result, {store=false, kind="node", content=content})
                elseif not firstValueFound then
                    valueCount = valueCount+1
                    table.insert(acc, content)
                else
                    valueCount = valueCount+1
                    table.insert(result, {store=true, kind="node", content=content})
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

        ---Transpiles child nodes of an AST element into executable Lua code
        ---Handles value accumulation and control flow wrapping
        ---@param node AST node to process
        ---@param wrapInFunction Whether to wrap in IIFE for scope isolation
        ---@param shouldInitAccumulator Whether to create temporary value storage
        ---@param forceReturn Whether to force return statement at end
        ---@return table List of generated code lines
        local function transpileChildren (node, wrapInFunction, shouldInitAccumulator, forceReturn)
            local infos, onlyValues, valueCount = parseChildren(node)

            if onlyValues and shouldInitAccumulator then
                local result = {}
                local wrapInTable  = (node.returnType == "TABLE") or valueCount>2
                local concat       = (node.returnType == "TEXT") and valueCount>2
                local directConcat = (node.returnType == "TEXT") and valueCount==2

                if forceReturn then
                    table.insert(result, newline())
                    table.insert(result, "return ")
                end

                 if concat then
                    table.insert(result, "__plume_concat ")
                end

                if wrapInTable then
                    table.insert(result, "{")
                end

                local sep
                if directConcat then
                    sep = " .. "
                else
                    sep = ", "
                end

                table.insert(result, newline())
                for i, content in ipairs(infos[1].content) do
                    table.insert(result, content)
                    if i < #infos[1].content then
                        table.insert(result, sep)
                    end
                    table.insert(result, newline())
                end

                if wrapInTable then
                    table.insert(result, newline())
                    table.insert(result, "}")
                end

                return result
            else
                local result = {}

                if wrapInFunction then
                    table.insert(result, "(function()")
                end

                local firstValueFound = false
                local alreadyReturn   = false
                for index, info in ipairs(infos) do

                    if info.store then
                        local values = info.content
                        if info.kind == "node" then
                            values = {values}
                        end

                        if valueCount == 1 and shouldInitAccumulator and #values>0 then

                            local value = values[1]

                            if node.returnType == "TABLE" then
                                value = "\n{\n" .. value .. "\n}\n"
                            end

                            if index == #infos then
                                alreadyReturn = true
                                table.insert(result, "\nreturn " .. value)
                            else
                                table.insert(result, "\nlocal __plume_temp = " .. value)
                            end
                        else
                            if firstValueFound or (not shouldInitAccumulator) then
                                for _, value in ipairs(values) do
                                    table.insert(result, "\ntable.insert(__plume_temp, " .. value .. ")")
                                end
                            elseif #values > 0 then
                                firstValueFound = true
                                table.insert(result,
                                    "\nlocal __plume_temp = {\n"
                                        .. table.concat(values, ",\n")
                                    .. "\n}")
                            else
                                firstValueFound = true
                                table.insert(result, "\nlocal __plume_temp = {}")
                            end
                        
                        end
                    else
                        table.insert(result, "\n"..info.content)
                    end
                end

                if (wrapInFunction or forceReturn) and not alreadyReturn then
                    if node.returnType == "TEXT" and (valueCount ~= 1 or not shouldInitAccumulator) then
                        table.insert(result, newline())
                        table.insert(result, "return __plume_concat (__plume_temp)")
                    elseif node.returnType ~= "NIL" and node.returnType ~= "VALUE" then
                        table.insert(result, newline())
                        table.insert(result, "return __plume_temp")
                    end
                end

                if wrapInFunction then
                    table.insert(result, newline())
                    table.insert(result, "end)()")
                end

                return result
            end        
        end

        local function handlerMACRO (node, islocal)
            local parameters = node.children[1]
            local body       = node.children[2]
            local result = transpileChildren (body, false, true, true)

            local paramList = {}

            for _, child in ipairs(parameters.children) do
                if child.kind == "LIST_ITEM" then
                    table.insert(result, newline())
                    table.insert(paramList, child.content)
                end
            end

            result = "\nfunction (".. table.concat(paramList, ", ") ..")\n"
                ..table.concat(result, "\n")
            .. "\nend"

            if islocal then
                return "\nlocal " .. node.content.." = " .. result
            elseif node.content and #node.content > 0 then
                return "\n"..node.content.." = " .. result
            else
                return result
            end
        end

        -- AST node type to handler mapping
        local tokenHandlers = {
            BLOCK = function (node)
                local mainBlock = (node.indent or 0) >= 0
                local result = transpileChildren (node, mainBlock, true, true)
                result = table.concat(result, "")

                if not mainBlock then
                    result = INITIAL_DECLARATION .. result
                end

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
                    return node.content .. "()"
                elseif not extendedArgs then
                    local result = transpileChildren (inlineArgs, true, true)
                    result = table.concat(result, "\n")
                    return node.content .. "(unpack(\n" .. result .. "\n))"
                elseif not inlineArgs then
                    if extendedArgs.returnType == "TABLE" then
                        local result = transpileChildren (extendedArgs, true, true)
                        result = table.concat(result, "\n")
                        return node.content .. "(unpack(\n" .. result .. "\n))"
                    else
                        local result = transpileChildren (extendedArgs, true, true)
                        result = table.concat(result, "\n")
                        return node.content .. "(\n" .. result .. "\n)"
                    end
                else
                    local inline   = table.concat(transpileChildren (inlineArgs, true, true), "\n")
                    local extended = table.concat(transpileChildren (extendedArgs, true, true), "\n")

                    if extendedArgs.returnType == "TEXT" then
                        extended = "\n{\n" .. extended .. "\n}\n"
                    end

                    return node.content .. "(unpack(\nplume.table.merge(\n" .. inline .. ",\n" .. extended .. "\n)\n))"
                    
                end
            end,

            ASSIGNMENT = function (node)
                local result = transpileChildren (node, true, true)

                return node.content.." = " .. table.concat(result, "")
            end,

            LOCAL_ASSIGNMENT = function (node)
                local result = transpileChildren (node, true, true)
                return "local " .. node.content.." = " .. table.concat(result, "")
            end,

            -- VOID = function (node)
            --     local result = transpileChildren (node, true, true)

            --     return "__plume_void = " .. table.concat(result, "\n")
            -- end,

            MACRO = function (node)
                return handlerMACRO(node)
            end,

            LOCAL_MACRO = function (node)
                return handlerMACRO(node, true)
            end,

            INLINE_MACRO = function (node)
                return handlerMACRO(node)
            end,

            LIST_ITEM = function (node)
                local result = transpileChildren (node, true, true)
                return table.concat(result, "")
            end,

            HASH_ITEM = function (node)
                local result = transpileChildren (node, true, true)
                return node.content .. " = " .. table.concat(result, "")
            end,

            RETURN = function (node)
                local result = transpileChildren (node, true, true)
                return "return " .. table.concat(result, "")
            end,

            FOR = function (node)
                local result = transpileChildren (node, false, false)

                table.insert(result, 1, "for" .. node.content .. " do")
                table.insert(result, "end")

                return table.concat(result, "\n")
            end,

            IF = function (node)
                local result = transpileChildren (node, false, false)

                table.insert(result, 1, "if" .. node.content .. " then")

                if not node.noend then
                    table.insert(result, "end")
                end

                return table.concat(result, "")
            end,

            ELSEIF = function (node)
                local result = transpileChildren (node, false, false)

                table.insert(result, 1, "elseif" .. node.content .. " then")

                if not node.noend then
                    table.insert(result, "end")
                end

                return table.concat(result, "")
            end,

            ELSE = function (node)
                local result = transpileChildren (node, false, false)

                table.insert(result, 1, "else")
                table.insert(result, "end")

                return table.concat(result, "")
            end,

            TEXT = function (node)
                if tonumber(node.content) then
                    return node.content
                else
                    return '"' .. node.content:gsub('"', '\\"') .. '"'
                end
            end,

            VARIABLE = function (node)
                return node.content
            end,

            LUA_EXPRESSION = function (node)
                return node.content
            end
        }

    
        local function transpileToLua(ast)
            if tokenHandlers[ast.kind] then
                return tokenHandlers[ast.kind](ast)
            else
                error("NIY " .. ast.kind)
            end
        end

        return transpileToLua(ast)
    end
end