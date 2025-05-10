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

-- This module provides a list of patterns used by `parser.lua` to identify
-- various expression-level constructs within a token stream. These patterns
-- are typically applied when the parser is not in a statement-expecting context
-- (e.g., after an operator, within parentheses, or as part of an assignment's
-- right-hand side).

return {
    {
        name = "ENDLINE",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = {"NEWLINE", "ENDLINE"}, name = "tokens", multipleCapture = true}},
            {kind = "SPACE", multipleCapture = true, optional=true},
    },
    {
        name = "MACRO_CALL_BEGIN",
        pattern = {
            {kind = "EVAL"},
            {kind = "TEXT", name = "variable"},
            {kind = "LPAR"},
        }
    },
    {
        name = "VARIABLE",
        pattern = {
            {kind = "EVAL"},
            {kind = "TEXT", name = "variable"},
            {
                braced = {
                    open  = {kind = "LBRK"},
                    close = {kind = "RBRK"}
                },
                name = "index",
                optional = true
            }
        }
    },
    {
        name = "VARIABLE",
        pattern = {
            {kind = "EVAL"},
            {kind = "NUMBER", name = "variable"}
        }
    },
    {
        name = "LUA_EXPRESSION",
        pattern = {
            {kind = "EVAL"},
            {
                braced = {
                    open  = {kind = "LPAR"},
                    close = {kind = "RPAR"}
                },
                name = "content"
            }
        }
    },
    {
        name = "USER_SPACE",
        pattern = {
            {kind = "ESCAPE", content={"\\n", "\\s", "\\t"}, name="content"},
        }
    },
    {
        name = "ESCAPE",
        pattern = {
            {kind = "ESCAPE", name="content"},
        }
    },
    {
        name = "ESCAPE_ALONE",
        pattern = {
            {kind = "ESCAPE_ALONE"},
        }
    },
    {
        name = "RPAR",
        pattern = {
            {kind = "RPAR"},
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaces"},
        }
    },
    {
        name = "LPAR",
        pattern = {
            {kind = "LPAR"},
        }
    },
    {
        name = "COMMA",
        pattern = {
            {kind = "COMMA", name="token"},
        }
    },
    {
        name = "COMMENT",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = "COMMENT"},
            {neg={kind = {"NEWLINE"}}, multipleCapture = true, optional=true},
            {kind = {"NEWLINE"}, name = "tokens", multipleCapture = true, optional=true}
        }
    },
    {name = "EXPAND",  pattern = {
        {kind = "OPERATOR", content = "*"},
        {kind = "TEXT", name = "variable"}
    }},
}