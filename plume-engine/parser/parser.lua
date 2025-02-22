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
return function(plume)
    local trim = plume.utils.trim
    local contains = plume.utils.containsWord

    local statementPatternList  = require ("plume-engine/parser/statementPatterns")
    local expressionPatternList = require ("plume-engine/parser/expressionPatterns")

    --- Transforms a stream of lexical tokens into structured semantic elements
    ---@param tokens table[] Sequence of input tokens from lexical analysis
    ---@return table[] Structured tokens with semantic typing and context
    plume.parse = function(tokens)
        local pos = 1
        local inStatementContext = true -- Flag for structural token recognition
        local textAccumulator  -- Buffer for text fragments between structural tokens
        local result = {} -- Final structured token collection

        local captureBeginPos
        local captureTextEndPos
        local captureEndPos

        local function mergeSource(pos1, pos2)
            local source1 = tokens[pos1].source
            local source2 = tokens[pos2].source

            return  {
                filename         = source1.filename,
                sourceFile       = source1.sourceFile,
                absolutePosition = source1.absolutePosition,
                length           = source2.absolutePosition + source2.length - source1.absolutePosition,
            }
        end

        --- Accumulates text content while managing statement context state
        ---@param s string Text fragment to accumulate
        local function pushText(s)
            if not textAccumulator then
                textAccumulator = {}
            end

            if not captureTextBeginPos then
                captureTextBeginPos = captureEndPos
            end

            table.insert(textAccumulator, s)
        end

        --- Finalizes text accumulation and creates TEXT token
        local function popText()
            if textAccumulator then
                local text = table.concat(textAccumulator)

                if #text > 0 then
                    table.insert(
                        result,
                        {
                            kind = "TEXT",
                            content = text,
                            source = mergeSource(
                                captureTextBeginPos,
                                captureTextBeginPos+#textAccumulator-1
                            )
                        }
                    )
                end
                textAccumulator     = nil
                captureTextBeginPos = nil
            end
        end

        --- Adds structured token and clears text buffer
        ---@param token table Token to add to result
        local function pushToken(token)
            popText()
            token.source = mergeSource(captureBeginPos, captureEndPos)
            table.insert(result, token)
        end

        --- Captures all content until line ending
        ---@return string Concatenated line content
        local function captureLine()
            local lineContent = {}
            while tokens[pos] and not contains("NEWLINE ENDLINE", tokens[pos].kind) do
                table.insert(lineContent, tokens[pos].content)
                pos = pos + 1
            end

            return table.concat(lineContent)
        end

        --- Processes macro definition syntax
        local function captureMacro(macroName, islocal)

            if macroName then
                if islocal then
                    pushToken {
                        kind = "LOCAL_MACRO",
                        content = macroName,
                    }
                else
                    pushToken {
                        kind = "MACRO",
                        content = macroName,
                    }
                end
            else
                pushToken {
                    kind = "INLINE_MACRO",
                    content = "",
                }
            end

            while pos < #tokens do
                pos = pos + 1
                token = tokens[pos]

                if token.kind == "SPACE" or token.kind == "COMMA" then
                    -- Skip separators
                elseif token.kind == "TEXT" then
                    pushToken {
                        kind = "LIST_ITEM",
                        content = token.content
                    }
                elseif token.kind == "RPAR" then
                    break
                else
                    error("Unexpected '" .. token.kind .. "' inside arg list")
                end
            end

            pushToken {
                kind = "MACRO_ARG_END",
                content = ""
            }
        end

        local statementHandler
        statementHandler = {
            LIST_ITEM = function(match)
                pushToken {
                    kind = "LIST_ITEM",
                    content = ""
                }
            end,
            LIST_ITEM_ENDLINE = function(match)
                pushToken {
                    kind = "LIST_ITEM",
                    content = ""
                }
                statementHandler.ENDLINE(match)
            end,
            VOID_LINE = function(match)
                pushToken {
                    kind = "VOID_LINE",
                    content = ""
                }
            end,
            HASH_ITEM = function(match)
                pushToken {
                    kind = "HASH_ITEM",
                    content = match.key.content
                }
            end,
            HASH_ITEM_ENDLINE = function(match)
                pushToken {
                    kind = "HASH_ITEM",
                    content = match.key.content
                }
                statementHandler.ENDLINE(match)
            end,
            LOCAL_ASSIGNMENT = function(match)
                pushToken {
                    kind = "LOCAL_ASSIGNMENT",
                    content = match.variable.content
                }
            end,
            ASSIGNMENT = function(match)
                pushToken {
                    kind = "ASSIGNMENT",
                    content = match.variable.content
                }
            end,
            LOCAL_MACRO_DEFINITION = function(match)
                pos = pos - 1
                captureMacro(match.macroName.content, true)
                pos = pos + 1
            end,
            MACRO_DEFINITION = function(match)
                pos = pos - 1
                captureMacro(match.macroName.content)
                pos = pos + 1
            end,
            INLINE_MACRO_DEFINITION = function(match)
                pos = pos - 1
                captureMacro()
                pos = pos + 1
            end,
            RETURN = function(match)
                pushToken {
                    kind = "RETURN",
                    content = ""
                }
            end,
            LINE_STATEMENT = function(match)
                pushToken {
                    kind = match.statement.content:upper(),
                    content = captureLine()
                }
            end,
            ELSE = function(match)
                pushToken {
                    kind = "ELSE",
                    content = ""
                }
            end,
            BREAK = function(match)
                pushToken {
                    kind = "BREAK",
                    content = ""
                }
            end,
            ENDLINE = function(match)
                pushToken {
                    kind = "ENDLINE",
                    content = "",
                    indent = match.tokens[#match.tokens].indent
                }
                inStatementContext = true
            end,
            COMMENT = function(match)
                local indent = 0
                if match.tokens and #match.tokens > 0 then
                    indent = match.tokens[#match.tokens].indent
                end

                pushToken {
                    kind = "ENDLINE",
                    content = "",
                    indent = indent
                }
                inStatementContext = true
            end,
            MACRO_CALL_BEGIN = function(match)
                pushToken {
                    kind = "MACRO_CALL_BEGIN",
                    content = match.variable.content
                }
            end,
            VARIABLE = function(match)
                pushToken {
                    kind = "VARIABLE",
                    content = match.variable.content
                }
            end,
            LUA_EXPRESSION = function(match)
                local content = {}
                for _, token in ipairs(match.content) do
                    table.insert(content, token.content)
                end
                pushToken {
                    kind = "LUA_EXPRESSION",
                    content = table.concat(content, "", 2, #content-1) -- remove braces
                }
            end,
            USER_SPACE = function(match)
                local content = match.content.content
                if content == "\\s" then
                    content = " "
                end
                pushToken {
                    kind = "TEXT",
                    content = content
                }
            end,
            ESCAPE = function(match)
                local content = match.content.content:sub(2, -1)
                if content == "\\" then
                    content = "\\\\"
                end
                pushToken {
                    kind = "TEXT",
                    content = content
                }
            end,
            ESCAPE_ALONE = function(match)
                pushToken {
                    kind = "TEXT",
                    content = "\\\\"
                }
            end,
            RPAR = function(match)
                pushToken {
                    kind    = "RPAR",
                    content = ""
                }
            end,
            COMMA = function(match)
                pushToken {
                    kind    = "COMMA",
                    content = ""
                }
            end
        }

        local function testAllPatterns(patternList)
            for _, patternInfo in ipairs(patternList) do
                local match = plume.matchPattern(tokens, pos, patternInfo.pattern)
                if match then
                    return patternInfo.name, match
                end
            end
        end

        -- Main parsing loop
        while pos <= #tokens do
            local patternName, match
            if inStatementContext then
                patternName, match = testAllPatterns(statementPatternList)
            end

            if not patternName then
                inStatementContext = false
                patternName, match = testAllPatterns(expressionPatternList)
            end

            if patternName then

                captureBeginPos = pos
                pos = pos + match.length
                captureEndPos = pos-1
                
                popText()

                statementHandler[patternName](match)

                if inStatementContext then
                    while tokens[pos] and tokens[pos].kind == "SPACE" do
                        pos = pos + 1
                    end
                end
            else
                captureEndPos = pos

                pushText(tokens[pos].content)
                pos = pos + 1
            end

        end

        popText()

        return result
    end
end
