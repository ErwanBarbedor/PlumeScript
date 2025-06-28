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

-- This module provides a flexible mechanism for matching sequences of
-- tokens against predefined patterns. It is primarily used by the
-- `parser.lua` module to identify Plume language constructs. The matching
-- logic supports optional tokens, multiple captures, named captures,
-- simple negation (non-matching), as well as handling of nested
-- delimited structures (e.g., parenthesized expressions).
--
-- The main function exported by this module is `plume.matchPattern`.
-- It attempts to match a sequence of tokens, starting from a given
-- position, against an ordered list of pattern specifications.
--
-- Each pattern specification within the list is a table that can
-- contain the following fields to define the characteristics of the
-- expected token or token sequence:
--
--   - `kind`:    String or table of strings. Specifies the expected
--                token type(s) (e.g., "TEXT", "OPERATOR").
--
--   - `content`: String or table of strings. Specifies the expected
--                literal content(s) of the token (e.g., "if", "+").
--
--   - `optional`: Boolean. If `true`, the presence of the token or sequence
--                 matching this specification is not mandatory for the
--                 overall pattern to succeed.
--
--   - `multipleCapture`: Boolean. If `true`, the specification will attempt
--                        to capture zero or more consecutive tokens that
--                        match the `kind` and `content` criteria.
--
--   - `name`:    String. If this field is present, the captured token
--                (or list of tokens in the case of `multipleCapture` or `braced`)
--                will be stored in the result table under a key with this name.
--
--   - `neg`:     Table (itself a pattern specification). If present, the
--                current token must NOT match this sub-pattern for the
--                condition to be validated.
--
--   - `braced`:  Table. Used to capture token sequences delimited by
--                specific opening and closing tokens, while correctly
--                handling nesting levels. This table must contain two fields:
--                  - `open`:  Pattern specification for the opening token.
--                  - `close`: Pattern specification for the closing token.
--
--   - `or`:      Table of pattern specifications. If this field is present,
--                it must contain a list (table) of pattern specifications.
--                The pattern is considered matched if at least one of these
--                sub-patterns matches the token sequence at this position.
--                This allows the definition of several alternative patterns:
--                the pattern is valid if at least one alternative succeeds.
--
-- Conceptual examples of pattern specifications:
--
-- 1. Matching a specific token by type and content:
--    {kind = "TEXT", content = "local"}
--    -- This pattern looks for a token of type "TEXT" with the exact content "local".
--
-- 2. Matching an optional token:
--    {kind = "SPACE", optional = true}
--    -- This pattern looks for a token of type "SPACE". If not found,
--    -- the matching of the overall pattern can still proceed.
--
-- 3. Multiple and named capture of tokens:
--    {kind = "IDENTIFIER_PART", multipleCapture = true, name = "variableName"}
--    -- This pattern captures a sequence of zero or more consecutive tokens
--    -- of type "IDENTIFIER_PART". The list of captured tokens is stored
--    -- in the result table under the key `variableName`.
--
-- 4. Matching with a negation condition:
--    {kind = "KEYWORD", neg = {content = "end"}}
--    -- This pattern looks for a token of type "KEYWORD" whose content
--    -- is NOT "end".
--
-- 5. Capturing a nested (delimited) structure:
--    {
--        braced = {
--            open  = {kind = "LPAR"},  -- LPAR for '('
--            close = {kind = "RPAR"}   -- RPAR for ')'
--        },
--        name = "parenthesized_expression"
--    }
--    -- This pattern captures the sequence of tokens between an "LPAR" token
--    -- and the corresponding closing "RPAR" token, respecting parenthesis
--    -- nesting. The captured sequence is stored under the key
--    -- `parenthesized_expression`.
--
-- 6. Pattern with alternatives ("or"):
--    {
--        or = {
--            {kind = "NUMBER"},
--            {kind = "IDENTIFIER"}
--        }
--    }
--    -- This pattern matches if the next token is either of type "NUMBER"
--    -- or of type "IDENTIFIER". The pattern is valid if one of the
--    -- sub-patterns matches.
--
-- On success, `plume.matchPattern` returns a capture table. This table
-- contains the tokens captured via the `name` field of the specifications,
-- as well as a `length` field indicating the total number of tokens from
-- the input sequence that were consumed by the match. On failure,
-- the function returns `false`.

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
        -- Must satisfy both field constraints
        return plume.checkFieldPattern(token, patternInfos, "kind")
           and plume.checkFieldPattern(token, patternInfos, "content")
           and not (patternInfos.neg and plume.checkPattern(token, patternInfos.neg))
    end

    function plume.capturePattern(tokens, tokenPos, patternInfos)
        local token = tokens[tokenPos]
        if patternInfos.braced then
            -- Handle nested bracket structures
            if plume.checkPattern(token, patternInfos.braced.open) then
                local captureList = {}
                local depth = 0    -- Bracket nesting level
                local offset = 0   -- Token lookahead offset

                -- Capture until matching closing bracket
                while tokens[tokenPos + offset] do
                    local current_token = tokens[tokenPos + offset]

                    if plume.checkPattern(current_token, patternInfos.braced.open) then
                        depth = depth + 1
                    elseif plume.checkPattern(current_token, patternInfos.braced.close) then
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
                    return nil, true, 0
                end

                return captureList, true, offset
            else
                return nil, true, 0
            end
        elseif patternInfos["or"] then
            
            for _, subPatternInfos in ipairs(patternInfos["or"]) do
                -- Should be factorized with the same logic in matchPattern
                if subPatternInfos.multipleCapture then
                    local captureList = {}
                    local totalOffset = 0
                    local captureCount = 0
                    while token do
                        local capture, isList, offset = plume.capturePattern(tokens, tokenPos, subPatternInfos)

                        if capture then
                            table.insert(captureList, capture)
                            if isList then
                                tokenPos = tokenPos + offset + 1
                                captureCount = captureCount + #capture
                            else
                                tokenPos = tokenPos + 1
                                captureCount = captureCount + 1
                            end
                            if offset then
                                totalOffset = totalOffset + offset
                            end
                            token = tokens[tokenPos]
                        else
                            break
                        end
                    end 

                    -- Fail if mandatory capture has zero matches
                    if captureCount > 0  then
                        tokenPos = tokenPos - 1  -- Adjust for last non-matching token
                        if subPatternInfos.name then
                            capture[subPatternInfos.name] = captureList
                        end
                        return captureList, true, totalOffset
                    end
                else
                    local capture, isList, offset = plume.capturePattern(tokens, tokenPos, subPatternInfos)
                    if capture then
                        return capture, isList, offset
                    end
                end
            end
        else
            if plume.checkPattern(token, patternInfos) then
                return token
            end
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
        local tokenPos = pos - 1      -- Current token index
        
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
                while token do
                    local found, isList, offset = plume.capturePattern(tokens, tokenPos, infos)

                    if found then
                        table.insert(captureList, found)
                        if isList then
                            tokenPos = tokenPos + offset + 1
                            captureCount = captureCount + #found
                        else
                            tokenPos = tokenPos + 1
                            captureCount = captureCount + 1
                        end
                        token = tokens[tokenPos]
                    else
                        break
                    end
                end 

                -- Fail if mandatory capture has zero matches
                if captureCount > 0 or infos.optional then
                    tokenPos = tokenPos - 1  -- Adjust for last non-matching token
                else
                    return false
                end

                if infos.name then
                    capture[infos.name] = captureList
                end
            else
                local found, isList, offset = plume.capturePattern(tokens, tokenPos, infos)
                if found then
                    if infos.name then
                        capture[infos.name] = found  -- Store named capture
                    end

                    if isList then
                        captureCount = #found
                        tokenPos = tokenPos + offset
                    else
                        captureCount = 1
                    end
                elseif infos.optional then
                    -- Create placeholder for optional captures
                    tokenPos = tokenPos - 1  -- Maintain position
                    captureCount = 0
                    if not isList then
                        
                        if infos.name then
                            capture[infos.name] = {content = "", kind = "EMPTY"}
                        end
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
