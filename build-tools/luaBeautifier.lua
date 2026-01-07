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
    {   -- label
        pattern = {"::.-::",},
        action = function (state, match)
            state.newline()
            state.newline()
            state.write(match)
        end
    },

	{	-- affectation
        pattern = {
            "[a-zA-Z_][a-zA-Z_0-9%.]*%s*=[^\n]*",
            "[a-zA-Z_][a-zA-Z_0-9%.],[^\n]-=[^\n]*",
            "local[^\n]-=[^\n]*",
            "local [^\n=]+"},
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
        pattern = {"function%s*[a-zA-Z_0-9%.:]*%s*%(.-%)", "return function*%s*%(.-%)"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
        	state.iinc()
        end
    },
    {	-- open
        pattern = {"if.-then", "while.-do", "for.-do", "do"},
        action = function (state, match)
        	state.newline()
        	state.write(match)
            state.iinc()
        end
    },
    {   -- elseif
        pattern = {"elseif.-then"},
        action = function (state, match)
            state.idec()
            state.newline()
            state.write(match)
            state.iinc()
        end
    },

    {	-- words
        pattern = {"break", "goto"},
        action = function (state, match)
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
		state.indent = state.indent .. "    "
	end
	function state.idec ()
		state.indent = state.indent:sub(1, -5)
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

return beautifier