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

--=====================--
-- Instruction format --
--=====================--
local bit = require("bit")
local OP_BITS   = 7
local ARG1_BITS = 5
local ARG2_BITS = 20
local ARG1_SHIFT = ARG2_BITS
local OP_SHIFT   = ARG1_BITS + ARG2_BITS
local MASK_OP   = bit.lshift(1, OP_BITS) - 1
local MASK_ARG1 = bit.lshift(1, ARG1_BITS) - 1
local MASK_ARG2 = bit.lshift(1, ARG2_BITS) - 1

--================--
-- Initalization --
--===============--
function _VM_INIT (plume, chunk, arguments)
    require("table.new")

    --! table-to-remove vm
    local vm = {} 
    
    -- to avoid context injection
    vm.plume = plume -- !to-remove

    _VM_INIT_VARS(vm, chunk)
    _VM_INIT_ARGUMENTS(vm, chunk, arguments)

    return vm
end

--! inline
function _VM_INIT_VARS(vm, chunk)
    vm.chunk = chunk
    vm.bytecode  = chunk.bytecode
    vm.constants = chunk.constants
    vm.static    = chunk.static

    -- instruction pointer
    vm.ip      = 0
    -- total instruction count
    vm.tic     = 0

    vm.mainStack                = table.new(2^14, 0)
    vm.mainStack.frames         = table.new(2^8, 0)
    vm.mainStack.pointer        = 0 -- !index-to-inline
    vm.mainStack.frames.pointer = 0 -- !index-to-inline

    vm.variableStack                = table.new(2^10, 0)
    vm.variableStack.frames         = table.new(2^8, 0)
    vm.variableStack.pointer        = 0  -- !index-to-inline
    vm.variableStack.frames.pointer = 0 -- !index-to-inline

    -- easier debuging than setting vm.ip
    vm.jump    = 0

    -- local variables
    vm.empty = vm.plume.obj.empty
end

--! inline
function _VM_INIT_ARGUMENTS(vm, chunk, arguments)
    if arguments then
        if chunk.isFile then
            for k, v in pairs(arguments) do
                local offset = chunk.namedParamOffset[k]
                if offset then
                    chunk.static[offset] = v
                end
            end
        -- macro
        else 
            for i=1, chunk.localsCount do
                if arguments[i] == nil then
                    _STACK_SET(vm.variableStack, i, vm.empty)
                else
                    _STACK_SET(vm.variableStack, i, arguments[i])
                end
            end

            _STACK_MOVE(vm.variableStack, chunk.localsCount)
            _STACK_PUSH(vm.variableStack.frames, 1)
        end
    end
end
--! inline

function _VM_TICK (vm)
    --! to-remove-begin
    if vm.plume.hook then
        if vm.ip>0 then 
            local instr, op, arg1, arg2
            instr = vm.bytecode[vm.ip]
            op, arg1, arg2 = _VM_DECODE_CURRENT_INSTRUCTION(vm)

            vm.plume.hook (
                vm.chunk,
                vm.tic,
                vm.ip,
                vm.jump,
                instr,
                op,
                arg1,
                arg2,
                vm.mainStack,
                vm.mainStack.pointer,
                vm.mainStack.frames,
                vm.mainStack.frames.pointer,
                vm.variableStack,
                vm.variableStack.pointer,
                vm.variableStack.frames,
                vm.variableStack.frames.pointer
            )
        end       
    end  
    --! to-remove-end

    if vm.jump>0 then
        vm.ip = vm.jump
        vm.jump = 0-- 0 instead of nil to preserve type
    else
        vm.ip = vm.ip+1
    end
    vm.tic = vm.tic+1
end

function _VM_DECODE_CURRENT_INSTRUCTION(vm)
    local instr, op, arg1, arg2
    instr = vm.bytecode[vm.ip]
    op    = bit.band(bit.rshift(instr, OP_SHIFT), MASK_OP)
    arg1  = bit.band(bit.rshift(instr, ARG1_SHIFT), MASK_ARG1)
    arg2  = bit.band(instr, MASK_ARG2)

    return op, arg1, arg2
end