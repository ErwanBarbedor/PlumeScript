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

    --- Gets the source line, line number and context for a given error position.
    --- @param source table Source metadata containing sourceFile, absolutePosition, and filename
    --- @param includeLine boolean Whether to include the line contents in the output
    --- @return string Formatted error context string with filename, line number, and line content
    local function getSourceLine(source, includeLine)
        local pos = 0
        local lineCount = 0
        local capturedLine

        -- Iterate over lines until the error's absolute position is reached
        for line in (source.sourceFile.."\n"):gmatch('([^\n]*)\n') do
            lineCount = lineCount + 1
            pos = pos + #line + 1  -- Add 1 for newline character
            if pos >= source.absolutePosition then
                capturedLine = line:gsub('^%s*', '') -- Remove leading whitespace
                break
            end
        end

        if includeLine then
            capturedLine = "\n    " .. capturedLine
        end
        -- Compose the context string (skip leading '@' on filename)
        return string.format("File %s, line n°%i:%s", source.filename:sub(2, -1), lineCount, capturedLine)
    end

    -- Extract filename, line number, and message from a Lua error line.
    --- @param line string
    --- @return string? filename, string? noline, string? message
    local function getLineInfos(line)
        return line:match('%s*(.-):(.-):%s*(.*)')
    end

    --- Handles and formats errors, mapping and annotating source context when possible.
    --- @param err string The original error message from Lua
    --- @param env table Runtime context/environment
    --- @param fullTraceback boolean Whether or not to show full stack trace, including internal frames
    --- @return string The final formatted error message
    function plume.errorHandler (err, env, fullTraceback)
        local mainFilename, mainNoline, mainMessage = getLineInfos(err)

        if not mainMessage then
            mainMessage = err
        end

        local rawTraceback = debug.traceback("", 2)
        -- Clean header and whitespace from traceback, leaving one line per frame
        rawTraceback = rawTraceback:gsub('^%s*stack traceback:\n%s*', ''):gsub('\n%s+', '\n')
        local traceback = {}
        local stopRecording = false
        
        -- Parse each frame in the Lua traceback
        for line in rawTraceback:gmatch('[^\n\r]+') do
            local filename, noline, message = getLineInfos(line)
            if message == "in main chunk" then
                if not mainFilename then
                    mainFilename, mainNoline = filename, noline
                end
            elseif (not stopRecording) and filename and (filename ~= mainFilename or noline ~= mainNoline) then
                table.insert(traceback, {filename=filename, noline=noline, message=message, raw=line})
            elseif (message or line):match('^%[C%]') then
                -- Indicates entry into compiled/C functions: stop trace here to avoid clutter
                stopRecording = true
            end

            if stopRecording and mainFilename then
                break
            end
        end

        local result = {}

        -- Try to map error to Plume's debug sources (if available)
        local mainMap
        if mainFilename then
            mainMap = env.plume.package.map['@'..mainFilename]
            if mainMap then
                table.insert(result, plume.convertLuaError(mainFilename, mainNoline, mainMessage, mainMap, true, true))
            else
                table.insert(result, err)
            end
        else
            table.insert(result, err)
        end

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

        -- Special fallback: no info, but files were loading; note which file
        local fileTrace = env.plume.package.fileTrace
        if #traceback == 0 and not mainFilename and #fileTrace > 0 then
            table.insert(result, "Occuring when loading '" .. fileTrace[#fileTrace] .. "'.")
        end
        
        return table.concat(result, "\n")
    end

    --- Throws a contextual error from a source location (immediately stops execution).
    --- @param source table Source metadata
    --- @param msg string Error message to display
    function plume.error (source, msg)
        local line = getSourceLine(source, true)
        -- Use error at level -1 so this function is omitted from the stack trace
        error (msg .. "\n" .. line, -1)
    end

    -- AST errors

    --- Indicates a type mismatch in a block (e.g., non-homogeneous expression list).
    --- @param source table Source metadata
    --- @param expectedType string The expected type
    --- @param givenType string The supplied type
    function plume.mixedBlockError (source, expectedType, givenType)
        plume.error(source, string.format(
            "mixedBlockError: Given the previous expressions in this block, it was expected to be of type %s, but a %s expression has been supplied",
            expectedType, givenType
        ))
    end

    --- Throws syntax error for an invalid Lua identifier name.
    --- @param source table Source metadata
    --- @param name string The identifier name
    function plume.invalidLuaNameError(source, name)
        plume.error(source, string.format(
            "Syntax error: '%s' isn't a valid name.",
            name
        ))
    end

    -- Syntax and runtime errors

    --- Converts a Lua error message by mapping to Plume debug info, formatted for user.
    --- @param filename string The filename reported by Lua
    --- @param noline string The line number (as string) reported by Lua
    --- @param message string The error message
    --- @param map table The map from line numbers to token sources
    --- @param includeLine boolean? If true, include the line text (default: false)
    --- @param includeMessage boolean? If true, prepend error message (default: false)
    --- @return string Formatted error message with context
    function plume.convertLuaError(filename, noline, message, map, includeLine, includeMessage)
        local result = {}

        -- Allow fallback parsing if not split yet
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
            -- Try to find original source token for this error
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

    --- Throws error when a block/context isn't properly closed (e.g., missing 'end').
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

    --- Throws error if an unexpected token is encountered (wrong value/type).
    --- @param source table Source metadata
    --- @param expected string The expected value/type
    --- @param given string The token encountered
    function plume.unexpectedTokenError (source, expected, given)
        plume.error(source, string.format(
            "Syntax error: expected %s, not \"%s\".",
            expected, given
        ))
    end

    --- Throws error if vararg is in the wrong position.
    --- @param source table Source metadata
    function plume.unexpectedVarargError(source)
        plume.error(source, "vararg must be in last position.")
    end

    --- Throws error if a return statement is not last in a block.
    --- @param source table Source metadata
    function plume.followedReturnError(source)
        plume.error(source, "Syntax error: expected block end. Return must be the last statement of a block.")
    end

    --- Throws error if multiline eval syntax is followed by a newline.
    --- @param source table Source metadata
    --- @param sep string The separator/identifier in $var...
    function plume.multilineEvalError(source, sep)
        plume.error(source, "Syntax error: '$var" .. sep .. "' syntax cannot be followed by a line break.")
    end
end
