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

--================--
-- Initalization --
--===============--
--- Initiialize the VM
--- @param runtime runtime The runtime to execute
--! inline-nodo
function _VM_INIT (plume, runtime, ip)
    require("table.new")

    local vm = {} --! to-remove
    
    -- to avoid context injection
    vm.plume = plume --! to-remove

    _VM_INIT_VARS(vm, runtime, ip)

    return vm --! to-remove
end

--- Declare all vm variables
--- @param runtime runtime The runtime to execute
--! inline-nodo
function _VM_INIT_VARS(vm, runtime, chunk)
    --! index-to-inline vm.err vmerr
    --! index-to-inline vm.serr vmserr
    --! index-to-inline vm.* *
    --! index-to-inline mainStack.*
    --! index-to-inline variableStack.*
    --! index-to-inline mainStackFrames.*
    --! index-to-inline variableStackFrames.*
    --! index-to-inline fileStack.*
    --! index-to-inline macroStack.*
    --! index-to-inline injectionStack.*
    --! index-to-inline flag.* *

    vm.runtime   = runtime
    vm.bytecode  = runtime.bytecode
    vm.constants = runtime.constants
    vm.static    = runtime.static

    -- instruction pointer
    vm.ip      = chunk.offset - 1
    -- total instruction count
    vm.tic     = 0

    vm.mainStack                = table.new(2^14, 0)
    vm.mainStack.frames         = table.new(2^8, 0)
    vm.mainStack.pointer        = 0
    vm.mainStack.frames.pointer = 0

    vm.variableStack                = table.new(2^10, 0)
    vm.variableStack.frames         = table.new(2^8, 0)
    vm.variableStack.pointer        = 0
    vm.variableStack.frames.pointer = 0

    vm.fileStack = table.new(2^8, 0)
    vm.fileStack[1] = chunk.fileID
    vm.fileStack.pointer = 1

    vm.macroStack = table.new(2^8, 0)
    vm.macroStack.pointer = 0

    vm.injectionStack         = table.new(64, 0)
    vm.injectionStack.pointer = 0

    vm.tagStack = table.new(2^14, 0)

    -- easier debuging than setting vm.ip
    vm.jump    = 0

    -- local variables
    vm.empty = vm.plume.obj.empty

    -- flag
    vm.flag = {}
    vm.flag.ITER_TABLE = 0
    vm.flag.ITER_SEQ = 1
    vm.flag.ITER_ITEMS = 2
    vm.flag.ITER_ENUMS = 3

    --=====================--
    -- Instruction format --
    --=====================--
    vm.bit = require("bit")
    vm.OP_BITS    = vm.plume.OP_BITS
    vm.ARG1_BITS  = vm.plume.ARG1_BITS
    vm.ARG2_BITS  = vm.plume.ARG2_BITS
    vm.ARG1_SHIFT = vm.ARG2_BITS
    vm.OP_SHIFT   = vm.ARG1_BITS + vm.ARG2_BITS
    vm.MASK_OP    = vm.bit.lshift(1, vm.OP_BITS) - 1
    vm.MASK_ARG1  = vm.bit.lshift(1, vm.ARG1_BITS) - 1
    vm.MASK_ARG2  = vm.bit.lshift(1, vm.ARG2_BITS) - 1
    vm.band       = vm.bit.band
    vm.rshift     = vm.bit.rshift
    ---------------------------

    --! to-remove-begin
    if vm.plume.runStatFlag then
        vm.stats = {}
        vm.stats.opseq = {} -- opcode sequences
        
        -- queue for opcodes history
        vm.stats.ophist = 0
        vm.stats.histmask = 128^vm.plume.runStatDeep
    end
    --! to-remove-end
end

--- Register opcodes usages
function _STAT_REGISTER(vm, op)
    -- Update history
    vm.stats.ophist = ((vm.stats.ophist % vm.stats.histmask) * 128) + op
    -- Update sequences
    vm.stats.opseq[vm.stats.ophist] = 1 + (vm.stats.opseq[vm.stats.ophist] or 0)
end

--- Called at each instruction.
--- Jump if needed and increment instruction counter
--! inline-nodo
function _VM_TICK (vm)
    if vm.jump>0 then
        vm.ip = vm.jump
        vm.jump = 0-- 0 instead of nil to preserve type
    else
        vm.ip = vm.ip+1
    end
    vm.tic = vm.tic+1
end

--- Decoding opcode and arguments from instruction
--! inline-nodo
function _VM_DECODE_CURRENT_INSTRUCTION(vm)
    local op, arg1, arg2
    if _CAN_INJECT(vm) then
        op, arg1, arg2 = _INJECTION_POP(vm)
    else    
        _VM_TICK(vm)
        local instr = vm.bytecode[vm.ip]
        op    = vm.band(vm.rshift(instr, vm.OP_SHIFT), vm.MASK_OP)
        arg1  = vm.band(vm.rshift(instr, vm.ARG1_SHIFT), vm.MASK_ARG1)
        arg2  = vm.band(instr, vm.MASK_ARG2)
    end

    --! to-remove-begin
    if vm.plume.hook then
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
    if vm.plume.runStatFlag then
        _STAT_REGISTER(vm, op)
    end
    --! to-remove-end

    return op, arg1, arg2
end