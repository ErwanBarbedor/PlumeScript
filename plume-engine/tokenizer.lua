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
--- Lexical analyzer module for Plume language processing

-- Ordered list of token patterns with match priority (first match takes precedence)
-- Patterns use Lua string patterns with following notable behaviors:
local tokenPatterns = {
    -- Structural tokens (order-sensitive syntax elements)
    {name = "EVAL",    pattern = "%$"},      -- Expression evaluation marker
    {name = "NEWLINE", pattern = "\r?\n"},   -- Line endings (CRLF or LF)
    {name = "SPACE",   pattern = "[ \t]"},   -- Individual whitespace character
    {name = "DASH",    pattern = "%-"},      -- List item identifier
    {name = "COLON",   pattern = ":"},       -- Type/Value separator
    {name = "EQUAL",   pattern = "="},       -- Assignment operator
    {name = "ENDLINE", pattern = ";"},       -- Statement terminator
    {name = "COMMA",   pattern = ",[ \t]*"}, -- Argument list separator
    {name = "LPAR",    pattern = "%("},      -- Expression group start
    {name = "RPAR",    pattern = "%)"},      -- Expression group end
    {name = "QUOTE",   pattern = '"'},       -- String literal delimiter
    {name = "COMMENT", pattern = '//'},      -- Line comment
    {name = "OPERATOR",pattern = "[%+%-%*%/]"},  -- */-+ operator
    {name = "OPERATOR",pattern = "%.%."},  -- .. operator
    -- Value tokens
    {name = "ESCAPE", pattern = "\\\\"},  
    {name = "ESCAPE", pattern = "\\[-:=;,%(%)/snt]"},    -- Escaped character (any following character)
    {name = "ESCAPE_ALONE", pattern = "\\"},    -- Escaped character (any following character)
    -- Alphanumeric identifier
    {name = "TEXT",  pattern = "[a-zA-Z_][a-zA-Z0-9%_%.:]*[a-zA-Z0-9%_]"},
    {name = "TEXT",  pattern = "[a-zA-Z_][a-zA-Z0-9%_]*"}, 
    {name = "NUMBER",  pattern = "[0-9]+"}, 
    {name = "NUMBER",  pattern = "[0-9]+%.[0-9]+"}, 
    {name = "SYMBOL", pattern = "."}       -- Catch-all for unmatched single characters
}

-- Prepending ^ makes pattern match from current position only
for _, tp in ipairs(tokenPatterns) do
    tp.anchored = "^" .. tp.pattern
end

return function(plume)
    --- Tokenizes input text into annotated tokens with source metadata
    -- Handles indentation-based block structure through NEWLINE tracking
    -- @param text string Input source code to analyze
    -- @param filename? string Optional source identifier for error reporting
    -- @return table[] Sequence of token objects with:
    --         kind: Token type identifier
    --         content: Matched text segment
    --         source: Source location metadata
    --         indent: (NEWLINE only) Subsequent indentation level
    plume.tokenize = function(text, filename)
        local pos = 1 -- Current parsing position in source text
        local tokens = {} -- Accumulated token stream

        -- Factory for source metadata objects
        local source = function(length)
            return {
                filename = filename,
                sourceFile = text, -- NOTE: Storing entire text may be memory-intensive for large files
                absolutePosition = pos, -- Starting position of token
                length = length -- Token content length
            }
        end

        -- Detect standard indentation from first line's leading whitespace
        local indentPattern = text:match("\n([ \t]+)")
        local indentAnchored = indentPattern and "^" .. indentPattern or nil

        -- Main tokenization loop
        while pos <= #text do
            local matched = false

            -- Attempt pattern matches in priority order
            for _, tokenPattern in ipairs(tokenPatterns) do
                local start, finish = text:find(tokenPattern.anchored, pos)
                if start then
                    local content = text:sub(start, finish)
                    table.insert(
                        tokens,
                        {
                            kind = tokenPattern.name,
                            content = content,
                            source = source(finish - start + 1)
                        }
                    )
                    pos = finish + 1
                    matched = true

                    -- Handle indentation tracking after newlines
                    if tokenPattern.name == "NEWLINE" and indentAnchored then
                        local indent = 0
                        -- Count consecutive standard indent units
                        while true do
                            local s, e = text:find(indentAnchored, pos)
                            if s == pos then
                                pos = e + 1
                                indent = indent + 1
                            else
                                break
                            end
                        end
                        -- Store indent level on NEWLINE token
                        tokens[#tokens].indent = indent
                    end

                    break -- Process next character after successful match
                end
            end

            -- Safety check for unexpected parsing states
            -- NOTE: SYMBOL fallback should prevent this from ever executing
            if not matched then
                error("Lexer error: Unexpected character at position " .. pos)
            end
        end

        return tokens
    end
end
