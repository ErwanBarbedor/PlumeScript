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
        name = "MACRO_CALL_KEY",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceBefore"},
            {kind = "TEXT",  name = "keyValue"},
            {kind = "COLON", name = "token"},
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceAfter"},
        }
    },
    {
        name = "MACRO_CALL_KEY",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceBefore"},
            {kind = "TEXT",  name = "validator"},
            {kind = "SPACE"},
            {kind = "TEXT",  name = "keyValue"},
            {kind = "COLON", name = "token"},
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceAfter"},
        }
    },
    {
        name = "MACRO_CALL_KEY_SHORT",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceBefore"},
            {kind = "COLON", name = "token"},
            {kind = "TEXT",  name = "keyValue"},
            {kind = "SPACE", multipleCapture = true, optional=true, name="spaceAfter"},
        }
    },
    {
        name = "ENDLINE",
        pattern = {
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = {"NEWLINE", "ENDLINE"}, name = "tokens", multipleCapture = true}},
            {kind = "SPACE", multipleCapture = true, optional=true},
    },
    {
        name = "VARIABLE",
        pattern = {
            {kind = "EVAL"},
            {kind = "TEXT", name = "variable"},
            {
                ["or"] = {
                    {
                        braced = {
                            open  = {kind = "LBRK"},
                            close = {kind = "RBRK"}
                        }
                    },
                    {
                        kind = "FIELD_ACCESS"
                    }
                },
                name = "index",
                optional = true,
                multipleCapture = true
            },
            {
                kind = "LPAR",
                optional = true,
                name = "call"
            }
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
            {kind = "ESCAPE", content={"\\n", "\\s", "\\t", "\\r"}, name="content"},
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
    {name = "EXPAND_LIST",  pattern = {
        {kind = "OPERATOR", content = "*"},
        {kind = "TEXT", name = "variable"}
    }},
    {name = "EXPAND_HASH",  pattern = {
        {kind = "OPERATOR", content = "*"},
        {kind = "OPERATOR", content = "*"},
        {kind = "TEXT", name = "variable"}
    }},
    {
        name = "SPACE",
        pattern = {
            {kind = "SPACE",  name = "content"},
        }
    },
    {
        name = "WORD",
        pattern = {
            {kind = "TEXT",  name = "content"},
        }
    },
}