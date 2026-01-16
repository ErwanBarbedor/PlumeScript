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
	nodeHandlerTable.MACRO = function(node)
		local macroIdentifier = plume.ast.get(node, "IDENTIFIER")
		local body            = plume.ast.get(node, "BODY")
		local paramList       = plume.ast.get(node, "PARAMLIST") or {children={}}
		local uid = context.getUID()

		local macroObj     = plume.newPlumeExecutableChunk(false, context.chunk.state)
		macroObj.static    = context.chunk.static
		macroObj.constants = context.constants
		local macroOffset  = context.registerConstant(macroObj)
		
		context.registerOP(macroIdentifier, plume.ops.LOAD_CONSTANT, 0, macroOffset)
		
		local macroName
		if macroIdentifier then
			macroName = macroIdentifier.content
			local variable = context.registerVariable(
				macroName,
				true -- static
			)
			if not variable then
				plume.error.letExistingStaticVariableError(node, macroName, context.getNameSource(macroName))
			end
			
			context.registerOP(macroIdentifier, plume.ops.STORE_STATIC, 0, variable.offset)
		end

		macroObj.name = macroName or node.label

		context.file(function ()
			-- Each macro open a scope, but it is handled by ACC_CALL and RETURN.
			table.insert(context.scopes, {})
			table.insert(context.loops, {})
			table.insert(context.chunks, macroObj)
			for i, param in ipairs(paramList.children) do
				local paramName = plume.ast.get(param, "IDENTIFIER", 1, 2).content
				local variadic  = plume.ast.get(param, "VARIADIC")
				local paramBody = plume.ast.get(param, "BODY")
				local param = context.registerVariable(paramName)

				if paramBody then
					context.registerOP(param, plume.ops.LOAD_LOCAL, 0, i)
					context.registerGoto(param, "macro_var_" .. i .. "_" .. uid, "JUMP_IF_NOT_EMPTY")
					context.accBlock()(paramBody)
					context.registerOP(param, plume.ops.STORE_LOCAL, 0, i)
					context.registerLabel(param, "macro_var_" .. i .. "_" .. uid)

					macroObj.namedParamCount = macroObj.namedParamCount+1
					macroObj.namedParamOffset[paramName] = param.offset
				elseif variadic then
					macroObj.variadicOffset = param.offset
				else
					macroObj.positionalParamCount = macroObj.positionalParamCount+1
				end
			end
			-- always register self parameter
			if not context.getVariable("self") then
				local param = context.registerVariable("self")
				macroObj.namedParamCount = macroObj.namedParamCount+1
				macroObj.namedParamOffset.self = param.offset
			end

			context.accBlock()(body, "macro_end")
			macroObj.localsCount = #context.getCurrentScope()
			
			table.remove(context.scopes)
			table.remove(context.chunks)
			
		end) ()

		plume.finalize(macroObj)
	end
end