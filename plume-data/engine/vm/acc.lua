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
function CONCAT_TABLE (vm, arg1, arg2)
    local limit = _STACK_GET(vm.mainStack.frames)+1 -- Frame beggining
    local current = _STACK_POS(vm.mainStack)
    local keyTable = _STACK_GET(vm.mainStack, limit-1)
    local keyCount = #keyTable / 3
    local args = vm.plume.obj.table(current-limit+1, keyCount)
    for i=1, current-limit+1 do -- dump items
        args.table[i] = _STACK_GET(vm.mainStack, limit+i-1)
    end
    for i=1, #keyTable, 3 do --dump keys 
        if keyTable[i+2] then -- meta
            _TABLE_META_SET (vm, args, keyTable[i], keyTable[i+1])
        else
            _TABLE_SET (vm, args, keyTable[i], keyTable[i+1])
        end
    end
    _STACK_MOVE(vm.mainStack, limit-2)
    _STACK_PUSH(vm.mainStack, args)

    _END_ACC(vm)
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
        if t == "table" and value.meta.table.tostring then
            local meta = value.meta.table.tostring
            local args = {}
            _STACK_SET(vm.mainStack, _STACK_POS(vm.mainStack), _CALL (vm, meta, args))
        else
            _ERROR (vm, vm.plume.error.cannotConcatValue(t))
        end
    end
end

--- Close the current frame
--! inline
function _END_ACC (vm)
    _STACK_POP(vm.mainStack.frames)
end