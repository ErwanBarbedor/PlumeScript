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
	function context.registerLabel(node, name)
		local current = context.getLast("chunks").instructions
		current[#current+1] = {label=name, mapsto=node}
	end
	
	function context.registerGoto(node, name, jump)
		local current = context.getLast("chunks").instructions
		current[#current+1] = {_goto=name, jump=jump or "JUMP", mapsto=node}
	end

	function context.registerMacroLink(node, offset)
		local current = context.getLast("chunks").instructions
		current[#current+1] = {link=offset, mapsto=node}
	end
end