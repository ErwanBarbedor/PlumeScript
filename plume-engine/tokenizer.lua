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

-- This module is responsible for breaking down a raw Plume source code string
-- into a sequence of tokens. Each token represents a fundamental syntactical
-- element (e.g., keyword, operator, identifier, literal). The tokenizer uses
-- a prioritized list of regular expression patterns to identify these elements.
-- It also handles indentation tracking for newline tokens, which is crucial for
-- Plume's block structuring.

--- @class token
--- @field kind string The `name` from the matched `tokenPattern`.
--- @field content string The actual matched substring.
--- @field source @source
--- @field indent number|nil (for "NEWLINE" tokens only) The level of indentation on the
--         subsequent line, calculated based on a detected standard indent unit.

--- @class source
--- @field filename string
--- @field sourceFile string
--- @field absolutePosition
--- @field length

-- Ordered list of token patterns with match priority (first match takes precedence)
-- Patterns use Lua string patterns with following notable behaviors:
local tokenPatterns = {
    -- Structural tokens (order-sensitive syntax elements)
    {name = "EVAL",    pattern = "%$"},      -- Expression evaluation marker
    -- Line endings (CRLF or LF)
    {name = "NEWLINE", pattern = "\r?\n"},
    {name = "SPACE",   pattern = "[ \t]"},   -- Individual whitespace character
    {name = "DASH",    pattern = "%-"},      -- List item identifier
    {name = "COLON",   pattern = ":"},       -- Type/Value separator
    {name = "EQUAL",   pattern = "="},       -- Assignment operator
    {name = "ENDLINE", pattern = ";"},       -- Statement terminator
    {name = "COMMA",   pattern = ",[ \t]*"}, -- Argument list separator
    {name = "LPAR",    pattern = "%("},      -- Expression group start
    {name = "RPAR",    pattern = "%)"},      -- Expression group end
    {name = "LBRK",    pattern = "%["},      -- Index start
    {name = "RBRK",    pattern = "%]"},      -- Index end
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
    {name = "FIELD_ACCESS",  pattern = "%.[a-zA-Z_][a-zA-Z0-9%_]*"},
    {name = "SYMBOL", pattern = "."}       -- Catch-all for unmatched single characters
}

-- Prepending ^ makes pattern match from current position only
for _, tp in ipairs(tokenPatterns) do
    tp.anchored = "^" .. tp.pattern
end

local function getFileIndent(text)
    local tabs, spaces
    local indent = text
    local noline = 0
    for s in ("\n"..text):gmatch("\n([ \t]+)") do
        noline = noline + 1

        if s:match(' ') then
            space = true
        end
        if s:match('\t') then
            tabs = true
        end
        
        if space and tabs then
            error("Error: mixed tabs and spaces for indentation.", -1)
        end

        if #s < #indent then
            indent = s
        end
    end
    return indent

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
                sourceFile = text,
                absolutePosition = pos, -- Starting position of token
                length = length -- Token content length
            }
        end

        -- Detect standard indentation from first line's leading whitespace
        local indentPattern = getFileIndent(text)
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
