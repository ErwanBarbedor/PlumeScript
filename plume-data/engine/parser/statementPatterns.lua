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
-- statement-level constructs and other structural elements at the beginning of
-- lines or within blocks. These patterns have higher precedence when the parser
-- is in a "statement context".

return {
    {
        name = "MACRO_DEFINITION",--local
        pattern = {
            {kind = "TEXT",  content = "local", name="isLocal"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  content = "macro"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  name = "macroName", optional = true},
            {kind = "SPACE", multipleCapture = true, optional = true},
            {kind = "LPAR"}
        }
    },
    {
        name = "MACRO_DEFINITION",
        pattern = {
            {kind = "TEXT",  content = "macro"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  name = "macroName"},
            {kind = "SPACE", multipleCapture = true, optional = true},
            {kind = "LPAR"},
        }
    },
    {
        name = "LINE_STATEMENT",
        pattern = {
            {
                kind = "TEXT",
                name = "statement",
                content = {"for", "if", "elseif", "while" }
            },
            {
                neg = {kind = {"ENDLINE", "NEWLINE", "COMMENT"}},
                multipleCapture = true,
                name = "line"
            }
        }
    },
    {
        name = "RETURN",
        pattern = {
            {kind = "TEXT", content = "return"},
            {kind = "SPACE", multipleCapture = true, optional=true}
        }
    },
    {
        name = "LEAVE",
        pattern = {
            {kind = "TEXT", content = "leave"},
        }
    },
    {name = "VOID",      pattern = {{kind = "TEXT", content = "void"}}},
    {name = "ELSE",      pattern = {{kind = "TEXT", content = "else"}}},
    {name = "BREAK",     pattern = {{kind = "TEXT", content = "break"}}},
    {name = "CONTINUE",  pattern = {{kind = "TEXT", content = "continue"}}},
    {name = "COMMAND_EXPAND_LIST",  pattern = {
        {kind = "OPERATOR", content = "*"},
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
    }},
    {name = "COMMAND_EXPAND_HASH",  pattern = {
        {kind = "OPERATOR", content = "*"},
        {kind = "OPERATOR", content = "*"},
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
    }},
    {
        name = "LIST_ITEM",
        pattern = {
            {kind = "DASH"},
            {
                ["or"] = {
                    {kind = "SPACE", multipleCapture = true},
                    {kind = {"NEWLINE", "ENDLINE"}}
                },
                name="final"
            }
        }
    },
    {
        name = "HASH_ITEM",
        pattern = {
            {kind = "META", name = "meta",     optional=true},
            {kind = "EVAL", name = "evalmode", optional=true},
            {
                ['or'] = {
                    {kind = "TEXT", name = "keyValue"},
                    {
                        braced = {
                            open  = {kind = "LPAR"},
                            close = {kind = "RPAR"}
                        },
                        name = "keyExpression"
                    }
                },
                name = "key"
            },
            {kind = "COLON"},
            {
                ["or"] = {
                    {kind = "SPACE", multipleCapture = true},
                    {kind = {"NEWLINE", "ENDLINE"}}
                },
                name="final"
            }
        }
    },
    {
        name = "LOCAL_ASSIGNMENT",
        pattern = {
            {kind = "TEXT", content = "local"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "variable"},
            {kind = "SPACE", multipleCapture = true},
            {kind = {"OPERATOR", "DASH"}, name = "compound_operator", optional=true},
            {kind = "EQUAL"},
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = {"NEWLINE", "ENDLINE"}, name = "endline", optional = true}
        }
    },
    {
        name = "LOCAL_ASSIGNMENT",
        pattern = {
            {kind = "TEXT", content = "local"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "variable", neg={content="macro"}}
        }
    },
    {
        name = "ASSIGNMENT",
        pattern = {
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "variable"},
            {
                braced = {
                    open  = {kind = "LBRK"},
                    close = {kind = "RBRK"}
                },
                name = "index",
                optional = true
            },
            {kind = "SPACE", multipleCapture = true},
            {kind = {"OPERATOR", "DASH"}, name = "compound_operator", optional=true},
            {kind = "EQUAL"},
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = {"NEWLINE", "ENDLINE"}, name = "endline", optional = true}
        }
    },
    {
        name = "ASSIGNMENT",
        pattern = {
            {kind = "EVAL", name = "evalmode"},
            {
                braced = {
                    open  = {kind = "LPAR"},
                    close = {kind = "RPAR"}
                },
                name = "variableExpression"
            },
            {
                braced = {
                    open  = {kind = "LBRK"},
                    close = {kind = "RBRK"}
                },
                name = "index",
                optional = true
            },
            {kind = "SPACE", multipleCapture = true},
            {kind = "OPERATOR", name = "compound_operator", optional=true},
            {kind = "EQUAL"},
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = {"NEWLINE", "ENDLINE"}, name = "endline", optional = true}
        }
    },
}