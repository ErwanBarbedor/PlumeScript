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

--- @opcode
--- Create a new accumulation frame
--! inline
function BEGIN_ACC(vm, arg1, arg2)
    _STACK_PUSH(
        vm.mainStack.frames,
        vm.mainStack.pointer+1
    )
end

--- Close the current frame
--! inline
function _END_ACC (vm)
    _STACK_POP(vm.mainStack.frames)
end

--- @opcode
--- Concat all element in the current frame.
--- Unstack all element in current frame, remove the last frame
--- and stack the concatenation for theses elements
--! inline
function CONCAT_TEXT (vm, arg1, arg2)
    local start = _STACK_GET(vm.mainStack.frames)
    local stop  = _STACK_POS(vm.mainStack)
    for i = start, stop do

        if _STACK_GET(vm.mainStack, i) == vm.empty then
            _STACK_SET(vm.mainStack, i, "")
        end
    end

    local acc_text = table.concat(vm.mainStack, "", start, stop)
    _STACK_MOVE(vm.mainStack, start)
    _STACK_SET (vm.mainStack, start, acc_text)
    _END_ACC(vm)
end

--- @opcode
--- Make a table from elements of the current frame
--- Unstack all element in current frame, remove the last frame.
--- Make a new table
--- First unstacked element must be a table, containing in order key, value, ismeta to insert in the new table
--- All following elements are appended to the new table.
--! inline
function CONCAT_TABLE(vm)
    -- Treat all arguments as variadic by asking for 0 positional variables and 0 named variables
    local resultTable = _CONCAT_TABLE(vm, 0, nil, true)

    _STACK_POP_FRAME(vm.mainStack) -- Clean stack from arguments
    _STACK_PUSH(vm.mainStack, resultTable) -- Push the resulting table onto the stack

    return resultTable
end

---@param posParamCount integer The number of expected positional parameters (0 for none).
---@param namedParamOffset table|nil A map of named parameters to their register offsets (nil for none).
---@return table The variadic table object containing surplus/variadic arguments.
--! inline
function _CONCAT_TABLE(vm, posParamCount, namedParamOffset, variadic)
    local argsOffset   = 1
    
    local frameOffset  = _STACK_GET(vm.mainStack.frames)
    local bufferOffset = frameOffset
    local mainStackTop = _STACK_POS(vm.mainStack)

    local variadicTable
    -- Heuristic allocation: assume worst case (all items are part of the table)
    if variadic then
        local max = mainStackTop - bufferOffset + 1
        variadicTable = vm.plume.obj.table(max, max / 2)
    end

    local tomanyPositionnalCounter = 0
    local capturedCount = 0
    local unknowNamed

    while bufferOffset <= mainStackTop do
        local tag = vm.tagStack[bufferOffset+1]
        local value = _STACK_GET(vm.mainStack, bufferOffset)
        -- Positional Argument
        if tag == nil then
            if argsOffset <= posParamCount then
                -- Assign to local variable register
                _STACK_SET_FRAMED(vm.variableStack, argsOffset-1, 0, value)
                capturedCount = capturedCount+1
            elseif variadicTable then
                -- Surplus -> Insert into variadic table
                local key = #variadicTable.table+1
                if not variadicTable.table[key] then
                    table.insert(variadicTable.keys, key)
                end
                variadicTable.table[key] = value
            else
                tomanyPositionnalCounter = tomanyPositionnalCounter+1
            end
            argsOffset = argsOffset + 1

        -- Named Argument or Meta Key
        else
            bufferOffset = bufferOffset + 1
            local key = _STACK_GET(vm.mainStack, bufferOffset)
            -- Check if this key corresponds to a declared named parameter
            local argOffset = namedParamOffset and (namedParamOffset)[key]
            if argOffset then
                if tag == "key" then
                    -- Assign to local variable register
                    _STACK_SET_FRAMED(vm.variableStack, argOffset-1, 0, value)
                else
                    _ERROR(vm, vm.plume.error.cannotUseMetaKey)
                end
            else
                -- Unknown key -> Insert into variadic table
                if variadicTable then
                    if tag == "key" then
                        if not variadicTable.table[key] then
                            table.insert(variadicTable.keys, key)
                        end
                        variadicTable.table[key] = value
                    elseif tag == "metakey" then
                        local success, err = _META_CHECK (key, value)
                        if success then
                            variadicTable.meta.table[key] = value
                        else
                            _ERROR(vm, err)
                        end
                    end
                else
                    unknowNamed = key
                    break
                end
            end
            
            vm.tagStack[bufferOffset] = nil -- Clean tagstack for the key
        end
        bufferOffset = bufferOffset + 1
    end

    return variadicTable, tomanyPositionnalCounter, capturedCount, unknowNamed
end

--- @opcode
--- Check if stack top can be concatened
--- Get stack top. If neither empty, number or string, try
--- to convert it, else throw an error.
--! inline
function CHECK_IS_TEXT (vm, arg1, arg2)
    local value = _STACK_GET(vm.mainStack)
    local t     = _GET_TYPE(vm, value)

    if t ~= "number" and t ~= "string" and value ~= vm.empty then
        local meta = t == "table" and value.meta.table.tostring
        if  meta then
            _STACK_POP(vm.mainStack)

            BEGIN_ACC(vm, 0, 0)
            _PUSH_SELF(vm, t)
            _STACK_PUSH(vm.mainStack, meta)
            _INJECTION_PUSH(vm, vm.plume.ops.CONCAT_CALL, 0, 0)
        elseif t == "boolean" then
            _STACK_SET(vm.mainStack, _STACK_POS(vm.mainStack), tostring(value))
        else
            _ERROR (vm, vm.plume.error.cannotConcatValue(t))
        end
    end
end