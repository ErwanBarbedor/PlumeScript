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
    local tocall = _STACK_POP(vm.mainStack)
    local t = _GET_TYPE(vm, tocall)
    local self

    if t == "table" then
        if tocall.meta and tocall.meta.table.call then
            self = tocall
            tocall = tocall.meta.table.call
            t = tocall.type
        end
    end

    if t == "macro" then
        local capture = vm.plume.obj.table(0, 0)
        local arguments = {}

        _UNSTACK_POS   (vm, tocall, arguments, capture)
        _UNSTACK_NAMED (vm, tocall, arguments, capture)

        -- Add self to params
        if self then  
            table.insert(arguments, self)
        end

        if tocall.variadicOffset>0 then -- variadic
            arguments[tocall.variadicOffset] = capture
        end
        _END_ACC(vm)

        _STACK_PUSH(
            vm.mainStack,
            _CALL (vm, tocall, arguments)
        )

    elseif t == "luaFunction" then
        ACC_TABLE(vm)
        table.insert(vm.chunk.callstack, {chunk=vm.chunk, macro=tocall, ip=vm.ip})
        local success, result  =  pcall(tocall.callable, _STACK_GET(vm.mainStack), vm.chunk)
        if success then
            table.remove(vm.chunk.callstack)
            if result == nil then
                result = vm.empty
            end
            _STACK_POP(vm.mainStack)
            _STACK_PUSH(vm.mainStack, result)
        else
            _ERROR(vm, result)
        end
        
    else
        _ERROR (vm, vm.plume.error.cannotCallValue(t))
    end
end

--! inline
function _UNSTACK_POS (vm, macro, arguments, capture)
    local argcount = _STACK_POS(vm.mainStack) - _STACK_GET(vm.mainStack.frames)
    if argcount ~= macro.positionalParamCount and macro.variadicOffset==0 then
        local name

        -- Last OP_CODE before call is loading the macro
        -- by it's name
        if vm.chunk.mapping[vm.ip-1] then
            name = vm.chunk.mapping[vm.ip-1].content
        end

        if not name then
            name = macro.name or "???"
        end

        _ERROR (vm, vm.plume.error.wrongArgsCount(name, argcount, macro.positionalParamCount))
    end

    for i=1, macro.positionalParamCount do
        arguments[i] = _STACK_GET_OFFSET(vm.mainStack, i-argcount)
    end

    for i=macro.positionalParamCount+1, argcount do
        table.insert(capture.table, _STACK_GET_OFFSET(vm.mainStack, i-argcount))
    end

    _STACK_MOVE_FRAMED(vm.mainStack)
end

--! inline
function _UNSTACK_NAMED (vm, macro, arguments, capture)
    local stack_bottom = _STACK_GET_FRAMED(vm.mainStack)
    local err
    for i=1, #stack_bottom, 3 do
        local k=stack_bottom[i]
        local v=stack_bottom[i+1]
        local m=stack_bottom[i+2]
        local j = macro.namedParamOffset[k]
        if m then
            _TABLE_META_SET (vm, capture, k, v)
        elseif j then
            arguments[j] = v
        elseif macro.variadicOffset>0 then
            _TABLE_SET (vm, capture, k, v)
        else
            local name = macro.name or "???"
            err =  "Unknow named parameter '" .. k .."' for macro '" .. name .."'."
        end
    end

    if err then
        _ERROR(vm, err)
    else
        _STACK_POP(vm.mainStack)
    end
end

--! inline
function _CALL (vm, macro, arguments)
    table.insert(vm.chunk.callstack, {chunk=vm.chunk, macro=macro, ip=vm.ip})
    if #vm.chunk.callstack<=1000 then
        local success, callResult, cip, source  = vm.plume.run(macro, arguments)
        if success then
            table.remove(vm.chunk.callstack)
            return callResult
        else
            _SPECIAL_ERROR(vm, callResult, cip, (source or macro) )
        end
    else
        _ERROR (vm, vm.plume.error.stackOverflow())
    end
end