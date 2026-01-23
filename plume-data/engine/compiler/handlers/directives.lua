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
	--- `use` directive execute a file that must return a table,
	--- and load all keys as constants into the current file static table.
	nodeHandlerTable.USE = function(node)
		local path = node.content

		-- Same path resolver as `import`
		local filename, searchPaths = plume.getFilenameFromPath(path, false, context.runtime, context.chunk.name, context.chunk.name )
		if not filename then
            plume.error.compilationCannotOpenFile(node, path, searchPaths)
		end

		local success, result = plume.executeFile(filename, context.runtime)
        if not success then
            plume.error.cannotExecuteFile(node, path, result)
        end

        local t = type(result) == "table" and result.type or type(result)
        if t ~= "table" then
        	plume.error.fileMustReturnATable(node, path, t)
        end

        for _, key in ipairs(result.keys) do
        	local var = context.registerVariable(
        		key,                -- name
        		true,               -- isStatic,
        		true,               -- isConst,
        		false,              -- isParam
        		result.table[key],  -- staticValue
        		path                -- source
        	)
			if not var then
				plume.error.useExistingStaticVariableError(node, key, path)
			end
        end

        return result
	end

end