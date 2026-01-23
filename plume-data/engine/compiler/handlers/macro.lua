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
		local debugMacroName = macroName or node.label
		-- Case let x = macro
		if not debugMacroName then
			local parent = node.parent.parent
			if parent.name == "SET" or parent.name == "LET" then
				local varlist    = plume.ast.get(parent, "VARLIST")
				local identifier = plume.ast.get(varlist, "IDENTIFIER")
				debugMacroName = identifier and identifier.content
			end
		end
		if not debugMacroName then
			debugMacroName = "???"
		end

		-- Save name in the node
		node.debugMacroName = debugMacroName

		local macroObj     = plume.obj.macro(debugMacroName, context.chunk)
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
		context.registerGoto(node, "macro_declaration_end_" .. uid)

		table.insert(context.macros, uid)

		-- Anchor point to find macro beginings
		context.registerLabel(node, "macro_begin_" .. uid, macroOffset)

		context.file(function ()
			-- Each macro open a scope, but it is handled by plume.run
			table.insert(context.scopes, {})
			table.insert(context.loops, {})

			-------------------------------------------------------------
			--- Count arguments, save variadic offset
			--- and evaluate default value when optionnal args are empty.
			-------------------------------------------------------------
			for i, paramNode in ipairs(paramList.children) do
				local paramName = plume.ast.get(paramNode, "IDENTIFIER", 1, 2).content
				local variadic  = plume.ast.get(paramNode, "VARIADIC")
				local paramBody = plume.ast.get(paramNode, "BODY")
				local param = context.registerVariable(paramName)

				if paramBody then
					if macroObj.variadicOffset then
						plume.error.cannotAddNamedAfterVariadic(paramNode)
					end
					context.registerOP(paramNode, plume.ops.LOAD_LOCAL, 0, i)
					context.registerGoto(paramNode, "macro_var_" .. i .. "_" .. uid, "JUMP_IF_NOT_EMPTY")
					context.accBlock()(paramBody)
					context.registerOP(paramNode, plume.ops.STORE_LOCAL, 0, i)
					context.registerLabel(paramNode, "macro_var_" .. i .. "_" .. uid)

					macroObj.namedParamCount = macroObj.namedParamCount+1
					macroObj.namedParamOffset[paramName] = param.offset
				elseif variadic then
					macroObj.variadicOffset = param.offset
				else
					if macroObj.namedParamCount > 0 then
						plume.error.cannotAddPositionnalAfterNamed(paramNode)
					end
					if macroObj.variadicOffset then
						plume.error.cannotAddPositionnalAfterVariadic(paramNode)
					end
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

			context.accBlock()(body, "macro_body_end_" .. uid) -- Handle the macro body
			
			macroObj.localsCount = #context.getCurrentScope()
			table.remove(context.scopes)
			
		end) ()
		context.registerOP(node, plume.ops.RETURN, 0, 0)

		context.registerLabel(node, "macro_declaration_end_" .. uid)
		table.remove(context.macros)
	end

	nodeHandlerTable.LEAVE = function(node)
		local uid = context.getLast "macros"
		if uid then
			context.registerGoto(node, "macro_body_end_" .. uid)
		else
			context.registerOP(node, plume.ops.END, 0, 0) -- waiting for file rewrite
		end
	end
end