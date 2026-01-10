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
    {"label-end", "::END::"},
    {"label", "::[a-zA-Z_][a-zA-Z_0-9]*::"},
    {"goto-dispatch", "goto DISPATCH"},
    {"word", "[a-zA-Z_][a-zA-Z_0-9]*"},
    {"space", "%s+"},
    {"open", "[%(]"},
    {"close", "[%)]"},
    {"string", "'.-'"},
    {"string", '".-"'},
    {"opperator", "[=%*%+%-/^~<>%%]+"},
    {"opperator", "%.%.+"},
    {"len", "#"},
    {"delimiter-open", "[%{%[]"},
    {"delimiter-close", "[%}%]]"},
    {"comma", ','},
    {"word", "[0-9]+"},
    {"index", "[:%.]"},
    {"other", "."}

}

local function beautifier(code)
    local elements = {}
    local pos = 1

    while pos < #code do
        local chunk = code:sub(pos, -1)
        for _, patternInfo in ipairs(patterns) do
            local name    = patternInfo[1]
            local pattern = patternInfo[2]

            local match = chunk:match('^'..pattern)
            if match then
                table.insert(elements, {name=name, value=match})
                pos = pos + #match
                break
            end
        end
    end

    local result = {}
    local indent = 0
    local function newline()
        if #result > 0 then
            table.insert(result, "\n")
            for i=1, indent do
                table.insert(result, "\t")
            end
        end
    end

    local sticky
    local stickyLine
    local last
    pos = 1
    while pos <= #elements do
        local element = elements[pos]
        if element.name ~= "space" then
            if element.name == "word" then
                if element.value == "end" then
                    indent = indent - 1
                    sticky = false
                    stickyLine = false
                elseif element.value == "elseif" or element.value == "else" then
                    indent = indent - 1
                elseif element.value == "then" or element.value == "do" or element.value == "or" or element.value == "and" then
                    sticky = true
                end
            elseif element.name == "opperator" or element.name == "open" or element.name == "delimiter-close" or element.name == "delimiter-open" or element.name == "comma" or element.name == "close"then
                sticky = true
            elseif element.name == "goto-dispatch" then
                sticky = false
            elseif element.name == "index" then
                sticky = true
            end

            if last == "label" then
                sticky = false
            end


            if not sticky and not stickyLine then
                newline()
                if element.name == "label" then
                    newline()
                    indent = indent + 1
                elseif element.name == "label-end" then
                    newline()
                    indent = indent - 1
                elseif element.name == "word" and element.value == "function" then
                    newline()
                end
            elseif element.name == "word" and last ~= "opperator" and last ~= "open" and last ~= "delimiter-open" and last ~= "comma" and last ~= "len" and last ~= "index" then
                table.insert(result, " ")
            end

            sticky = false

            if element.name == "word" then
                if element.value == "function" then
                    indent = indent + 1
                    stickyLine = true
                elseif element.value == "if" or element.value == "elseif" or element.value == "for" or element.value == "while" then
                    stickyLine = true
                elseif element.value == "else" then
                    indent = indent + 1
                elseif element.value == "then" or element.value == "do" then
                    indent = indent + 1
                    stickyLine = false
                elseif element.value == "return" then
                    stickyLine = true
                elseif element.value == "local" or element.value == "or" or element.value == "and" or element.value == "goto" then
                    sticky = true
                end
            elseif element.name == "open" then
                stickyLine = true
            elseif element.name == "close" then
                stickyLine = false
            elseif element.name == "opperator" then
                sticky = true
                table.insert(result, " ")
            elseif element.name == "len" or element.name == "delimiter-open" or element.name == "comma" then
                sticky = true
            end

            table.insert(result, element.value)
            last = element.name

            if element.name == "comma" then
                table.insert(result, " ")
            elseif element.name == "opperator" then
                table.insert(result, " ")
            elseif element.name == "index" then
                sticky = true
            elseif element.name == "goto-dispatch" then
                indent = indent - 1
            end
        end

        pos = pos+1
    end

    return table.concat(result)
end

return beautifier