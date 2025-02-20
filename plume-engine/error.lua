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
    
    local function getLine(source)
        local pos = 0
        local lineCount = 0
        local capturedLine

        for line in (source.sourceFile.."\n"):gmatch('([^\n]*)\n') do
            lineCount = lineCount + 1
            pos = pos + #line + 1
            if pos >= source.absolutePosition then
                capturedLine = line:gsub('^%s*', '')
                break
            end
        end

        return string.format("File %s, line n°%i : %s", source.filename, lineCount, capturedLine)

    end

    function plume.error (source, msg)
        local line = getLine(source)
        error (msg .. "\n    " .. line, -1)
    end

    function plume.mixedBlockError (source, expectedType, givenType)
        
        plume.error(source, string.format("mixedBlockError : Given the previous expressions in this block, it was expected to be of type %s, but a %s expression has been supplied", expectedType, givenType))
    end
end