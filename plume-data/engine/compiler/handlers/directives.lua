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

return function (plume, context, nodeHandlerTable)
	nodeHandlerTable.USE = function(node)
		local path = node.content
		local filename, searchPaths = plume.getFilenameFromPath(path, false, context.chunk)

		if not filename then
            plume.error.cannotOpenFile(node, path, searchPaths)
		end

		local success, result = plume.executeFile(filename, context.chunk.state, false)
        if not success then
            plume.error.cannotExecuteFile(node, path, result)
        end

        local t = type(result) == "table" and result.type or type(result)
        if t ~= "table" then
        	plume.error.fileMustReturnATable(node, path, t)
        end

        for _, key in ipairs(result.keys) do
        	local var = context.registerVariable(key, true, true, false, result.table[key], path)
			if not var then
				plume.error.useExistingStaticVariableError(node, key, path)
			end
        end

        return result
	end

end