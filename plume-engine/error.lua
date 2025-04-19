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
    local function getSourceLine(source, includeLine)
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

    local function getLineInfos(line)
        return line:match('%s*(.-):(.-):%s*(.*)')
    end

    --- Handles and formats errors, mapping them to source context if possible
    --- @param err string The original error message from Lua
    --- @param env table Runtime
    --- @param fullTraceback boolean Whether or not to show full stack trace including internal
    --- @return string The final formatted error message
    function plume.errorHandler (err, env, fullTraceback)
        local mainFilename, mainNoline, mainMessage = getLineInfos(err)

        if not mainFilename then
            mainMessage = err
        end

        local rawTraceback = debug.traceback("", 2)
        rawTraceback = rawTraceback:gsub('^%s*stack traceback:\n%s*', ''):gsub('\n%s+', '\n')
        -- print(rawTraceback)
        local traceback = {}
        
        for line in rawTraceback:gmatch('[^\n\r]+') do

            filename, noline, message = getLineInfos(line)

            if message == "in main chunk" then
                if not mainFilename then
                    mainFilename, mainNoline = filename, noline
                end
            elseif filename and (filename ~= mainFilename or noline ~= mainNoline) then
                table.insert(traceback, {filename=filename, noline=noline, message=message, raw=line})
            elseif (message or line):match('^%[C%]') then
                break
            end
        end

        local result = {}

        local mainMap = env.plume.package.map['@'..mainFilename]
        table.insert(result, plume.convertLuaError(mainFilename, mainNoline, mainMessage, mainMap, true, true))

        if #traceback > 0 then
            table.insert(result, "Traceback:")
        end

        for _, lineInfos in ipairs(traceback) do
            local map = env.plume.package.map['@'..lineInfos.filename]
            if map then
                table.insert(result, "   " .. plume.convertLuaError(lineInfos.filename, lineInfos.noline, lineInfos.message, mainMap))
            else
                table.insert(result, "   " .. lineInfos.raw)
            end
        end
        
        return table.concat(result, "\n")
    end

    --- Throws a contextual error with source code location information
    --- @param source table Source metadata
    --- @param msg string Error message to display
    function plume.error (source, msg)
        local line = getSourceLine(source, true)
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
    function plume.convertLuaError(filename, noline, message, map, includeLine, includeMessage)
        local result = {}

        if not filename or not noline then
            filename, noline, message = getLineInfos(message)
        end

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
                    table.insert(result, getSourceLine(token.sourceToken.source, includeLine))
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
