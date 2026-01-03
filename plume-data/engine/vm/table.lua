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

--- To rewrite
function TABLE_NEW (vm, arg1, arg2)
    --- Stack 1 table
    --- arg1: -
    --- arg2: -
    msp = msp + 1
    ms[msp] = table.new(0, arg1)
end

function TABLE_ADD (vm, arg1, arg2)
end

function CHECK_META (vm, arg1, arg2)
    if not arg1.meta then
        arg1.meta = plume.obj.table(0, 0)
    end
end

function TABLE_INDEX (vm, arg1, arg2)
    --- Unstack 2, in order: table, key
    --- Stack 1, table[key]
    --- arg1: safe?
    --- arg2: -
    local key = ms[msp-1]
    key = tonumber(key) or key
    if key==empty then
        if arg1 == 1 then
            msp = msp-2
            LOAD_EMPTY()
        else
            _ERROR ("Cannot use empty as key.")
        end
    else
        local _table = ms[msp]
        local t = _type(_table)
        if t ~= "table" then
            if arg1 == 1 then
                msp = msp-2
                LOAD_EMPTY()
            else
                _ERROR("Try to index a '" ..t .."' value.")
            end
        else
            local value = _table.table[key]
            if not value then
                if arg1 == 1 then
                    msp = msp-2
                    LOAD_EMPTY()
                elseif _table.meta.table.getindex then
                    local meta = _table.meta.table.getindex
                    local params = {key}
                    _CALL (meta, params)
                    value = callResult
                    ms[msp-1] = value
                    msp = msp-1
                else
                    if tonumber(key) then
                        _ERROR ("Invalid index '" .. key .."'.")
                    else
                        _ERROR ("Unregistered key '" .. key .."'.")
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
    table.insert(ms[msf[msfp]], "self")
    table.insert(ms[msf[msfp]], ms[msp])
    table.insert(ms[msf[msfp]], false)
    TABLE_INDEX()
end

function TABLE_INDEX_META (vm, arg1, arg2)
    --- Unstack 2, in order: table, key
    --- Stack 1, table[key]
    --- arg1: -
    --- arg2: -
    _CHECK_META (ms[msp])
    ms[msp-1] = ms[msp].meta.table[ms[msp-1]]
    msp = msp-1
end

function _TABLE_SET (t, k, v)
    -- if dont exists, register key
    local key   = k
    local value = v
    key = tonumber(key) or key
    if not t.table[key] then
        table.insert(t.keys, k)
    end
    t.table[key] = value --set
end

function _TABLE_META_SET (t, k, v)
    _META_CHECK (k, v)
    t.meta.table[k] = v --set
end

function TABLE_SET (vm, arg1, arg2)
    --- Unstack 3, in order: table, key, value
    --- Set the table.key to value
    --- arg1: -
    --- arg2: -
    local t = ms[msp]
    local key = ms[msp-1]
    local value = ms[msp-2]
    if not t.table[key] then
        table.insert(t.keys, key)
        if t.meta.table.setindex then
            local meta = t.meta.table.setindex
            local params = {key, value}
            _CALL (meta, params)
            value = callResult
        end
    end
    key = tonumber(key) or key
    t.table[key] = value
    msp = msp-3
end

function TABLE_SET_META (vm, arg1, arg2)
    --- Unstack 3, in order: table, key, value
    --- Set the table.key to value
    --- arg1: -
    --- arg2: -
    _CHECK_META (ms[msp-2])
    ms[msp-2].meta.table[ms[msp-1]] = ms[msp]
    msp = msp-3
end

function TABLE_SET_ACC (vm, arg1, arg2)
    --- Unstack 2: a key, then a value
    --- Assume the main stack frame first value is a table
    --- Register key, then value in
    --- arg1: -
    --- arg2: -
    table.insert(ms[msf[msfp]], ms[msp])
    table.insert(ms[msf[msfp]], ms[msp-1])
    table.insert(ms[msf[msfp]], false)
    msp = msp-2
end

function TABLE_SET_ACC_META (vm, arg1, arg2)
    --- Unstack 2: a key, then a value
    --- Assume the main stack frame first value is a table
    --- Register key, then value in
    --- arg1: -
    --- arg2: -
    table.insert(ms[msf[msfp]], ms[msp])
    table.insert(ms[msf[msfp]], ms[msp-1])
    table.insert(ms[msf[msfp]], true)
    msp = msp-2
end

function TABLE_EXPAND (vm, arg1, arg2)
    --- Unstack 1: a table
    --- Stack all list item
    --- Put all hash item on the acc table
    --- arg1: -
    --- arg2: -
    local t = ms[msp]
    if _type(t) ~= "table" then
        _ERROR ("Try to expand a '" .._type(t) .."' value.")
    end

    msp = msp-1
    for _, item in ipairs(t.table) do
        msp = msp+1
        ms[msp] = item
    end
    for _, key in ipairs(t.keys) do
        table.insert(ms[msf[msfp]], key)
        table.insert(ms[msf[msfp]], t.table[key])
        table.insert(ms[msf[msfp]], false)
    end
end