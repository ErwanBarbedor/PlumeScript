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

return function (plume)
	local function escapeString(s, maxlength)

		if type(s) == "table" then
			if s == plume.obj.empty then
				s = "empty"
			elseif s[1] == "macro" then
				s = "macro x0" .. s[2]
			elseif s[1] == "luaFunction" then
				s = "luaFunction '" .. s[3] .. "'"
			end
		end

		s = tostring(s)
		s = s:gsub('\n', '\\n'):gsub('\t', '\\t')

		if #s >= (maxlength or 20)+5 then
			s = s:sub(1, maxlength or 20) .. '[...]'
		end

		if s:match('^%s+$') then
			s = '"' ..s .. '"'
		end

		return s
	end

	local function printCols(t, sep, center, border)
		local tspaced = {}
		sep = sep or 20
		for i, x in ipairs(t) do
			x = tostring(x)
			local left, right
			if center then
				left = (" "):rep(math.floor((sep - #x)/2))
				right = (" "):rep(math.floor((sep - #x)/2+0.5))
			else
				left = ""
				right = (" "):rep((sep - #x))
			end
			if border then
				right = right .. "|"
				if i==0 then
					left = "|" .. left
				end
			end
			table.insert(tspaced, left..x..right)
		end

		print(table.concat(tspaced, ""))
	end

	plume.debug = {}

	function plume.debug.invTable(t)
		local result = {}
		for k, v in pairs(t) do
			result[v] = k
		end
		return result
	end

	
	function plume.debug.format(x, indent, cache, maxStringLength)
		local sep = ", "
		if indent then
			sep = ",\n"
		end
		cache = cache or {}
		if type(x) == "number" then
			return x
		elseif type(x) == "string" then
			if maxStringLength and #x>maxStringLength then
				x = x:sub(1, maxStringLength-5) .. "[...]"
			end

			return '"'.. x:gsub("\n", "\\n") .. '"'
		elseif type(x) == "table" then
			-- local id = tostring(x):sub(16, -1)
			local result = {"{"}
			if indent then
				table.insert(result, "\n")
			end
			if cache[x] then
				table.insert(result, "{...}")
			else
				cache[x] = true
				for _, v in ipairs(x) do
					table.insert(result, plume.debug.format(v, indent, cache, 20))
					table.insert(result, sep )
				end
				if #x > 0 then
					table.remove(result) -- last sep
				end
				local first = true
				for k, v in pairs(x) do
					if type(k) ~= "number" then
						if #x > 0 or not first then
							table.insert(result, sep)
						end
						if type(k) ~= "string" then
							k = "[" .. plume.debug.format(k) .. "]"
						end
						table.insert(result, k .. "=" .. plume.debug.format(v, indent, cache, 20))
						first = false
					end
				end
				if indent then
					table.insert(result, "\n")
				end
				table.insert(result, "}")
			end
			result = table.concat(result)
			if indent then
				result = result:gsub('\n', '\n\t'):gsub('\t}$', '}')
			end
			return result
		else
			return tostring(x)
		end
	end

	function plume.debug.print(...)
		local args = {...}
		local result = {}
		for k, v in ipairs(args) do
			table.insert(result, plume.debug.format(v))
		end
		print(table.concat(result, "\t"))
	end

	function plume.debug.pprint(x)
		print(plume.debug.format(x, true))
	end

	function plume.debug.printSimpleAST(ast, deep)
		deep = deep or 0
		if deep==0 and ast.type then
			print("("..ast.type..")")
		end
		for _, node in ipairs(ast.children) do
			local line = ("\t"):rep(deep)..node.name
			if not (" TEXT MACRO EVAL IDENTIFIER NUMBER EXPR EQ NEQ ADD SUB MUL DIV LT LTE GT GTE AND OR NOT CONDITION LET SET "):match(" "..node.name.." ") then
				line = line.." ("..(node.type or "")..")"
			end
			if (" SET ESCAPE TABLE_INDEX QUOTE ESCAPED EVAL_SHORT NAMED_PARAMETER MACRO LET FOR TEXT NUMBER IDENTIFIER PARAMETER "):match(" "..node.name.." ") then
				line = line .. "\t" .. escapeString(node.content or "", 20)
			end

			print(line)
			if node.children then
				plume.debug.printSimpleAST(node, deep+1)
			end
		end
	end

	local function getConstantInfos(num, runtime)
		local obj = runtime.constants[num]
		if not obj then
			return
		end
		value = escapeString(obj, 30)

		return {value=value}
	end

	local OP_BITS   = 7
	local ARG1_BITS = 5
	local ARG2_BITS = 20
	local ARG1_SHIFT = ARG2_BITS
	local OP_SHIFT   = ARG1_BITS + ARG2_BITS
	local MASK_OP   = bit.lshift(1, OP_BITS) - 1
	local MASK_ARG1 = bit.lshift(1, ARG1_BITS) - 1
	local MASK_ARG2 = bit.lshift(1, ARG2_BITS) - 1
	local function getInstrInfos(instr, runtime)
		local op   = bit.band(bit.rshift(instr, OP_SHIFT), MASK_OP)
		local arg1 = bit.band(bit.rshift(instr, ARG1_SHIFT), MASK_ARG1)
		local arg2 = bit.band(instr, MASK_ARG2)

		local t = plume.debug.invTable(plume.ops)

		local name = plume.debug.invTable(plume.ops)[op] or "NULL"
		local constInfos
		local value
		constInfos = getConstantInfos(arg2, runtime)

		if ("LOAD_CONSTANT"):match(name) then
			value = constInfos.value
		elseif ("CALL OPP_CONCAT LOAD_STATIC STORE_STATIC ESCAPE EVAL_SHORT STORE_LOCAL LOAD_LOCAL JUMP_IF ACC_CALL JUMP_IF_NOT_EMPTY JUMP ENTER_FILE"):match(name) then
			-- value = arg2
		elseif ("LOAD_LEXICAL STORE_LEXICAL ENTER_SCOPE"):match(name) then
			-- value = arg1 .. " " .. arg2
		end

		return {
			op = op,
			name = name,
			arg1 = arg1,
			arg2 = arg2,
			value = value
		}
	end

	function plume.debug.printConstants(runtime)
		local maxlength = 10
		for name, obj in ipairs(runtime.constants) do	
			local infos = getConstantInfos(name, runtime)

			printCols({name, infos.type, infos.value}, maxlength)
		end
	end

	function plume.debug.printBytecode(runtime)
		local maxlength = 15
		for ip, instr in ipairs(runtime.bytecode) do
			local content = ""
			local node = runtime.mapping[ip]
			if node then
				content = plume.error.getLineInfos(node).content
				if content:match('\n') then
					content = content:match('^[^\n]*').."[...]"
				end
			end

			if type(instr) == "table" then
				if instr.label then
					value = "LABEL " .. instr.label
				elseif instr._goto then
					value = "GOTO " .. instr._goto .." (" .. instr.jump .. ")"
				elseif instr.link then
					value = "LINK " .. instr.link
				end
				printCols({ip..".", "", "", value, "; "..content}, maxlength)
			else
				local infos = getInstrInfos(instr, runtime)
				local raw = string.format("%08x", instr)
				local value = escapeString(infos.value or "")
				printCols({ip..".", raw, infos.op.."+"..infos.arg1.."+"..infos.arg2, infos.name, value, "; "..content}, maxlength)
			end
		end
	end

	function plume.debug.bytecodeGrid(runtime)
		local result = {}
		for ip, instr in ipairs(runtime.bytecode) do
			local infos = getInstrInfos(instr, runtime)
			local raw = string.format("%08X", instr)

			local node = runtime.mapping[ip]
			local content = ""
			if node and node.code then
				local info = plume.error.getLineInfos(node)
				if info then
					content = info.content
					if content:match('\n') then
						content = content:match('^[^\n]*').."[...]"
					end
				end
			end
			
			table.insert(result, {raw, infos.name, infos.arg1, infos.arg2, content})
		end
		return result
	end

	local function getStack(t, s, sp, sf, sfp)
		table.insert(t, "[")
		for i=0, sp do
			local frame = false
			for j=1, sfp do
				if sf[j] == i+1 then
					frame = true
				end
			end
			if i>0 then
				if i<=sp then
					table.insert(t, escapeString(s[i]))
				end
				if i<sp then
					if frame then
						table.insert(t, " || ")
					else
						table.insert(t, " | ")
					end
				elseif frame then
					table.insert(t, " |")
				else
					table.insert(t, " ")
				end
			elseif frame then
				table.insert(t, "| ")
			else
				table.insert(t, " ")
			end
		end
		table.insert(t, "]")
		return result
	end

	function plume.debug.hookPrintVMState(tic, ip, jump, instr, op, arg1, arg2, ms, msp, msf, msfp, vs, vsp, vsf, vsfp, calls, cp, memory, mp)

		if jump==0 then
			jump = ip+1
		end

		local sinstr = ""
		if ip>0 then
			sinstr = string.format("%s %i %i", plume.debug.invTable(plume.ops)[op], arg1, arg2)
		end
		local header = string.format("Step %i, instr %i->%i: %s", tic, ip, jump, sinstr)

		local s_ms = {"main stack: "}
		local s_vs = {"var  stack: "}

		getStack(s_ms, ms, msp, msf, msfp)
		getStack(s_vs, vs, vsp, vsf, vsfp)

		local cm = string.format("Calls: {%s}, Memory: {%s}", table.concat(calls, "", 1, cp), table.concat(memory, "", 1, mp))

		local show = {header, table.concat(s_ms), table.concat(s_vs), cm, ""}

		print(table.concat(show, "\n\t"))
		
	end
end