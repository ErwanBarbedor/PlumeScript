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

function TABLE_NEW (vm, arg1, arg2)
    --- Stack 1 table
    --- arg1: -
    --- arg2: -
    _STACK_PUSH(vm.mainStack, table.new(0, arg1))
end

function _TABLE_SET (vm, t, k, v)
    -- if dont exists, register key
    local key   = k
    local value = v
    key = tonumber(key) or key
    if not t.table[key] then
        table.insert(t.keys, k)
    end
    --set
    t.table[key] = value 
end

function TABLE_SET_ACC (vm, arg1, arg2)
    --- Unstack 2: a key, then a value
    --- Assume the main stack frame first value is a table
    --- Register key, then value in
    --- arg1: -
    --- arg2: is meta?
    local t = _STACK_GET_FRAMED(vm.mainStack)
    
    table.insert(t, _STACK_POP(vm.mainStack)) -- key
    table.insert(t, _STACK_POP(vm.mainStack)) -- value
    table.insert(t, arg2==1)                  -- is meta
end

function TABLE_SET_META (vm, arg1, arg2)
    --- Unstack 3, in order: table, key, value
    --- Set the table.key to value
    --- arg1: -
    --- arg2: -
    local t     = _STACK_POP(vm.mainStack)
    local key   = _STACK_POP(vm.mainStack)
    local value = _STACK_POP(vm.mainStack)
    t.meta.table[key] = value
end

function TABLE_INDEX (vm, arg1, arg2)
    --- Unstack 2, in order: table, key
    --- Stack 1, table[key]
    --- arg1: safe?
    --- arg2: -
    local t   = _STACK_POP(vm.mainStack)
    local key = _STACK_POP(vm.mainStack)
    key = tonumber(key) or key

    if key == vm.empty then
        if arg1 == 1 then
            LOAD_EMPTY(vm)
        else
            _ERROR (vm, "Cannot use empty as key.")
        end
    else
        local tt = _GET_TYPE (vm, t)
        if tt ~= "table" then
            if arg1 == 1 then
                LOAD_EMPTY(vm)
            else
                _ERROR(vm, "Try to index a '" ..tt .."' value.")
            end
        else
            local value = t.table[key]
            if value then
                _STACK_PUSH(vm.mainStack, value)
            else
                if arg1 == 1 then
                    LOAD_EMPTY(vm)
                elseif t.meta.table.getindex then
                    local meta = t.meta.table.getindex
                    local args = {key}
                    _STACK_PUSH(vm.mainStack, _CALL (vm, meta, args))
                else
                    if tonumber(key) then
                        _ERROR (vm, "Invalid index '" .. key .."'.")
                    else
                        _ERROR (vm, "Unregistered key '" .. key .."'.")
                    end
                end
            end
        end
    end
end

function TABLE_INDEX_ACC_SELF (vm, arg1, arg2)
    --- Unstack 2, in order: table, key
    --- Add current table as self key for current
    --- call table.
    --- Stack 1, table[key]
    --- arg1: -
    --- arg2: -
    local t = _STACK_GET_FRAMED(vm.mainStack)
    table.insert(t, "self")
    table.insert(t, _STACK_GET(vm.mainStack))
    table.insert(t, false)
    TABLE_INDEX(vm, 0, 0)
end

function TABLE_INDEX_META (vm, arg1, arg2)
    --- Unstack 2, in order: table, key
    --- Stack 1, table[key]
    --- arg1: -
    --- arg2: -
    ms[msp-1] = ms[msp].meta.table[ms[msp-1]]
    msp = msp-1
end

function _TABLE_META_SET (vm, t, k, v)
    local success, err = _META_CHECK (k, v)
    if success then
        t.meta.table[k] = v --set
    else
        _ERROR(vm, err)
    end
end

function TABLE_SET (vm, arg1, arg2)
    --- Unstack 3, in order: table, key, value
    --- Set the table.key to value
    --- arg1: -
    --- arg2: -
    local t     = _STACK_POP(vm.mainStack)
    local key   = _STACK_POP(vm.mainStack)
    local value = _STACK_POP(vm.mainStack)
    if not t.table[key] then
        table.insert(t.keys, key)
        if t.meta.table.setindex then
            local meta = t.meta.table.setindex
            local args = {key, value}
            
            value = _CALL (vm, meta, args)
        end
    end
    key = tonumber(key) or key
    t.table[key] = value
end

function TABLE_EXPAND (vm, arg1, arg2)
    --- Unstack 1: a table
    --- Stack all list item
    --- Put all hash item on the acc table
    --- arg1: -
    --- arg2: -
    local t  = _STACK_POP(vm.mainStack)
    local tt = _GET_TYPE(vm, t)
    if tt == "table" then
        for _, item in ipairs(t.table) do
            _STACK_PUSH(vm.mainStack, item)
        end

        local ft = _STACK_GET_FRAMED(vm.mainStack)
        for _, key in ipairs(t.keys) do
            table.insert(ft, key)
            table.insert(ft, t.table[key])
            table.insert(ft, false)
        end
    else
        _ERROR (vm, "Try to expand a '" .. tt .."' value.")
    end
end