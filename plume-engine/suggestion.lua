return function(plume)
    -- Compute Damerau-Levenshtein distance
    -- @param s1 string first word to compare
    -- @param s2 string second word to compare
    -- @return int Damerau-Levenshtein distance bewteen s1 and s2
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

    --- Convert an associative table to an alphabetically sorted one.
    -- @param t table The associative table to sort
    -- @return table The table containing sorted keys
    local function sort(t)
        -- Create an empty table to store the sorted keys
        local sortedTable = {}
        
        -- Extract keys from the associative table
        for k in pairs(t) do
            table.insert(sortedTable, k)
        end

        -- Sort the keys alphabetically
        table.sort(sortedTable)
        
        return sortedTable
    end

    local function searchWord(target, words, types)
        local suggestions = {}

        for word, wordType in pairs(words) do
            if types:match(wordType) then
                if word_distance (word, target) <= math.max(1, #target/2) then
                    suggestions["'"..word.."'"] = true
                end
            end
        end

        return sort(suggestions)-- To make the order deterministic
    end

    function plume.makeSuggestion(message, t)
        local error, variable = message:match("attempt to (.-) global '(.-)' %(a .- value%)")
        if not variable then
            error, variable = message:match("attempt to (.-) local '(.-)' %(a .- value%)")
        end

        local suggestions = {}
        if variable then
            local types = "table string number function"

            if error:match("perform arithmetic on") then
                types = "number"
            elseif error:match("call") then
                types = "function"
            elseif error:match("index a") then
                types = "table"
            elseif error:match("concatenate") then
                types = "string"
            elseif error:match("get length of") then
                types = "string table"
            end

            if message:match("%(a %w+ value%)") then
                suggestions = searchWord(variable, t, types)
            end
        end

        if #suggestions > 0 then
            message = message
                .. ". Perhaps you mean "
                .. table.concat(suggestions, ", "):gsub(',([^,]*)$', " or%1")
                .. "?"
        end

        return message
    end
end