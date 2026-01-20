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
--- Unstack 1 iterable object and stack 1 iterator.
--- If object as a meta field `next`, it's already and iterator, and will be returned as it.
--- If object as a meta field `iter`, call it.
--- Else, stack the defaut iterator
--- Raise an error if the object isn't a table.
--! inline
function GET_ITER (vm, arg1, arg2)
    local obj = _STACK_POP(vm.mainStack)
    local tobj = _GET_TYPE(vm, obj)
    
    local value, flag
    if tobj == "table" then
        local iter
        if obj.meta.table.next then
            iter = obj
        else
            iter = obj.meta.table.iter
        end

        
        if iter then
            if iter.type == "luaFunction" then
                value = iter.callable({obj})
            elseif iter.type == "table" then
                value = iter
            elseif iter.type == "macro" then
                value = _CALL (vm, iter, {obj})
            end
        else
            value = obj.table
            flag = vm.flag.ITER_TABLE
        end

    elseif tobj == "seq" then
        value = obj
        flag = vm.flag.ITER_SEQ

    else
        _ERROR(vm, vm.plume.error.cannotIterateValue(tobj))
    end 

    _STACK_PUSH(vm.mainStack, flag)
    _STACK_PUSH(vm.mainStack, 0) -- state
    _STACK_PUSH(vm.mainStack, value)

    -- GET_ITER is followed by 3 STORE_LOCAL
end

--- @opcode
--- Unstack 1 iterator and call it
--- If empty, jump to for loop end.
--- @param arg2 number Offset of the loop end
--! inline
function FOR_ITER (vm, arg1, arg2)
    local obj   = _STACK_GET_FRAMED(vm.variableStack, 0, 0)
    local state = _STACK_GET_FRAMED(vm.variableStack, 1, 0)
    local flag  = _STACK_GET_FRAMED(vm.variableStack, 2, 0)

    local result
    if flag == vm.flag.ITER_TABLE then
        state = state+1

        if state > #obj then
            result = vm.empty
        else
            result = obj[state]
        end
    elseif flag == vm.flag.ITER_SEQ then
        state = state + obj.step
        if state > obj.stop then
            result = vm.empty
        else
            result = state
        end
    else
        local iter = obj.meta.table.next
        if iter.type == "luaFunction" then
            result = iter.callable()
        else
            result = _CALL (vm, iter, {obj})
        end
    end

    -- Save state. Offset 1 for local var #2
    _STACK_SET_FRAMED(vm.variableStack, 1, 0, state)

    if result == vm.empty then
        JUMP (vm, 0, arg2)
    else
        _STACK_PUSH(vm.mainStack, result)
    end
end