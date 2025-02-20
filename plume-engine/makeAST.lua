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

-- AST Construction Module
-- Parses tokens into an abstract syntax tree (AST) structure

return function (plume)
    local contains = plume.utils.containsWord

    

    -- Main parser function
    plume.makeAST = function(tokens)
        local context = {}     
        local pos = 0                           -- Position in the tokens list
        local currentIndent = 0                 -- Track indentation
        local insideMacroCall = 0                

        --- Propagates return type through parent contexts
        ---@param token table Used to throw error
        ---@param kind string Type to set ('TEXT' or 'TABLE')
        ---@param context table Current context stack
        local function setReturnType(token, kind, context)
            for i=#context, 1, -1 do
                if context[i].returnType ~= "NIL" and context[i].returnType ~= kind then
                    plume.mixedBlockError (token.source, context[i].returnType, kind)
                end

                context[i].returnType = kind
                if not contains("FOR IF ELSE ELSEIF WHILE", context[i].kind) then
                    break
                end
            end
        end

        --- Creates a terminal node without children
        ---@param kind string Leaf type identifier
        ---@param value any Contained value
        ---@return table New leaf structure
        local function pushChild (sourceToken, kind, content)
            local current = context[#context]
            local last    = current.children[#current.children]

            if kind == "TEXT" and last and last.kind == "TEXT" then
                last.content = last.content .. content
            else
                table.insert(context[#context].children, {
                    kind  = kind,
                    content = content
                })
            end
        end

        --- Creates a new AST node with children container
        ---@param kind string Node type identifier
        ---@param integer indent Nesting level for block structure
        ---@param info any Additional node-specific data
        ---@return table New node structure
        local function pushContext(sourceToken, kind, indent, content)
            table.insert(context, {
                kind        = kind,
                returnType  = "NIL",     -- Default return type for code generation
                indent      = indent,    -- Indentation level for scope management
                children    = {},
                content     = content,    -- Node metadata (e.g., variable names, list contents),
                sourceToken = sourceToken
            })
        end

        --- Closes completed contexts based on indentation level
        ---@param context table Current context stack
        ---@param integer indent Current indentation level
        ---@param integer limit maximum number of scope to pop
        local function popContext(indent, limit)
            -- Close over-indented contexts when returning to outer scope
            for i=#context, 1, -1 do
                if context[i].indent > indent then
                    local lastContext = context[i]
                    local parentContext = context[i-1]
                    local lastChildren = parentContext.children[#parentContext.children]

                    if contains("ELSE ELSEIF", lastContext.kind) then
                        if lastChildren and contains("IF ELSEIF", lastChildren.kind) then
                            lastChildren.noend = true
                        else
                            error(lastContext.kind .. " must follow a if or and elseif")
                        end
                    end

                    -- Move node to parent's children when leaving its scope
                    table.insert(parentContext.children, lastContext)
                    table.remove(context)
                else
                    break
                end
                if limit then
                    limit = limit - 1
                    if limit == 0 then
                        break
                    end
                end
            end
        end

        local function captureMacroArgs ()
            pushContext (nil, "MACRO_ARG_TABLE", currentIndent+1)
            while pos < #tokens do
                pos = pos+1
                local token = tokens[pos]

                if token.kind == "MACRO_ARG_END" then
                    break
                else
                    pushChild(token, token.kind, token.content)
                end
            end
            popContext(-1, 1)
        end

        local function closeMacroInlineParameters()
            local antelast = context[#context-1]
            
            if antelast and antelast.kind == "MACRO_CALL_INLINE_PARAMETERS" then
                local lastArg = context[#context]

                if #lastArg.children == 0 then
                    table.remove(context) -- Empty LIST_ITEM
                else
                    popContext(-1, 1)
                end

                popContext(-1, 1) -- MACRO_CALL_INLINE_PARAMETERS
                insideMacroCall = insideMacroCall-1
            end
        end

        pushContext (nil, "BLOCK", -1) -- Root block

        while pos < #tokens do
            pos = pos +1
            local token = tokens[pos]
            local current = context[#context]-- Deepest active context

            if contains("TEXT VARIABLE LUA_EXPRESSION ", token.kind) then
                setReturnType(token, "TEXT", context)
                pushChild(token, token.kind, token.content)

            elseif contains("MACRO_CALL_BEGIN", token.kind) then
                insideMacroCall = insideMacroCall + 1
                setReturnType(token, "TEXT", context)

                pushContext (token, "MACRO_CALL", currentIndent+1, token.content)
                setReturnType(token, "TEXT", context)
                pushContext (token, "MACRO_CALL_INLINE_PARAMETERS", currentIndent+1)
                setReturnType(token, "TABLE", context)
                pushContext (token, "LIST_ITEM", currentIndent+1)

            elseif contains("RPAR", token.kind) then
                if insideMacroCall > 0 then
                    closeMacroInlineParameters()

                    if tokens[pos+1] and tokens[pos+1].kind == "ENDLINE" then
                        pushContext(token, "MACRO_CALL_EXTENDED_PARAMETERS", currentIndent+1)
                    else
                        popContext(-1, 1)
                    end
                else
                    pushChild(token, "TEXT", ")")
                end

            elseif contains("COMMA", token.kind) then
                if insideMacroCall > 0 then
                    popContext(-1, 1)
                    pushContext (token, "LIST_ITEM", currentIndent+1)
                else
                    pushChild(token, "TEXT", ",")
                end

            elseif token.kind == "ASSIGNMENT" then
                pushContext(token, "ASSIGNMENT", currentIndent+1, token.content)

            elseif token.kind == "LOCAL_ASSIGNMENT" then
                pushContext(token, "LOCAL_ASSIGNMENT", currentIndent+1, token.content)
            
            elseif token.kind == "LIST_ITEM" then
                setReturnType(token, "TABLE", context)
                pushContext (token, "LIST_ITEM", currentIndent+1)

            -- elseif token.kind == "VOID_LINE" then
            --     table.insert(context, node("VOID", currentIndent+1))

            elseif token.kind == "HASH_ITEM" then
                setReturnType(token, "TABLE", context)
                pushContext (token, "HASH_ITEM", currentIndent+1, token.content)
            
            elseif token.kind == "ENDLINE" then
                closeMacroInlineParameters()
                currentIndent = token.indent or currentIndent
                popContext(currentIndent)

            elseif contains("FOR IF ELSEIF ELSE", token.kind) then
                pushContext (token, token.kind, currentIndent+1, token.content)

            elseif contains("RETURN", token.kind) then
                setReturnType(token, "VALUE", context)
                pushContext (token, token.kind, currentIndent+1, token.content)

            elseif contains("MACRO LOCAL_MACRO", token.kind) then
                
                pushContext (token, token.kind, currentIndent+1, token.content)
                captureMacroArgs()
                pushContext (token, "MACRO_BODY", currentIndent+1)

            elseif contains("INLINE_MACRO", token.kind) then
                setReturnType(token, "VALUE", context)
                
                pushContext (token, token.kind, currentIndent+1, token.content)
                captureMacroArgs()
                setReturnType(token, "VALUE", context)

                pushContext (token, "MACRO_BODY", currentIndent+1)
                
            else
                error("NIY " .. token.kind)
            end
        end

        popContext(-1)
        return context[1]
    end
end