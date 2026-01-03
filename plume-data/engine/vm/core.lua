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
function _VM_INIT ()

    require("table.new")

    local bytecode    = chunk.bytecode
    local constants   = chunk.constants
    local static      = chunk.static

    local ip      = 0 -- instruction pointer
    local tic     = 0 -- total instruction count

    local ms   = table.new(2^14, 0) -- main stack
    local msf  = table.new(2^8, 0)  -- main stack frames (accumulators)
    local msp  = 0                  -- pointers
    local msfp = 0

    local vs   = table.new(2^10, 0)  -- variables stack
    local vsf  = table.new(2^8, 0)   -- variables stack frames (lexical scope)
    local vsp  = 0                   -- pointers
    local vsfp = 0

    local jump    = 0 -- easier debuging than setting ip
    local instr, op, vm, arg1, arg2 = 0, 0, 0, 0

    --debug
    local hook = plume.hook

    --------------------
    -- When is called -- 
    --------------------

    if parameters then
        if chunk.isFile then
            for k, v in pairs(parameters) do
                local offset = chunk.namedParamOffset[k]
                if offset then
                    chunk.static[offset] = v
                end
            end
        else -- macro
            for i=1, chunk.localsCount do
                if parameters[i] == nil then
                    vs[i] = empty
                else
                    vs[i] = parameters[i]
                end
            end

            vsp = chunk.localsCount
            vsfp = 1
            table.insert(vsf, 1)
        end
    end
end

function _VM_DEBUG ()
end

function _VM_TICK ()
end

function _VM_DECODE_CURRENT_INSTRUCTION()
end