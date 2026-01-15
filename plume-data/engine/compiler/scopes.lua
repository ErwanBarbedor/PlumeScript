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
	function context.getCurrentScope()
		return context.scopes[#context.scopes]
	end

	function context.getVariable(name)
		for i=#context.scopes, context.roots[#context.roots], -1 do
			local current = context.scopes[i]
			if current[name] then
				local variable = current[name]
				return {
					frameOffset = #context.scopes-i,
					offset   = variable.offset,
					isConst  = variable.isConst,	
				}
			end
		end
		if context.static[name] then
			local variable = context.static[name]
			return {
				offset   = variable.offset,
				isConst  = variable.isConst,
				isStatic = variable.isStatic	
			}
		end
	end

	function context.registerConstant(value)
			local key = tostring(value) -- for numeric keys
			if not context.constants[key] then
				table.insert(context.constants, value)
				context.constants[key] = #context.constants
			end
			return context.constants[key]
		end

	function context.registerVariable(name, isStatic, isConst, isParam, staticValue, source)
		local scope
		if isStatic then
			scope = context.static
			table.insert(context.chunk.static, staticValue or plume.obj.empty)
		else
			scope = context.getCurrentScope()
		end

		-- To avoid conflicts between static variables
		-- and non-static variables declared at the root
		if isStatic then
			if #context.scopes > 0 and context.scopes[1][name] then
				return nil
			end
		elseif #context.scopes == 1 then
			if context.static[name] then
				return nil
			end
		end 

		if scope[name] then
			return nil
		end
		
		table.insert(scope, {scope[name]})
		scope[name] = {offset = #scope, isStatic = isStatic, isConst = isConst, source = source}

		if isParam then
			context.chunk.namedParamCount = context.chunk.namedParamCount+1
			context.chunk.namedParamOffset[name] = #scope
		end

		return scope[name]
	end

end