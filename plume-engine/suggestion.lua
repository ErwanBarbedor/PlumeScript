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

-- This module provides functionality to enhance Lua error messages
-- by suggesting corrections for misspelled variable or function names.
-- It uses the Damerau-Levenshtein distance to find similar names
-- within a given context (e.g., global variables, local scope).

return function(plume)
    --- Computes the Damerau-Levenshtein distance between two strings.
    ---@param s1 string The first string to compare.
    ---@param s2 string The second string to compare.
    ---@return number The Damerau-Levenshtein distance between s1 and s2.
    local function word_distance(s1, s2)
        local len1, len2 = #s1, #s2
        local matrix = {}

        for i = 0, len1 do
            matrix[i] = {[0] = i}
        end
        for j = 0, len2 do
            matrix[0][j] = j
        end

        for i = 1, len1 do
            for j = 1, len2 do
                local cost = (s1:sub(i,i) ~= s2:sub(j,j)) and 1 or 0
                matrix[i][j] = math.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
                if i > 1 and j > 1 and s1:sub(i,i) == s2:sub(j-1,j-1) and s1:sub(i-1,i-1) == s2:sub(j,j) then
                    matrix[i][j] = math.min(matrix[i][j], matrix[i-2][j-2] + cost)
                end
            end
        end

        return matrix[len1][len2]
    end

    --- Creates a numerically-indexed table containing the alphabetically sorted keys of an associative table.
    ---@param t table The associative table whose keys are to be sorted.
    ---@return table A new numerically-indexed table containing the alphabetically sorted keys.
    local function sort(t)
        local sortedTable = {}
        
        for k in pairs(t) do
            table.insert(sortedTable, k)
        end

        table.sort(sortedTable)
        
        return sortedTable
    end

    --- Searches for words in a dictionary that are similar to a target word, filtering by type.
    --- Similarity is determined using Damerau-Levenshtein distance with a dynamic threshold.
    ---@param target string The word to find suggestions for.
    ---@param words table A dictionary where keys are words (string) and values are their types (string).
    ---@param types string A string containing space-separated type names (e.g., "function table").
    ---                 A word from the `words` dictionary is considered if its type is found as a substring in this `types` string.
    ---@return table A numerically-indexed, alphabetically sorted table of suggested words (strings, single-quoted).
    local function searchWord(target, words, types)
        local suggestions = {} -- Using a table as a set to store unique suggestions

        for word, wordType in pairs(words) do
            -- Check if the word's type is among the allowed types.
            -- string.match is used for a simple substring check.
            if types:match(wordType) then
                -- Calculate Damerau-Levenshtein distance.
                -- The threshold for similarity is the maximum of 1 or half the target word's length (integer division).
                -- This allows more typos for longer words, providing a flexible matching criterion.
                if word_distance(word, target) <= math.max(1, math.floor(#target/2)) then
                    suggestions["'"..word.."'"] = true -- Add quoted word to suggestions set
                end
            end
        end

        return sort(suggestions) -- Sort for deterministic output order, useful for tests and consistent user experience.
    end

    --- Analyzes a Lua error message to extract a potentially misspelled variable name
    --- and suggests corrections from a given table of symbols.
    --- It attempts to parse common "attempt to <action> <scope> '<name>' (a <type> value)" error patterns.
    ---@param message string The original Lua error message.
    ---@param t table A table representing the current scope (e.g., globals), where keys are symbol names (string)
    ---            and values are their types (string, e.g., "function", "table", "number").
    ---@return string The original message, potentially augmented with "Perhaps you mean..." suggestions.
    function plume.makeSuggestion(message, t)
        -- Try to extract the type of error and the variable name from common Lua error message patterns.
        local error_action, variable = message:match("attempt to (.-) global '(.-)' %(a .- value%)")
        if not variable then -- If not a global variable error, try matching a local variable error pattern.
            error_action, variable = message:match("attempt to (.-) local '(.-)' %(a .- value%)")
        end

        local suggestions = {}
        if variable then
            -- Default set of types to consider if the error message doesn't provide more specific clues.
            local expected_types = "table string number function"

            -- Narrow down the expected type based on the action being attempted in the error message.
            -- This helps in providing more relevant suggestions.
            if error_action:match("perform arithmetic on") then
                expected_types = "number"
            elseif error_action:match("call") then
                expected_types = "function"
            elseif error_action:match("index") then -- e.g., "index a nil value", "index a boolean value"
                expected_types = "table" -- Strings can also be indexed, but tables are primary target for general indexing errors.
            elseif error_action:match("concatenate") then
                expected_types = "string" -- Numbers can be concatenated in Lua (coerced to string), but primary intent is usually string.
            elseif error_action:match("get length of") then
                expected_types = "string table" -- Both strings and tables support the length operator.
            end

            -- Further refine the search only if the error message confirms a type mismatch or nil value access context.
            -- The pattern "%(a %w+ value%)" matches phrases like "(a nil value)", "(a boolean value)", etc.
            if message:match("%(a %w+ value%)") then
                suggestions = searchWord(variable, t, expected_types)
            end
        end

        if #suggestions > 0 then
            -- Format suggestions into a human-readable list: "A, B or C".
            local suggestion_str = table.concat(suggestions, ", ")
            -- Replace the last comma with " or" for better grammar.
            suggestion_str = suggestion_str:gsub(',([^,]*)$', " or%1") 
            message = message
                .. ". Perhaps you mean "
                .. suggestion_str
                .. "?"
        end

        return message
    end
end
