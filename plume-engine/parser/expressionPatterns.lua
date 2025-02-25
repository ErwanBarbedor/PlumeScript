return {
    {
        name = "ENDLINE",
        pattern = {
            {kind = {"NEWLINE", "ENDLINE"}, name = "tokens", multipleCapture = true}}
    },
    {
        name = "INLINE_MACRO_DEFINITION",
        pattern = {
            {kind = "TEXT",  content = "def"},
            {kind = "SPACE", multipleCapture = true, optional=true},
            {kind = "LPAR"}
        }
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
            {kind = "TEXT", name = "variable"}
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
            {kind = "COMMENT"},
            {neg={kind = {"NEWLINE"}}, multipleCapture = true, optional=true},
            {kind = {"NEWLINE"}, name = "tokens", multipleCapture = true, optional=true}
        }
    }
}