return {
    {
        name = "LIST_ITEM",
        pattern = {
            {kind = "DASH"},
            {kind = "SPACE"}
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
            {kind = "TEXT", name = "variable"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "EQUAL"}
        }
    },
    {
        name = "ASSIGNMENT",
        pattern = {
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
            {kind = "TEXT",  content = "def"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  name = "macroName", optional = true},
            {kind = "LPAR"}
        }
    },
    {
        name = "MACRO_DEFINITION",
        pattern = {
            {kind = "TEXT",  content = "def"},
            {kind = "SPACE", multipleCapture = true},
            {kind = "TEXT",  name = "macroName"},
            {kind = "LPAR"}
        }
    },
    {
        name = "LINE_STATEMENT",
        pattern = {
            {
                kind = "TEXT",
                name = "statement",
                content = {"for", "if", "elseif", "while" }
            }
        }
    },
    {name = "RETURN", pattern = {{kind = "TEXT", content = "return"}}},
    {name = "ELSE",   pattern = {{kind = "TEXT", content = "else"}}},
    {name = "BREAK",  pattern = {{kind = "TEXT", content = "break"}}},
}