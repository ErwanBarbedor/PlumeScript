local table = require 'ext.table'
local showcode = require 'template.showcode'
local DefaultOutput = require 'template.output'

--[[
Lua template

template(code, env, args)
	text = text to process
	env = environment of the code in the text to use
	args = extra args
		output = override output function
			During string processing, output(str) is called on each string block 'str'.
			Once processing is finished, the result of template() is output:done(), or nil if output has no 'done' function.
			The default 'output' accumulates strings and returns the concatenated results.

usage: template(code, {a=1, b=2, ...})
--]]
local function template(code, env, args)
	local output = args and args.output or DefaultOutput()
	-- setup env, let it see _G
	local newenv = setmetatable({}, {
		__index = function(t,k)
			if env then
				local v = env[k] if v then return v end
			end
			local v = _G[k] if v then return v end
		end,
	})

	-- make sure the env isn't already using the name for the output function
	local outputFuncName = '__output'
	if newenv[outputFuncName] then
		for i=2,math.huge do
			local trial = outputFuncName..i
			if not newenv[trial] then
				outputFuncName = trial
				break
			end
		end
	end

	-- assign output function
	newenv[outputFuncName] = output

	-- generate instructions to process template
	local newcode = table()
	local function addprint(from,to)
		local block = code:sub(from,to)

		-- make sure no such [=..=[ appears in the code block
		local eq, open, close
		for i=1,math.huge do
			eq = ('='):rep(i)
			open = '['..eq..'['
			close = ']'..eq..']'
			if not (block:find(open,1,true) or block:find(close,1,true)) then break end
		end

		local nl = block:find('\n',1,true) and '\n' or ''
		newcode:insert(outputFuncName..' '..open..nl..block..close..'\n')
	end
	local pos = 1
	while true do
		local start1, start2 = code:find('<%?', pos)
		if not start1 then
			addprint(pos, #code)
			break
		else
			local ret
			if code:sub(start2+1,start2+1) == '=' then
				ret = true
				start2 = start2 + 1
			end
			local end1, end2 = code:find('%?>', start2+1)
			end1 = end1 or #code+1
			end2 = end2 or #code-1
			addprint(pos, start1-1)
			local block = code:sub(start2+1, end1-1)
			if ret then
				newcode:insert(outputFuncName..'(tostring('..block..'))\n')
			else
				newcode:insert(block..'\n')
			end
			pos = end2+1
			if pos > #code then break end
		end
	end

	-- generate code
	newcode = newcode:concat()
	local f, msg = load(newcode, nil, 'bt', newenv)
	if not f then
		error('\n'
			..showcode(newcode)..'\n'
			..tostring(msg)
		)
	end

	assert(xpcall(f, function(msg)
		return '\n'
			..showcode(newcode)..'\n'
			..tostring(msg)..'\n'
			..debug.traceback()
	end))

	return output:done()
end

return template
