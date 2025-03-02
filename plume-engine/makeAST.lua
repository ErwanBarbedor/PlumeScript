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

-- AST construction module
-- Transforms token stream into nested hierarchical structure representing program logic
return function (plume)
    local contains = plume.utils.containsWord

    -- Main parser function
    plume.makeAST = function(tokens)
        local context         = {} -- Node hierarchy stack (path from root to current node)
        local pos             = 0  -- Current position in token stream
        local currentIndent   = 0  -- Track indentation for block scoping (Python-like)
        local insideMacroCall = 0  -- Track nested macro call depth

        --- Propagates return type constraints through parent scopes
        --- Enforces type consistency in code generation paths
        ---@param token table Trigger token for error reporting
        ---@param kind string Expected return type ('TEXT' or 'TABLE')
        ---@param context table Current context stack
        local function setReturnType(token, kind)
            for i=#context, 1, -1 do
                -- Ensure parent control structures maintain consistent return types
                if context[i].returnType ~= "NIL" and context[i].returnType ~= kind then
                    plume.mixedBlockError(token.source, context[i].returnType, kind)
                end

                context[i].returnType = kind
                -- Stop propagation at non-control flow nodes
                if not contains("FOR IF ELSE ELSEIF WHILE", context[i].kind) then
                    break
                end
            end
        end

        --- Creates terminal node, merging consecutive text nodes
        ---@param sourceToken table|nil Originating token for error tracking
        ---@param kind string Node type identifier
        ---@param content string|any Node payload (text content, variable name, etc)
        local function pushChild(sourceToken, kind, content)
            local current = context[#context]
            local last = current.children[#current.children]

            -- Merge adjacent text nodes to reduce AST size
            if kind == "TEXT" and last and last.kind == "TEXT" then
                last.content = last.content .. content
            else
                table.insert(current.children, {
                    kind        = kind,
                    content     = content,
                    sourceToken = sourceToken  -- Track origin for debug purposes
                })
            end
        end

        --- Creates new parent node and pushes onto context stack
        ---@param sourceToken table|nil Originating token
        ---@param kind string Node type identifier
        ---@param indent integer Scope nesting level
        ---@param content any Context-specific metadata
        local function pushContext(sourceToken, kind, indent, content)
            table.insert(context, {
                kind        = kind,
                returnType  = "NIL",   -- Determined during type propagation
                indent      = indent,      -- Controls scoping in popContext
                children    = {},        -- Child nodes
                content     = content,    -- Type-specific data (e.g., macro name)
                sourceToken = sourceToken
            })
        end

        --- Pops contexts when exiting scopes based on indentation
        ---@param indent integer Current indentation level after ENDLINE
        ---@param limit integer|nil Maximum contexts to pop (optional)
        local function popContext(indent, limit)
            -- Close over-indented contexts when returning to outer scope
            for i=#context, 1, -1 do
                if context[i].indent > indent then
                    local lastContext = context[i]
                    local parentContext = context[i-1]
                    
                    -- Validate control flow structure
                    if contains("ELSE ELSEIF", lastContext.kind) then
                        local lastChildren = parentContext.children[#parentContext.children]
                        if lastChildren and contains("IF ELSEIF", lastChildren.kind) then
                            lastChildren.noend = true  -- Mark as chained conditional
                        else
                            error(lastContext.kind .. " must follow a if or elseif")
                        end

                    -- Force list and hash item to have a type
                    elseif contains("LIST_ITEM HASH_ITEM", lastContext.kind) and lastContext.returnType == "NIL" then
                         lastContext.returnType = "TEXT" 
                    end

                    -- Move closed context to parent's children
                    table.insert(parentContext.children, lastContext)
                    table.remove(context)
                else
                    break  -- Stop at first context with <= indent
                end
                
                -- Apply pop limit if specified
                if limit then
                    limit = limit - 1
                    if limit == 0 then break end
                end
            end
        end

        local function checkMacroArgument ()
            local current = context[#context]

            -- todo :
            -- if not contains("MACRO_ARG_TABLE", current.kind) then
                -- error...

            for _, arg in ipairs(current.children) do
                -- arg.kind is LIST_ITEM or HASH_ITEM

                local token = arg.children[1]
                local content
                if arg.kind == "LIST_ITEM" then
                    content = token.content
                elseif arg.kind == "HASH_ITEM" then
                    content = arg.content
                -- else
                    -- not supposed to happen. Raise error?
                end

                -- todo: check #arg.children == 0
                local name, over = content:match('%s*([a-zA-Z_][a-zA-Z0-9_]*)%s*(%S*)')

                if not name then
                    plume.unexpectedTokenError (token.sourceToken.source, "parameter name", content)
                else
                    if not over and (#arg.children > 1 and arg.kind == "LIST_ITEM") then
                        over = arg.children[2].content
                    end

                    if #over > 0 then
                        plume.unexpectedTokenError (token.sourceToken.source, "a comma", over)
                    end
                end
            end

        end

        --- Closes inline macro parameter contexts when encountering RPAR
        local function closeMacroInlineParameters()
            local antelast = context[#context-1]
            
            -- Handle inline parameter lists like macro(arg1, arg2)
            if antelast and antelast.kind == "MACRO_CALL_INLINE_PARAMETERS" then
                local lastArg = context[#context]

                -- Remove empty list items
                if #lastArg.children == 0 then
                    table.remove(context)
                else
                    popContext(-1, 1)
                end

                popContext(-1, 1)  -- Close MACRO_CALL_INLINE_PARAMETERS
                insideMacroCall = insideMacroCall-1
            end
        end

        local function isInside(kind)
            for i=#context, 1, -1 do
                if context[i].kind == kind then
                    return true
                end
            end
            return false
        end

        local function popMacroArgument ()
            local antecurrent = context[#context-1]
            local current     = context[#context]

            -- todo :
            -- if not contains("LIST_ITEM", current.kind) then
                -- error...

            -- Remove empty parameter, if first
            if #current.children == 0 and #antecurrent.children == 0 then
                table.remove(context)
                return
            else
                local text = current.children[1].content

                if text then
                    local lft1, key, lft2 = text:match('(%s*)([a-zA-Z_][a-zA-Z_0-9]*)(:%s*)')

                    if key then
                        current.kind = "HASH_ITEM"
                        current.content = key
                        current.children[1].content = text:gsub(lft1 .. key .. lft2, "", 1)
                    end
                end
            end

            popContext(-1, 1)
        end

        local function pushMacroArgument ()
            pushContext(nil, "LIST_ITEM", currentIndent)
        end

        -- Initialize with root block
        pushContext(nil, "BLOCK", -1)

        -- Begin token processing loop
        while pos < #tokens do
            pos = pos + 1
            local token = tokens[pos]
            local current = context[#context]

            -- Handle content nodes
            if contains("TEXT VARIABLE LUA_EXPRESSION ", token.kind) then
                setReturnType(token, "TEXT", context)
                pushChild(token, token.kind, token.content)

            -- Macro definitions
            elseif contains("MACRO_DEFINITION", token.kind) then
                pushContext (token, token.kind, currentIndent+1, token.content)
                pushContext (token, "MACRO_ARG_TABLE", currentIndent+1)

                pushMacroArgument ()

            -- Inline macros definitions
            elseif contains("INLINE_MACRO_DEFINITION", token.kind) then
                setReturnType(token, "VALUE")
                pushContext(token, token.kind, currentIndent+1, token.content)
                setReturnType(token, "VALUE")

                pushContext (token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument ()

            -- Macro call initiation
            elseif contains("MACRO_CALL_BEGIN", token.kind) then
                insideMacroCall = insideMacroCall + 1
                setReturnType(token, "TEXT")
                
                pushContext  (token, "MACRO_CALL", currentIndent+1, token.content)
                setReturnType(token, "TEXT")
                
                pushContext  (token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument ()
                

            -- Right parenthesis handling
            elseif contains("RPAR", token.kind) then
                if isInside("MACRO_DEFINITION") or isInside("INLINE_MACRO_DEFINITION") then
                    popMacroArgument ()
                    checkMacroArgument ()
                    popContext(-1, 1) -- pop MACRO_ARG_TABLE
                    pushContext (token, "MACRO_BODY", currentIndent+1)

                elseif isInside("MACRO_CALL") then
                    popMacroArgument ()
                    popContext(-1, 1) -- pop MACRO_ARG_TABLE
                    -- Detect extended parameters (multi-line)
                    if tokens[pos+1] and tokens[pos+1].kind == "ENDLINE" then
                        pushContext  (token, "MACRO_EXTENDED_ARG_TABLE", currentIndent+1)
                    else
                        popContext(-1, 1)
                    end
                else
                    pushChild(token, "TEXT", ")")
                end

            -- Parameter list comma handling
            elseif contains("COMMA", token.kind) then

                if isInside("MACRO_DEFINITION") or isInside("MACRO_CALL") or isInside("INLINE_MACRO_DEFINITION") then
                    popMacroArgument ()
                    pushMacroArgument ()
                else
                    pushChild(token, "TEXT", token.content)
                end

            -- Variable assignment constructs
            elseif token.kind == "ASSIGNMENT" then
                pushContext(token, "ASSIGNMENT", currentIndent+1, token.content)

            elseif token.kind == "LOCAL_ASSIGNMENT" then
                pushContext(token, "LOCAL_ASSIGNMENT", currentIndent+1, token.content)
            
            -- List and hash structures
            elseif token.kind == "LIST_ITEM" then
                setReturnType(token, "TABLE")

                pushContext(token, "LIST_ITEM", currentIndent+1)

            elseif token.kind == "HASH_ITEM" then
                setReturnType(token, "TABLE")

                pushContext(token, "HASH_ITEM", currentIndent+1, token.content)
            
            -- Line ending processing
            elseif token.kind == "ENDLINE" then
                -- Todo: Check if last context must
                -- be closed before endline, line macro argument list

                currentIndent = token.indent or currentIndent
                popContext(currentIndent)  -- Close completed contexts

            -- Control flow constructs
            elseif contains("FOR IF ELSEIF ELSE WHILE", token.kind) then
                pushContext(token, token.kind, currentIndent+1, token.content)

            -- Return statement handling
            elseif contains("RETURN", token.kind) then
                setReturnType(token, "VALUE", context)
                pushContext(token, token.kind, currentIndent+1, token.content)

            -- Break for loops
            elseif contains("BREAK", token.kind) then
                -- Todo : check if we are inside a loop
                pushChild(token, "BREAK", "")
                
            else
                error("Not Implemented Yet: " .. token.kind)
            end
        end

        -- Todo: error if #context != 1

        -- Finalize root node
        popContext(-1)

        return context[1]
    end
end
