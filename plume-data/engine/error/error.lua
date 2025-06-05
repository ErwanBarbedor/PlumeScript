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

-- This module contains functions for generating user-friendly error messages,
-- converting Lua tracebacks to Plume source-mapped tracebacks, and raising
-- specific Plume parsing or runtime errors. It aims to provide clearer diagnostics
-- by relating errors back to the original Plume source code.

return function (plume)

    --- Gets the source line, line number, and context for a given error position.
    --- @param source @source
    --- @param includeLine boolean Whether to include the line content in the output.
    --- @return string Formatted error context string with filename, line number, and optionally line content.
    local function getSourceLine(source, includeLine)
        local pos = 0
        local lineCount = 0
        local capturedLine
        local lastLine

        -- Iterate over lines of the source file to find the one corresponding to the error's absolute position.
        -- A newline is appended to sourceFile to ensure the last line is processed correctly by gmatch.
        for line in (source.sourceFile.."\n"):gmatch('([^\n]*)\n') do
            lineCount = lineCount + 1
            pos = pos + #line + 1  -- Current position in the file; +1 accounts for the newline character.
            if pos >= source.absolutePosition then
                lastLine     = line
                capturedLine = line:gsub('^%s*', '') -- Remove leading whitespace from the captured line.
                break
            end
        end

        local tokenIndication
        if includeLine then
            capturedLine = "\n    " .. capturedLine -- Indent the line content if included.
            tokenIndication = {"    "}
            for i=pos-#lastLine, source.absolutePosition-1-#(lastLine:match('^%s+')or"") do
                table.insert(tokenIndication, " ")
            end
            for i=1, source.length do
                table.insert(tokenIndication, "^")
            end
            tokenIndication = "\n" .. table.concat(tokenIndication)
        else
            tokenIndication = ""
            capturedLine = ""
        end

        -- Compose the context string. The '^@' is typically prepended by Lua for loaded files; remove it for cleaner display.
        local fullLine = string.format("File %s, line n°%i:%s", source.filename:gsub("^@", ""), lineCount, capturedLine)

        fullLine = fullLine .. tokenIndication
        
        return fullLine
    end

    --- Extracts filename, line number, and message from a standard Lua error string.
    --- Example input: "file.lua:10: attempt to call a nil value"
    --- @param line string The Lua error line.
    --- @return string|nil filename The extracted filename, or nil if not found.
    --- @return string|nil noline The extracted line number as a string, or nil if not found.
    --- @return string|nil message The extracted error message, or nil if not found.
    local function getLineInfos(line)
        return line:match('%s*(.-):(.-):%s*(.*)')
    end

    --- Makes a Plume-specific traceback from a Lua traceback.
    --- This function attempts to map Lua source lines to their corresponding Plume source lines
    --- and skips frames that cannot be mapped or are considered internal.
    --- @param err string The original error message, potentially containing location info.
    --- @param rawTraceback string The raw Lua traceback string (from `debug.traceback()`).
    --- @param env table The runtime environment
    --- @return string Lua traceback
    function plume.convertLuaTraceback (err, rawTraceback, env)
        local mainFilename, mainNoline, mainMessage = getLineInfos(err)

        -- If the error message itself doesn't contain file and line information, use the raw error message.
        if not mainMessage then
            mainMessage = err
        end

        -- Clean Lua's standard traceback header and reduce whitespace, aiming for one line per stack frame.
        rawTraceback = rawTraceback:gsub('^%s*stack traceback:\n%s*', ''):gsub('\n%s+', '\n')
        local traceback = {}
        
        -- Parse each frame in the Lua traceback.
        for line in rawTraceback:gmatch('[^\n\r]+') do
            local filename, noline, message = getLineInfos(line)
            -- Avoid duplicating filename/line info if already extracted from the main error message.
            if message == "in main chunk" then
                if not mainFilename then
                    mainFilename, mainNoline = filename, noline
                end
            elseif filename then
                -- Try to find a source map for the file.
                local map = env.config.package.map['@'..filename]
                if map then
                    local convertedMessage = plume.convertLuaError(
                        filename,
                        noline,
                        message,
                        map,
                        false, -- includeLine
                        false, -- includeMessage
                        true   -- ignoreNotFound (if true, returns nil on mapping failure)
                    )

                    -- If mapping fails, convertedMessage will be nil.
                    if convertedMessage then
                        -- Plume conceptualizes its script blocks as "macros" rather than "functions".
                        convertedMessage = convertedMessage .. " " .. message:gsub('^in function', 'in macro')
                        table.insert(traceback, convertedMessage)
                    end
                end
            end
        end

        local result = {}

        -- Try to map the main error to Plume's debug sources, if available.
        local mainMap
        if mainFilename then
            mainMap = env.config.package.map['@'..mainFilename]

            if mainMap then
                -- Convert the main error using Plume's source mapping.
                table.insert(result, plume.convertLuaError(
                    mainFilename,
                    mainNoline,
                    mainMessage,
                    mainMap,
                    true,
                    true
                ))
            else
                -- If no map, use the original error message.
                table.insert(result, err)
            end
        else
            table.insert(result, err)
        end

        -- Show "Traceback" only if needed
        if #traceback > 0 then
            table.insert(result, "Traceback:")
        end

        for _, err in ipairs(traceback) do
            table.insert(result, "    " .. err)
        end

        -- Special fallback: if no traceback information could be generated and no main file was identified,
        -- but Plume was in the process of loading files, indicate the last known file being loaded.
        -- local fileTrace = env.plume.package.fileTrace
        -- if #traceback == 0 and not mainFilename and #fileTrace > 0 then
        --     table.insert(result, "Occurring when loading '" .. fileTrace[#fileTrace] .. "'.")
        -- end
        
        return table.concat(result, "\n")
    end

    --- Throws an error, using a "source" table to make a detailed debug message.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param err string The error message.
    function plume.sourcedError(source, err)
        local customMessage = {
            err,
            "\n",
            getSourceLine(source, true)
        }
        error(table.concat(customMessage), -1) 
    end

    --- Error handler designed to enhance Lua error messages with variable scope context and improved tracebacks.
    --- @param err string The error message
    --- @param env table The environment table to introspect for global variables.
    --- @return string Enhanced error message string.
    function plume.errorHandler(err, env)
        -- VisibleVariables will store names and types of variables in scope.
        local visiblesVariables = {}

        -- Capture all local variables and their types from the current call stack.
        local j = 2 -- Start at stack level 2 (caller of errorHandler). Level 1 is errorHandler itself.
        local sourceName = debug.getinfo(j) and debug.getinfo(j).source -- Initial source file.
        while true do
            local info = debug.getinfo(j)
            -- Stop traversing if there are no more stack frames,
            -- or if we have reached a function from a different source file (to stay within related code).
            if not info or info.source ~= sourceName then
                break
            end

            local i = 0
            while true do
                i = i + 1
                -- Get name and value of the local variable at stack level `j`, index `i`.
                local name, value = debug.getlocal(j, i)
                if not name then break end -- No more locals at this stack level.
                -- Filter out internal Lua variable names like "(*temporary)".
                if not name:match('%(') then
                    if not visiblesVariables[name] then -- Prioritize locals from lower stack frames.
                        visiblesVariables[name] = type(value)
                    end
                end
            end
            j = j + 1
        end

        -- Capture all global variables and their types from the provided `env`.
        for k, v in pairs(env.plume) do
            if type(k) ~= "tonumber" then -- Exclude numeric keys, which are unlikely to be variable names.
                if not visiblesVariables[name] then
                    visiblesVariables[k] = type(v)
                end
            end
        end

        -- Attempt to make suggestions for type errors based on visible variables.
        err = plume.makeSuggestion(err, visiblesVariables)

        -- Convert the Lua traceback to a Plume-specific, more informative traceback.
        return plume.convertLuaTraceback(err, debug.traceback(), env)
    end

    --- Converts a Lua error message by mapping its location to Plume debug information, formatting it for the user.
    --- @param filename string The filename as reported by Lua (e.g., "script.lua").
    --- @param noline string The line number (as a string) as reported by Lua.
    --- @param message string The core error message from Lua.
    --- @param map table map between Lua and Plume code
    --- @param includeLine boolean|nil If true, includes the content of the Plume source line in the error
    --- @param includeMessage boolean|nil If true, prepends the original Lua error message
    --- @param ignoreNotFound boolean|nil If true, returns `nil` if the error location cannot be mapped to Plume source,
    ---                           instead of an "Unable to locate..." message (default: false).
    --- @return string? Formatted error message with Plume context, or `nil` if `ignoreNotFound` is true and mapping fails.
    function plume.convertLuaError(filename, noline, message, map, includeLine, includeMessage, ignoreNotFound)
        local result = {}

        -- Fallback: if filename or noline wasn't pre-parsed, try to extract them from the message.
        if not filename or not noline then
            local f, nl, m = getLineInfos(message)
            filename = f
            noline = nl
            message = m -- Update message to be the core part if it was combined.
        end

        -- Retrieve the list of Plume tokens that correspond to the Lua line number.
        local tokens = map[tonumber(noline)]

        if includeMessage then
            table.insert(result, "Error: ")
            table.insert(result, message)
            if includeLine then -- Add a newline only if line content will follow.
                table.insert(result, "\n")
            end
        end

        local lineFound = false

        if tokens then
            -- Try to find an original Plume source token corresponding to this Lua error.
            for _, token in ipairs(tokens) do
                -- A token is mappable if it has a sourceToken field, which in turn has a source field.
                if token.sourceToken and token.sourceToken.source then
                    -- Lua will never raise errors against assignement token
                    if token.kind ~= "ASSIGNMENT" then
                        table.insert(result, getSourceLine(token.sourceToken.source, includeLine))
                        lineFound = true
                        break -- First mappable token is usually sufficient.
                    end
                end
            end
        end

        if not lineFound then
            if ignoreNotFound then
                return nil
            end
            -- If no Plume source mapping, indicate that the error location is unclear in Plume terms.
            table.insert(result, "\nUnable to locate the error in a Plume file.")
        end
        
        return table.concat(result)
    end
end