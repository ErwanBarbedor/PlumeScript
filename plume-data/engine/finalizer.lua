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

return function (plume)

	local function link(runtime)
		local labels = {}

		local removedCount = 0
		for offset, instr in ipairs(runtime.instructions) do
			if instr.label then
				labels[instr.label] = offset - removedCount
				removedCount = removedCount + 1
			elseif instr.link then
				removedCount = removedCount + 1
			end
		end

		local computedInstructions = {}
		local removedOffset = 0
		for offset, instr in ipairs(runtime.instructions) do
			offset = offset-removedOffset
			if instr.label then
				removedOffset = removedOffset + 1
			elseif instr.link then
				removedOffset = removedOffset + 1
				runtime.constants[instr.link][2] = offset --set macro offset
			elseif instr._goto then
				if not labels[instr._goto] then
					error("Internal Error: no label " .. instr._goto)
				end

				computedInstructions[offset] = {plume.ops[instr.jump], 0, labels[instr._goto]}
			else
				computedInstructions[offset] = instr
			end
		end

		table.insert(computedInstructions, {plume.ops.END, 0, 0})
		runtime.instructions = computedInstructions
	end
	
	------------------------
    -- Instruction format --
    ------------------------
    require"table.new"
    local bit = require("bit")
    local OP_BITS   = 7
    local ARG1_BITS = 5
    local ARG2_BITS = 20
    local ARG1_SHIFT = ARG2_BITS
    local OP_SHIFT   = ARG1_BITS + ARG2_BITS
    local MASK_OP   = bit.lshift(1, OP_BITS) - 1
    local MASK_ARG1 = bit.lshift(1, ARG1_BITS) - 1
    local MASK_ARG2 = bit.lshift(1, ARG2_BITS) - 1
    ------------------------
	local function encode(runtime)
		runtime.bytecode = table.new(#runtime.instructions, 0)
		for offset, instr in ipairs(runtime.instructions) do
			local op_part = bit.lshift(bit.band(instr[1], MASK_OP), OP_SHIFT)
			local arg1_part = bit.lshift(bit.band(instr[2], MASK_ARG1), ARG1_SHIFT)
			local arg2_part = bit.band(instr[3], MASK_ARG2)
			local byte = bit.bor(op_part, arg1_part, arg2_part)
			runtime.bytecode[offset] = byte
		end
	end

	function plume.finalize(runtime)
		-- replaces labels/goto by jumps
		-- compute real macro offsets
		-- Add "end" byte
		link(runtime)
		-- Encode instruction in one 32bits int
		encode(runtime)
	end
end