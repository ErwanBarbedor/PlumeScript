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
function _UNSTACK_POS ()
    local argcount = msp-msf[msfp]
    if argcount ~= macro.positionalParamCount and macro.variadicOffset==0 then
        local name

        -- Last OP_CODE before call is loading the macro
        -- by it's name
        if chunk.mapping[ip-1] then
            name = chunk.mapping[ip-1].content
        end

        if not name then
            name = macro.name or "???"
        end

        _ERROR ("Wrong number of positionnal arguments for macro '" .. name .. "', " ..   argcount .. " instead of " .. macro.positionalParamCount .. ".")
    end

    for i=1, macro.positionalParamCount do
        parameters[i] = ms[msp+i-argcount]
    end

    for i=macro.positionalParamCount+1, argcount do
        table.insert(capture.table, ms[msp+i-argcount])
    end

    msp = msf[msfp]
end

function _UNSTACK_NAMED ()
    for i=1, #ms[msf[msfp]], 3 do
        local k=ms[msf[msfp]][i]
        local v=ms[msf[msfp]][i+1]
        local m=ms[msf[msfp]][i+2]
        local j = macro.namedParamOffset[k]
        if m then
            _TABLE_META_SET (capture, k, v)
        elseif j then
            parameters[j] = v
        elseif macro.variadicOffset>0 then
            _TABLE_SET (capture, k, v)
        else
            local name = macro.name or "???"
            _ERROR("Unknow named parameter '" .. k .."' for macro '" .. name .."'.")
        end
    end    
    msp = msp-1
end

function _CALL (macro, parameters)
    table.insert(chunk.callstack, {chunk=chunk, macro=macro, ip=ip})
    if #chunk.callstack>1000 then
        _ERROR ("stack overflow")
    end

    local success, callResult, cip, source  = plume.run(macro, parameters)
    if not success then
        return success, callResult, cip, (source or macro)
    end
    table.remove(chunk.callstack)
end

function ACC_CALL (vm, arg1, arg2)
    --- Unstack 1 (the macro)
    --- Unstack until frame begin + 1 (all positionals arguments)
    --- Unstack 1 (table of named arguments)
    --- Create a new scope
    --- Stack all arguments to varstack
    --- Set jump to macro offset
    --- Stack current ip to calls
    --- arg1: -
    --- arg2: -
    local macro = ms[msp]
    msp = msp - 1
    local t = _type(macro)
    local self

    if t == "table" then
        if macro.meta and macro.meta.table.call then
            local params = ms[msp]
            self = macro

            t = macro.meta.table.call.type
            macro = macro.meta.table.call
        end
    end

    if t == "macro" then
        local capture
        local parameters = {}
        if macro.variadicOffset>0 then -- variadic
            capture = ptable(0, 0) -- can be optimized
        end
        _UNSTACK_POS()
        _UNSTACK_NAMED()

        -- Add self to params
        if self then  
            table.insert(parameters, self)
        end

        if macro.variadicOffset>0 then -- variadic
            parameters[macro.variadicOffset] = capture
        end
        _END_ACC()
        _CALL (macro, parameters)
        msp = msp+1
        ms[msp] = callResult
    elseif t == "luaFunction" then
        ACC_TABLE()
        table.insert(chunk.callstack, {chunk=chunk, macro=macro, ip=ip})
        local success, result  =  pcall(macro.callable, ms[msp], chunk)
        if not success then
            return success, result, ip, chunk
        end
        table.remove(chunk.callstack)

        if result == nil then
            result = empty
        end
        ms[msp] = result
    else
        _ERROR ("Try to call a '" .. t .. "' value")
    end
end

function RETURN (vm, arg1, arg2)
    --- Unstack 1 from calls
    --- Set jump to it
    --- Leave scope
    --- arg1: -
    --- arg2: -
    jump = calls[cp]
    if not jump then -- exit the main programm
        jump = #bytecode -- goto to END
    end
    cp = cp - 1
    LEAVE_SCOPE (0, 0)
end