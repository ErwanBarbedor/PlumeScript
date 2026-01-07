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

local patterns = {
	{	-- comment
        pattern = {"%-%-[^\n]*"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        end
    },

	{	-- affectation
        pattern = {"[a-zA-Z_][a-zA-Z_0-9,]*%s*=%s*", "local%s+[a-zA-Z_][a-zA-Z_0-9,]*%s*=[^\n]*", "local [^\n=]+"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        end
    },
    {	-- callbegin
        pattern = {"[a-zA-Z_][a-zA-Z_0-9%.:]*%s*%("},
        action = function (state, match)
        	if state.newcall == 0 then
        		state.newline()
	        end
	        state.newcall = state.newcall + 1
        	state.write(match)
        end
    },
    {	-- callstring
        pattern = {'[a-zA-Z_][a-zA-Z_0-9%.:]*%s*".-"', "[a-zA-Z_][a-zA-Z_0-9%.:]*%s*'.-'"},
        action = function (state, match)
        	if state.newcall == 0 then
        		state.newline()
	        end
        	state.write(match)
        end
    },
    {	-- callchain
        pattern = {"%)[:%.][a-zA-Z_][a-zA-Z_0-9%.:]*%s*%("},
        action = function (state, match)
        	state.write(match)
        end
    },
    {	-- callend
        pattern = {"%)"},
        action = function (state, match)
        	state.write(match)
        	state.newcall = state.newcall - 1
        end
    },

    {	-- function
        pattern = {"function [a-zA-Z_0-9%.:]*%s*%(.-%)"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        	state.iinc()
        end
    },
    {	-- before open
        pattern = {"if", "while", "for"},
        action = function (state, match)
        	state.newcall = state.newcall + 1
        	state.newline()
        	state.write(match)
        end
    },
    {	-- open
        pattern = {"then", "do"},
        action = function (state, match)
        	state.newcall = state.newcall - 1
        	state.write(match)
        	state.iinc()
        end
    },

    {	-- words
        pattern = {"break"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        end
    },
    {	-- elseif
        pattern = {"elseif"},
        action = function (state, match)
        	state.newcall = state.newcall + 1
        	state.idec()
        	state.newline()
        	state.write(match)
        end
    },
    {	-- else
        pattern = {"else"},
        action = function (state, match)
        	state.idec()
        	state.newline()
        	state.write(match)
        	state.iinc()
        end
    },

    {	-- label
        pattern = {"::.-::",},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        end
    },

    {	-- end
        pattern = {"end"},
        action = function (state, match)
        	state.idec()
        	state.newline()
        	state.write(match)
        end
    },

    {	-- line start space
        pattern = {"\n[ \t]+"},
        action = function (state, match)
        end
    },
    {	-- white space
        pattern = {" +"},
        action = function (state, match)
        	state.write(" ")
        end
    },
    {	-- other space
        pattern = {"%s+"},
        action = function (state, match)
        end
    },

    {	-- string
        pattern = {'".-"', "'.-'"},
        action = function (state, match)
            state.write(match)
        end
    },
    {	-- return
        pattern = {'return[^\n]+'},
        action = function (state, match)
        	state.newline()
            state.write(match)
        end
    },

    {	-- fallback
        pattern = {"."},
        action = function (state, match)
            state.write(match)
        end
    },
}

local function beautifier(code)
	code = "\n" .. code
	local state = {result={}, indent="", newcall=0}
	local pos = 1

	function state.newline()
		if #state.result>0 then
			table.insert(state.result, "\n"..state.indent)
		end
	end
	function state.iinc ()
		state.indent = state.indent .. "  "
	end
	function state.idec ()
		state.indent = state.indent:sub(1, -3)
	end
	function state.write(txt)
		table.insert(state.result, txt)
	end

	while pos < #code do
		local match
        for _, patternList in ipairs(patterns) do
            for _, pattern in ipairs(patternList.pattern) do
                match = code:sub(pos):match("^"..pattern)
                if match then
                    patternList.action(state, match)
                    break
                end
            end
            if match then
                break
            end
        end

        pos = pos + #match
    end

    return table.concat(state.result)
end

print(beautifier[[
_VM_TICK(vm)op, arg1, 
  arg2 = 
  _VM_DECODE_CURRENT_INSTRUCTION(vm)
]])

return beautifier