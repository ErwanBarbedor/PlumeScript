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
--- Create a new table, waiting CONCAT_TABLE or CALL
--- @param arg1 number Number of hash slot to allocate
--! inline
function TABLE_NEW (vm, arg1, arg2)
    _STACK_PUSH(vm.mainStack, table.new(0, arg1))
end

--- @opcode
--- Mark the last element of the stack as a key
--! inline
function TAG_KEY(vm, arg1, arg2)
    local pos = _STACK_POS(vm.mainStack)
    vm.tagStack[pos] = "key"
end

--- @opcode
--- Mark the last element of the stack as a meta-key
--! inline
function TAG_META_KEY(vm, arg1, arg2)
    local pos = _STACK_POS(vm.mainStack)
    vm.tagStack[pos] = "metakey"
end

--- Set a table field. If k isn't a number and is a new key, save it in `t.keys`.
--- Should certainly be handled by the table itself?
--- @param t table
--- @param k string
--- @param v any
--- @return nil
--! inline
function _TABLE_SET (vm, t, k, v)
    local key   = k
    local value = v
    key = tonumber(key) or key
    if not t.table[key] then
        table.insert(t.keys, k)
    end
    --set
    t.table[key] = value 
end

--- Set a table metafield
--- @param t table
--- @param k string
--- @param v any
--- @return nil
--! inline
function _TABLE_META_SET (vm, t, k, v)
    local success, err = _META_CHECK (k, v)
    if success then
        t.meta.table[k] = v --set
    else
        _ERROR(vm, err)
    end
end

--- @opcode
--- Add a key to the current accumulation table (bottom of the current frame)
--- Unstack 2: a key, then a value
--- @param arg2 number 1 if the key should be registered as metafield
--! inline
function TABLE_SET_ACC (vm, arg1, arg2)
    local t = _STACK_GET_FRAMED(vm.mainStack)
    
    table.insert(t, _STACK_POP(vm.mainStack)) -- key
    table.insert(t, _STACK_POP(vm.mainStack)) -- value
    table.insert(t, arg2==1)                  -- is meta
end

--- @opcode
--- Unstack 3, in order: table, key, value
--- Set the table.key to value
--! inline
function TABLE_SET_META (vm, arg1, arg2)
    local t     = _STACK_POP(vm.mainStack)
    local key   = _STACK_POP(vm.mainStack)
    local value = _STACK_POP(vm.mainStack)
    t.meta.table[key] = value
end

--- @opcode
--- Index a table
--- Unstack 2, in order: table, key
--- Stack 1, `table[key]`
--- @param arg1 number 1 if "safe mode" (return empty if key not exit), 0 else (raise error if key not exist)
--! inline
function TABLE_INDEX (vm, arg1, arg2)
    local t   = _STACK_POP(vm.mainStack)
    local key = _STACK_POP(vm.mainStack)
    key = tonumber(key) or key

    if key == vm.empty then
        if arg1 == 1 then
            LOAD_EMPTY(vm)
        else
            _ERROR (vm, vm.plume.error.cannotUseEmptyAsKey())
        end
    else
        local tt = _GET_TYPE (vm, t)
        if tt ~= "table" then
            if arg1 == 1 then
                LOAD_EMPTY(vm)
            else
                _ERROR(vm, vm.plume.error.cannotIndexValue(tt))
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
                    BEGIN_ACC(vm, 0, 0)
                    _STACK_PUSH(vm.mainStack, key)
                    _PUSH_SELF(vm, t)
                    _STACK_PUSH(vm.mainStack, meta)
                    _INJECTION_PUSH(vm, vm.plume.ops.CONCAT_CALL, 0, 0)
                else
                    if tonumber(key) then
                        _ERROR (vm, vm.plume.error.invalidKey(key))
                    else
                        _ERROR (vm, vm.plume.error.unregisteredKey(key))
                    end
                end
            end
        end
    end
end

--- @param self table
--- Register a table as the value for the field self
--- in the current accumulation table
--! inline
function _PUSH_SELF(vm, self)
    _STACK_PUSH(vm.mainStack, self)
    _STACK_PUSH(vm.mainStack, "self")
    TAG_KEY(vm)
end

--- @opcode
--- The stack may be [(frame begin)| call arguments | index | table]
--- Insert self | table in the call arguments
--! inline
function CALL_INDEX_REGISTER_SELF (vm, arg1, arg2)
    local t = _STACK_POP(vm.mainStack)
    local index = _STACK_POP(vm.mainStack)
    
    
    _STACK_PUSH(vm.mainStack, t)
    _STACK_PUSH(vm.mainStack, "self")
    TAG_KEY(vm)
    _STACK_PUSH(vm.mainStack, index)
    _STACK_PUSH(vm.mainStack, t)
end

--- @opcode
--- Unstack 3, in order: table, key, value
--- Set the table.key to value
--- @param arg1 number If set to 1, take table, key, value in reverse order
--! inline
function TABLE_SET (vm, arg1, arg2)
    local t, key, value

    if arg1 == 1 then
        value = _STACK_POP(vm.mainStack)
        key   = _STACK_POP(vm.mainStack)
        t     = _STACK_POP(vm.mainStack)
    else
        t     = _STACK_POP(vm.mainStack)
        key   = _STACK_POP(vm.mainStack)
        value = _STACK_POP(vm.mainStack)
    end
    local meta
    if not t.table[key] then
        table.insert(t.keys, key)
        meta = t.meta.table.setindex
        if meta then
            -- for preventing infinite loop with next TABLE_SET
            -- quite dirty an vulnerable (ex: meta set this key to nil)
            -- may be rewrited in the futur
            t.table[key] = vm.empty 

            -- table & key
            _STACK_PUSH(vm.mainStack, t)
            _STACK_PUSH(vm.mainStack, key)

            -- value
            BEGIN_ACC(vm, 0, 0)
            _STACK_PUSH(vm.mainStack, key)
            _STACK_PUSH(vm.mainStack, value)
            _PUSH_SELF(vm, t)
            _STACK_PUSH(vm.mainStack, meta)

            _INJECTION_PUSH(vm, vm.plume.ops.TABLE_SET, 1, 0)   -- set
            _INJECTION_PUSH(vm, vm.plume.ops.CONCAT_CALL, 0, 0) -- call
        end
    end

    if not meta then
        key = tonumber(key) or key
        t.table[key] = value
    end
end

--- @opcode
--- Unstack 1: a table
--- Stack all list item
--- Put all hash item on the stack
--! inline
function TABLE_EXPAND (vm, arg1, arg2)
    local t  = _STACK_POP(vm.mainStack)
    local tt = _GET_TYPE(vm, t)
    if tt == "table" then
        for _, item in ipairs(t.table) do
            _STACK_PUSH(vm.mainStack, item)
        end

        for _, key in ipairs(t.keys) do
            _STACK_PUSH(vm.mainStack, t.table[key])
            _STACK_PUSH(vm.mainStack, key)
            TAG_KEY(vm)
        end
    else
        _ERROR (vm, vm.plume.error.cannotExpandValue(tt))
    end
end