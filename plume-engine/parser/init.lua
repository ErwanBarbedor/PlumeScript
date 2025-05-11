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

-- This module is a semantic parser that processes a flat list of tokens generated
-- by the lexer. It applies a series of predefined patterns (from
-- `statementPatterns.lua` and `expressionPatterns.lua`) to identify higher-level
-- language constructs like statements, expressions, and macro definitions.
-- The output is a refined stream of tokens with enhanced semantic meaning,
-- which serves as input for the AST (Abstract Syntax Tree) construction.

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
        local lineCache = {}            -- Store informations about indentation and commands
        local currentIndent = 0

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

        --- Checks if the sequence of commands in `lineCache` is valid according to certain rules.
        --- These rules prevent chaining specific commands and opening blocks in invalid contexts.
        local function checkIsValid()
            if #lineCache == 1 then
                return
            end

            local source = lineCache.firstCommand.source

            -- Check rules for ASSIGNMENT and HASH_ITEM commands
            if contains("ASSIGNMENT HASH_ITEM", lineCache[1]) then
                if lineCache[1] == lineCache[2] then
                    plume.cannotChainSeveralCommand (source, lineCache[1])
                elseif contains("ASSIGNMENT HASH_ITEM LIST_ITEM IF FOR ELSEIF WHILE", lineCache[2]) then
                    plume.cannotChainCommands(source, lineCache[1], lineCache[2])
                -- Check for invalid block opening
                elseif lineCache[#lineCache] == "BLOCK_OPEN" then  
                    if #lineCache > 2 then
                        if not contains("INLINE_MACRO_DEFINITION MACRO_CALL_BEGIN", lineCache[2])   then
                            plume.cannotOpenBlock(source, lineCache[1])
                        end
                    end

                    if lineCache[2] == "INLINE_MACRO_DEFINITION" then
                        local pos = 2
                        while pos < #lineCache and lineCache[pos] ~= "RPAR" do
                            pos = pos + 1
                        end
                        if #lineCache > pos+1 then
                            plume.cannotOpenBlock(source, lineCache[2])
                        end
                    end
                end
            -- Check rules for MACRO_DEFINITION and LOCAL_MACRO_DEFINITION commands
            elseif contains("MACRO_DEFINITION LOCAL_MACRO_DEFINITION", lineCache[1]) then
                local pos = 1
                while pos < #lineCache and lineCache[pos] ~= "RPAR" do
                    pos = pos + 1
                end

                if lineCache[#lineCache] == "BLOCK_OPEN" and #lineCache > pos+1 then
                    plume.cannotOpenBlock(source, lineCache[1])
                end
            end
        end

        --- Enforces command usage rules, particularly for block openings and command chaining.
        --- This function analyzes the current `token` and its context to ensure proper syntax
        --- and prevent forbidden command sequences.
        ---@param token table? The current token being processed. If nil, it's treated as a text token.
        local function checkCommandsRules(token)
            local kind = (token and token.kind) or ("TEXT")

            if kind and inStatementContext then
                lineCache.indent = currentIndent
                lineCache.firstCommand = token  
            end

            if kind == "ENDLINE" then
                -- Check and handle block opening based on indent
                if token.indent and lineCache.firstCommand and lineCache.indent < token.indent then
                    table.insert(lineCache, "BLOCK_OPEN")
                    checkIsValid()
                end

                lineCache = {} -- Reset lineCache at the end of a line
            elseif lineCache.firstCommand then
                table.insert(lineCache, kind)
            end

            if lineCache.firstCommand then
                checkIsValid()
            end

            if token and token.indent then
                currentIndent = token.indent
            end
        end

        --- Adds structured token and clears text buffer
        ---@param token table Token to add to result
        local function pushToken(token)
            popText()
            token.source = mergeSource(captureBeginPos, captureEndPos)
            checkCommandsRules(token)
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

            inStatementContext = false
        end

        function handleMacroCall (match)
            plume.checkVariableName(match.variable.source, match.variable.content)
            pushToken {
                kind = "MACRO_CALL_BEGIN",
                content = match.variable.content
            }

            inStatementContext = false
        end

        local statementHandler
        statementHandler = {
            LIST_ITEM = function(match)
                pushToken {
                    kind = "LIST_ITEM",
                    content = ""
                }
                match.tokens = {{indent = currentIndent + 1}}
                statementHandler.ENDLINE(match)
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
                local key = match.key and match.key.content

                if not key then
                    local t = {}
                    for _, token in ipairs(match.keyExpression) do
                        table.insert(t, token.content)
                    end
                    key = table.concat(t, "", 2, #t-1)
                end

                pushToken {
                    kind = "HASH_ITEM",
                    content = key,
                    eval    = #match.evalmode.content>0
                }
            end,
            HASH_ITEM_ENDLINE = function(match)
                if #match.evalmode.content>0 then
                    plume.multilineEvalError(match.key.source, ":")
                end

                pushToken {
                    kind = "HASH_ITEM",
                    content = match.key.content,
                }
                
                statementHandler.ENDLINE(match)
            end,
            LOCAL_ASSIGNMENT = function(match)

                if #match.evalmode.content>0 then
                    plume.error(match.variable.source, "Syntax forbiden") -- todo: better error message
                end

                plume.checkVariableName(match.variable.source, match.variable.content)
                local tokenInfos = {
                    kind = "LOCAL_ASSIGNMENT",
                    content = match.variable.content,
                }
                if match.compound_operator and match.compound_operator.kind ~= "EMPTY" then
                    tokenInfos.compound_operator = match.compound_operator.content
                end

                pushToken (tokenInfos)
                if #match.evalmode.content>0 then
                    pushToken {
                        kind = "BEGIN_LINE_EXPRESSION",
                        content = ""
                    }
                end

                if match.endline and #match.endline.content>0 then
                    pushToken {
                        kind = "ENDLINE",
                        content = "",
                        indent = match.endline.indent
                    }
                end
            end,
            ASSIGNMENT = function(match)

                local variable = match.variable and match.variable.content

                -- If not variable, use variableExpression field
                if variable then
                    plume.checkVariableName(match.variable.source, variable)
                else
                    local t = {}
                    for _, token in ipairs(match.variableExpression) do
                        table.insert(t, token.content)
                    end
                    variable = table.concat(t, "", 2, #t-1)
                end

                local index
                if match.index then
                    index = {}
                    for _, token in ipairs(match.index) do
                        table.insert(index, token.content)
                    end
                    index = table.concat(index, "", 2, #index-1) -- remove brackets
                end

                local tokenInfos = {
                    kind    = "ASSIGNMENT",
                    content = variable,
                    index   = index,
                    eval    = #match.evalmode.content>0
                }
                if match.compound_operator.kind ~= "EMPTY" then
                    tokenInfos.compound_operator = match.compound_operator.content
                end

                pushToken (tokenInfos)

                if #match.endline.content>0 then
                    pushToken {
                        kind = "ENDLINE",
                        content = "",
                        indent = match.endline.indent
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
                local line = {}
                for _, token in ipairs(match.line) do
                    table.insert(line, token.content)
                end

                pushToken {
                    kind = "RETURN",
                    content = ""
                }

                pushToken {
                    kind = "LUA_EXPRESSION",
                    content = table.concat(line):gsub('^%s*', ''):gsub('%s*$', '')
                }
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
                local index = {}

                if match.index then
                    for _, capture in ipairs(match.index) do
                        if #capture > 0 then -- bracket indexing
                            local code = {}
                            for _, subCapture in ipairs(capture) do
                                table.insert(code, subCapture.content)
                            end
                            table.insert(index, {
                                kind="INDEX_ACCESS",
                                content=table.concat(code, "", 2, #code-1) -- removing brackets
                            })
                        else -- field indexing
                            local name = capture.content:sub(2, -1) -- removing leading dot
                            plume.checkVariableName(capture.source, name)
                            table.insert(index, {
                                kind="FIELD_ACCESS",
                                content=name
                            })
                        end
                    end
                end

                pushToken {
                    kind    = "VARIABLE",
                    content = match.variable.content,
                    index   = index
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
                local spaces = {}

                for k, v in ipairs(match.spaces) do
                    table.insert(spaces, v.content)
                end
                
                pushToken {
                    kind    = "RPAR",
                    content = ")" .. table.concat(spaces)
                }
            end,
            LPAR = function(match)
                pushToken {
                    kind    = "LPAR",
                    content = "("
                }
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
                checkCommandsRules(nil, true)
                pushText(tokens[pos].content)
                pos = pos + 1
            end

        end

        popText()

        return result
    end
end
