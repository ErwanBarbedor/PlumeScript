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
	--- Return the source filename, if exists and differents from processing one, of an imported variable. 
	--- Used when name conflict between file variables and variables imported via `use`.
	--- @param name string Name of the variable
	--- @param isStatic bool
	--- @return string|nil
	function context.getNameSource(name, isStatic)
		local scope
		if isStatic then
			scope = context.static
		else
			scope = context.getCurrentScope()
		end

		if scope[name] then
			return scope[name].source
		end
	end
	
	--- Get informations about a variable by it's name.
	--- Return nil if the variable hasn't be registered
	--- @param name string The name of the variable
	--- @return table|nil {frameOffset?, offset, isConst, isStatic}
	function context.getVariable(name)
		for i=#context.scopes, context.roots[#context.roots], -1 do
			local current = context.scopes[i]
			if current[name] then
				local variable = current[name]
				local result = {
					frameOffset = #context.scopes-i,
					offset   = variable.offset,
					isConst  = variable.isConst,
					isRef    = variable.isRef
				}

				if variable.isRef then
					result.frameOffset = context.accBlockDeep - variable.blockOffset
				end

				return result
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

	--- Add a constant (raw strings or number found in the sourcecode) to the constant table.
	--- @param value any The value to register.
	--- @return number Offset of the constant, used by the opcode LOAD_CONSTANT
	function context.registerConstant(value)
		local key = tostring(value) -- for numeric keys
		if not context.constants[key] then
			table.insert(context.constants, value)
			context.constants[key] = #context.constants
		end
		return context.constants[key]
	end

	--- Register a variable by its name in the local or static scope.
	--- @param name string The name of the variable.
	--- @param isStatic boolean Store in the static scope.
	--- @param isConst boolean Flag to prevent future edits.
	--- @param isParam boolean True if it should be initialized by the calling script.
	--- @param staticValue any Initial value for static vars (compilation time, default to empty).
	--- @param source string|nil The path to the file if imported via `use`.
	--- @param isRef boolean True if it is a reference to a table field
	--- @return table|nil Returns the variable metadata {offset, isStatic, isConst, isRef, source}, or nil on name collision.
	function context.registerVariable(name, isStatic, isConst, isParam, staticValue, source, isRef)
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
		
		-- Why count var by inserting empty table?
		-- Certainly legacy code that should be examinated
		table.insert(scope, {scope[name]}) 

		scope[name] = {
			offset = #scope, -- Used by opcodes GET_LOCAL / SET_LOCAL to use the correct frame
			isStatic = isStatic,
			isConst = isConst,
			isRef = isRef,
			source = source
		}

		if isRef then
			scope[name].blockOffset = context.accBlockDeep
		end

		if isParam then
			-- Files parameters are always named.
			context.chunk.namedParamCount = context.chunk.namedParamCount+1
			context.chunk.namedParamOffset[name] = #scope
		end

		return scope[name]
	end

end