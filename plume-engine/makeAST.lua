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

        --- Captures macro arguments until MACRO_ARG_END token
        local function captureMacroArgs()
            pushContext(nil, "MACRO_ARG_TABLE", currentIndent+1)
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

            -- Macro call initiation
            elseif contains("MACRO_CALL_BEGIN", token.kind) then
                insideMacroCall = insideMacroCall + 1
                setReturnType(token, "TEXT")
                
                pushContext  (token, "MACRO_CALL", currentIndent+1, token.content)
                setReturnType(token, "TEXT")
                
                pushContext  (token, "MACRO_CALL_INLINE_PARAMETERS", currentIndent+1)
                setReturnType(token, "TABLE")
                
                pushContext  (token, "LIST_ITEM", currentIndent+1)

            -- Right parenthesis handling
            elseif contains("RPAR", token.kind) then
                if insideMacroCall > 0 then
                    closeMacroInlineParameters()

                    -- Detect extended parameters (multi-line)
                    if tokens[pos+1] and tokens[pos+1].kind == "ENDLINE" then
                        pushContext(token, "MACRO_CALL_EXTENDED_PARAMETERS", currentIndent+1)
                    else
                        popContext(-1, 1)
                    end
                else
                    pushChild(token, "TEXT", ")")
                end

            -- Parameter list comma handling
            elseif contains("COMMA", token.kind) then
                if insideMacroCall > 0 then
                    popContext(-1, 1)  -- Close current list item
                    pushContext(token, "LIST_ITEM", currentIndent+1)  -- New parameter
                else
                    pushChild(token, "TEXT", ",")
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
                closeMacroInlineParameters()
                currentIndent = token.indent or currentIndent
                popContext(currentIndent)  -- Close completed contexts

            -- Control flow constructs
            elseif contains("FOR IF ELSEIF ELSE WHILE", token.kind) then
                pushContext(token, token.kind, currentIndent+1, token.content)

            -- Return statement handling
            elseif contains("RETURN", token.kind) then
                setReturnType(token, "VALUE", context)
                pushContext(token, token.kind, currentIndent+1, token.content)

            -- Macro definitions
            elseif contains("MACRO LOCAL_MACRO", token.kind) then
                pushContext(token, token.kind, currentIndent+1, token.content)
                captureMacroArgs()
                pushContext(token, "MACRO_BODY", currentIndent+1)

            -- Inline macros (value-producing)
            elseif contains("INLINE_MACRO", token.kind) then
                setReturnType(token, "VALUE")
                pushContext(token, token.kind, currentIndent+1, token.content)
                captureMacroArgs()
                setReturnType(token, "VALUE")
                pushContext(token, "MACRO_BODY", currentIndent+1)
                
            else
                error("Not Implemented Yet: " .. token.kind)
            end
        end

        -- Finalize root node
        popContext(-1)
        return context[1]
    end
end
