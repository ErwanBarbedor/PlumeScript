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
    ---Finds the source line containing the error position and formats context information
    ---@param source table Source metadata containing sourceFile, absolutePosition, and filename
    ---@return string Formatted error context string with filename, line number, and line content
    local function getLine(source)
        local pos = 0
        local lineCount = 0
        local capturedLine

        -- Iterate through lines while tracking cumulative position to find the error line
        for line in (source.sourceFile.."\n"):gmatch('([^\n]*)\n') do
            lineCount = lineCount + 1
            pos = pos + #line + 1  -- +1 accounts for newline character
            if pos >= source.absolutePosition then
                -- Remove leading whitespace for cleaner error display
                capturedLine = line:gsub('^%s*', '')
                break
            end
        end

        return string.format("File %s, line n°%i :\n    %s", source.filename:sub(2, -1), lineCount, capturedLine)
    end

    ---Throws a contextual error with source code location information
    ---@param source table Source metadata
    ---@param msg string Error message to display
    function plume.error (source, msg)
        local line = getLine(source)
        error (msg .. "\n" .. line, -1)  -- -1 level hides this function from stack trace
    end

    -- AST errors

    ---Handles type mismatch errors within blocks
    ---@param source table Source metadata
    ---@param expectedType string Expected expression type
    ---@param givenType string Actually provided type
    function plume.mixedBlockError (source, expectedType, givenType)
        plume.error(source, string.format(
            "mixedBlockError : Given the previous expressions in this block, it was expected to be of type %s, but a %s expression has been supplied",
            expectedType, givenType
        ))
    end

    function plume.invalidLuaNameError(source, name)
        plume.error(source, string.format(
            "Syntax error : '%s' isn't a valid name.",
            name
        ))
    end

    -- Syntax and runtime errors
    function plume.convertLuaError(msg, map)
        local result = {}
        local filename, noline, message = msg:match('(.-):(.-):%s*(.*)')

        table.insert(result, "Error : ")
        table.insert(result, message)
        local tokens = map[tonumber(noline)]

        local lineFound = false

        for _, token in ipairs(tokens) do
            if token.sourceToken and token.sourceToken.source then
                table.insert(result, "\n")
                table.insert(result, getLine(token.sourceToken.source))
                table.insert(result, "\n(Error handling is still under development, so locating the lua error in the Plume code may be imprecise.)")
                lineFound = true
                break
            end
        end

        if not lineFound then
            table.insert(result, "\nUnable to locate the error in a Plume file.")
        end
        
        return table.concat(result)
    end

    function plume.unclosedContextError(source, kind)
        if kind == "MACRO_ARG_TABLE" then
            plume.error(source,"Syntax error : \")\" expected to close argument list.")
        else
            plume.error(source, string.format(
                "Syntax error : block '%s' never closed.",
                kind
            ))
        end
    end

    -- parser errors
    function plume.unexpectedTokenError (source, expected, given)
        plume.error(source, string.format(
            "Syntax error : expected %s, not \"%s\".",
            expected, given
        ))
    end
end