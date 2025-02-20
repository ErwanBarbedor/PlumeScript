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
    local function formatContent(content)
        return "'" .. content:gsub("\n", "\\n") .. "'"
    end

    local function createIndentation(level)
        return string.rep("\t", level)
    end

    plume.printLexResult = function(tokens)
        local currentIndent = 0
        for _, token in ipairs(tokens) do
            local output = string.format(
                "%s%s %s",
                createIndentation(currentIndent),
                token.kind,
                formatContent(token.content)
            )
            print(output)
            currentIndent = token.indent or currentIndent
        end
    end


    local function printAstNode(node, indent)
        indent = indent or ""
        if node.children then
            print(indent..node.returnType .. " " .. node.kind .. ': ' .. (node.content or ""))

            for _, child in ipairs(node.children) do
                printAstNode(child, indent.."\t")
            end
        else
            print(indent..node.kind .. ': ' .. node.content)
        end
    end

    plume.printParseResult = function(ast)
        printAstNode(ast)
    end
end
