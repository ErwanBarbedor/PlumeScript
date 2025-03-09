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
            {kind = "TEXT", name = "key"},
            {kind = "COLON"},
            {kind = "SPACE"}
        }
    },
    {
        name = "HASH_ITEM_ENDLINE",
        pattern = {
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
            {kind = "EQUAL"}
        }
    },
    {
        name = "ASSIGNMENT",
        pattern = {
            {kind = "EVAL", name = "evalmode", optional=true},
            {kind = "TEXT", name = "variable"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "EQUAL"}
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
            {kind = "LPAR"},
            -- {kind = "SPACE", optional = true},
            -- {kind = "RPAR",  optional = true, name = "rpar"}
        }
    },
    {
        name = "MACRO_DEFINITION",
        pattern = {
            {kind = "TEXT",  content = "macro"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  name = "macroName"},
            {kind = "LPAR"},
            -- {kind = "SPACE", optional = true},
            -- {kind = "RPAR",  optional = true, name = "rpar"}
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
    {name = "RETURN", pattern = {{kind = "TEXT", content = "return"}}},
    {name = "ELSE",   pattern = {{kind = "TEXT", content = "else"}}},
    {name = "BREAK",  pattern = {{kind = "TEXT", content = "break"}}},
}