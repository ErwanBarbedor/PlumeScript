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

    ---@brief Main parser function that constructs an Abstract Syntax Tree from a token stream
    ---@param tokens table Array of lexical tokens to be processed
    ---@return table Root node of the constructed AST
    plume.makeAST = function(tokens)
        local context         = {} -- Node hierarchy stack (path from root to current node)
        local pos             = 0  -- Current position in token stream
        local currentIndent   = 0  -- Track indentation for block scoping (Python-like)
        local parenthesisDeep = 0 -- Track nested macro call depth

        --- Propagates return type constraints through parent scopes
        --- Enforces type consistency in code generation paths
        ---@param token table Trigger token for error reporting
        ---@param kind string Expected return type ('TEXT' or 'TABLE' or 'VALUE')
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

        --- Check if context could be popped by endline
        ---@param context table
        local function checkPoppedContext (context)
            if contains("MACRO_ARG_TABLE", context.kind) then
                plume.unclosedContextError(context.sourceToken.source, context.kind)
            end
        end

        --- Pops contexts when exiting scopes based on indentation
        ---@param indent integer Current indentation level after ENDLINE
        ---@param limit integer|nil Maximum contexts to pop (optional)
        ---@param endline bool It is endline context pop?
        local function popContext(indent, limit, endline)
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

                    -- Somme context must be closed before endline
                    if endline then
                        checkPoppedContext(lastContext)
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

        --- Validates macro argument syntax
        ---@brief Checks if macro arguments follow correct naming conventions
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
                    plume.unexpectedTokenError(token.sourceToken.source, "parameter name", content)
                else
                    if not over and (#arg.children > 1 and arg.kind == "LIST_ITEM") then
                        over = arg.children[2].content
                    end

                    if #over > 0 then
                        plume.unexpectedTokenError(token.sourceToken.source, "a comma", over)
                    end
                end
            end
        end

        --- Checks if current context is inside a specific node type
        ---@param kind string Node type to look for
        ---@return boolean True if inside the specified node type
        local function isInside(kind)
            for i=#context, 1, -1 do
                if context[i].kind == kind then
                    return true
                end
            end
            return false
        end

        --- Finalizes a macro argument and determines if it's a named parameter
        ---@brief Converts list items to hash items when they use key:value syntax
        local function popMacroArgument()
            local antecurrent = context[#context-1]
            local current     = context[#context]

            -- todo :
            -- if not contains("LIST_ITEM", current.kind) then
                -- error...

            -- Remove empty parameter, if first
            if #current.children == 0 and #antecurrent.children == 0 then
                table.remove(context)
                return
            elseif #current.children > 0 then
                local text = current.children[1].content

                if text then
                    -- Detect key:value pattern for named parameters
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

        -- Put rest of the line a new context
        local function captureLineExpression(token)
            pushContext(nil, "LUA_EXPRESSION", currentIndent)
            setReturnType(token, "TEXT")
            local content = {}
            while tokens[pos+1] and tokens[pos+1].kind ~= "ENDLINE" do
                table.insert(content, tokens[pos+1].content)
                pos = pos + 1
            end
            context[#context].content = table.concat(content)
            popContext(-1, 1)
        end

        --- Creates a new macro argument context
        local function pushMacroArgument()
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
                pushContext(token, token.kind, currentIndent+1, token.content)
                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1)

                pushMacroArgument()

            -- Inline macros definitions
            elseif contains("INLINE_MACRO_DEFINITION", token.kind) then
                setReturnType(token, "VALUE")
                pushContext(token, token.kind, currentIndent+1, token.content)
                setReturnType(token, "VALUE")

                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument()

            -- Macro call initiation
            elseif contains("MACRO_CALL_BEGIN", token.kind) then
                setReturnType(token, "TEXT")
                
                pushContext(token, "MACRO_CALL", currentIndent+1, token.content)
                setReturnType(token, "TEXT")
                
                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument()
                
            -- Left parenthesis handling
            elseif contains("LPAR", token.kind) then
                parenthesisDeep = parenthesisDeep+1
                pushChild(token, "TEXT", "(")

            -- Right parenthesis handling
            elseif contains("RPAR", token.kind) then
                if parenthesisDeep > 0 then
                    parenthesisDeep = parenthesisDeep - 1
                    pushChild(token, "TEXT", ")")
                elseif isInside("MACRO_DEFINITION") or isInside("INLINE_MACRO_DEFINITION") then
                    popMacroArgument()
                    checkMacroArgument()
                    popContext(-1, 1) -- pop MACRO_ARG_TABLE
                    pushContext(token, "MACRO_BODY", currentIndent+1)

                elseif isInside("MACRO_CALL") then
                    popMacroArgument()
                    popContext(-1, 1) -- pop MACRO_ARG_TABLE
                    -- Detect extended parameters (multi-line)
                    if tokens[pos+1] and tokens[pos+1].kind == "ENDLINE" then
                        pushContext(token, "MACRO_EXTENDED_ARG_TABLE", currentIndent+1)
                    else
                        popContext(-1, 1)
                    end
                else
                    pushChild(token, "TEXT", ")")
                end

            -- Parameter list comma handling
            elseif contains("COMMA", token.kind) then
                if isInside("MACRO_ARG_TABLE") then
                    popMacroArgument()
                    pushMacroArgument()
                else
                    pushChild(token, "TEXT", token.content)
                end

            -- Variable assignment constructs
            elseif token.kind == "ASSIGNMENT" then
                pushContext(token, "ASSIGNMENT", currentIndent+1, token.content)

            elseif token.kind == "LOCAL_ASSIGNMENT" then
                pushContext(token, "LOCAL_ASSIGNMENT", currentIndent+1, token.content)
            
            -- Rest of the line is an expressoin
            elseif token.kind == "BEGIN_LINE_EXPRESSION" then
                captureLineExpression(token)

            -- List and hash structures
            elseif token.kind == "LIST_ITEM" then
                setReturnType(token, "TABLE")
                pushContext(token, "LIST_ITEM", currentIndent+1)

            elseif token.kind == "HASH_ITEM" then
                setReturnType(token, "TABLE")
                pushContext(token, "HASH_ITEM", currentIndent+1, token.content)
            
            -- Line ending processing
            elseif token.kind == "ENDLINE" then
                parenthesisDeep = 0
                currentIndent = token.indent or currentIndent
                popContext(currentIndent, nil, true)  -- Close completed contexts

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

        -- Finalize root node
        popContext(-1, nil, true)

        return context[1]
    end
end