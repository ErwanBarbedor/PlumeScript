_CHECK_NUMBER = function (x)
    if _type(x) == "string" then
        x = tonumber(x)
        if not x then
            _ERROR ("Cannot convert the string value to a number.")
        end
    elseif _type(x) ~= "number" then
        if _type(x) == "table" and x.meta.table.tonumber then
            local meta = ms[msp].meta.table.tonumber
            local params = {}
            _CALL meta params
            x = callResult
        else
            _ERROR ("Cannot do comparison or arithmetic with " .. _type(x).. " value.")
        end
    end
end

_CHECK_BOOL = function (x)
    if x == empty then
        x = false
    end
end

_CHECK_OPTN_NUMBER = function (x)
    if _type(x) == "string" then
        x = tonumber(x) or x
    end
end

_BIN_OPP = function (opp check)
    --- Classic opperations
    --- Unstack 2
    --- Stack 1, the result
    --- arg1: -
    --- arg2: -
    x = ms[msp-1]
    y = ms[msp]

    _CHECK_check x
    _CHECK_check y

    msp = msp-1
    ms[msp] = x opp y
end

_UN_OPP = function (opp check)
    --- Classic opperations
    --- Unstack 1
    --- Stack 1, the result
    --- arg1: -
    --- arg2: -
    x = ms[msp]

    _CHECK_check (x)

    ms[msp] = opp x
end


_CHECK_NUMBER_META = function (x)
    if _type(x) == "string" then
        x = tonumber(x)
        if not x then
            err = "Cannot convert the string value to a number."
        end
    elseif _type(x) ~= "number" then
        if _type(x) == "table" and x.meta.table.tonumber then
            local meta = x.meta.table.tonumber
            local params = {}
            _CALL meta params
            x = callResult
        else
            err = "Cannot do comparison or arithmetic with " .. _type(x).. " value."
        end
    end
end

_HANDLE_META_BIN = function (name)
    local meta
    local params
    if _type(x) == "table" and x.meta and x.meta.table.(name)r then
        meta = x.meta.table.(name)r
        params = {y, x} -- self last
    elseif _type(y) == "table" and y.meta and y.meta.table.(name)l then
        meta = y.meta.table.(name)l
        params = {x, y}
    elseif _type(x) == "table" and x.meta and x.meta.table.name then
        meta = x.meta.table.name
        params = {x, y, x}
    elseif _type(y) == "table" and y.meta and y.meta.table.name then
        meta = y.meta.table.name
        params = {x, y, y}
    end

    if not meta then
        _ERROR err
    end

    _CALL meta params

    ms[msp] = callResult
end

_BIN_OPP_META = function (opp name)
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META x
    _CHECK_NUMBER_META y

    msp = msp-1

    if err then
        _HANDLE_META_BIN name
    else
        ms[msp] = x opp y
    end
end

_HANDLE_META_UN = function (name)
    local meta
    local params = {x}
    if _type(x) == "table" and x.meta and x.meta.table.name then
        meta = x.meta.table.name
    end

    if not meta then
        _ERROR err
    end

    _CALL meta params

    ms[msp] = callResult
end

_UN_OPP_META = function (opp name)
    x = ms[msp]

    local err

    _CHECK_NUMBER_META x

    if err then
        _HANDLE_META_UN name
    else
        ms[msp] = opp x
    end
end

OPP_ADD = function (_BIN_OPP_META + add end)
OPP_MUL = function (_BIN_OPP_META * mul end)
OPP_SUB = function (_BIN_OPP_META - sub end)
OPP_DIV = function (_BIN_OPP_META / div end)
OPP_MOD = function (_BIN_OPP_META % mod end)
OPP_POW = function (_BIN_OPP_META ^ pow end)
OPP_NEG = function (_UN_OPP_META  - minus end)

-- comp
OPP_G = function (T)
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META x
    _CHECK_NUMBER_META y

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
            _ERROR err
        end

        _CALL meta params

        if invert then
            callResult = not callResult
            if callResult then
                ms[msp] = callResult
            else
                msp = msp+1
                OPP_EQ
            end
        else
            ms[msp] = callResult
        end
    else
        ms[msp] = x > y
    end
end

OPP_L = function (T)
    x = ms[msp-1]
    y = ms[msp]

    local err

    _CHECK_NUMBER_META x
    _CHECK_NUMBER_META y

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
            _ERROR err
        end

        _CALL meta params

        if invert then
            callResult = not callResult
            if callResult then
                ms[msp] = callResult
            else
                msp = msp+1
                OPP_EQ
            end
        else
            ms[msp] = callResult
        end

    else
        ms[msp] = x < y
    end
end

OPP_E = function (Q)
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
        _CALL meta params
        ms[msp] = callResult
    else
        _CHECK_OPTN_NUMBER x
        _CHECK_OPTN_NUMBER y
        ms[msp] = x == y
    end
end

OPP_NE = function (Q)
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
        _CALL meta params
        ms[msp] = not callResult
    else
        _CHECK_OPTN_NUMBER x
        _CHECK_OPTN_NUMBER y
        ms[msp] = x ~= y
    end
end

-- bool
OPP_AND = function (_BIN_OPP and BOOL end)
OPP_OR = function (_BIN_OPP or  BOOL end)
OPP_NOT = function (_UN_OPP  not BOOL end)