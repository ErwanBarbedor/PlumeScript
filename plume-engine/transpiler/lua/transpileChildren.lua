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

return function(plume, transpiler)
    local contains   = plume.utils.containsWord
    -- A string containing all statement kinds, used to differentiate them from expressions.
    local STATEMENTS = "VOID FOR ASSIGNMENT LOCAL_ASSIGNMENT IF ELSE ELSEIF WHILE MACRO LOCAL_MACRO RETURN BREAK COMMAND_EXPAND COMMAND_EXPAND_CALL"

    ---Parses the children of a given node, categorizing them into lists of values or individual statements.
    ---This helps in deciding how to transpile them, especially when mixing values and statements.
    ---@param node table The node whose children are to be parsed.
    ---@return table result A table containing the parsed children. Each element is a table with:
    ---                      `store` (boolean): true if it's a value/list of values to be potentially stored.
    ---                      `kind` (string): "nodeList" for a list of value nodes, "node" for a single node.
    ---                      `content` (table): The actual node or list of nodes.
    ---@return boolean onlyValues True if all children are value-producing expressions, false otherwise.
    ---@return number valueCount The number of value children if `onlyValues` is true and no control structures are present.
    ---                        Returns -1 if counting is disabled (e.g., inside control structures where return count is complex).
    function transpiler.parseChildren (node)
        local result = {}

        -- Flag: true if all children encountered so far are values.
        local onlyValues      = true  
        -- Flag: true after the first sequence of values has been processed or a statement is encountered.
        -- This helps separate initial value sequences from subsequent ones.
        local firstValueFound = false 
                                    
        -- Counts consecutive value nodes, reset if a statement is found or counting is disabled.
        local valueCount = 0
        -- Accumulator for consecutive value nodes before a statement or end of children.      
        local acc        = {}

        for _, child in ipairs(node.children) do
            local isStatement = contains(STATEMENTS, child.kind)
            -- A child is considered a non-value if it's a statement or returns NIL.
            if child.returnType == "NIL" or isStatement then
                -- If we encounter a statement or a NIL-returning child, not all children are simple values.
                onlyValues = false

                -- If we haven't processed the first group of values yet (or any values at all)
                if not firstValueFound then
                    -- If there are accumulated values or the current child itself is a statement (meaning no preceding values),
                    -- package the accumulated values (if any) into a nodeList.
                    if #acc > 0 or isStatement then
                        table.insert(result, {store=true, kind="nodeList", content=acc})
                        firstValueFound = true -- Mark that the initial value processing phase is over.
                    end
                end

                -- Add the current statement/NIL-returning child as a non-storable node.
                table.insert(result, {store=false, kind="node", content=child})

                -- Cannot reliably count return values when control structures are involved,
                -- as their execution path can vary. valueCount = -1 signifies this.
                if contains("IF ELSEIF ELSE FOR WHILE COMMAND_EXPAND COMMAND_EXPAND_CALL", child.kind) then
                    valueCount = -1
                end

            -- If the child is a value and we are still in the initial sequence of values
            elseif not firstValueFound then
                if valueCount ~= -1 then -- Only count if counting is not disabled
                    valueCount = valueCount+1
                end
                table.insert(acc, child) -- Accumulate this value node.
            -- If the child is a value, but we've already passed the initial sequence (or a statement)
            else
                if valueCount ~= -1 then
                    valueCount = valueCount+1
                end
                -- Add this value node directly to the result, as it's a standalone value after a statement.
                table.insert(result, {store=true, kind="node", content=child})
            end
        end

        -- After iterating through all children, if we haven't "finalized" the first group of values
        -- (meaning all children were values), package the accumulator.
        if not firstValueFound then
            if #acc > 0 then
                table.insert(result, {store=true, kind="nodeList", content=acc})
            end
        end

        -- If the result is empty (e.g., an empty block), it's not "only values".
        if #result == 0 then
            onlyValues = false
        end

        return result, onlyValues, valueCount
    end

    --- Transpiles a node's children when they only contain values.
    ---@param node table The node whose children are being transpiled.
    ---@param infos table Information about the node's children .
    ---@param valueCount number Number of values being returned by the children.
    ---@param forceReturn boolean Whether to force a Lua `return` statement.
    function transpiler.transpileChildrenOnlyValuesCase(node, infos, valueCount, forceReturn)
        -- Determine how to format the output based on the node's expected return type and value count.
        -- Wrap multiple values in a table, or if explicitly a TABLE.
        local wrapInTable  = (node.returnType == "TABLE") or valueCount > 2
        -- Concatenate multiple text values using a helper. 
        local concat       = (node.returnType == "TEXT") and valueCount > 2
        -- Directly concatenate two text values with `..`.
        local directConcat = (node.returnType == "TEXT") and valueCount == 2

        if forceReturn then
            -- If a return is forced, we might need a temporary variable if further operations are done before returning.
            transpiler:emitASSIGNMENT(nil, "__plume_temp", nil, true)
        end

        if concat then
            transpiler:write("__plume_concat ")
        end

        if wrapInTable then
            transpiler:emitOPEN("{")
        end

        if directConcat then
            transpiler:emitOPEN("(") -- Parentheses for `tostring(a) .. tostring(b)` operations.
        end

        for i, content in ipairs(infos[1].content) do
            -- If concatenating, ensure non-text values are converted to strings.
            if (directConcat or concat) and content.kind ~= "TEXT" then
                transpiler:write("__plume_check(")
            end
            transpiler.transpileToLua(content)
            if (directConcat or concat) and content.kind ~= "TEXT" then
                transpiler:write(")")
            end

            if i < #infos[1].content then
                if directConcat then
                    transpiler:newline()
                    transpiler:write(".. ") -- Lua string concatenation operator.
                else
                    transpiler:write(", ") -- Separator for table elements or multiple return values.
                    transpiler.forceBreak = true -- Hint to the code emitter to prefer a line break here if needed.
                end
            end
        end

        if directConcat then
            transpiler:emitCLOSE(")")
        end

        if wrapInTable then
            transpiler:emitCLOSE("}")
        end

        if forceReturn then
            transpiler:newline()
            transpiler:write("return __plume_temp") -- Return the accumulated/single value.
        end
    end

    --- Transpiles children of a node that are a mix of values and statements, or when values need accumulation.
    ---@param node table The AST node whose children are being transpiled.
    ---@param infos table A table (from `parseChildren`) containing information about the children to transpile.
    ---@param valueCount number The expected number of values to be ultimately returned. -1 indicates an unknown or complex number (e.g., due to control flow).
    ---@param shouldInitAccumulator boolean Whether an accumulator variable (`__plume_temp`) should be initialized.
    ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous Lua function `(function() ... end)()`.
    ---@param forceReturn boolean Whether to force a Lua `return` statement at the end of the generated block.
    ---@return nil
    function transpiler.transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)
        local concat = (node.returnType == "TEXT")

        -- Wrap the output in an IIFE if required. This creates a new scope.
        if wrapInFunction then
            transpiler:emitOPEN("(function()")
        end

        local firstValueFound = false -- Tracks if the first group of storable values has been processed.

        for _, info in ipairs(infos) do
            -- Check if the child group should be stored (i.e., it represents a value or list of values).
            if info.store then
                local values = info.content
                -- If it's a single node, wrap it in a table for uniform processing.
                if info.kind == "node" then
                    values = {values}
                end

                -- Handle the specific case of a single expected value when an accumulator should be initialized.
                -- This avoids creating a table if only one value is ultimately needed.
                if valueCount == 1 and shouldInitAccumulator and #values > 0 then
                    transpiler:emitASSIGNMENT(nil, "__plume_temp", nil, true)

                    -- If expecting a table, wrap the single value.
                    if node.returnType == "TABLE" then
                        transpiler:emitOPEN("{") 
                    end

                    transpiler.transpileToLua(values[1])

                    if node.returnType == "TABLE" then
                        transpiler:emitCLOSE("}")
                    end
                -- Handle multiple values or cases where a table accumulator is generally needed.
                else
                    -- If we've already processed some values or an accumulator isn't strictly needed for the first value set.
                    if firstValueFound or (not shouldInitAccumulator) then
                        for _, value in ipairs(values) do
                            if value.kind == "HASH_ITEM" then
                                local name = value.content

                                if value.sourceToken and value.sourceToken.eval then
                                    name = "__plume_temp[" .. name .. "]"
                                else
                                    name = "__plume_temp[\"" .. name .. "\"]"
                                end

                                transpiler:emitASSIGNMENT(value, name, nil)
                                -- Transpile childrens of the HASH_ITEM (its value).
                                transpiler.transpileChildren(value, false, true, false)
                            else
                                transpiler:newline()
                                -- Insert value into the accumulator table.
                                transpiler:emitOPEN("__plume_insert (__plume_temp, ")
                                if concat and value.kind ~= "TEXT" then 
                                    transpiler:emitOPEN("__plume_check(")
                                end
                                transpiler.transpileToLua(value)
                                if concat and value.kind ~= "TEXT" then
                                    transpiler:emitCLOSE(")")
                                end
                                transpiler:emitCLOSE(")")
                            end
                        end
                    -- Initialize accumulator table with the first set of values.
                    elseif #values > 0 then
                        firstValueFound = true
                        transpiler:emitASSIGNMENT(nil, "__plume_temp", nil, true)
                        transpiler:emitOPEN("{")
                        for i_val, value in ipairs(values) do
                            if concat and value.kind ~= "TEXT" then
                                transpiler:emitOPEN("__plume_check(")
                            end
                            transpiler.transpileToLua(value)
                            if concat and value.kind ~= "TEXT" then
                                transpiler:emitCLOSE(")")
                            end
                            -- Add comma for all but the last element.
                            if i_val < #values then 
                                transpiler:write(", ")
                            end
                        end
                        transpiler:emitCLOSE("}")
                    -- Initialize empty accumulator if necessary (e.g., values might be added by later statements).
                    -- `valueCount == -1` means complex flow.
                    elseif valueCount ~= 0 and (valueCount == -1 or #values > 0) then 
                        firstValueFound = true
                        if node.returnType ~= "VALUE" then
                            transpiler:newline()
                            transpiler:insert("local __plume_temp = {}")
                        end
                    end
                end

            -- Special case: expand macro call
            elseif info.content.kind == "COMMAND_EXPAND" then
                local name = transpiler.getVariableName(info.content)
                transpiler:chunkEXPAND(name)

            elseif info.content.kind == "COMMAND_EXPAND_CALL" then
                local temp = transpiler:getTempVarName()
                transpiler:emitASSIGNMENT(info.content, temp, nil, true)
                transpiler.transpileToLua(info.content)
                transpiler:chunkEXPAND(temp)

            -- If it is not a storable value (i.e., it's a statement), transpile it directly.
            else
                transpiler.transpileToLua(info.content)
            end
        end

        -- Add return statement if needed (either at the end of an IIFE or if forced).
        if (wrapInFunction or forceReturn) then
            if node.returnType == "TEXT" and (valueCount ~= 1 or not shouldInitAccumulator) then
                -- If expecting TEXT and not a single, directly assigned value.
                transpiler:newline()
                if valueCount == 0 then
                    -- Return empty string if no text parts.
                    transpiler:insert("return \"\"") 
                else
                    -- Concatenate accumulated text parts.
                    transpiler:insert("return __plume_concat (__plume_temp)") 
                end
            elseif node.returnType == "NIL" then
                -- For NIL return type (procedures), only add explicit `return` if forced (usually by IIFE).
                if forceReturn then
                    transpiler:newline()
                    transpiler:insert("return")
                end
            elseif node.returnType ~= "VALUE" then
                transpiler:newline()
                if valueCount == 0 then
                    -- Return empty table if no values accumulated.
                    transpiler:insert("return {}") 
                else
                    -- Return accumulated values.
                    transpiler:insert("return __plume_temp") 
                end
            end
        end

        -- Close the wrapping IIFE if it was opened.
        if wrapInFunction then
            transpiler:emitCLOSE("end)()")
        end
    end

    ---Transpiles child nodes of an AST element into executable Lua code.
    ---This is the main entry point for transpiling children of a node.
    ---It decides whether to use a simpler "only values" path or a more complex "mixed case" path.
    ---Handles value accumulation and control flow wrapping.
    ---@param node table AST node whose children are to be processed.
    ---@param wrapInFunction boolean Whether to wrap the generated code in an anonymous function (IIFE).
    ---@param shouldInitAccumulator boolean Whether an accumulator variable (`__plume_temp`) should be initialized or if values can be returned directly.
    ---@param forceReturn boolean Whether to force a Lua `return` statement at the end of the generated block, even if not in an IIFE.
    ---@return nil -- Returns table of generated code lines in some cases, but often nil as it writes via `transpiler:emit...`
    function transpiler.transpileChildren (node, wrapInFunction, shouldInitAccumulator, forceReturn)

        -- Handle nodes with no children, providing default empty values based on context.
        if #node.children == 0 then
            if contains("LIST_ITEM HASH_ITEM TEXT VALUE RETURN ", node.kind) then
                -- For these kinds, an empty child list often implies an empty string or equivalent.
                transpiler:write('""')
                return
            elseif contains("ASSIGNMENT LOCAL_ASSIGNMENT", node.kind) then
                -- Assignments with no right-hand side might implicitly mean `nil`, handled by assignment logic.
                return
            end
        end

        local infos, onlyValues, valueCount = transpiler.parseChildren(node)

        -- If all children are simple values and an accumulator is intended, use the optimized path.
        if onlyValues and shouldInitAccumulator then
            transpiler.transpileChildrenOnlyValuesCase(node, infos, valueCount, forceReturn)
        else
            -- Otherwise, use the more general path that handles mixed statements and values, or complex accumulation.
            transpiler.transpileChildrenMixedCase(node, infos, valueCount, shouldInitAccumulator, wrapInFunction, forceReturn)
        end
    end

    ---Handles macro (function) definition transpilation.
    ---@param node table The macro definition node (`MACRO` or `LOCAL_MACRO`).
    ---@param islocal boolean True if this is a `local function`, false otherwise.
    ---@param inline boolean True if this macro is intended for inlining (potentially affects generation, though not explicitly used in this snippet).
    ---@return nil
    function transpiler.handleMacroDefinition (node, islocal, inline)

        local parameters_node = node.children[1] -- The first child is the parameter list node.
        local body_node       = node.children[2] -- The second child is the body of the macro.

        local parametersList       = {} -- Ordered list of parameter names/nodes.
        local namedParameterValues = {} -- Map of parameter name to its HASH_ITEM node (for default values).
        local positionalParameterCount = 0 -- Count of positional parameters.
        local vararg = false            -- True if the macro accepts variable arguments.

        -- Process the parameter definition node.
        for _, param_child_node in ipairs(parameters_node.children) do
            if param_child_node.kind == "LIST_ITEM" then -- Positional parameter.
                local actual_param_node = param_child_node.children[1]
                table.insert(parametersList, actual_param_node)
                if actual_param_node.kind == "VARARG" then
                    vararg = true
                else
                    positionalParameterCount = positionalParameterCount + 1
                end
            else -- Named parameter (often a HASH_ITEM for `name = default_value`).
                table.insert(parametersList, param_child_node)
                namedParameterValues[param_child_node.content] =  param_child_node -- Store the HASH_ITEM itself.
            end
        end

        -- Emit the Lua function signature.
        transpiler:emitDEFINITION(node, node.content, islocal, inline, positionalParameterCount, vararg)

        local current_pos_param_index = 0
        -- Generate Lua code for initializing parameters (handling defaults, varargs).
        for _, arg_node in ipairs(parametersList) do
            local argName = arg_node.content
            if arg_node.kind == "VARARG" then
                transpiler:chunkINIT_VARARG(argName, current_pos_param_index) 
            elseif namedParameterValues[argName] then
                -- Initialize named parameter, potentially with a default value.
                transpiler:chunkINIT_NAMED_PARAM(argName, function()
                    -- The default value is the content of the HASH_ITEM.
                    transpiler.transpileChildren(namedParameterValues[argName], false, true)
                end)
            else
                current_pos_param_index = current_pos_param_index + 1
                transpiler:chunkINIT_PARAM(argName, current_pos_param_index, vararg) 
            end
        end

        -- Initialize `self` if applicable (for table field call).
        transpiler:chunkINIT_SELF_PARAM() 

        -- Raises an error if a named parameter is unknown, except in case of vararg
        if not vararg then
            transpiler:chunckCHECK_UNUSED_NAMED_PARAM(namedParameterValues)
        end

        -- Transpile the macro body.
        transpiler.transpileChildren (body_node, false, true, true)
        transpiler:emitEND()
    end
end
