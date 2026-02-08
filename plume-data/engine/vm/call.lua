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
    if t == "macro" then
        if self then
            _PUSH_SELF(vm, self)
        end

        _CALL_MACRO(vm, tocall)

    -- Std functions defined in lua or user lua functions
    elseif t == "luaFunction" then
        CONCAT_TABLE(vm)
        table.insert(vm.runtime.callstack, {runtime=vm.runtime, macro=tocall, ip=vm.ip})
        local success, result  =  pcall(tocall.callable, _STACK_POP(vm.mainStack), vm.runtime, _STACK_GET(vm.fileStack), vm.ip)
        if success then
            table.remove(vm.runtime.callstack)
            if result == nil then
                result = vm.empty
            end
            
            _STACK_PUSH(vm.mainStack, result)
        else
            _ERROR(vm, result)
        end

    -- Some harcoded std functions
    elseif t == "luaStdFunction" then
        local args = CONCAT_TABLE(vm)
        if #args.table < tocall.minArgs or #args.table > tocall.maxArgs then
            _ERROR(vm, vm.plume.error.wrongArgsCountStd(tocall.name, #args.table, tocall.minArgs, tocall.maxArgs))
        end

        _INJECTION_PUSH(vm, tocall.opcode, 0, 0)

    -- @table ... end just return the accumulated table
    elseif tocall == vm.plume.std.table then
        CONCAT_TABLE(vm)

    -- CHECK_IS_TEXT do exactly the same thing as tostring
    elseif tocall == vm.plume.std.tostring then
        local value = _STACK_POP(vm.mainStack)
        _STACK_POP_FRAME(vm.mainStack)
        _STACK_PUSH(vm.mainStack, value)
        -- Should check for to many arguments, instead of ignoring them
        _INJECTION_PUSH(vm, vm.plume.ops.CHECK_IS_TEXT, 0, 0)
    
    else
        _ERROR (vm, vm.plume.error.cannotCallValue(t))
    end
end

---@param vm VM The virtual machine instance.
---@param chunk table The function chunk to call.
--! inline
function _CALL_MACRO(vm, chunk)
    local allocationCount = chunk.positionalParamCount + chunk.namedParamCount

    if chunk.variadicOffset then
        allocationCount = allocationCount + 1
    end
    
    ENTER_SCOPE(vm, 0, chunk.localsCount) -- Create a new scope

    -- Distribute arguments to locals and get the overflow table
    local variadicTable, tomanyPositionnalCounter, capturedCount, unknowNamed = _CONCAT_TABLE(
        vm,
        chunk.positionalParamCount,
        chunk.namedParamOffset,
        chunk.variadicOffset
    )

    if tomanyPositionnalCounter>0 then
        _ERROR(vm, vm.plume.error.wrongArgsCount(
            chunk.name,
            chunk.positionalParamCount+tomanyPositionnalCounter,
            chunk.positionalParamCount
        ))
    elseif capturedCount < chunk.positionalParamCount then
        _ERROR(vm, vm.plume.error.wrongArgsCount(
            chunk.name,
            capturedCount,
            chunk.positionalParamCount
        ))
    elseif unknowNamed then
        _ERROR(vm, vm.plume.error.unknowParameter(unknowNamed, chunk.name))
    else
        -- If the chunk expects a variadic argument, assign the table to the specific register
        if chunk.variadicOffset then
            _STACK_SET_FRAMED(vm.variableStack, chunk.variadicOffset - 1, 0, variadicTable)
        end

        table.insert(vm.runtime.callstack, {macro=chunk, ip=vm.ip})
        if #vm.runtime.callstack<=1000 then
            _STACK_POP_FRAME(vm.mainStack)        -- Clean stack from arguments
            _STACK_PUSH(vm.macroStack, vm.ip + 1) -- Set the return pointer
            JUMP(vm, 0, chunk.offset)             -- Jump to macro body  
        else
            _ERROR (vm, vm.plume.error.stackOverflow())
        end
    end
end

--- @opcode
--! inline
function RETURN(vm, arg1, arg2)
    LEAVE_SCOPE(vm, 0, 0) -- close macro scope
    table.remove(vm.runtime.callstack)
    JUMP(vm, 0, _STACK_POP(vm.macroStack)) -- return in the previous position
end