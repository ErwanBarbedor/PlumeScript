return {
    {
        name = "LIST_ITEM",
        pattern = {
            {kind = "DASH"},
            {kind = "SPACE"}
        }
    },
    {
        name = "LIST_ITEM_ENDLINE",
        pattern = {
            {kind = "DASH"},
            {kind = {"NEWLINE", "ENDLINE"}, name = "tokens", multipleCapture = true}
        }
    },
    {
        name = "HASH_ITEM",
        pattern = {
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "key"},
            {kind = "COLON"},
            {kind = "SPACE"}
        }
    },
    {
        name = "HASH_ITEM",
        pattern = {
            {kind = "EVAL", name = "evalmode"},
            {
                braced = {
                    open  = {kind = "LPAR"},
                    close = {kind = "RPAR"}
                },
                name = "keyExpression"
            },
            {kind = "COLON"},
            {kind = "SPACE"}
        }
    },
    {
        name = "HASH_ITEM_ENDLINE",
        pattern = {
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "key"},
            {kind = "COLON"},
            {kind = {"NEWLINE", "ENDLINE"}, name = "tokens", multipleCapture = true}
        }
    },
    -- {
    --     name = "VOID_LINE",
    --     pattern = {
    --         {kind = "AT"},
    --         {kind = "SPACE"}
    --     }
    -- },
    {
        name = "LOCAL_ASSIGNMENT",
        pattern = {
            {kind = "TEXT", content = "local"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "variable"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "OPERATOR", name = "compound_operator", optional=true},
            {kind = "EQUAL"},
            {kind = {"NEWLINE", "ENDLINE"}, name = "endline", optional = true}
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
            {kind = "OPERATOR", name = "compound_operator", optional=true},
            {kind = "EQUAL"},
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
            {kind = {"NEWLINE", "ENDLINE"}, name = "endline", optional = true}
        }
    },
    {
        name = "LOCAL_MACRO_DEFINITION",
        pattern = {
            {kind = "TEXT",  content = "local"},
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
            },{
                neg = {kind = {"ENDLINE", "NEWLINE", "COMMENT"}},
                multipleCapture = true,
                name = "line"
            }
        }
    },
    {name = "RETURN", pattern = {
        -- {kind = "EVAL", name = "evalmode", optional=true},
        {kind = "TEXT", content = "return"}
    }},
    {name = "ELSE",   pattern = {{kind = "TEXT", content = "else"}}},
    {name = "BREAK",  pattern = {{kind = "TEXT", content = "break"}}},
    {name = "COMMAND_EXPAND",  pattern = {
        {kind = "OPERATOR", content = "*"},
        {kind = "TEXT", name = "variable"}
    }},
}