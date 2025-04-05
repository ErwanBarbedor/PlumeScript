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
        local textAccumulator           -- Buffer for text fragments between structural tokens
        local result = {}               -- Final structured token collection

        local macroDefDeep = 0

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

        function handleMacroDef (match, isLocal)
            if match.macroName and match.macroName.content then
                pushToken {
                    kind = "MACRO_DEFINITION",
                    content = match.macroName.content,
                    isLocal = isLocal
                }  
            else
                pushToken {
                    kind = "INLINE_MACRO_DEFINITION",
                    content = ""
                }  
            end
             

            -- if match.rpar.kind == "EMPTY" then
            --     macroDefDeep = 1
            -- else
            --     pushToken {
            --         kind = "MACRO_ARG_END",
            --         content = ""
            --     }
            -- end

            inStatementContext = false
        end

        function handleMacroCall (match)
            plume.checkVariableName(match.variable.source, match.variable.content)
            pushToken {
                kind = "MACRO_CALL_BEGIN",
                content = match.variable.content
            }
            -- if match.rpar.kind == "EMPTY" then
            --     macroCallDeep = 1
            -- else
            --     pushToken {
            --         kind = "MACRO_ARG_END",
            --         content = ""
            --     }
            -- end

            inStatementContext = false
        end

        -- function updateMacroDefDeep(delta)
        --     if macroDefDeep > 0 then
        --         macroDefDeep = macroDefDeep + delta
        --         if macroDefDeep == 0 then
        --             pushToken {
        --                 kind = "MACRO_ARG_END",
        --                 content = ""
        --             }
        --             return true
        --         end
        --     end
        -- end


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

                if #match.evalmode.content>0 then
                    pushToken {
                        kind = "BEGIN_LINE_EXPRESSION",
                        content = ""
                    }
                end
            end,
            HASH_ITEM_ENDLINE = function(match)
                pushToken {
                    kind = "HASH_ITEM",
                    content = match.key.content,
                }
                
                statementHandler.ENDLINE(match)
            end,
            LOCAL_ASSIGNMENT = function(match)
                plume.checkVariableName(match.variable.source, match.variable.content)
                local tokenInfos = {
                    kind = "LOCAL_ASSIGNMENT",
                    content = match.variable.content,
                }
                if match.compound_operator.kind ~= "EMPTY" then
                    tokenInfos.compound_operator = match.compound_operator.content
                end

                pushToken (tokenInfos)
                if #match.evalmode.content>0 then
                    pushToken {
                        kind = "BEGIN_LINE_EXPRESSION",
                        content = ""
                    }
                end
            end,
            ASSIGNMENT = function(match)
                plume.checkVariableName(match.variable.source, match.variable.content)
                local tokenInfos = {
                    kind = "ASSIGNMENT",
                    content = match.variable.content,
                }
                if match.compound_operator.kind ~= "EMPTY" then
                    tokenInfos.compound_operator = match.compound_operator.content
                end

                pushToken (tokenInfos)
                if #match.evalmode.content>0 then
                    pushToken {
                        kind = "BEGIN_LINE_EXPRESSION",
                        content = ""
                    }
                end
            end,
            LOCAL_MACRO_DEFINITION = function(match)
                handleMacroDef(match, true)
            end,
            MACRO_DEFINITION = function(match)
                handleMacroDef(match)
            end,
            INLINE_MACRO_DEFINITION = function(match)
                handleMacroDef(match)
            end,
            RETURN = function(match)
                pushToken {
                    kind = "RETURN",
                    content = ""
                }

                if #match.evalmode.content>0 then
                    pushToken {
                        kind = "BEGIN_LINE_EXPRESSION",
                        content = ""
                    }
                end
            end,
            LINE_STATEMENT = function(match)
                local line = {}
                for _, token in ipairs(match.line) do
                    table.insert(line, token.content)
                end
                
                pushToken {
                    kind = match.statement.content:upper(),
                    content = table.concat(line)
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
                handleMacroCall(match)
            end,
            VARIABLE = function(match)
                plume.checkVariableName(match.variable.source, match.variable.content)
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
                -- if not updateMacroDefDeep(-1) then
                    pushToken {
                        kind    = "RPAR",
                        content = ")"
                    }
                -- end
            end,
            LPAR = function(match)
                pushToken {
                    kind    = "LPAR",
                    content = "("
                }
                -- updateMacroDefDeep(1)
            end,
            COMMA = function(match)
                pushToken {
                    kind    = "COMMA",
                    content = match.token.content
                }
            end,
            EXPAND = function(match)
                pushToken {
                    kind    = "EXPAND",
                    content = match.variable.content
                }
            end,
            COMMAND_EXPAND = function(match)
                pushToken {
                    kind    = "COMMAND_EXPAND",
                    content = match.variable.content
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

        -- skip first spaces
        while tokens[pos] and tokens[pos].kind == "SPACE" do
            pos = pos + 1
        end

        -- skip last spaces
        while #tokens>0 and tokens[#tokens].kind == "SPACE" do
            table.remove(tokens)
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
