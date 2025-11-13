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
		local static  = {}
		local scopes  = {}
		local concats = {}
		local roots   = {}
		local loops   = {}
		local chunks  = {chunk}

		local constants = chunk.constants
		local ops = plume.ops

		local uid = 0
		local function getUID()
			uid = uid+1
			return uid
		end

		local function registerOP(node, op, arg1, arg2)
			assert(op)
			local current = chunks[#chunks].instructions
			table.insert(current, {op, arg1, arg2, mapsto=node})
		end

		local function registerLabel(node, name)
			local current = chunks[#chunks].instructions
			current[#current+1] = {label=name, mapsto=node}
		end
		local function registerGoto(node, name, jump)
			local current = chunks[#chunks].instructions
			current[#current+1] = {_goto=name, jump=jump or "JUMP", mapsto=node}
		end
		local function registerMacroLink(node, offset)
			local current = chunks[#chunks].instructions
			current[#current+1] = {link=offset, mapsto=node}
		end

		local function registerConstant(value)
			local key = tostring(value) -- for numeric keys
			if not constants[key] then
				table.insert(constants, value)
				constants[key] = #constants
			end
			return constants[key]
		end

		local function registerVariable(name, isStatic, isConst, staticValue)
			local scope
			if isStatic then
				scope = static
				table.insert(chunk.static, staticValue or plume.obj.empty)
			else
				scope = scopes[#scopes]
			end

			if scope[name] then
				return nil
			end
			
			table.insert(scope, {scope[name]})
			scope[name] = {offset=#scope, isStatic = isStatic, isConst = isConst}

			return scope[name]
		end

		-- All lua std function are stored as static variables
		local function loadSTD()
			local keys = {}
			for key, f in pairs(plume.std) do
				table.insert(keys, key)
			end
			table.sort(keys)

			for _, key in ipairs(keys) do
				registerVariable(key, true, false, plume.std[key])
			end
		end

		local function getLabel(name)
			return name
		end

		local function getVariable(name)
			for i=#scopes, roots[#roots], -1 do
				local current = scopes[i]
				if current[name] then
					local variable = current[name]
					return {
						frameOffset = #scopes-i,
						offset   = variable.offset,
						isConst  = variable.isConst,	
					}
				end
			end
			if static[name] then
				local variable = static[name]
				return {
					offset   = variable.offset,
					isConst  = variable.isConst,
					isStatic = variable.isStatic	
				}
			end
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
			registerOP(nil, ops.BEGIN_ACC, 0, 0)
			registerOP(nil, ops.TABLE_NEW, 0, 0)
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
					table.insert(concats, true)
					registerOP(node, ops.BEGIN_ACC, 0, 0)
					f(node)
					if label then
						registerLabel(node, label)
					end
					registerOP(nil, ops.ACC_TEXT, 0, 0)
				else
					table.insert(concats, false)
					-- More or less a TEXT block with 1 element
					if node.type == "VALUE" then
						f(node)
						if label then
							registerLabel(node, label)
						end
					-- Handled by block in most cases
					elseif node.type == "TABLE" then
						_accTableInit()
						f(node)
						if label then
							registerLabel(node, label)
						end
						registerOP(nil, ops.ACC_TABLE, 0, 0)
					elseif node.type == "EMPTY" then
						-- Exactly same behavior as BEGIN_ACC (nothing) ACC_TEXT
						f(node)
						if label then
							registerLabel(node, label)
						end
						registerOP(nil, ops.LOAD_EMPTY, 0, 0)
					end
				end
				table.remove(concats)
			end		
		end

		local function scope(f, internVar)
			f = f or childrenHandler
			return function (node)
				local lets = #plume.ast.getAll(node, "LET") + (internVar or 0)
				if lets>0 or forced then
					registerOP(node, ops.ENTER_SCOPE, 0, lets)
					table.insert(scopes, {})
					f(node)
					table.remove(scopes)
					registerOP(nil, ops.LEAVE_SCOPE, 0, 0)
				else
					f(node)
				end
			end		
		end

		local function file(f)
			f = f or childrenHandler
			return function (node)
				table.insert(roots, #scopes+1)
				f(node)
				table.remove(roots)
			end		
		end

		local function opLoadVar(node, varName)
			local var = getVariable(varName)
			if not var then
				plume.error.useUnknowVariableError(node, varName)
			end
			if var.isStatic then
				registerOP(node, ops.LOAD_STATIC, 0, var.offset)
			elseif var.frameOffset > 0 then
				registerOP(node, ops.LOAD_LEXICAL, var.frameOffset, var.offset)
			else
				registerOP(node, ops.LOAD_LOCAL, 0, var.offset)
			end
		end

		-----------
		-- ENTER --
		-----------
		nodeHandlerTable.FILE = file(function(node)
			local lets = #plume.ast.getAll(node, "LET")
			registerOP(node, ops.ENTER_SCOPE, 0, lets)
			table.insert(scopes, {})
			accBlock()(node, "macro_end")
			table.remove(scopes)
			-- LEAVE_SCOPE handled by RETURN
		end)

		nodeHandlerTable.DO = function(node)
			accBlock(function(node)
				childrenHandler(node)
			end)(node)
			registerOP(node, ops.STORE_VOID, 0, 0)
		end

		------------------
		-- TEXT & table --
		------------------
		nodeHandlerTable.COMMENT = function()end

		nodeHandlerTable.TEXT = function(node)
			local offset = registerConstant(node.content)
			registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end
		nodeHandlerTable.NUMBER = function(node)
			local offset = registerConstant(tonumber(node.content))
			registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end
		nodeHandlerTable.QUOTE = function(node)
			local content = (node.children[1] and node.children[1].content) or ""
			local offset = registerConstant(content)
			registerOP(node, ops.LOAD_CONSTANT, 0, offset)
		end

		nodeHandlerTable.LIST_ITEM = accBlock()

		nodeHandlerTable.HASH_ITEM = function(node)
			local identifier = plume.ast.get(node, "IDENTIFIER").content
			local body = plume.ast.get(node, "BODY")
			local meta = plume.ast.get(node, "META")

			local offset = registerConstant(identifier)

			accBlock()(body)
			registerOP(node, ops.LOAD_CONSTANT, 0, offset)

			if meta then
				registerOP(node, ops.TABLE_SET_ACC_META, 0, 0)
			else
				registerOP(node, ops.TABLE_SET_ACC, 0, 0)
			end
		end

		nodeHandlerTable.EXPAND = function(node)
			table.insert(concats, false)
			childrenHandler(node)
			table.remove(concats)
			registerOP(node, ops.TABLE_EXPAND, 0, 0)
		end

		--------------
		-- VARIABLE --
		--------------
		nodeHandlerTable.LET = function(node)
			local idns    = plume.ast.getAll(node, "IDENTIFIER")
			local body    = plume.ast.get(node, "BODY") or plume.ast.get(node, "EVAL")
			local const   = plume.ast.get(node, "CONST")
			local static  = plume.ast.get(node, "STATIC")
			local from    = plume.ast.get(node, "FROM")
			local eq      = plume.ast.get(node, "EQ")

			local varlist = {}
			for _, idn in ipairs(idns) do
				local var = registerVariable(idn.content, static, const)
				if not var then
					plume.error.letExistingVariableError(node, idn.content)
				end
				table.insert(varlist, var)
				var.name = idn.content
				var.ref = idn
			end

			if body then
				if from then
					table.insert(concats, false)
					nodeHandler(body)
					table.remove(concats)
				else
					scope(accBlock())(body)
				end
				
				for i, var in ipairs(varlist) do
					if from then
						if i < #varlist then
							registerOP(nil, ops.DUPLICATE, 0, 0)
						end
						registerOP(var.ref, ops.LOAD_CONSTANT, 0, registerConstant(var.name))
						registerOP(nil, ops.SWITCH, 0, 0)
						registerOP(nil, ops.TABLE_INDEX, 0, 0)
					end
					if static then
						registerOP(var.ref, ops.STORE_STATIC, 0, var.offset)
					else
						registerOP(var.ref, ops.STORE_LOCAL, 0, var.offset)
					end
				end
			elseif const then
				plume.error.letEmptyConstantError(node)
			end
		end

		nodeHandlerTable.SET = function(node)
			local idn      = plume.ast.get(node, "IDENTIFIER")
			local eval     = plume.ast.get(node, "EVAL")
			local body     = plume.ast.get(node, "BODY")
			local compound = plume.ast.get(node, "COMPOUND")
			
			local varName
			if idn then
				local var = getVariable(idn.content)
				if not var then
					plume.error.setUnknowVariableError(node, idn.content)
				elseif var.isConst then
					plume.error.setConstantVariableError(node, idn.content)
				end

				if compound then
					nodeHandler(idn)
				end
				accBlock()(body)
				if compound then
					registerOP(idn, ops["OPP_" .. compound.children[1].name], 0, 0)
				end

				if var.isStatic then
					registerOP(idn, ops.STORE_STATIC, 0, var.offset)
				elseif var.frameOffset > 0 then
					registerOP(idn, ops.STORE_LEXICAL, var.frameOffset, var.offset)
				else
					registerOP(idn, ops.STORE_LOCAL, 0, var.offset)
				end
			else
				-- The last index should be detected by the parser, and not modified here.
				-- This is a temporary workaround.
				local last = eval.children[#eval.children]

				if last.name == "INDEX" or last.name == "DIRECT_INDEX" then
					eval.children[#eval.children] = nil

					local function getKey()
						if last.name == "DIRECT_INDEX" then
							local key = registerConstant(last.children[1].content)
							registerOP(node, ops.LOAD_CONSTANT, 0, key)
						else
							childrenHandler(last) -- key
						end
						table.insert(concats, false) -- prevent value to be checked against text type
						nodeHandler(eval) -- table
						table.remove(concats)
					end

					if compound then
						getKey()
						registerOP(node, ops.TABLE_INDEX, 0, 0)
					end

					accBlock()(body) -- value
					if compound then
						registerOP(node, ops["OPP_" .. compound.children[1].name], 0, 0)
					end

					getKey()
					registerOP(node, ops.TABLE_SET, 0, 0)
				else
					plume.error.cannotSetCallError(node)
				end
			end
		end

		----------
		-- EVAL --
		----------
		local oppNames = "ADD SUB MUL DIV MOD LT GT LTE GTE EQ NEQ NOT NEG POW"

		for oppName in oppNames:gmatch("%S+") do
			nodeHandlerTable[oppName] = function(node)
				nodeHandler(node.children[1])
				if node.children[2] then--only binary
					nodeHandler(node.children[2])
				end
				registerOP(node, ops["OPP_" .. oppName], 0, 0)
			end
		end

		nodeHandlerTable.OR = function(node)
			local uid = getUID()
			nodeHandler(node.children[1])
			registerGoto(node, "or_end_"..uid, "JUMP_IF_PEEK")
			nodeHandler(node.children[2])
			registerOP(node, ops["OPP_OR"], 0, 0)
			registerLabel(node, "or_end_"..uid)
		end

		nodeHandlerTable.AND = function(node)
			local uid = getUID()
			nodeHandler(node.children[1])
			registerGoto(node, "and_end_"..uid, "JUMP_IF_NOT_PEEK")
			nodeHandler(node.children[2])
			registerOP(node, ops["OPP_AND"], 0, 0)
			registerLabel(node, "and_end_"..uid)
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
					local offset = registerConstant(name)
					registerOP(index, ops.LOAD_CONSTANT, 0, offset)
				end
			end

			-- Load eval value
			nodeHandler(node.children[1])

			-- Push all index/call op in order
			for i=2, #node.children do
				local child = node.children[i]
				if child.name == "CALL" or child.name == "BLOCK_CALL" then
					registerOP(node, ops.ACC_CALL, 0, 0)
				elseif child.name == "INDEX" or child.name == "DIRECT_INDEX" then
					if node.children[i+1] and (node.children[i+1].name == "CALL" or node.children[i+1].name == "BLOCK_CALL") then
						registerOP(child, ops.TABLE_INDEX_ACC_SELF, 0, 0)
					else
						registerOP(child, ops.TABLE_INDEX, 0, 0)
					end
				end
			end

			if concats[#concats] then
				registerOP(node, ops.ACC_CHECK_TEXT, 0, 0)
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
			registerOP(node, ops.LOAD_TRUE, 0, 0)
		end

		nodeHandlerTable.FALSE = function(node)
			registerOP(node, ops.LOAD_FALSE, 0, 0)
		end

		nodeHandlerTable.EMPTY = function(node)
			registerOP(node, ops.LOAD_EMPTY, 0, 0)
		end

		-----------
		-- LOOPS --
		-----------
		nodeHandlerTable.WHILE = function(node)
			local condition = plume.ast.get(node, "CONDITION")
			local body      = plume.ast.get(node, "BODY")
			local uid = getUID()

			registerLabel(node, "while_begin_"..uid)
			childrenHandler(condition)
			registerGoto(node, "while_end_"..uid, "JUMP_IF_NOT")

			table.insert(loops, {begin_label="while_begin_"..uid, end_label="while_end_"..uid})
			scope()(body)
			table.remove(loops)

			registerGoto(node, "while_begin_"..uid)
			registerLabel(node, "while_end_"..uid)
		end

		nodeHandlerTable.FOR = function(node)
			local identifier = plume.ast.get(node, "IDENTIFIER")
			local iterator   = plume.ast.get(node, "ITERATOR")
			local body       = plume.ast.get(node, "BODY")
			local uid = getUID()

			local next = registerConstant("next")
			local iter = registerConstant("iter")

			table.insert(concats, false)
			childrenHandler(iterator)
			table.remove(concats)

			registerOP(node, ops.GET_ITER, 0, 0)
			registerOP(nil, ops.ENTER_SCOPE, 0, 1)
			table.insert(scopes, {})

				registerOP(nil, ops.STORE_LOCAL, 0, 1)

				registerLabel(nil, "for_begin_"..uid)
				registerOP(nil, ops.LOAD_LOCAL, 0, 1)
				registerGoto(nil, "for_end_"..uid, "FOR_ITER", 1)

				scope(function(body)
					local var = registerVariable(identifier.content)
					registerOP(identifier, ops.STORE_LOCAL, 0, var.offset)
					
					table.insert(loops, {begin_label="for_loop_end_"..uid, end_label="for_end_"..uid})
					childrenHandler(body)
					table.remove(loops)
					registerLabel(nil, "for_loop_end_"..uid)
				end, 1)(body)

				registerGoto (nil, "for_begin_"..uid)
				registerLabel(nil, "for_end_"..uid)

			table.remove(scopes)
			registerOP(node, ops.LEAVE_SCOPE, 0, 0)	
		end

		nodeHandlerTable.CONTINUE = function(node)
			local loop = loops[#loops]
			if not loop or not loop.begin_label then
				plume.error.cannotUseBreakOutsideLoop(node)
			end
			registerGoto (node, loop.begin_label)
		end

		nodeHandlerTable.BREAK = function(node)
			local loop = loops[#loops]
			if not loop or not loop.end_label then
				plume.error.cannotUseBreakOutsideLoop(node)
			end
			registerGoto (node, loop.end_label)
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
				registerLabel(node, "branch_"..i.."_"..uid)
				if condition then
					childrenHandler(condition)
					registerGoto(node, "branch_"..(i+2).."_"..uid, "JUMP_IF_NOT")
				end
				if body.type == "TEXT" then
					scope(accBlock())(body)
				else
					scope()(body)
				end
				if specialValueMode and body.type == "EMPTY" then
					registerOP(node, ops.LOAD_EMPTY, 0, 0)
				end

				registerGoto(node, "branch_"..finalBranch.."_"..uid)
			end

			registerLabel(node, "branch_"..finalBranch.."_"..uid)

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
			macroObj.static    = chunk.static
			macroObj.constants = constants
			local macroOffset  = registerConstant(macroObj)
			
			registerOP(macroIdentifier, ops.LOAD_CONSTANT, 0, macroOffset)
			
			if macroIdentifier then
				local macroName = macroIdentifier.content
				local variable = registerVariable(
					macroName,
					true -- static
				)
				if not variable then
					plume.error.letExistingStaticVariableError(node, macroName)
				end
				macroObj.name = macroName
				registerOP(macroIdentifier, ops.STORE_STATIC, 0, variable.offset)
			end

			file(function ()
				-- Each macro open a scope, but it is handled by ACC_CALL and RETURN.
				table.insert(scopes, {})
				table.insert(loops, {})
				table.insert(chunks, macroObj)
				for i, param in ipairs(paramList.children) do
					local paramName = plume.ast.get(param, "IDENTIFIER", 1, 2).content
					local variadic  = plume.ast.get(param, "VARIADIC")
					local paramBody = plume.ast.get(param, "BODY")
					local param = registerVariable(paramName)

					if paramBody then
						registerOP(param, ops.LOAD_LOCAL, 0, i)
						registerGoto(param, "macro_var_" .. i .. "_" .. uid, "JUMP_IF_NOT_EMPTY")
						accBlock()(paramBody)
						registerOP(param, ops.STORE_LOCAL, 0, i)
						registerLabel(param, "macro_var_" .. i .. "_" .. uid)

						macroObj.namedParamCount = macroObj.namedParamCount+1
						macroObj.namedParamOffset[paramName] = param.offset
					elseif variadic then
						macroObj.variadicOffset = param.offset
					else
						macroObj.positionalParamCount = macroObj.positionalParamCount+1
					end
				end
				-- always register self parameter
				if not getVariable("self") then
					local param = registerVariable("self")
					macroObj.namedParamCount = macroObj.namedParamCount+1
					macroObj.namedParamOffset.self = param.offset
				end

				accBlock()(body, "macro_end")
				macroObj.localsCount = #scopes[#scopes]
				
				table.remove(scopes)
				table.remove(chunks)
				
			end) ()

			plume.finalize(macroObj)
			
		end

		nodeHandlerTable.LEAVE = function(node)
			registerGoto(node, "macro_end")
		end

		loadSTD()

		local ast = plume.parse(code, filename)
		nodeHandler(ast)

		return true
	end
end