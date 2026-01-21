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

return function (plume, context)
	--- Insert a label. Serves as the basis for plume.finalize to calculate
	--- the offset of goto statements. Does not appear in the final bytecode.
	--- @param node node Emiting node
	--- @param name string Unique name of this label
	function context.registerLabel(node, name)
		local current = context.runtime.instructions
		table.insert(current, {label=name, mapsto=node})
	end

	--- Insert a goto. Will be resolved as a JUMP opcode, to the offset
	--- determined by the label with the same name.
	--- @param node node Emiting node
	--- @param name string Unique name of this label
	--- @param jump string|nil Jump method to use. Default to JUMP.
	--- Can be: JUMP_IF JUMP_IF_NOT JUMP_IF_NOT_EMPTY JUMP JUMP_IF_PEEK JUMP_IF_NOT_PEEK
	function context.registerGoto(node, name, jump)
		local current = context.runtime.instructions
		table.insert(current, {_goto=name, jump=jump or "JUMP", mapsto=node})
	end
end