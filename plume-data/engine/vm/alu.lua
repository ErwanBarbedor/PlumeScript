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
function _CHECK_NUMBER (x)
    if _type(x) == "string" then
        x = tonumber(x)
        if not x then
            _ERROR ("Cannot convert the string value to a number.")
        end
    elseif _type(x) ~= "number" then
        if _type(x) == "table" and x.meta.table.tonumber then
            local meta = ms[msp].meta.table.tonumber
            local params = {}
            _CALL (meta, params)
            x = callResult
        else
            _ERROR ("Cannot do comparison or arithmetic with " .. _type(x).. " value.")
        end
    end
end

function _CHECK_BOOL (x)
    if x == empty then
        x = false
    end
end

function _CHECK_OPTN_NUMBER (x)
    if _type(x) == "string" then
        x = tonumber(x) or x
    end
end

function _BIN_OPP (opp, check)
    --- Classic opperations
    --- Unstack 2
    --- Stack 1, the result
    --- arg1: -
    --- arg2: -
    x = ms[msp-1]
    y = ms[msp]

    _CHECK_check (x)
    _CHECK_check (y)

    msp = msp-1
    ms[msp] = opp(x, y)
end

function _UN_OPP (opp, check)
    --- Classic opperations
    --- Unstack 1
    --- Stack 1, the result
    --- arg1: -
    --- arg2: -
    x = ms[msp]

    _CHECK_check (x)

    ms[msp] = opp( x)
end


function _CHECK_NUMBER_META (x)
    if _type(x) == "string" then
        x = tonumber(x)
        if not x then
            err = "Cannot convert the string value to a number."
        end
    elseif _type(x) ~= "number" then
        if _type(x) == "table" and x.meta.table.tonumber then
            local meta = x.meta.table.tonumber
            local params = {}
            _CALL (meta, params)
            x = callResult
        else
            err = "Cannot do comparison or arithmetic with " .. _type(x).. " value."
        end
    end
end

function _HANDLE_META_BIN (name)
    local meta
    local params
    -- if _type(x) == "table" and x.meta and x.meta.table.(name)r then
    --     meta = x.meta.table.(name)r
    --     params = {y, x} -- self last
    -- elseif _type(y) == "table" and y.meta and y.meta.table.(name)l then
    --     meta = y.meta.table.(name)l
    --     params = {x, y}
    -- elseif _type(x) == "table" and x.meta and x.meta.table.name then
    --     meta = x.meta.table.name
    --     params = {x, y, x}
    -- elseif _type(y) == "table" and y.meta and y.meta.table.name then
    --     meta = y.meta.table.name
    --     params = {x, y, y}
    -- end

    if not meta then
        _ERROR (err)
    end

    _CALL (meta, params)

    ms[msp] = callResult
end

function _BIN_OPP_META (opp, name)
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META (x)
    _CHECK_NUMBER_META (y)

    msp = msp-1

    if err then
        _HANDLE_META_BIN (name)
    else
        ms[msp] = opp(x, y)
    end
end

function _HANDLE_META_UN (name)
    local meta
    local params = {x}
    if _type(x) == "table" and x.meta and x.meta.table.name then
        meta = x.meta.table.name
    end

    if not meta then
        _ERROR (err)
    end

    _CALL (meta, params)

    ms[msp] = callResult
end

function _UN_OPP_META (opp, name)
    x = ms[msp]

    local err

    _CHECK_NUMBER_META (x)

    if err then
        _HANDLE_META_UN (name)
    else
        ms[msp] = opp (x)
    end
end

function OPP_ADD () _BIN_OPP_META (_ADD, "add") end
function OPP_MUL () _BIN_OPP_META  (_MUL, "mul") end
function OPP_SUB () _BIN_OPP_META (_SUB, "sub") end
function OPP_DIV () _BIN_OPP_META (_DIV, "div") end
function OPP_MOD () _BIN_OPP_META (_MOD, "mod") end
function OPP_POW () _BIN_OPP_META (_POW, "pow") end
function OPP_NEG () _UN_OPP_META (_MINUS, "minus") end

-- comp
function OPP_GT ()
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META (x)
    _CHECK_NUMBER_META (y)

    msp = msp-1

    if err then
        local macro, params, meta
        if _type(x) == "table" and x.meta and x.meta.table.gt then
            meta = x.meta.table.gt
            params = {y, x}
        elseif _type(y) == "table" and y.meta and y.meta.table.lt then
            meta = y.meta.table.lt
            params = {x, y}
        end
        if not meta then
            _ERROR (err)
        end

       _CALL (meta, params)

        if invert then
            callResult = not callResult
            if callResult then
                ms[msp] = callResult
            else
                msp = msp+1
                OPP_EQ()
            end
        else
            ms[msp] = callResult
        end
    else
        ms[msp] = x > y
    end
end

function OPP_LT ()
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META (x)
    _CHECK_NUMBER_META (y)

    msp = msp-1

    if err then
        local macro, params, meta, invert
        if _type(x) == "table" and x.meta and x.meta.table.lt then
            meta = x.meta.table.lt
            params = {y, x}
        elseif _type(y) == "table" and y.meta and y.meta.table.gt then
            meta = y.meta.table.gt
            params = {x, y}
        elseif _type(x) == "table" and x.meta and x.meta.table.gt then
            meta = x.meta.table.gt
            params = {y, x}
            invert = true
        elseif _type(y) == "table" and y.meta and y.meta.table.lt then
            meta = y.meta.table.lt
            params = {x, y}
            invert = true
        end
        if not meta then
            _ERROR (err)
        end

        _CALL (meta, params)

        if invert then
            callResult = not callResult
            if callResult then
                ms[msp] = callResult
            else
                msp = msp+1
                OPP_EQ()
            end
        else
            ms[msp] = callResult
        end

    else
        ms[msp] = x < y
    end
end

function OPP_EQ ()
    x = ms[msp-1]
    y = ms[msp]

    msp = msp-1

    local macro, params, meta

    if _type(x) == "table" and x.meta and x.meta.table.eq then
        meta = x.meta.table.eq
        params = {y, x}
    elseif _type(y) == "table" and y.meta and y.meta.table.eq then
        meta = y.meta.table.eq
        params = {x, y}
    end

    if meta then
        _CALL (meta, params)
        ms[msp] = callResult
    else
        _CHECK_OPTN_NUMBER (x)
        _CHECK_OPTN_NUMBER (y)
        ms[msp] = x == y
    end
end

function OPP_NEQ ()
    x = ms[msp-1]
    y = ms[msp]

    msp = msp-1

    local macro, params, meta

    if _type(x) == "table" and x.meta and x.meta.table.eq then
        meta = x.meta.table.eq
        params = {y, x}
    elseif _type(y) == "table" and y.meta and y.meta.table.eq then
        meta = y.meta.table.eq
        params = {x, y}
    end

    if meta then
        _CALL (meta, params)
        ms[msp] = not callResult
    else
        _CHECK_OPTN_NUMBER (x)
        _CHECK_OPTN_NUMBER (y)
        ms[msp] = x ~= y
    end
end

-- bool
function OPP_AND () _BIN_OPP (_AND) end
function OPP_OR () _BIN_OPP (_OR) end
function OPP_NOT () _UN_OPP (_NOT) end