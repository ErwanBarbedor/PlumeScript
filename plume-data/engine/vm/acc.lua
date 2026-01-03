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

BEGIN_ACC = function(vm, arg1, arg2)
    --- Stack 1 to main stack frame, the current msp
    --- arg1: -
    --- arg2: -
    msfp = msfp + 1
    msf[msfp] = msp+1
end

_END_ACC = function (vm, arg1, arg2)
    msfp = msfp-1
end

ACC_TEXT = function (vm, arg1, arg2)
    --- Unstack all until main stack frame begin
    --- Concat and main stack the result
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -
    local limit = msf[msfp]
    for i=limit, msp do
        if ms[i] == empty then
            ms[i] = ""
        end
    end
    ms[limit] = table.concat(ms, "", limit, msp)
    msp = limit
    _END_ACC
end

ACC_TABLE = function (vm, arg1, arg2)
    --- Unstack all until main stack frame begin
    --- Make a table from it
    --- Unstack 1, a hash table
    --- Add keys to the table
    --- Stack the table
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -
    local limit = msf[msfp]+1 -- Count items
    local keyCount = #ms[limit-1] / 2
    local args = ptable(msp-limit+1, keyCount)
    for i=1, msp-limit+1 do -- dump items
        args.table[i] = ms[limit+i-1]
    end
    for i=1, #ms[limit-1], 3 do --dump keys 
        if ms[limit-1][i+2] then -- meta
            _TABLE_META_SET args ms[limit-1][i] ms[limit-1][i+1]
        else
            _TABLE_SET args ms[limit-1][i] ms[limit-1][i+1]
        end
    end
    ms[limit-1] = args
    msp = limit - 1
    _END_ACC
end

ACC_EMPTY = function (vm, arg1, arg2)
    --- Stack 1 constant empty
    --- Unstack main stack frame
    --- arg1: -
    --- arg2: -
    msp = msp+1
    ms[msp] = empty
    _END_ACC
end

ACC_CHECK_TEXT = function (vm, arg1, arg2)
    --- Check if stack top can be concatened
    local t = _type(ms[msp])
    if t ~= "number" and t ~= "string" and ms[msp] ~= empty then
        if t == "table" and ms[msp].meta.table.tostring then
            local meta = ms[msp].meta.table.tostring
            local params = {}
            _CALL meta params
            ms[msp] = callResult
        else
            _ERROR ("Cannot concat a '" ..t .. "' value.")
        end
    end
end