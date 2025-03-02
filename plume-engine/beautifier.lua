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

--- Formats Lua code with automatic indentation based on syntax patterns.

return function(plume)

    plume.beautifier = function(code)
        local formatted_lines = {}
        local indent_level = 0

        -- Pattern configuration for indentation changes
        local INDENT_RULES = {
            decrement = {  -- Rules for decreasing indentation BEFORE processing line
                { pattern = "^},?%s?$"     },  -- Closing brace (with optional comma)
                { pattern = "end"       },  -- End of block
                { pattern = "return $"  },  -- Return statement (simplistic match)
                { pattern = "^else"     },  -- Else/elseif keyword at line start
                { pattern = "^%)+,?%s*$"     }   -- Lines ending with closing parentheses
            },
            increment = {  -- Rules for increasing indentation AFTER processing line 
                { pattern = "{$"        },  -- Opening brace
                { pattern = "function"  },  -- Function declaration
                { pattern = "return $"  },  -- Match returns with block creation
                { pattern = "^for"      },  -- Loop structures
                { pattern = "^if"       },  -- Conditional blocks
                { pattern = "^else"     },  -- Else block (indent after)
                { pattern = "^while"    },  -- While loop
                { pattern = "%($"       }   -- Opening parenthesis (basic match)
            }
        }

        --- Checks if a line matches indentation rules while ignoring excluded patterns
        -- @param line: Raw input line to check
        -- @param rule: Rule table containing pattern and optional exclude
        -- @return: boolean indicating match status
        local function match_line(line, rule)
            return line:match(rule.pattern) and not (rule.exclude and line:match(rule.exclude))
        end

        -- Main processing loop
        for line in (code.."\n"):gmatch("([^\n]*)\n") do
            -- Process DECREMENT rules before adding line
            for _, rule in ipairs(INDENT_RULES.decrement) do
                if match_line(line, rule) then
                    indent_level = math.max(indent_level - 1, 0)  -- Prevent negative indentation
                    break  -- Only apply first matching decrement rule
                end
            end

            -- Add line with current indentation
            table.insert(formatted_lines, string.rep("\t", indent_level) .. line:gsub("^%s+", ""))

            -- Process INCREMENT rules after adding line
            for _, rule in ipairs(INDENT_RULES.increment) do
                if match_line(line, rule) then
                    indent_level = indent_level + 1
                    break  -- Only apply first matching increment rule
                end
            end
        end

        return table.concat(formatted_lines, "\n")
    end
end