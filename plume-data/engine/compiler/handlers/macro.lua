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

		-- If the macro is named, save them in a static variable:
		-- `macro wing()` is a sugar for `let static wing = macro()`
		local macroName = macroIdentifier and macroIdentifier.content

		-- node.label is a debug informations for macro declared as table field
		local macroObj     = plume.obj.chunk(macroName or node.label, context.chunk)
		local macroOffset  = context.registerConstant(macroObj)
		context.registerOP(macroIdentifier or node, plume.ops.LOAD_CONSTANT, 0, macroOffset)

		if macroName then
			local variable = context.registerVariable(
				macroName,
				true -- static
			)
			if not variable then
				plume.error.letExistingStaticVariableError(node, macroName, context.getNameSource(macroName))
			end
			
			context.registerOP(macroIdentifier, plume.ops.STORE_STATIC, 0, variable.offset)
		end


		-- Skip macro body
		context.registerGoto(node, "macro_declaration_end" .. uid)

		-- Anchor point to find macro beginings
		context.registerLabel(node, "macro_begin" .. uid, macroOffset)

		context.file(function ()
			-- Each macro open a scope, but it is handled by plume.run
			table.insert(context.scopes, {})
			table.insert(context.loops, {})

			-------------------------------------------------------------
			--- Count arguments, save variadic offset
			--- and evaluate default value when optionnal args are empty.
			-------------------------------------------------------------
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
			-- Always register self parameter.
			-- If the macro is called as a table field, `self`
			-- is a reference to this table.
			-- Else is empty
			if not context.getVariable("self") then
				local param = context.registerVariable("self")
				macroObj.namedParamCount = macroObj.namedParamCount+1
				macroObj.namedParamOffset.self = param.offset
			end

			context.accBlock()(body, "macro_end") -- Handle the macro body
			
			macroObj.localsCount = #context.getCurrentScope()
			table.remove(context.scopes)
			
		end) ()
		context.registerOP(param, plume.ops.RETURN, 0, 0)

		context.registerLabel(param, "macro_declaration_end" .. uid)
	end
end