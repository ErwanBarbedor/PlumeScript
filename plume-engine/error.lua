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
    --- Finds the source line containing the error position and formats context information
    --- @param source table Source metadata containing sourceFile, absolutePosition, and filename
    --- @param includeLine boolean Whether to include the line contents in the output
    --- @return string Formatted error context string with filename, line number, and line content
    local function getLine(source, includeLine)
        local pos = 0
        local lineCount = 0
        local capturedLine

        -- Find which line contains the error position
        for line in (source.sourceFile.."\n"):gmatch('([^\n]*)\n') do
            lineCount = lineCount + 1
            pos = pos + #line + 1  -- count +1 for newline
            if pos >= source.absolutePosition then
                -- Remove leading whitespace for error readability
                capturedLine = line:gsub('^%s*', '')
                break
            end
        end

        if includeLine then
            capturedLine = "\n    " .. capturedLine
        end
        return string.format("File %s, line n°%i:%s", source.filename:sub(2, -1), lineCount, capturedLine)
    end

    --- Handles and formats errors, mapping them to source context if possible
    --- @param err string The original error message from Lua
    --- @param env table Runtime
    --- @param fullTraceback boolean Whether or not to show full stack trace including internal
    --- @return string The final formatted error message
    function plume.errorHandler (err, env, fullTraceback)
        local result    = {}
        local firstLine = false
        for line in debug.traceback(err, 2):gmatch('[^\n\r]+') do
            local filename, noline, message = line:match('%s*(.-):(.-):%s*(.*)')
            local map
            if filename then
                map = env.plume.package.map["@"..filename]
            end

            if not firstLine then
                firstLine = true
                -- Convert if debug info is available, else just store the line
                if map then
                    table.insert(result, plume.convertLuaError(line, map, true, true))
                else
                    table.insert(result, line)
                end
            elseif line:match('^%s*%[C%]:') and not fullTraceback then
                break -- Hide C/debug internals unless explicitly wanted
            elseif filename and map then
                -- Provide mapped error for non-initial lines
                table.insert(result, "    " .. plume.convertLuaError(line, map) .. message)
            elseif not line:match "^%s*$" then
                table.insert(result, line)
            end
        end
        
        -- Remove ending "stack traceback" for short backtraces
        if (#result == 2 or #result == 3) and not fullTraceback then
            for i=1, #result-1 do
                table.remove(result)
            end
        end

        return table.concat(result, "\n")
    end

    --- Throws a contextual error with source code location information
    --- @param source table Source metadata
    --- @param msg string Error message to display
    function plume.error (source, msg)
        local line = getLine(source, true)
        error (msg .. "\n" .. line, -1)  -- Level -1 hides this function from stack trace
    end

    -- AST errors

    --- Signals a type mismatch within a block (mixing types of expressions)
    --- @param source table Source metadata
    --- @param expectedType string The expected type
    --- @param givenType string The actual type provided
    function plume.mixedBlockError (source, expectedType, givenType)
        plume.error(source, string.format(
            "mixedBlockError: Given the previous expressions in this block, it was expected to be of type %s, but a %s expression has been supplied",
            expectedType, givenType
        ))
    end

    --- Error for invalid Lua identifier
    --- @param source table Source metadata
    --- @param name string The identifier name
    function plume.invalidLuaNameError(source, name)
        plume.error(source, string.format(
            "Syntax error: '%s' isn't a valid name.",
            name
        ))
    end

    -- Syntax and runtime errors

    --- Converts and maps a raw Lua error message to Plume context using debug map
    --- @param msg string The original Lua error message
    --- @param map table Mapping from line numbers to token sources
    --- @param includeLine boolean Optional; if true, include line text (default: false)
    --- @param includeMessage boolean Optional; if true, prepend error message (default: false)
    --- @return string Formatted error message with contextual info
    function plume.convertLuaError(msg, map, includeLine, includeMessage)
        local result = {}

        local filename, noline, message = msg:match('%s*(.-):(.-):%s*(.*)')
        local tokens = map[tonumber(noline)]

        if includeMessage then
            table.insert(result, "Error: ")
            table.insert(result, message)
            if includeLine then
                table.insert(result, "\n")
            end
        end

        local lineFound = false

        if tokens then
            for _, token in ipairs(tokens) do
                if token.sourceToken and token.sourceToken.source then
                    table.insert(result, getLine(token.sourceToken.source, includeLine))
                    lineFound = true
                    break
                end
            end
        end

        if not lineFound then
            table.insert(result, "\nUnable to locate the error in a Plume file.")
        end
        
        return table.concat(result)
    end

    --- Error for unclosed block/context (eg, missing end or closing delimiter)
    --- @param source table Source metadata
    --- @param kind string The kind of block or context
    function plume.unclosedContextError(source, kind)
        if kind == "MACRO_ARG_TABLE" then
            plume.error(source, 'Syntax error: ")" expected to close argument list.')
        else
            plume.error(source, string.format(
                "Syntax error : block '%s' never closed.",
                kind
            ))
        end
    end

    -- Parser errors

    --- Error for encountering an unexpected token
    --- @param source table Source metadata
    --- @param expected string The expected value/type
    --- @param given string The actual value found
    function plume.unexpectedTokenError (source, expected, given)
        plume.error(source, string.format(
            "Syntax error: expected %s, not \"%s\".",
            expected, given
        ))
    end

    --- Error for improper vararg usage (not in last position)
    --- @param source table Source metadata
    function plume.unexpectedVarargError(source)
        plume.error(source, "vararg must be in last position.")
    end

    --- Error for using return before block end
    --- @param source table Source metadata
    function plume.followedReturnError(source)
        plume.error(source, "Syntax error: expected block end. Return must be the last statement of a block.")
    end

    --- Error for line break after $var... block
    --- @param source table Source metadata
    --- @param sep string The separator/identifier used
    function plume.multilineEvalError(source, sep)
        plume.error(source, "Syntax error: '$var" .. sep .. "' syntax cannot be followed by a line break.")
    end
end
