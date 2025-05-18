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

--- Registers AST node handlers for the transpiler.
-- @param plume table The Plume runtime object.
-- @param transpiler table The transpiler instance.
-- @return nil
return function(plume, transpiler)
    function transpiler.getVariableName(node)
        local name = node.content
        for _, index in ipairs(node.sourceToken.index or {}) do
            if index.kind == "INDEX_ACCESS" then
                name = name
                    .. "["
                        .. transpiler.editLuaCode(index.content)
                    .. "]"
            elseif index.kind == "FIELD_ACCESS" then
                name = name .. "." .. index.content
            end
        end
        return name
    end

    local function handleMacroCall(node)
        local name = transpiler.getVariableName(node)
        -- Check for "method call" syntax (e.g., table.method) to correctly handle 'self'.
        local tableName, methodName = name:match("^(.-)%.([^%.]+)$")

        local inlineArgs   = node.children[1]
        local extendedArgs = node.children[2] or {children={}} -- Extended arguments are optional.
        local argList = {}

        -- Combine inline and extended arguments into a single list.
        plume.insertAll(argList, inlineArgs.children)
        if extendedArgs.returnType == "TABLE" then
            plume.insertAll(argList, extendedArgs.children)
        elseif extendedArgs.returnType == "TEXT" then
            table.insert(argList, {
                kind="LIST_ITEM",
                children=extendedArgs.children,
                returnType="TEXT"
            })
        end

        -- Check for several argument with the same name
        local names = {}
        for _, arg in ipairs(argList) do
            if arg.kind == "HASH_ITEM" then
                if names[arg.content] then
                    plume.multipleArgumentSameName (node.sourceToken.source, arg.content)
                else
                    names[arg.content] = true
                end
            end
        end

        transpiler:emitCALL(node, name)
        if #extendedArgs.children == 0 and #inlineArgs.children == 0 then
            -- If there are no arguments, emit empty parentheses,
            -- or specific handling if it's a table method call likely expecting no explicit args.
            transpiler:emitEMPTY_ARGS(tableName)
        else
            if tableName then
                -- If it's a method call (e.g., myTable.myMethod() ),
                -- add 'self = tableName' as a named argument.
                table.insert(argList, {
                    kind = "HASH_ITEM", content = "self",
                    children = {
                        {kind = "VARIABLE", content = tableName, sourceToken = {}}
                    }
                })
            end
            transpiler:write('(')
            -- Transpile the combined arguments, typically as a list of expressions or a table structure.
            transpiler.transpileChildren({kind="TABLE", children=argList, returnType="TABLE"}, true, true)
            transpiler:write(')')
        end
    end

    -- Table mapping AST node types to handler functions.
    transpiler.tokenHandlers = {
        --- Handles block nodes, which contain multiple statements.
        -- @param node table The block node to process.
        -- @return nil
        BLOCK = function (node)
            -- Check if this is the main block or a nested block.
            -- mainBlock influences how children are transpiled (e.g., statement separation).
            local mainBlock = (node.indent or 0) >= 0
            transpiler.transpileChildren(node, mainBlock, true, true)
        end,

        --- Handles macro calls, processing both inline and extended arguments.
        -- @param node table The macro call node to process.
        -- @return nil
        MACRO_CALL = function (node)
            handleMacroCall(node)
        end,

        COMMAND_EXPAND_LIST_CALL = function (node)
            handleMacroCall(node)
        end,

        COMMAND_EXPAND_HASH_CALL = function (node)
            handleMacroCall(node)
        end,

        --- Handles variable assignment, including table indexing and global assignment.
        -- @param node table The assignment node to process.
        -- @return nil
        ASSIGNMENT = function (node)
            local varName = node.content -- The name of the variable being assigned to.
            local targetVariable

            if node.sourceToken.eval then
                -- If node.sourceToken.eval is true, assign to the global table _G
                -- using varName as a key.
                targetVariable = "_G[" .. varName .. "]"
            else
                targetVariable = varName
            end

            if node.sourceToken.index then
                targetVariable = targetVariable .. "[" .. transpiler.editLuaCode(node.sourceToken.index) .. "]"
            end

            -- false indicates a global assignment.
            transpiler:emitASSIGNMENT(node, targetVariable, node.sourceToken.compound_operator, false, true)

            if #node.children > 0 then
                -- Transpile the value being assigned.
                transpiler.transpileChildren(node, true, true)
            else
                -- If there's no explicit value (e.g., "myVar=" in Plume), default to assigning an empty string.
                transpiler:write('""')
            end
        end,

        --- Handles local variable assignment, including indexed cases.
        -- @param node table The local assignment node to process.
        -- @return nil
        LOCAL_ASSIGNMENT = function (node)
            local targetVariable
            if node.sourceToken.index then
                targetVariable = node.content .. "[" .. transpiler.editLuaCode(node.sourceToken.index) .. "]"
            else
                targetVariable = node.content
            end

            -- true indicates a local assignment.
            transpiler:emitASSIGNMENT(node, targetVariable, node.sourceToken.compound_operator, true)

            if #node.children > 0 then
                -- Transpile the value being assigned.
                transpiler.transpileChildren(node, true, true)
            else
                -- If there's no explicit value (e.g., "local myVar="), default to assigning an empty string.
                transpiler:write('""')
            end
        end,

        --- Handles macro definitions (block or statement macros).
        -- @param node table The macro definition node to process.
        -- @return nil
        MACRO_DEFINITION = function (node)
            transpiler.handleMacroDefinition(node)
        end,

        --- Handles inline macro definitions.
        -- @param node table The inline macro definition node to process.
        -- @return nil
        INLINE_MACRO_DEFINITION = function (node)
            transpiler.handleMacroDefinition(node, false, true)
        end,

        --- Handles list items, typically representing positional arguments in a call or parameters in a definition.
        -- @param node table The list item node to process.
        -- @return nil
        LIST_ITEM = function (node)
            transpiler:use(node)
            transpiler.transpileChildren(node, true, true)
        end,

        --- Handles hash items, typically representing named arguments in a call or key-value pairs.
        -- @param node table The hash item node to process.
        -- @return nil
        HASH_ITEM = function (node)
            local name = node.content -- This is the key of the hash item.

            if node.sourceToken and node.sourceToken.eval then
                name = "[" .. transpiler.editLuaCode(name) .. "]"
            end
            
            -- emitASSIGNMENT here emits "[key_expr] = ".
            transpiler:emitASSIGNMENT(node, name) 
            -- Transpile the children of the hash item, which represent its value.
            transpiler.transpileChildren(node, true, true)
        end,

        --- Handles return statements.
        -- @param node table The return node to process.
        -- @return nil
        RETURN = function (node)
            -- Plume's return statements use a temporary variable '__plume_temp' to break tailcall.
            transpiler:emitASSIGNMENT(nil, "__plume_temp", nil, true) -- true for local

            -- A RETURN node is expected to have one child (e.g., a BLOCK or expression container).
            if node.children[1] and #node.children[1].content > 0 then
                transpiler:use(node)
                transpiler.transpileChildren(node, true, true)
            else
                -- If there's no explicit return value (e.g. `return` on its own, or an "empty" expression),
                -- __plume_temp is assigned nil.
                transpiler:write('nil')
            end

            transpiler:emitRETURN()
            transpiler:write("__plume_temp")
        end,

        --- Handles 'for' loops.
        -- @param node table The for loop node to process.
        -- @return nil
        FOR = function (node)
            -- node.content contains the Plume code for the loop's iterator part (e.g., "i = 1, 10" or "k, v in pairs(t)").
            transpiler:emitFOR(node, transpiler.editLuaCode(node.content))
            -- Transpile the body of the loop.
            transpiler.transpileChildren(node, false, false)
            transpiler:emitEND()
        end,

        --- Handles 'while' loops.
        -- @param node table The while loop node to process.
        -- @return nil
        WHILE = function (node)
            transpiler:emitWHILE(node, transpiler.editLuaCode(node.content))
            -- Transpile the body of the loop.
            transpiler.transpileChildren(node, false, false)
            transpiler:emitEND() -- Emits 'end' for the loop.
        end,

        --- Handles 'if' statements.
        -- @param node table The if statement node to process.
        -- @return nil
        IF = function (node)
            transpiler:emitIF(node, transpiler.editLuaCode(node.content))
            -- Transpile the body of the if block.
            transpiler.transpileChildren(node, false, false)
            if not node.noend then
                transpiler:emitEND()
            end
        end,

        --- Handles 'elseif' statements. The condition is Plume code.
        -- @param node table The elseif statement node to process.
        -- @return nil
        ELSEIF = function (node)
            transpiler:emitELSEIF(node, transpiler.editLuaCode(node.content))
            -- Transpile the body of the elseif block.
            transpiler.transpileChildren(node, false, false)
            if not node.noend then
                transpiler:emitEND()
            end
        end,

        --- Handles 'else' statements.
        -- @param node table The else statement node to process.
        -- @return nil
        ELSE = function (node)
            transpiler:emitELSE() -- Emits 'else'.
            -- Transpile the body of the else block.
            transpiler.transpileChildren(node, false, false)
            transpiler:emitEND()
        end,

        -- Not very optimized
        VOID = function (node)
            transpiler:newline()
            -- add ';' avoid ambiguous syntax in situation like
            -- `a = bar (function () ... end)`
            transpiler:emitOPEN(';(function ()') 
            transpiler:newline()
            transpiler.transpileChildren(node, false, true, true)
            transpiler:emitCLOSE('end)()')
        end,

        --- Handles 'break' statements.
        -- @param node table The break statement node to process.
        -- @return nil
        BREAK = function (node)
            transpiler:emitBREAK()
        end,

        --- Handles text literals, typically transpiled into Lua string literals.
        -- @param node table The text node to process.
        -- @return nil
        TEXT = function (node)
            -- tonumber(" 1") return 1
            if tonumber(node.content) and not node.content:match('%s') then
                transpiler:insert(node.content)
            else
                transpiler:emitTEXT(node, node.content)
            end
        end,

        --- Handles variable references, including indexed access.
        -- @param node table The variable node to process.
        -- @return nil
        VARIABLE = function (node)
            local variableExpression = transpiler.getVariableName(node)

            transpiler:emitVARIABLE(node, variableExpression) 
        end,

        --- Handles raw Lua expressions embedded in Plume code.
        -- @param node table The Lua expression node to process.
        -- @return nil
        LUA_EXPRESSION = function (node)
            transpiler:use(node)
            transpiler:emitLUA(node, transpiler.editLuaCode(node.content))
        end
    }
end
