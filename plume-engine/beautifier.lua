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

return function(plume)
    -- Defines a code formatter for the plume object
    plume.beautifier = function(code)
        local formatted_lines = {}
        local indent_level = 0

        -- Indentation pattern configuration
        local INDENT_RULES = {
            decrement = {
                { pattern = "^},?$"},                    -- Closing brace (non-empty)
                { pattern = "end" },                  -- Block end
                { pattern = "return $" },
                { pattern = "^else" },                -- Else control structure
                { pattern = "^elseif" },              -- Elseif control structure
                { pattern = "^%)+$" }
            },
            increment = {
                { pattern = "{$"},                    -- Opening brace (non-empty)
                { pattern = "function" },         -- Function declaration
                { pattern = "return $" },
                { pattern = "^for" },                 -- For loop
                { pattern = "^if" },                  -- If condition
                { pattern = "^else" },                -- Else block
                { pattern = "^elseif" },              -- Elseif block
                { pattern = "^while" },                -- While loop
                { pattern = "%($" }
            }
        }

        -- Checks if a line matches a pattern with exclusions
        local function match_line(line, rule)
            return line:match(rule.pattern) and not (rule.exclude and line:match(rule.exclude))
        end

        -- Line-by-line processing
        for line in code:gmatch("[^\n]+") do
            -- Decrease indentation before line
            for _, rule in ipairs(INDENT_RULES.decrement) do
                if match_line(line, rule) then
                    indent_level = math.max(indent_level - 1, 0)
                    break -- Single decrement per line
                end
            end

            -- Format current line
            table.insert(formatted_lines, string.rep("\t", indent_level) .. line)

            -- Increase indentation after line
            for _, rule in ipairs(INDENT_RULES.increment) do
                if match_line(line, rule) then
                    indent_level = indent_level + 1
                    break -- Single increment per line
                end
            end
        end

        return table.concat(formatted_lines, "\n")
    end
end
