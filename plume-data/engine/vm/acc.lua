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
--! inline
function BEGIN_ACC(vm, arg1, arg2)
    --- Stack 1 to main stack frame, the current msp
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(
        vm.mainStack.frames,
        vm.mainStack.pointer+1
    )
end

function ACC_TEXT (vm, arg1, arg2)
    --- Unstack all until main stack frame begin
    --- Concat and main stack the result
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -
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

function ACC_TABLE (vm, arg1, arg2)
    --- Unstack all until main stack frame begin
    --- Make a table from it
    --- Unstack 1, a hash table
    --- Add keys to the table
    --- Stack the table
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -

    -- Count items
    local limit = _STACK_GET(vm.mainStack.frames)+1
    local current = _STACK_POS(vm.mainStack)
    local t = _STACK_GET(vm.mainStack, limit-1)
    local keyCount = #t / 2
    local args = vm.plume.obj.table(current-limit+1, keyCount)
    for i=1, current-limit+1 do -- dump items
        args.table[i] = _STACK_GET(vm.mainStack, limit+i-1)
    end
    for i=1, #t, 3 do --dump keys 
        if t[i+2] then -- meta
            _TABLE_META_SET (vm, args, t[i], t[i+1])
        else
            _TABLE_SET (vm, args, t[i], t[i+1])
        end
    end
    _STACK_MOVE(vm.mainStack, limit-2)
    _STACK_PUSH(vm.mainStack, args)

    _END_ACC(vm)
end

function ACC_CHECK_TEXT (vm, arg1, arg2)
    --- Check if stack top can be concatened
    local value = _STACK_GET(vm.mainStack)
    local t     = _GET_TYPE(vm, value)
    if t ~= "number" and t ~= "string" and value ~= vm.empty then
        if t == "table" and value.meta.table.tostring then
            local meta = value.meta.table.tostring
            local args = {}
            _STACK_SET(vm.mainStack, _STACK_POS(vm.mainStack), _CALL (vm, meta, args))
        else
            _ERROR (vm, "Cannot concat a '" ..t .. "' value.")
        end
    end

end

function _END_ACC (vm)
    _STACK_POP(vm.mainStack.frames)
end

function ACC_EMPTY (vm, arg1, arg2)
    --- Stack 1 constant empty
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, vm.empty)
    _END_ACC(vm)
end

