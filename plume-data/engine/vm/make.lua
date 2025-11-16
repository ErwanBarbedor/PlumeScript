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

-- Very dirty.
-- Let's keep our fingers crossed that it holds up.

local function escapePattern(s)
	return s:gsub("[%%%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")..""
end

local function escapeSubPattern(s)
	return s:gsub("%%", "%%%%")..""
end

local lfs = require "lfs"
local lpeg = require "lpeg"
local P, R, S, C, V, Cc, Cp, Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.V, lpeg.Cc, lpeg.Cp, lpeg.Ct

local onspace = S" \n\t"^0
local ospace = S" \t"^0
local space = S" \t"^1

local identifier = (R("az", "AZ")+P"_") * (R("az", "AZ", "09")+P"_")^0

local args = Ct((ospace * (
					(P'{{'*
	   			   		C((P(1)-P'}}')^0)*
	   			   	P'}}' )
	   			 +  C((P'"'*
	   			   		(P(1)-P'"')^0)*
	   			   	P'"' )
				 + C((P(1)-S"@ \t\n")^1)
				))^0) * P"\n"^0
local macroDef = "@define" * space * C(identifier)
							* args
							* Ct((
								(ospace * P"--" * (P(1) - P"@end" - P"\n")^1 * P"\n"^0)
							  + ( C(ospace *(P(1) - P"@end" - P"\n")^1) * P"\n"^0 )
							)^0)
				  * ospace * "@end"

local macroCall = C(ospace * (P(1) - "@")^0) * C("@" * C(identifier) * ospace * args) /
			function (before, capture, name, args)
				return {before=before, capture=capture, name=name, args=args}
			end

local regularCode = (P(1) - ("@define"))^0
macroDef =  C(regularCode) * C(macroDef) /
			function (before, capture, name, args, lines)
				return {before=before, capture=capture, name=name, args=args, lines=lines}
			end

local function getLine(code, pos)
	local result = 1
	for _ in code:sub(1, pos):gmatch("\n") do
		result = result + 1
	end
	return result
end

local function loadMacros(code)
	local macros = {}

	local pos = 1
	
	while true do
		local macro = lpeg.match(macroDef, code, pos)
		if not macro then
			break
		end

		macros[macro.name] = macro
		pos = pos + #macro.capture + #macro.before

		print("Defined: @" .. macro.name.. " " .. table.concat(macro.args, " ").. " (line " .. getLine(code, pos - #macro.capture)..")")
	end
	return macros
end

local function cleanMacros(code, macros, comment)
	for _, macro in pairs(macros) do
		if comment then
			code = code:gsub(
				escapePattern(macro.capture),
				escapeSubPattern("--- "..macro.capture:gsub("\n", "\n--- ")),
				1
			)
		else
			code = code:gsub(escapePattern(macro.capture), "", 1)
		end
	end
	code = code:gsub("\n(\t*)%-%-%- @define", "\n%-%-%- %1@define")
	return code
end

local function loadCalls(code, macros, silent)
	local calls = {}
	local pos = 1
	while true do
		local call = lpeg.match(macroCall, code, pos)

		if call then
			pos = pos + #call.before + #call.capture

			local lastLine = call.before:match("[^\n]+$") or ""
			local comment = lastLine:match("%-%-") 

			if call.name ~= "define" and call.name ~= "end" and not comment then

				local macro = macros[call.name]
				if not macro then
					print("Unknow: @" .. call.name.. " (line " .. getLine(code, pos - #call.capture)..")")
				elseif not silent then
					print("Founded: @" .. call.name.. " " ..table.concat(call.args, " ").. " (line " .. getLine(code, pos - #call.capture)..")")
				end

				call.macro = macro
				call.indent = lastLine:match("\t+") or ""
				call.beginpos = pos - #call.capture
				call.endpos   = pos
				table.insert(calls, call)
			end

			if comment then
				local nextLine = code:sub(pos-1, -1):match("^.-\n") or ""
				pos = pos + #nextLine-1
			end
		else
			local nextat = code:sub(pos, -1):match("^.-@")
			if nextat then
				pos = pos + #nextat
			else
				break
			end
		end
	end
	return calls
end

local function applyCalls(code, calls)
	for _, call in ipairs(calls) do
		local body = ""
		if call.macro and code:match(escapePattern(call.capture)) then
			local sep = "\n" .. call.indent
			body = table.concat(call.macro.lines, sep)
			for i=1, #call.macro.args do
				

				if call.args[i] then
					local param1 = escapePattern("$"..call.macro.args[i])
					local param2 = escapePattern("$("..call.macro.args[i] .. ")")
					local arg    = arg and escapeSubPattern(call.args[i])
					body = body:gsub(param1, arg):gsub(param2, arg)
				end
			end
			body = body .. "\n"
		end


		local sep = ""
		if not call.capture:match("\n%s*$") then
			sep = "\n" .. call.indent
		end

		code = code:gsub(
			escapePattern(call.capture), sep .. escapeSubPattern(body)
		)

	end
	code = code:gsub("\n(\t*)%-%-%- @", "\n%-%-%- %1@")
	return code
end

local function process(target, path, predefined)
	local code = ""

	for file in lfs.dir(path) do
		if file:match('%.plua$') then
			code = code .. "\n" .. io.open(path.."/"..file):read("*a")
		end
	end
	
	local macros = loadMacros(code)

	for k, v in pairs(predefined or {}) do
		macros[k] = v
	end

	code = cleanMacros(code, macros)

	local i = 1
	while true do
		print("=== Passe " .. i .. "===")

		i = i+1
		local calls = loadCalls(code, macros)
		code = applyCalls(code, calls)
		if #calls==0 then
			break
		end
		if i>6 then
			break
		end
	end

	code = code:gsub('%-%-[^\n]*', ""):gsub("%s*\n", "\n"):gsub("%s*=%s*", "="):gsub("::(\n%s*)", "::%1\t")
	code = "--File generated by preprocessor.lua\n--[[This file is part of Plume" .. code
	io.open(target, "w"):write(code)
end

local dispatch = {}
local instructions = {}

local plume = {}
require"plume-data/engine/utils"(plume)
local ops_names = plume.ops_names

local count = 0
for name in ops_names:gmatch("%S+") do
	count = count + 1
	local switch = "if op == " .. count .. " then goto " .. name
	if count > 1 then
		switch = "else" .. switch
	end
	switch = "\t\t\t"..switch

	table.insert(dispatch, switch)

	if name ~= "END" then
		local instrname = "\t\t::" .. name .. "::"
		instrname = "\t" .. instrname
		table.insert(instructions, instrname)
		table.insert(instructions, "do")
		table.insert(instructions, "\t@"..name.." arg1 arg2")
		table.insert(instructions, "\t\t\t\tgoto DISPATCH")
		table.insert(instructions, "end")
	end
end

table.insert(dispatch, "\t\t\tend")
table.insert(instructions, "\t\t::END::")

process("plume-data/engine/engine.lua", "plume-data/engine/vm", {
	_DISPATCH={
		before="&@NULL@&", capture="&@NULL@&", args={}, lines=dispatch
	},
	_INSTRUCTIONS={
		before="&@NULL@&", capture="&@NULL@&", args={}, lines=instructions
	}
})