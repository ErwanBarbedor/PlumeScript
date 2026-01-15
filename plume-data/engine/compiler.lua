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

return function(plume)
	
	function plume.compileFile(code, filename, chunk)
		local context = plume.newCompilationContext(chunk)
		
		local loops   = {}

		local ops = plume.ops

		local uid = 0
		local function getUID()
			uid = uid+1
			return uid
		end

		

		local function getNameSource(name, isStatic)
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

		-- All lua std function are stored as static variables
		local function loadSTD()
			local keys = {}
			for key, f in pairs(plume.std) do
				table.insert(keys, key)
			end
			table.sort(keys)

			for _, key in ipairs(keys) do
				context.registerVariable(key, true, false, false, plume.std[key])
			end
		end

		local function getLabel(name)
			return name
		end

		local nodeHandlerTable = {}
		local function nodeHandler(node)
			local handler = nodeHandlerTable[node.name]
			if not handler then
				error("NYI tokenhandler " .. node.name)
			end
			handler(node)
		end

		local function childrenHandler(node)
			for _, child in ipairs(node.children or {}) do
				nodeHandler(child)
			end
		end

		local function _accTableInit()
			context.registerOP(nil, ops.BEGIN_ACC, 0, 0)
			context.registerOP(nil, ops.TABLE_NEW, 0, 0)
		end

		local function _accTable(node)
			for _, child in ipairs(node.children) do
				if child.name == "LIST_ITEM"
				or child.name == "HASH_ITEM" then
					nodeHandler(child)
				else
					error("Internal Error: MixedBlockError")
				end
			end
		end

		local function accBlock(f)
			f = f or childrenHandler
			return function (node, label)
				if node.type == "TEXT" then
					table.insert(context.concats, true)
					context.registerOP(node, ops.BEGIN_ACC, 0, 0)
					f(node)
					if label then
						context.registerLabel(node, label)
					end
					context.registerOP(nil, ops.ACC_TEXT, 0, 0)
				else
					table.insert(context.concats, false)
					-- More or less a TEXT block with 1 element
					if node.type == "VALUE" then
						f(node)
						if label then
							context.registerLabel(node, label)
						end
					-- Handled by block in most cases
					elseif node.type == "TABLE" then
						_accTableInit()
						f(node)
						if label then
							context.registerLabel(node, label)
						end
						context.registerOP(nil, ops.ACC_TABLE, 0, 0)
					elseif node.type == "EMPTY" then
						-- Exactly same behavior as BEGIN_ACC (nothing) ACC_TEXT
						f(node)
						if label then
							context.registerLabel(node, label)
						end
						context.registerOP(nil, ops.LOAD_EMPTY, 0, 0)
					end
				end
				table.remove(context.concats)
			end		
		end

		local function scope(f, internVar)
			f = f or childrenHandler
			return function (node)
				local lets = #plume.ast.getAll(node, "LET") + (internVar or 0)
				if lets>0 or forced then
					context.registerOP(node, ops.ENTER_SCOPE, 0, lets)
					table.insert(context.scopes, {})
					f(node)
					table.remove(context.scopes)
					context.registerOP(nil, ops.LEAVE_SCOPE, 0, 0)
				else
					f(node)
				end
			end		
		end

		local function file(f)
			f = f or childrenHandler
			return function (node)
				table.insert(context.roots, #context.scopes+1)
				f(node)
				table.remove(context.roots)
			end		
		end

		local function opLoadVar(node, varName)
			local var = context.getVariable(varName)
			if not var then
				plume.error.useUnknowVariableError(node, varName)
			end
			if var.isStatic then
				context.registerOP(node, ops.LOAD_STATIC, 0, var.offset)
			elseif var.frameOffset > 0 then
				context.registerOP(node, ops.LOAD_LOCAL, var.frameOffset, var.offset)
			else
				context.registerOP(node, ops.LOAD_LOCAL, 0, var.offset)
			end
		end

		-----------
		-- ENTER --
		-----------
		nodeHandlerTable.FILE = file(function(node)
			local lets = #plume.ast.getAll(node, "LET")
			context.registerOP(node, ops.ENTER_SCOPE, 0, lets)
			table.insert(context.scopes, {})
			accBlock()(node, "macro_end")
			table.remove(context.scopes)
			-- LEAVE_SCOPE handled by RETURN
		end)

		nodeHandlerTable.DO = function(node)
			accBlock(function(node)
				childrenHandler(node)
			end)(node)
			context.registerOP(node, ops.STORE_VOID, 0, 0)
		end

		------------------
		-- TEXT & table --
		------------------
		nodeHandlerTable.COMMENT = function()end

		nodeHandlerTable.TEXT = function(node)
			local offset = context.registerConstant(node.content)
			context.registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end
		nodeHandlerTable.NUMBER = function(node)
			local offset = context.registerConstant(tonumber(node.content))
			context.registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end
		nodeHandlerTable.QUOTE = function(node)
			local content = (node.children[1] and node.children[1].content) or ""
			local offset = context.registerConstant(content)
			context.registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end

		nodeHandlerTable.LIST_ITEM = accBlock()

		nodeHandlerTable.HASH_ITEM = function(node)
			local identifier = plume.ast.get(node, "IDENTIFIER").content
			local body = plume.ast.get(node, "BODY")
			local meta = plume.ast.get(node, "META")

			local offset = context.registerConstant(identifier)

			accBlock()(body)
			context.registerOP(node, ops.LOAD_CONSTANT, 0, offset)

			if meta then
				context.registerOP(node, ops.TABLE_SET_ACC, 0, 1)
			else
				context.registerOP(node, ops.TABLE_SET_ACC, 0, 0)
			end
		end

		nodeHandlerTable.EXPAND = function(node)
			table.insert(context.concats, false)
			childrenHandler(node)
			table.remove(context.concats)
			context.registerOP(node, ops.TABLE_EXPAND, 0, 0)
		end

		--------------
		-- VARIABLE --
		--------------
		local function affectation(node, nodevarlist, body, isLet, isConst, isStatic, isParam, isFrom, compound, isBodyStacked)
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

					local source = getNameSource(name, isStatic)

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
								context.registerOP(node, ops.LOAD_CONSTANT, 0, key)
							else
								childrenHandler(last) -- key
							end
							table.insert(context.concats, false) -- prevent value to be checked against text type
							nodeHandler(var) -- table
							table.remove(context.concats)
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
					scope(accBlock())(body)
				end
				
				for i, var in ipairs(varlist) do
					local uid = getUID()
					if isParam then
						context.registerOP(node, ops.LOAD_STATIC, 0, var.offset)
						context.registerGoto(node, "param_end_"..uid, "JUMP_IF_PEEK")
						context.registerOP(nil, ops.STORE_VOID, 0, 0)
					end

					if compound then
						if var.getKey then
							var.getKey()
							context.registerOP(node, ops.TABLE_INDEX, 0, 0)
						else
							nodeHandler(var.ref)
						end
						scope(accBlock())(body)
						context.registerOP(var.ref, ops["OPP_" .. compound.children[1].name], 0, 0)
					end

					if isFrom then
						if i < #varlist then
							context.registerOP(nil, ops.DUPLICATE, 0, 0)
						end
						context.registerOP(var.ref, ops.LOAD_CONSTANT, 0, context.registerConstant(var.key))
						context.registerOP(nil, ops.SWITCH, 0, 0)
						if var.default then
							context.registerOP(nil, ops.TABLE_INDEX, 1, 0) -- 1 -> safemode
							local uid = getUID()
							context.registerGoto(node, "default_end_"..uid, "JUMP_IF_PEEK")
							context.registerOP(nil, ops.STORE_VOID, 0, 0)
							scope(accBlock())(var.default)
							context.registerLabel(node, "default_end_"..uid)
						else
							context.registerOP(nil, ops.TABLE_INDEX, 0, 0)
						end
					elseif dest then
						if i < #varlist then
							context.registerOP(nil, ops.DUPLICATE, 0, 0)
						end
						context.registerOP(nil, ops.LOAD_CONSTANT, 0, context.registerConstant(i))
						context.registerOP(nil, ops.SWITCH, 0, 0)
						context.registerOP(nil, ops.TABLE_INDEX, 0, 0)
					end

					if var.getKey then
						var.getKey()
						context.registerOP(node, ops.TABLE_SET, 0, 0)
					else
						if var.isStatic then
							context.registerOP(var.ref, ops.STORE_STATIC, 0, var.offset)
						elseif not isLet and var.frameOffset > 0 then
							context.registerOP(var.ref, ops.STORE_LOCAL, var.frameOffset, var.offset)
						else
							context.registerOP(var.ref, ops.STORE_LOCAL, 0, var.offset)
						end
					end

					if isParam then
						context.registerGoto(node, "param_end_skip_store"..uid)
						context.registerLabel(node, "param_end_"..uid)
						context.registerOP(nil, ops.STORE_VOID, 0, 0)
						context.registerOP(nil, ops.STORE_VOID, 0, 0)
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

			affectation(node, nodevarlist, body, isLet, isConst, isStatic, isParam, isFrom, compound)
		end

		nodeHandlerTable.LET = function(node)
			SETLET(node, true)
		end
		nodeHandlerTable.SET = function(node)
			SETLET(node, false)
		end

		----------
		-- EVAL --
		----------
		local oppNames = "ADD SUB MUL DIV MOD LT EQ NOT NEG POW"

		for oppName in oppNames:gmatch("%S+") do
			nodeHandlerTable[oppName] = function(node)
				nodeHandler(node.children[1])
				if node.children[2] then--only binary
					nodeHandler(node.children[2])
				end
				context.registerOP(node, ops["OPP_" .. oppName], 0, 0)
			end
		end

		nodeHandlerTable.NEQ = function(node)
			nodeHandlerTable.EQ(node)
			context.registerOP(node, ops.OPP_NOT, 0, 0)
		end

		nodeHandlerTable.GT = function(node)
			-- reverse the order of operands
			nodeHandler(node.children[2])
			if node.children[2] then
				nodeHandler(node.children[1])
			end
			context.registerOP(node, ops.OPP_LT, 0, 0)
		end

		nodeHandlerTable.LTE = function(node)
			nodeHandlerTable.GT(node)
			context.registerOP(node, ops.OPP_NOT, 0, 0)
		end

		nodeHandlerTable.GTE = function(node)
			nodeHandlerTable.LT(node)
			context.registerOP(node, ops.OPP_NOT, 0, 0)
		end

		nodeHandlerTable.OR = function(node)
			local uid = getUID()
			nodeHandler(node.children[1])
			context.registerGoto(node, "or_end_"..uid, "JUMP_IF_PEEK")
			nodeHandler(node.children[2])
			context.registerOP(node, ops["OPP_OR"], 0, 0)
			context.registerLabel(node, "or_end_"..uid)
		end

		nodeHandlerTable.AND = function(node)
			local uid = getUID()
			nodeHandler(node.children[1])
			context.registerGoto(node, "and_end_"..uid, "JUMP_IF_NOT_PEEK")
			nodeHandler(node.children[2])
			context.registerOP(node, ops["OPP_AND"], 0, 0)
			context.registerLabel(node, "and_end_"..uid)
		end

		nodeHandlerTable.EXPR = childrenHandler

		nodeHandlerTable.IDENTIFIER = function(node)
			local varName = node.content
			opLoadVar(node, varName)
		end

		nodeHandlerTable.EVAL = function(node)
			-- Push all index/call info in reverse order
			for i=#node.children, 2, -1 do
				local child = node.children[i]

				if child.name == "CALL" then
					_accTableInit()
					childrenHandler(child)
				elseif child.name == "BLOCK_CALL" then
					_accTableInit()
					nodeHandler(child)
				elseif child.name == "INDEX" then
					childrenHandler(child)
				elseif child.name == "DIRECT_INDEX" then
					local index = plume.ast.get(child, "IDENTIFIER")
					local name = index.content
					local offset = context.registerConstant(name)
					context.registerOP(index, ops.LOAD_CONSTANT, 0, offset)
				end
			end

			-- Load eval value
			nodeHandler(node.children[1])

			-- Push all index/call op in order
			for i=2, #node.children do
				local child = node.children[i]
				if child.name == "CALL" or child.name == "BLOCK_CALL" then
					context.registerOP(node, ops.ACC_CALL, 0, 0)
				elseif child.name == "INDEX" or child.name == "DIRECT_INDEX" then
					if node.children[i+1] and (node.children[i+1].name == "CALL" or node.children[i+1].name == "BLOCK_CALL") then
						context.registerOP(child, ops.TABLE_INDEX_ACC_SELF, 0, 0)
					else
						context.registerOP(child, ops.TABLE_INDEX, 0, 0)
					end
				end
			end

			if context.concats[#context.concats] then
				context.registerOP(node, ops.ACC_CHECK_TEXT, 0, 0)
			end
		end

		nodeHandlerTable.BLOCK_CALL = function(node)
			local argList = plume.ast.get(node, "CALL")
			local body    = plume.ast.get(node, "BODY")

			scope(function()
				if argList then
					_accTable(argList)
				end

				if node.type == "TABLE" then
					childrenHandler(body)
				else
					accBlock()(body)
				end
			end)(body)
		end

		nodeHandlerTable.TRUE = function(node)
			context.registerOP(node, ops.LOAD_TRUE, 0, 0)
		end

		nodeHandlerTable.FALSE = function(node)
			context.registerOP(node, ops.LOAD_FALSE, 0, 0)
		end

		nodeHandlerTable.EMPTY = function(node)
			context.registerOP(node, ops.LOAD_EMPTY, 0, 0)
		end

		-----------
		-- LOOPS --
		-----------
		nodeHandlerTable.WHILE = function(node)
			local condition = plume.ast.get(node, "CONDITION")
			local body      = plume.ast.get(node, "BODY")
			local uid = getUID()

			context.registerLabel(node, "while_begin_"..uid)
			childrenHandler(condition)
			context.registerGoto(node, "while_end_"..uid, "JUMP_IF_NOT")

			table.insert(loops, {begin_label="while_begin_"..uid, end_label="while_end_"..uid})
			scope()(body)
			table.remove(loops)

			context.registerGoto(node, "while_begin_"..uid)
			context.registerLabel(node, "while_end_"..uid)
		end

		nodeHandlerTable.FOR = function(node)
			local varlist = plume.ast.get(node, "VARLIST")
			local iterator   = plume.ast.get(node, "ITERATOR")
			local body       = plume.ast.get(node, "BODY")
			local uid = getUID()

			local next = context.registerConstant("next")
			local iter = context.registerConstant("iter")

			table.insert(context.concats, false)
			childrenHandler(iterator)
			table.remove(context.concats)

			context.registerOP(node, ops.GET_ITER, 0, 0)
			context.registerOP(nil, ops.ENTER_SCOPE, 0, 1)
			table.insert(context.scopes, {})

				context.registerOP(nil, ops.STORE_LOCAL, 0, 1)

				context.registerLabel(nil, "for_begin_"..uid)
				context.registerOP(nil, ops.LOAD_LOCAL, 0, 1)
				context.registerGoto(nil, "for_end_"..uid, "FOR_ITER", 1)

				scope(function(body)
					affectation(node, varlist,
						nil,   -- body
						true,  -- isLet
						false, -- isConst
						false, -- isStatic
						false, -- isParam
						false, -- isFrom 
						nil,   -- compound
						true   -- isBodyStacked
					)
					
					table.insert(loops, {begin_label="for_loop_end_"..uid, end_label="for_end_"..uid})
					childrenHandler(body)
					table.remove(loops)
					context.registerLabel(nil, "for_loop_end_"..uid)
				end, 1)(body)

				context.registerGoto (nil, "for_begin_"..uid)
				context.registerLabel(nil, "for_end_"..uid)

			table.remove(context.scopes)
			context.registerOP(node, ops.LEAVE_SCOPE, 0, 0)	
		end

		nodeHandlerTable.CONTINUE = function(node)
			local loop = loops[#loops]
			if not loop or not loop.begin_label then
				plume.error.cannotUseBreakOutsideLoop(node)
			end
			context.registerGoto (node, loop.begin_label)
		end

		nodeHandlerTable.BREAK = function(node)
			local loop = loops[#loops]
			if not loop or not loop.end_label then
				plume.error.cannotUseBreakOutsideLoop(node)
			end
			context.registerGoto (node, loop.end_label)
		end

		------------
		-- BRANCH --
		------------
		nodeHandlerTable.IF = function(node)
			local condition = plume.ast.get(node, "CONDITION")
			local body      = plume.ast.get(node, "BODY")
			local _elseif   = plume.ast.getAll(node, "ELSEIF")
			local _else     = plume.ast.get(node, "ELSE")
			local uid = getUID()

			
			local specialValueMode = (
				node.parent.type == "VALUE"
				and node.type ~= "EMPTY"
			)

			local _else_body
			if specialValueMode then
				-- Special case: if inside a VALUE block,
				-- create an ELSE branch to emit LOAD_EMPTY
				if not _else then
					_else_body = {type="EMPTY"}
				end
			end

			local branchs = {body, condition}
			for _, child in ipairs(_elseif) do
				local condition = plume.ast.get(child, "CONDITION")
				local body      = plume.ast.get(child, "BODY")

				table.insert(branchs, body)
				table.insert(branchs, condition)
			end

			if _else then
				local body = plume.ast.get(_else, "BODY")
				table.insert(branchs, body)
			elseif _else_body then
				table.insert(branchs, _else_body)
			end

			local finalBranch = #branchs+1
			for i=1, #branchs, 2 do
				local body = branchs[i]
				local condition = branchs[i+1]
				context.registerLabel(node, "branch_"..i.."_"..uid)
				if condition then
					childrenHandler(condition)
					context.registerGoto(node, "branch_"..(i+2).."_"..uid, "JUMP_IF_NOT")
				end
				if body.type == "TEXT" then
					scope(accBlock())(body)
				else
					scope()(body)
				end
				if specialValueMode and body.type == "EMPTY" then
					context.registerOP(node, ops.LOAD_EMPTY, 0, 0)
				end

				context.registerGoto(node, "branch_"..finalBranch.."_"..uid)
			end

			context.registerLabel(node, "branch_"..finalBranch.."_"..uid)

		end

		-----------
		-- MACRO --
		-----------
		nodeHandlerTable.MACRO = function(node)
			local macroIdentifier = plume.ast.get(node, "IDENTIFIER")
			local body            = plume.ast.get(node, "BODY")
			local paramList       = plume.ast.get(node, "PARAMLIST") or {children={}}
			local uid = getUID()

			local macroObj     = plume.newPlumeExecutableChunk(false, chunk.state)
			macroObj.static    = context.chunk.static
			macroObj.constants = context.constants
			local macroOffset  = context.registerConstant(macroObj)
			
			context.registerOP(macroIdentifier, ops.LOAD_CONSTANT, 0, macroOffset)
			
			local macroName
			if macroIdentifier then
				macroName = macroIdentifier.content
				local variable = context.registerVariable(
					macroName,
					true -- static
				)
				if not variable then
					plume.error.letExistingStaticVariableError(node, macroName, getNameSource(macroName))
				end
				
				context.registerOP(macroIdentifier, ops.STORE_STATIC, 0, variable.offset)
			end

			macroObj.name = macroName or node.label

			file(function ()
				-- Each macro open a scope, but it is handled by ACC_CALL and RETURN.
				table.insert(context.scopes, {})
				table.insert(loops, {})
				table.insert(context.chunks, macroObj)
				for i, param in ipairs(paramList.children) do
					local paramName = plume.ast.get(param, "IDENTIFIER", 1, 2).content
					local variadic  = plume.ast.get(param, "VARIADIC")
					local paramBody = plume.ast.get(param, "BODY")
					local param = context.registerVariable(paramName)

					if paramBody then
						context.registerOP(param, ops.LOAD_LOCAL, 0, i)
						context.registerGoto(param, "macro_var_" .. i .. "_" .. uid, "JUMP_IF_NOT_EMPTY")
						accBlock()(paramBody)
						context.registerOP(param, ops.STORE_LOCAL, 0, i)
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

				accBlock()(body, "macro_end")
				macroObj.localsCount = #context.getCurrentScope()
				
				table.remove(context.scopes)
				table.remove(context.chunks)
				
			end) ()

			plume.finalize(macroObj)
			
		end

		nodeHandlerTable.LEAVE = function(node)
			context.registerGoto(node, "macro_end")
		end

		----------------
		-- DIRECTIVES --
		----------------
		nodeHandlerTable.USE = function(node)
			local path = node.content
			local filename, searchPaths = plume.getFilenameFromPath(path, false, chunk)

			if not filename then
	            plume.error.cannotOpenFile(node, path, searchPaths)
			end

			local success, result = plume.executeFile(filename, chunk.state, false)
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

		-- Cache system disabled
		-- if not plume.copyExecutableChunckFromCache(filename, chunk) then
			loadSTD()

			local ast = plume.parse(code, filename)
			nodeHandler(ast)
			plume.finalize(chunk)

			-- plume.saveExecutableChunckToCache(filename, chunk)
		-- end

		return true
	end
end