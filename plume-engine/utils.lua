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
    plume.utils = {}

    --- Trims leading and trailing whitespace from a string
    ---@param s string The input string to process
    ---@return string The trimmed string
    plume.utils.trim = function (s)
       return s:match "^%s*(.-)%s*$"
    end

    --- Checks if a space-separated string contains a specific word
    ---@param s string The space-separated string to search
    ---@param x string The word to look for
    ---@return boolean True if the word is found
    plume.utils.containsWord = function (s, x)
        for w in s:gmatch('%S+') do
            if w == x then
                return true
            end
        end
        return false
    end

    --- Check if a given token contains a valid lua name
    function plume.checkVariableName(source, name)
        if plume.utils.containsWord("for while do repeat until if elseif else then function in end", name) then
            plume.invalidLuaNameError(source, name)
        end
    end
    function plume.checkParameterName(source, name)
        if not name:match('^[a-zA-Z_][a-zA-Z_0-9]*$')
           or plume.utils.containsWord("for while do repeat until if elseif else then function in end", name) then
            plume.invalidLuaNameError(source, name)
        end
    end
end