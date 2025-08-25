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
	function plume.initRuntime ()
		return {
			filesOffset = {},
			filesMemory  = {},
			filesVarMap  = {},
			instructions = {},
			constants    = {},
			fileCount    = 0
		}
	end

	function plume.compileFile(code, filename, runtime)
		runtime.fileCount = runtime.fileCount+1
		runtime.filesVarMap[filename]  = {}

		local fileNo = runtime.fileCount
		runtime.filesMemory[fileNo]  = {}

		local static = {}
		local scopes = {}
		local roots  = {}

		local constants = runtime.constants
		local instructions = runtime.instructions
		local ops = plume.ops

		local uid = 0
		local function getUID()
			uid = uid+1
			return fileNo.."_"..uid
		end

		local function registerOP(op, arg1, arg2)
			assert(op)
			table.insert(instructions, {op, arg1, arg2})
		end

		local function registerLabel(name)
			instructions[#instructions+1] = {label=name}
		end
		local function registerGoto(name, jump)
			instructions[#instructions+1] = {_goto=name, jump=jump or "JUMP"}
		end
		local function registerMacroLink(offset)
			instructions[#instructions+1] = {link=offset}
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
				table.insert(runtime.filesMemory[fileNo], staticValue or plume.obj.empty)
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
			for name, f in pairs(plume.std) do
				registerVariable(name, true, false, f)
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

		local function childsHandler(node)
			for _, child in ipairs(node.childs or {}) do
				nodeHandler(child)
			end
		end

		local function _accTableInit()
			registerOP(ops.BEGIN_ACC, 0, 0)
			registerOP(ops.TABLE_NEW, 0, 0)
		end

		local function _accTable(node)
			for _, child in ipairs(node.childs) do
				if child.name == "LIST_ITEM"
				or child.name == "HASH_ITEM" then
					nodeHandler(child)
				else
					error("Internal Error: MixedBlockError")
				end
			end
		end

		local function getBlockType(node, block)
			local type = "EMPTY"
			for _, child in ipairs(node.childs) do
				local detectedType
				if child.name == "TEXT" 
				or child.name == "EVAL"
				or child.name == "BLOCK" then
					detectedType = "TEXT"
				elseif child.name == "LIST_ITEM" 
					or child.name == "HASH_ITEM" then
					detectedType = "TABLE"
				elseif child.name == "IF"
				       or child.name == "ELSEIF"
				       or child.name == "ELSE"
				       or child.name == "FOR"
				       or child.name == "WHILE"
				       or child.name == "BODY" then
					detectedType = getBlockType(child)
				end

				if detectedType then
					if type == "EMPTY" then
						type = detectedType
					elseif type == detectedType then
					else
						error("MixedBlockError")
					end
				end
			end
			return type
		end

		local function accBlock(f)
			f = f or childsHandler
			return function (node)
				local type = getBlockType(node)
				if type == "TEXT" then
					if #node.childs ~= 1 then
						registerOP(ops.BEGIN_ACC, 0, 0)
						f(node)
						registerOP(ops.ACC_TEXT, 0, 0)
					else
						f(node)
					end
				-- Handled by block in most cases
				elseif type == "TABLE" then
					_accTableInit()
					f(node)
					registerOP(ops.ACC_TABLE, 0, 0)
				elseif type == "EMPTY" then
					-- Exactly same behavior as BEGIN_ACC (nothing) ACC_TEXT
					f(node)
					registerOP(ops.LOAD_EMPTY, 0, 0)
				end
			end		
		end

		local function scope(f)
			f = f or childsHandler
			return function (node)
				local lets = plume.ast.getAll(node, "LET")
				if #lets>0 then
					registerOP(ops.ENTER_SCOPE, 0, #lets)
					table.insert(scopes, {})
					f(node)
					table.remove(scopes)
					registerOP(ops.LEAVE_SCOPE, 0, 0)
				else
					f(node)
				end
			end		
		end

		local function file(f)
			f = f or childsHandler
			return function (node)
				registerOP(ops.ENTER_FILE, 0, runtime.fileCount)
				table.insert(roots, #scopes+1)
				f(node)
				table.remove(roots)
				registerOP(ops.LEAVE_FILE, 0, 0)
			end		
		end

		local function opLoadVar(node, varName)
			local var = getVariable(varName)
			if not var then
				error("Cannot eval variable '" .. varName .. "', it doesn't exist.")
			end
			if var.isStatic then
				registerOP(ops.LOAD_STATIC, 0, var.offset)
			elseif var.frameOffset > 0 then
				registerOP(ops.LOAD_LEXICAL, var.frameOffset, var.offset)
			else
				registerOP(ops.LOAD_LOCAL, 0, var.offset)
			end
		end

		-----------
		-- ENTER --
		-----------
		nodeHandlerTable.FILE = file(scope(accBlock()))

		------------------
		-- TEXT & table --
		------------------
		nodeHandlerTable.COMMENT = function()end

		nodeHandlerTable.TEXT = function(node)
			local offset = registerConstant(node.content)
			registerOP(ops.LOAD_CONSTANT, 0, offset)
		end
		nodeHandlerTable.NUMBER = function(node)
			local offset = registerConstant(tonumber(node.content))
			registerOP(ops.LOAD_CONSTANT, 0, offset)
		end

		nodeHandlerTable.LIST_ITEM = accBlock()

		nodeHandlerTable.HASH_ITEM = function(node)
			local identifier = plume.ast.get(node, "IDENTIFIER").content
			local body = plume.ast.get(node, "BODY")

			local offset = registerConstant(identifier)

			accBlock()(body)
			registerOP(ops.LOAD_CONSTANT, 0, offset)
			registerOP(ops.TABLE_SET_ACC, 0, 0)
		end

		--------------
		-- VARIABLE --
		--------------
		nodeHandlerTable.LET = function(node)
			local varName = plume.ast.get(node, "IDENTIFIER").content
			local body    = plume.ast.get(node, "BODY")
			local const   = plume.ast.get(node, "CONST")
			local static  = plume.ast.get(node, "STATIC")

			local var = registerVariable(varName, static, const)
			if not var then
				error("Cannot declare variable '" .. varName .. "', it already exist in this scope.")
			end

			if body then
				scope(accBlock())(body)
				if static then
					registerOP(ops.STORE_STATIC, 0, var.offset)
				else
					registerOP(ops.STORE_LOCAL, 0, var.offset)
				end
			elseif const then
				error("Cannot define a const empty variable.")
			end
		end

		nodeHandlerTable.SET = function(node)
			local varName = plume.ast.get(node, "IDENTIFIER").content
			local body    = plume.ast.get(node, "BODY")
			
			local var = getVariable(varName)
			if not var then
				error("Cannot set variable '" .. varName .. "', it doesn't exist.")
			elseif var.isConst then
				error("Cannot set variable '" .. varName .. "', is a constant.")
			end

			accBlock()(body)

			if var.isStatic then
				registerOP(ops.STORE_STATIC, 0, var.offset)
			elseif var.frameOffset > 0 then
				registerOP(ops.STORE_LEXICAL, var.frameOffset, var.offset)
			else
				registerOP(ops.STORE_LOCAL, 0, var.offset)
			end

		end

		----------
		-- EVAL --
		----------
		local oppNames = "ADD SUB MUL DIV MOD LT GT LTE GTE EQ NEQ OR AND NOT NEG POW"

		for oppName in oppNames:gmatch("%S+") do
			nodeHandlerTable[oppName] = function(node)
				nodeHandler(node.childs[1])
				if node.childs[2] then--only binary
					nodeHandler(node.childs[2])
				end
				registerOP(ops["OPP_" .. oppName], 0, 0)
			end
		end

		nodeHandlerTable.EXPR = childsHandler

		nodeHandlerTable.IDENTIFIER = function(node)
			local varName = node.content
			opLoadVar(node, varName)
		end

		nodeHandlerTable.EVAL = function(node)
			-- Push all index/call info in reverse order
			for i=#node.childs, 2, -1 do
				local child = node.childs[i]
				if child.name == "CALL" then
					_accTableInit()
					_accTable(child)
				elseif child.name == "INDEX" then
					childsHandler(child)
				elseif child.name == "DIRECT_INDEX" then
					local name = plume.ast.get(node, "IDENTIFIER")
					local offset = registerConstant(name)
					registerOP(ops.LOAD_CONSTANT, 0, offset)
				end
			end

			-- Load eval value
			nodeHandler(node.childs[1])

			-- Push all index/call op in order
			for i=2, #node.childs do
				local child = node.childs[i]
				if child.name == "CALL" then
					registerOP(ops.ACC_CALL, 0, 0)
				elseif child.name == "INDEX" then
					registerOP(ops.TABLE_INDEX, 0, 0)
				end
			end
		end

		nodeHandlerTable.BLOCK = function(node)
			local varName = plume.ast.get(node, "IDENTIFIER").content
			local argList = plume.ast.get(node, "CALL")
			local body    = plume.ast.get(node, "BODY")

			_accTableInit()

			if argList then
				_accTable(argList)
			end

			local bodyType = getBlockType(body)
			if bodyType == "TABLE" then
				_accTable(body)
			elseif bodyType == "TEXT" then
				accBlock()(body)
			end

			
			local var = getVariable(varName)
			if not var then
				error("Cannot call '" .. varName .. "': it doesn't exist.")
			end

			opLoadVar(node, varName)

			registerOP(ops.ACC_CALL, 0, 0)
		end

		-----------
		-- LOOPS --
		-----------
		nodeHandlerTable.WHILE = function(node)
			local condition = plume.ast.get(node, "CONDITION")
			local body      = plume.ast.get(node, "BODY")
			local uid = getUID()

			registerLabel("while_begin_"..uid)
			childsHandler(condition)
			registerGoto("while_end_"..uid, "JUMP_IF_NOT")
			scope()(body)
			registerGoto("while_begin_"..uid)
			registerLabel("while_end_"..uid)
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
			end

			local finalBranch = #branchs+1
			for i=1, #branchs, 2 do
				local body = branchs[i]
				local condition = branchs[i+1]
				registerLabel("branch_"..i.."_"..uid)
				if condition then
					childsHandler(condition)
					registerGoto("branch_"..(i+2).."_"..uid, "JUMP_IF_NOT")
				end
				scope()(body)
				registerGoto("branch_"..finalBranch.."_"..uid)
			end

			registerLabel("branch_"..finalBranch.."_"..uid)

		end

		-----------
		-- MACRO --
		-----------
		nodeHandlerTable.MACRO = function(node)
			local macroIdentifier = plume.ast.get(node, "IDENTIFIER")
			local body            = plume.ast.get(node, "BODY")
			local paramList       = plume.ast.get(node, "PARAMLIST") or {childs={}}
			local uid = getUID()

			local macroObj       = plume.obj.macro(0)
			local macroOffset = registerConstant(macroObj)
			
			registerOP(ops.LOAD_CONSTANT, 0, macroOffset)
			
			if macroIdentifier then
				local macroName = macroIdentifier.content
				local variable = registerVariable(
					macroName,
					true -- static
				)
				macroObj[6] = macroName
				registerOP(ops.STORE_STATIC, 0, variable.offset)
			end

			registerGoto("macro_end_" .. uid)
			registerMacroLink(macroOffset)

			
			file(function ()
				-- Each macro open a scope, but it is handled by ACC_CALL and RETURN.
				table.insert(scopes, {})
				for i, param in ipairs(paramList.childs) do
					local paramName = plume.ast.get(param, "IDENTIFIER").content
					local paramBody = plume.ast.get(param, "BODY")
					local param = registerVariable(paramName)

					if paramBody then
						registerOP(ops.LOAD_LOCAL, 0, i)
						registerGoto("macro_var_" .. i .. "_" .. uid, "JUMP_IF_NOT_EMPTY")
						accBlock()(paramBody)
						registerOP(ops.STORE_LOCAL, 0, i)
						registerLabel("macro_var_" .. i .. "_" .. uid)

						macroObj[4] = macroObj[4]+1
						macroObj[5][paramName] = param.offset
					else
						macroObj[3] = macroObj[3]+1
					end
				end

				accBlock()(body)
				table.remove(scopes)
			end) ()
			registerOP(ops.RETURN, 0, 0)
			registerLabel("macro_end_" .. uid)
		end

		loadSTD()

		local ast = plume.parse(code)
		nodeHandler(ast)
	end
end