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
    --- Checks if a specific token field matches pattern constraints
    ---@param token table Token to validate
    ---@param patternInfos table Constraints for field matching
    ---@param field string Token field to check ('kind' or 'content')
    ---@return boolean
    function plume.checkFieldPattern(token, patternInfos, field)
        -- No constraint means automatic match
        if not patternInfos[field] then
            return true
        end

        if not token then
            return false
        end

        -- Direct value comparison for string patterns
        if type(patternInfos[field]) == "string" then
            return token[field] == patternInfos[field]
        else -- Array of allowed values
            for _, content in ipairs(patternInfos[field]) do
                if content == token[field] then
                    return true
                end
            end
            return false
        end
    end

    --- Validates token against combined pattern requirements
    ---@param token table Token to check
    ---@param patternInfos table Combined pattern specifications
    ---@return boolean
    function plume.checkPattern(token, patternInfos)
        -- Handle negation through recursive call
        if patternInfos.neg then
            return not plume.checkPattern(token, patternInfos.neg)
        else
            -- Must satisfy both field constraints
            return plume.checkFieldPattern(token, patternInfos, "kind")
               and plume.checkFieldPattern(token, patternInfos, "content")
        end
    end

    --- Matches token sequence against complex pattern structure
    ---@param tokens table[] Array of tokens to process
    ---@param pos integer Starting index (1-based)
    ---@param patternList table[] Sequence of pattern specifications
    ---@return table|boolean,table Capture table with results and success status
    function plume.matchPattern(tokens, pos, patternList)
        local capture = {length = 0}  -- Stores captured tokens and total matched count
        local patternPos = 0          -- Current position in pattern list
        local tokenPos = pos - 1      -- Current token index (adjusted for 1-based Lua arrays)
        
        while true do
            patternPos = patternPos + 1
            tokenPos = tokenPos + 1

            local token = tokens[tokenPos]
            local infos = patternList[patternPos]

            -- Successful match when pattern list is exhausted
            if not infos then
                break
            end

            -- Fail if tokens exhausted before pattern completion
            if not token and not infos.optional then
                return false
            end

            local captureCount = 0

            -- Handle repeating captures (zero or more occurrences)
            if infos.multipleCapture then
                local captureList = {}
                -- Consume all consecutive matching tokens
                while token and plume.checkPattern(token, infos) do
                    table.insert(captureList, token)
                    tokenPos = tokenPos + 1
                    token = tokens[tokenPos]
                end 

                captureCount = #captureList
                -- Fail if mandatory capture has zero matches
                if captureCount > 0 or infos.optional then
                    tokenPos = tokenPos - 1  -- Adjust for last non-matching token
                else
                    return false
                end

                if infos.name then
                    capture[infos.name] = captureList
                end
            elseif infos.braced then
                -- Handle nested bracket structures
                if not plume.checkPattern(token, infos.braced.open) then
                    return false
                end

                local captureList = {}
                local depth = 0    -- Bracket nesting level
                local offset = 0   -- Token lookahead offset

                -- Capture until matching closing bracket
                while tokens[tokenPos + offset] do
                    local current_token = tokens[tokenPos + offset]

                    if plume.checkPattern(current_token, infos.braced.open) then
                        depth = depth + 1
                    elseif plume.checkPattern(current_token, infos.braced.close) then
                        depth = depth - 1
                    end

                    table.insert(captureList, current_token)

                    if depth == 0 then
                        break
                    end
                    offset = offset + 1
                end

                -- Check for unbalanced brackets
                if depth > 0 then
                    return false
                end

                if infos.name then
                    capture[infos.name] = captureList
                end

                captureCount = #captureList
                tokenPos = tokenPos + offset
            else
                -- Single token matching logic
                local found = plume.checkPattern(token, infos)

                if found then
                    if infos.name then
                        capture[infos.name] = token  -- Store named capture
                    end
                    captureCount = 1
                elseif infos.optional then
                    -- Create placeholder for optional captures
                    captureCount = 0
                    tokenPos = tokenPos - 1  -- Maintain position
                    if infos.name then
                        capture[infos.name] = {content = "", kind = "EMPTY"}
                    end
                else
                    return false  -- Non-optional pattern failed
                end
            end

            capture.length = capture.length + captureCount
        end
        return capture
    end
end
