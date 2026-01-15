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
function GET_ITER (vm, arg1, arg2)
    --- Unstack 1 iterable object
    --- Stack 1 iterator object
    --- arg1: -
    --- arg2: -
    local obj = _STACK_POP(vm.mainStack)
    local tobj = _GET_TYPE(vm, obj)
    if tobj == "table" then
        local iter
        if obj.meta.table.next then
            iter = obj
        else
            iter = obj.meta.table.iter or vm.plume.defaultMeta.iter
        end

        local value
        if iter.type == "luaFunction" then
            value = iter.callable({obj})
        elseif iter.type == "table" then
            value = iter
        elseif iter.type == "macro" then
            value = _CALL (vm, iter, {obj})
        end
        _STACK_PUSH(vm.mainStack, value)
    else
        _ERROR(vm, "Try to iterate over a non-table '" .. tobj .. "' value.")
    end 
end

--! inline
function FOR_ITER (vm, arg1, arg2)
    --- Unstack 1 iterator object
    --- Stack 1 next call result OR jump to for end
    --- arg1: -
    --- arg2: jump to end for
    local obj = _STACK_POP(vm.mainStack)
    local iter = obj.meta.table.next
    local result
    if iter.type == "luaFunction" then
        result = iter.callable()
    else
        result = _CALL (vm, iter, {obj})
    end

    if result == vm.empty then
        JUMP (vm, 0, arg2)
    else
        _STACK_PUSH(vm.mainStack, result)
    end
end