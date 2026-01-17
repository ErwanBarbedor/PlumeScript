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
	nodeHandlerTable.IDENTIFIER = function(node)
		local varName = node.content
		local var = context.getVariable(varName)
		if not var then
			plume.error.useUnknowVariableError(node, varName)
		end
		if var.isStatic then
			context.registerOP(node, plume.ops.LOAD_STATIC, 0, var.offset)
		elseif var.frameOffset > 0 then
			context.registerOP(node, plume.ops.LOAD_LOCAL, var.frameOffset, var.offset)
		else
			context.registerOP(node, plume.ops.LOAD_LOCAL, 0, var.offset)
		end
	end

	function context.affectation(node, nodevarlist, body, isLet, isConst, isStatic, isParam, isFrom, compound, isBodyStacked)
		local varlist = {}
		for _, var in ipairs(nodevarlist.children) do
			local rvar
			if var.name == "IDENTIFIER" or var.name == "ALIAS" or var.name == "DEFAULT" or var.name == "ALIAS_DEFAULT" then
				local key, name, default
				if var.name == "IDENTIFIER" then
					key = var.content
					name = var.content
				elseif var.name == "DEFAULT" then
					key = var.children[1].content
					name = key
					default = var.children[2]
				elseif var.name == "ALIAS" then
					key = var.children[1].content
					name = var.children[2].content
				else
					key = var.children[1].content
					name = var.children[2].content
					default = var.children[3]
				end

				if default and not isFrom then
					plume.error.cannotUseDefaultValueWithoutFrom(var)
				end

				local source = context.getNameSource(name, isStatic)

				if isLet then
					rvar = context.registerVariable(name, isStatic, isConst, isParam)
					if not rvar then
						if isStatic then
							plume.error.letExistingStaticVariableError(node, name, source)
						else
							plume.error.letExistingVariableError(node, name, source)
						end
					end
				else
					rvar = context.getVariable(name)
					if not rvar then
						plume.error.setUnknowVariableError(node, name)
					elseif rvar.isConst then
						plume.error.setConstantVariableError(node, name, source)
					end
				end
				rvar.key = key
				rvar.default = default
			elseif var.name == "SETINDEX" then
				-- The last index should be detected by the parser, and not modified here.
				-- This is a temporary workaround.
				local last = var.children[#var.children]
				if last.name == "INDEX" or last.name == "DIRECT_INDEX" then
					var.children[#var.children] = nil
					var.name = "EVAL"

					rvar = {}
					rvar.ref = var.children
					rvar.getKey = function()
						if last.name == "DIRECT_INDEX" then
							local key = context.registerConstant(last.children[1].content)
							context.registerOP(node, plume.ops.LOAD_CONSTANT, 0, key)
						else
							context.childrenHandler(last) -- key
						end
						context.toggleConcatOff() -- prevent value to be checked against text type
						context.nodeHandler(var) -- table
						context.toggleConcatPop()
					end
				else
					plume.error.cannotSetCallError(node)
				end
			end

			rvar.ref = var
			table.insert(varlist, rvar)
		end
		if body or isBodyStacked then
			local dest = #varlist > 1

			if dest and compound then
				plume.error.compoundWithDestructionError(node)
			end

			if not compound and not isBodyStacked then
				context.scope(context.accBlock())(body)
			end
			
			for i, var in ipairs(varlist) do
				local uid = context.getUID()
				if isParam then
					context.registerOP(node, plume.ops.LOAD_STATIC, 0, var.offset)
					context.registerGoto(node, "param_end_"..uid, "JUMP_IF_PEEK")
					context.registerOP(nil, plume.ops.STORE_VOID)
				end

				if compound then
					if var.getKey then
						var.getKey()
						context.registerOP(node, plume.ops.TABLE_INDEX)
					else
						context.nodeHandler(var.ref)
					end
					context.scope(context.accBlock())(body)
					context.registerOP(var.ref, plume.ops["OP_" .. compound.children[1].name])
				end

				if isFrom then
					if i < #varlist then
						context.registerOP(nil, plume.ops.DUPLICATE)
					end
					context.registerOP(var.ref, plume.ops.LOAD_CONSTANT, 0, context.registerConstant(var.key))
					context.registerOP(nil, plume.ops.SWITCH)
					if var.default then
						context.registerOP(nil, plume.ops.TABLE_INDEX, 1, 0) -- 1 -> safemode
						local uid = context.getUID()
						context.registerGoto(node, "default_end_"..uid, "JUMP_IF_PEEK")
						context.registerOP(nil, plume.ops.STORE_VOID)
						context.scope(context.accBlock())(var.default)
						context.registerLabel(node, "default_end_"..uid)
					else
						context.registerOP(nil, plume.ops.TABLE_INDEX, 0, 0)
					end
				elseif dest then
					if i < #varlist then
						context.registerOP(nil, plume.ops.DUPLICATE, 0, 0)
					end
					context.registerOP(nil, plume.ops.LOAD_CONSTANT, 0, context.registerConstant(i))
					context.registerOP(nil, plume.ops.SWITCH, 0, 0)
					context.registerOP(nil, plume.ops.TABLE_INDEX)
				end

				if var.getKey then
					var.getKey()
					context.registerOP(node, plume.ops.TABLE_SET, 0, 0)
				else
					if var.isStatic then
						context.registerOP(var.ref, plume.ops.STORE_STATIC, 0, var.offset)
					elseif not isLet and var.frameOffset > 0 then
						context.registerOP(var.ref, plume.ops.STORE_LOCAL, var.frameOffset, var.offset)
					else
						context.registerOP(var.ref, plume.ops.STORE_LOCAL, 0, var.offset)
					end
				end

				if isParam then
					context.registerGoto(node, "param_end_skip_store"..uid)
					context.registerLabel(node, "param_end_"..uid)
					context.registerOP(nil, plume.ops.STORE_VOID)
					context.registerOP(nil, plume.ops.STORE_VOID)
					context.registerLabel(node, "param_end_skip_store"..uid)
				end
			end
		elseif isConst and isLet and not isParam then
			plume.error.letEmptyConstantError(node)
		end
	end

	local function SETLET(node, isLet)
		local isConst     = plume.ast.get(node, "CONST")
		local isStatic    = plume.ast.get(node, "STATIC")
		local isParam     = plume.ast.get(node, "PARAM")

		if isParam then
			if isConst then
				plume.error.cannotUseParamAndConst(node)
			end
			if isStatic then
				plume.error.cannotUseParamAndStatic(node)
			end
			isConst = true
			isStatic = true
		end

		local isFrom    = plume.ast.get(node, "FROM")
		local compound = plume.ast.get(node, "COMPOUND")

		local nodevarlist = plume.ast.get(node, "VARLIST")
		local body        = plume.ast.get(node, "BODY")

		context.affectation(node, nodevarlist, body, isLet, isConst, isStatic, isParam, isFrom, compound)
	end

	nodeHandlerTable.LET = function(node)
		SETLET(node, true)
	end
	nodeHandlerTable.SET = function(node)
		SETLET(node, false)
	end
end