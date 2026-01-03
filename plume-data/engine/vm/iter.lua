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
function GET_ITER ()
    --- Unstack 1 iterable object
    --- Stack 1 iterator object
    --- arg1: -
    --- arg2: -
    local obj = ms[msp]
    local tobj = _type(obj)
    if tobj ~= "table" then
        _ERROR("Try to iterate over a non-table '" .. tobj .. "' value.")
    end

    local iter
    if obj.meta.table.next then
        iter = obj
    else
        iter = obj.meta.table.iter or plume.defaultMeta.iter
    end

    if iter.type == "luaFunction" then
        ms[msp] = iter.callable({obj})
    elseif iter.type == "table" then
        ms[msp] = iter
    elseif iter.type == "macro" then
        _CALL (iter, {obj})
        ms[msp] = callResult
    end
end

function FOR_ITER (vm, arg1, arg2)
    --- Unstack 1 iterator object
    --- Stack 1 next call result OR jump to for end
    --- arg1: -
    --- arg2: jump to end for
    local obj = ms[msp]
    local iter = obj.meta.table.next
    local result
    if iter.type == "luaFunction" then
        result = iter.callable()
    else
        _CALL (iter, {obj})
        result = callResult
    end
    if result == empty then
        msp = msp-1
        JUMP (0, arg1)
    else
        ms[msp] = result
    end
end