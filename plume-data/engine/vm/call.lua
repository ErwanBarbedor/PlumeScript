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
--- Take the stack top to call, with all elements of the current frame as parameters.
--- Stack the call result (or empty if nil)
--- Handle macros and luaFunctions
--! inline
function CONCAT_CALL (vm, arg1, arg2)
    local tocall = _STACK_POP(vm.mainStack)
    local t = _GET_TYPE(vm, tocall)
    local self

    -- Table can be called with, if exists, the meta-field call
    if t == "table" then
        if tocall.meta and tocall.meta.table.call then
            self = tocall
            tocall = tocall.meta.table.call
            t = tocall.type
        end
    end

    -- Macro
    if t == "chunk" then
        _CALL_CHUNK(vm, tocall)

    -- Std functions defined in lua or user lua functions
    elseif t == "luaFunction" then
        CONCAT_TABLE(vm)
        table.insert(vm.runtime.callstack, {runtime=vm.runtime, macro=tocall, ip=vm.ip})
        local success, result  =  pcall(tocall.callable, _STACK_GET(vm.mainStack), vm.runtime)
        if success then
            table.remove(vm.runtime.callstack)
            if result == nil then
                result = vm.empty
            end
            _STACK_POP(vm.mainStack)
            _STACK_PUSH(vm.mainStack, result)
        else
            _ERROR(vm, result)
        end

    -- Some harcoded std functions
    elseif t == "luaStdFunction" then
        CONCAT_TABLE(vm)
        _INJECTION_PUSH(vm, tocall.opcode, 0, 0)

    -- @table ... end just return the accumulated table
    elseif tocall == vm.plume.std.table then
        CONCAT_TABLE(vm)
    else
        _ERROR (vm, vm.plume.error.cannotCallValue(t))
    end
end

---@param vm VM The virtual machine instance.
---@param chunk table The function chunk to call.
--! inline
function _CALL_CHUNK(vm, chunk)
    local allocationCount = chunk.positionalParamCount + chunk.namedParamCount

    if chunk.variadicOffset then
        allocationCount = allocationCount + 1
    end

    ENTER_SCOPE(vm, 0, allocationCount) -- Create a new scope

    -- Distribute arguments to locals and get the overflow table
    local variadicTable = _CONCAT_TABLE(vm, chunk.positionalParamCount, chunk.namedParamOffset)

    -- If the chunk expects a variadic argument, assign the table to the specific register
    if chunk.variadicOffset then
        _STACK_SET_FRAMED(vm.variableStack, chunk.variadicOffset - 1, 0, variadicTable)
    end

    _STACK_POP_FRAME(vm.mainStack)        -- Clean stack from arguments
    _STACK_PUSH(vm.macroStack, vm.ip + 1) -- Set the return pointer
    JUMP(vm, 0, chunk.offset)             -- Jump to macro body
end

--- @opcode
--! inline
function RETURN(vm, arg1, arg2)
    LEAVE_SCOPE(vm, 0, 0) -- close macro stop
    JUMP(vm, 0, _STACK_POP(vm.macroStack)) -- return in the previous position
end

--- Collect postionnals argument from the current stack
--- @param macro macro Used for debug message
--- @param arguments table Table to store arguments
--- @param capture table Table to store leftover arguments
--- @return nil
--! inline
function _UNSTACK_POS (vm, macro, arguments, capture)
    local argcount = _STACK_POS(vm.mainStack) - _STACK_GET(vm.mainStack.frames)
    if argcount ~= macro.positionalParamCount and macro.variadicOffset==0 then
        local name
        -- Last OP_CODE before call is loading the macro by it's name
        if vm.runtime.mapping[vm.ip-1] then
            name = vm.runtime.mapping[vm.ip-1].content
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

--- Collect named argument from the current stack
--- Use the same rules as CONCAT_TABLE
--- @param macro macro Used for debug message
--- @param arguments table Table to store named arguments
--- @param capture table Table to store meta and leftover arguments
--- @return nil
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
            err =  vm.plume.error.unknowParameter(k, name)
        end
    end

    if err then
        _ERROR(vm, err)
    else
        _STACK_POP(vm.mainStack)
    end
end

--- Call a given macro, keep trace of execution in callstack, and return the result.
--- Throw stack overflow errors if callstack is too big.
--- @param macro macro The macro to call
--- @param arguments table Arguments for the call
--- @return any Call result
--! inline
function _CALL (vm, macro, arguments)
    table.insert(vm.plume.runtime.callstack, {chunk=vm.plume.runtime, macro=macro, ip=vm.ip})
    if #vm.plume.runtime.callstack<=500 then
        local success, callResult, cip, source  = vm.plume.run(macro, arguments)
        if success then
            table.remove(vm.plume.runtime.callstack)
            return callResult
        else
            _SPECIAL_ERROR(vm, callResult, cip, (source or macro) )
        end
    else
        _ERROR (vm, vm.plume.error.stackOverflow())
    end
end