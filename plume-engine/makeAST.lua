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

-- This module takes a sequence of lexical tokens and transforms them into a
-- hierarchical AST structure. The AST represents the program's logical organization
-- and is used for transpilation. It handles scope, indentation, macro argument parsing,
-- and return type propagation.

return function (plume)
    local contains = plume.utils.containsWord

    --- Main parser function that constructs an Abstract Syntax Tree (AST) from a token stream.
    ---@param tokens table Array of lexical tokens to be processed.
    ---@return table Root node of the constructed AST.
    plume.makeAST = function(tokens)
        local context         = {} -- Stack of currently open AST nodes, representing the path from the root to the current parsing location.
        local pos             = 0  -- Current position in the token stream.
        local currentIndent   = 0  -- Tracks indentation level for block scoping (Python-like).
        local parenthesisDepth = 0 -- Tracks the current nesting depth of regular parentheses `(` `)` encountered within the content of a line. This helps distinguish them from parentheses used for macro argument lists.

        --- Propagates return type constraints upwards through parent scopes.
        --- Ensures that control structures (like IF, FOR) and macro definitions
        --- maintain consistent return types (e.g., a block cannot return both TEXT and VALUE).
        ---@param token table The token triggering the type setting (used for error reporting).
        ---@param kind string The expected return type ("TEXT", "TABLE", or "VALUE").
        local function setReturnType(token, kind)
            for i=#context, 1, -1 do
                -- Ensure parent control structures (and other relevant nodes)
                -- maintain consistent return types.
                if context[i].returnType ~= "NIL" and context[i].returnType ~= kind then
                    plume.mixedBlockError(token.source, context[i].returnType, kind)
                end

                context[i].returnType = kind
                -- Stop propagation at nodes that don't inherently carry or enforce a specific return type
                -- from their children in this manner (e.g., a general 'BLOCK' might contain mixed types,
                -- but an 'IF' block's overall type is determined by its branches).
                if not contains("FOR IF ELSE ELSEIF WHILE", context[i].kind) then
                    break
                end
            end
        end

        --- Creates a terminal node (leaf) in the AST and adds it to the current context's children.
        ---@param sourceToken table|nil The original token from which this node is derived (for source mapping and error reporting).
        ---@param kind string The type identifier for the new node (e.g., "TEXT", "VARIABLE").
        ---@param content any The payload of the node (e.g., text content, variable name).
        local function pushChild(sourceToken, kind, content)
            local current = context[#context]
            local last = current.children[#current.children]

            -- Merge adjacent text nodes to reduce AST size and simplify processing later.
            if kind == "TEXT" and last and last.kind == "TEXT" then
                last.content = last.content .. content
            else
                table.insert(current.children, {
                    kind        = kind,
                    content     = content,
                    sourceToken = sourceToken  -- Track origin for debugging and error reporting.
                })
            end
        end

        --- Creates a new non-terminal (parent) node and pushes it onto the context stack,
        --- making it the current active context for subsequent nodes.
        ---@param sourceToken table|nil The original token that initiates this context (e.g., "MACRO_DEFINITION" token).
        ---@param kind string The type identifier for the new context node (e.g., "BLOCK", "MACRO_CALL").
        ---@param indent integer The indentation level associated with this context, used for scope management.
        ---@param content any Optional context-specific metadata (e.g., macro name for "MACRO_CALL").
        local function pushContext(sourceToken, kind, indent, content)
            table.insert(context, {
                kind        = kind,
                returnType  = "NIL",       -- Default return type; determined during type propagation by setReturnType.
                indent      = indent,      -- Controls scoping behavior in popContext.
                children    = {},          -- Child nodes of this context.
                content     = content,     -- Type-specific data (e.g., macro name, condition for IF).
                sourceToken = sourceToken  -- For error reporting and debugging.
            })
        end

        --- Performs validation checks on a context node right before it is popped from the stack,
        --- specifically when popped due to an ENDLINE.
        --- This is used to catch errors like unclosed macro argument tables.
        ---@param poppedNode table The context node being popped and checked.
        local function checkPoppedContext (poppedNode)
            -- Certain contexts, like MACRO_ARG_TABLE, must be properly closed by specific tokens (e.g., RPAR)
            -- before an ENDLINE is encountered.
            if contains("MACRO_ARG_TABLE", poppedNode.kind) then
                plume.unclosedContextError(poppedNode.sourceToken.source, poppedNode.kind)
            end
        end

        --- Pops contexts from the stack when exiting scopes, typically based on changes in indentation level.
        --- It also handles structural rules, like chaining IF/ELSEIF statements or disallowing code after RETURN.
        ---@param indent integer The current indentation level. Contexts with a greater indent will be popped.
        ---@param limit integer|nil Optional. The maximum number of contexts to pop.
        ---@param endline boolean True if this pop operation is triggered by an "ENDLINE" token.
        local function popContext(indent, limit, endlinePop)
            -- Close over-indented contexts when returning to an outer scope (lesser indentation).
            for i=#context, 1, -1 do
                if context[i].indent <= indent then
                    break  -- Stop at the first context that is not over-indented.
                else
                    local lastContext = context[i]
                    local parentContext = context[i-1] -- Assuming there's always a parent (root is -1 indent).

                    -- Validate and adjust control flow structures.
                    if contains("ELSE ELSEIF", lastContext.kind) then
                        local lastPeer = parentContext.children[#parentContext.children]
                        if lastPeer and contains("IF ELSEIF", lastPeer.kind) then
                            -- Mark the preceding IF/ELSEIF to indicate it's part of a chain
                            -- and might not need its own 'end' keyword during transpilation.
                            lastPeer.noend = true
                        else
                            -- This is a language rule: ELSE/ELSEIF must follow IF/ELSEIF.
                            error(lastContext.kind .. " must follow an if or elseif statement.")
                        end
                    -- Force list and hash items to have a type if none was explicitly propagated.
                    -- Defaulting to TEXT is a safe assumption for items whose content type isn't otherwise determined.
                    elseif contains("LIST_ITEM HASH_ITEM", lastContext.kind) and lastContext.returnType == "NIL" then
                         lastContext.returnType = "TEXT"
                    end

                    -- Some contexts require special validation when popped at an endline.
                    if endlinePop then
                        checkPoppedContext(lastContext)
                    end

                    -- A "RETURN" statement must be the final conceptual statement in its immediate block.
                    -- This check ensures no subsequent nodes are added to the parent after a RETURN.
                    local prevChildInParent = parentContext.children[#parentContext.children]
                    if prevChildInParent and prevChildInParent.kind == "RETURN" then
                       -- Error if the context being popped (lastContext) has children,
                       -- implying something came after the RETURN within the same logical scope defined by RETURN.
                       if #lastContext.children > 0 then
                           plume.followedReturnError(lastContext.children[1].sourceToken.source)
                       end
                    end

                    -- Move the fully processed (closed) context to its parent's children list.
                    table.insert(parentContext.children, lastContext)
                    table.remove(context) -- Pop from the active context stack.
                end

                -- Apply pop limit if specified (e.g., pop only 1 context).
                if limit then
                    limit = limit - 1
                    if limit == 0 then break end
                end
            end
        end

        --- Validates the syntax of arguments within the current "MACRO_ARG_TABLE" context.
        --- Checks for correct parameter naming, vararg (`*`) placement, and disallows unexpected tokens within argument definitions.
        local function checkMacroArgument ()
            local current = context[#context] -- Should be MACRO_ARG_TABLE node.

            for i, arg in ipairs(current.children) do
                local token = arg.children[1] -- The first child usually holds the parameter name or value.
                local content

                if not token then
                    -- This can happen if a comma is followed by a parenthesis, e.g., `macro(arg1,)`
                    plume.unexpectedTokenError(current.sourceToken.source, "parameter name after \",\"", ")")
                end

                -- Each 'arg' is expected to be a LIST_ITEM or HASH_ITEM representing a parameter.
                if arg.kind == "LIST_ITEM" then
                    content = token.content
                elseif arg.kind == "HASH_ITEM" then
                    content = arg.content -- For HASH_ITEM, the key is stored in arg.content itself.
                end

                -- Regex to extract the parameter name and check for stray characters around it.
                local inner, name, over = content:match('^(%S-)%s*([a-zA-Z_][a-zA-Z0-9_]*)%s*(%S*)$')

                if token.kind == "VARARG" and i < #current.children then
                    -- Vararg must be the last parameter in a macro definition.
                    plume.unexpectedVarargError(token.sourceToken.source, "vararg must be in last position.")
                end

                if not name then
                    plume.unexpectedTokenError(token.sourceToken.source, "parameter name", content)
                else
                    plume.checkParameterName(token.sourceToken.source, name) -- External validation for name format.
                    -- If 'over' is empty, but there are more children in a LIST_ITEM,
                    -- it means there was content after the name that wasn't captured by the regex,
                    -- potentially due to spacing issues not handled by %S.
                    if not over and (#arg.children > 1 and arg.kind == "LIST_ITEM") then
                        over = arg.children[2].content
                    end

                    if #over > 0 then
                        plume.unexpectedTokenError(token.sourceToken.source, "a comma or closing parenthesis", over)
                    end
                    if #inner > 0 then
                        plume.unexpectedTokenError(token.sourceToken.source, "parameter name", inner)
                    end
                end
            end
        end

        --- Checks if the current parsing context is nested within a context of a specific kind.
        ---@param kind string The node type (kind) to search for in the context stack.
        ---@param deep integer|nil Optional. The maximum depth to search upwards from the current context. Defaults to searching the entire stack.
        ---@return boolean True if a context of the specified kind is found within the search depth, false otherwise.
        local function isInside(kind, deep)
            for i=#context, #context - (deep or #context)+1, -1 do
                if context[i].kind == kind then
                    return true
                end
            end
            return false
        end

        --- Finalizes the current macro argument being parsed.
        --- It converts list items ("LIST_ITEM") to hash items ("HASH_ITEM") if they use `key:value` syntax.
        --- Also handles empty arguments and pops the argument context ("LIST_ITEM" or "HASH_ITEM") itself.
        local function popMacroArgument()
            local antecurrent = context[#context-1] -- The MACRO_ARG_TABLE node.
            local currentArgContext = context[#context] -- The LIST_ITEM/HASH_ITEM node for the current argument.

            -- Check if current context is actually an argument item.
            -- This check is a bit redundant if called correctly, but acts as a safeguard.
            if not currentArgContext.kind == "LIST_ITEM" and not currentArgContext.kind == "HASH_ITEM" then
                error("[Internal unexpected error]: Attempting to pop a non-argument context as a macro argument.")
            end

            -- Remove empty parameter if it's allowed (e.g., after an expand '*' or if it's the first one)
            if #currentArgContext.children == 0 and (#antecurrent.children == 0 or currentArgContext.canBeEmpty) then
                table.remove(context) -- Pop the empty LIST_ITEM.
                return
            elseif #currentArgContext.children > 0 then
                local firstChildOfArg = currentArgContext.children[1]
                local textContent = firstChildOfArg and firstChildOfArg.content -- Ensure firstChildOfArg exists

                -- Attempt to parse key:value from TEXT nodes
                if textContent and firstChildOfArg.kind == "TEXT" then
                    -- Detect `key:value` pattern for named parameters. Example: `name: "John"`
                    -- `key` must be a valid identifier. `lft1` captures leading whitespace. `lft2` captures `:` and following whitespace.
                    local lft1, key, lft2 = textContent:match('(%s*)([a-zA-Z_][a-zA-Z_0-9]*)(%s*:%s*)')

                    if key then
                        -- Convert LIST_ITEM to HASH_ITEM for named parameters.
                        currentArgContext.kind = "HASH_ITEM"
                        currentArgContext.content = key -- Store the key in the HASH_ITEM's content.
                        -- Remove the `key:` part from the first child's content.
                        currentArgContext.children[1].content = textContent:gsub(lft1 .. key .. lft2, "", 1)
                        if #currentArgContext.children[1].content == 0
                           and #currentArgContext.children > 1 then
                            table.remove(currentArgContext.children, 1) -- Remove child if it becomes empty.
                        end
                    end
                end
            end

            popContext(-1, 1, false) -- Pop the current argument context (LIST_ITEM/HASH_ITEM).
        end

        --- Captures the remainder of the current line as a single "LUA_EXPRESSION" node.
        ---@param token table The token that triggered this capture (e.g., "BEGIN_LINE_EXPRESSION"), used for source mapping.
        local function captureLineExpression(token)
            pushContext(nil, "LUA_EXPRESSION", currentIndent)
            -- Line expressions are expected to produce text or a value that can be cast to text.
            setReturnType(token, "TEXT")
            local content = {}
            while tokens[pos+1] and tokens[pos+1].kind ~= "ENDLINE" do
                table.insert(content, tokens[pos+1].content)
                pos = pos + 1
            end
            context[#context].content = table.concat(content)
            popContext(-1, 1, false) -- Pop LUA_EXPRESSION context.
        end

        --- Pushes a new "LIST_ITEM" context onto the stack to represent a macro argument.
        --- This serves as a temporary container; it might be converted to "HASH_ITEM" by `popMacroArgument`.
        ---@param canBeEmpty boolean|nil If true, this argument is allowed to be empty (e.g., after an expand `*`).
        local function pushMacroArgument(canBeEmpty)
            pushContext(nil, "LIST_ITEM", currentIndent) -- Default to LIST_ITEM.
            context[#context].canBeEmpty = canBeEmpty
        end

        -- Initialize with a root "BLOCK" node. All top-level elements will be children of this node.
        pushContext(nil, "BLOCK", -1) -- -1 indent ensures it's never popped by indentation rules.

        -- Begin token processing loop.
        while pos < #tokens do
            pos = pos + 1
            local token = tokens[pos]
            local current = context[#context] -- The current active AST node/context.

            -- Handle content nodes (TEXT, VARIABLE, LUA_EXPRESSION).
            if contains("TEXT VARIABLE LUA_EXPRESSION", token.kind) then
                setReturnType(token, "TEXT", context) -- These tokens produce text content.
                pushChild(token, token.kind, token.content)

            elseif contains("MACRO_DEFINITION", token.kind) then
                -- A macro definition itself doesn't have a "return type" in the same way a call does;
                -- its body will determine what it yields when called.
                pushContext(token, token.kind, currentIndent+1, token.content) -- `content` has macro name.
                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1) -- Context for parameter list.
                pushMacroArgument() -- Start context for the first (or AWAITED) parameter.

            -- Inline macros are defined to produce a single value.
            elseif contains("INLINE_MACRO_DEFINITION", token.kind) then
                -- First, set the expected return type for the parent context that will contain this inline macro.
                setReturnType(token, "VALUE")
                pushContext(token, token.kind, currentIndent+1, token.content)
                -- Then, set the return type for the INLINE_MACRO_DEFINITION node itself.
                setReturnType(token, "VALUE")

                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument()

            -- Macro call initiation.
            elseif contains("MACRO_CALL_BEGIN", token.kind) then
                -- Default return type for a block macro call is TEXT.
                -- This can be overridden if the macro is known (e.g., via a manifest) to return a VALUE.
                setReturnType(token, "TEXT") -- Expected type propagation to parent.
                pushContext(token, "MACRO_CALL", currentIndent+1, token.content) -- `content` has macro name.
                setReturnType(token, "TEXT") -- Set type for the MACRO_CALL node itself.

                pushContext(token, "MACRO_ARG_TABLE", currentIndent+1)
                pushMacroArgument()

            -- Left parenthesis handling.
            elseif contains("LPAR", token.kind) then
                parenthesisDepth = parenthesisDepth + 1
                pushChild(token, "TEXT", "(") -- Default: treat as literal text.

            -- Right parenthesis handling.
            elseif contains("RPAR", token.kind) then
                if parenthesisDepth > 0 then
                    -- This RPAR closes a regular parenthesis pair within text or an expression.
                    parenthesisDepth = parenthesisDepth - 1
                    pushChild(token, "TEXT", ")")
                elseif isInside("MACRO_DEFINITION", 3) or isInside("INLINE_MACRO_DEFINITION", 3) then
                    -- This RPAR closes the argument list of a macro definition.
                    -- Depth check: current (LIST_ITEM) -> MACRO_ARG_TABLE -> MACRO_DEFINITION
                    popMacroArgument()   -- Finalize the last argument.
                    checkMacroArgument() -- Validate all arguments in the MACRO_ARG_TABLE.
                    popContext(-1, 1, false) -- Pop MACRO_ARG_TABLE.
                    pushContext(token, "MACRO_BODY", currentIndent+1) -- Open context for the macro's body.

                elseif isInside("MACRO_CALL") then
                    -- This RPAR closes the argument list of a macro call.
                    popMacroArgument()   -- Finalize the last argument.
                    popContext(-1, 1, false) -- Pop MACRO_ARG_TABLE.
                    -- Check for Plume's extended argument syntax:
                    -- If RPAR is a_immediately_ followed by ENDLINE, it might be the start of an extended block.
                    if tokens[pos+1] and tokens[pos+1].kind == "ENDLINE" then
                        pushContext(token, "MACRO_EXTENDED_ARG_TABLE", currentIndent+1)
                    else
                        popContext(-1, 1, false) -- Pop MACRO_CALL context itself.
                    end
                else
                    -- RPAR not part of a recognized syntactic structure, treat as literal text.
                    pushChild(token, "TEXT", ")")
                end

            -- Parameter list comma handling.
            elseif contains("COMMA", token.kind) then
                if isInside("MACRO_ARG_TABLE") then
                    -- Comma separates arguments in a macro definition or call.
                    popMacroArgument()  -- Finalize the preceding argument.
                    pushMacroArgument() -- Start a new argument.
                else
                    -- Comma outside an argument list, treat as literal text.
                    pushChild(token, "TEXT", token.content)
                end

            -- Expand operator
            elseif contains("EXPAND", token.kind) then
                if isInside("MACRO_ARG_TABLE") then
                    if isInside("MACRO_DEFINITION") or isInside("INLINE_MACRO_DEFINITION") then
                        -- This is a vararg parameter in a macro definition (e.g., `def macro(param1, *arg)`).
                        pushChild(token, "VARARG", token.content) -- content is the vargard name
                    else -- Inside a macro call
                        -- This is expanding a variable into arguments
                        popMacroArgument() -- Finalize potentially empty argument before expand.
                        pushChild(token, "COMMAND_EXPAND", token.content) -- The actual var to expand.
                        pushMacroArgument(true) -- Next argument (if any) can be empty.
                    end
                else
                    -- Expand operator outside an argument list, treat as literal text
                    pushChild(token, "TEXT", "*"..(token.content or "")) -- token.content might be name after *
                end

            elseif contains("COMMAND_EXPAND", token.kind) then
                 -- An explicit command/variable to expand used in table.
                setReturnType(token, "TABLE")
                pushChild(token, "COMMAND_EXPAND", token.content)

            -- Variable assignment constructs.
            elseif token.kind == "ASSIGNMENT" then
                pushContext(token, "ASSIGNMENT", currentIndent+1, token.content) -- `content` has var name.

            elseif token.kind == "LOCAL_ASSIGNMENT" then
                pushContext(token, "LOCAL_ASSIGNMENT", currentIndent+1, token.content) -- `content` has var name.

            -- Rest of the line is an expression
            elseif token.kind == "BEGIN_LINE_EXPRESSION" then
                captureLineExpression(token)

            -- Explicit list item (e.g. `- item` in table constructor).
            elseif token.kind == "LIST_ITEM" then
                setReturnType(token, "TABLE") -- Parent context is expected to be a table.
                pushContext(token, "LIST_ITEM", currentIndent+1)

            -- Explicit hash/map item (e.g. `key: value`in table constructor).
            elseif token.kind == "HASH_ITEM" then
                setReturnType(token, "TABLE") -- Parent context is expected to be a table.
                pushContext(token, "HASH_ITEM", currentIndent+1, token.content) -- `content` has the key.

            -- Line ending processing.
            elseif token.kind == "ENDLINE" then
                parenthesisDepth = 0 -- Reset parenthesis counter for the new line.
                currentIndent = token.indent or currentIndent -- Update current indentation level.
                popContext(currentIndent, nil, true)  -- Close completed contexts based on new indent.

            -- Control flow constructs.
            elseif contains("FOR IF ELSEIF ELSE WHILE", token.kind) then
                -- `token.content` usually holds the condition or iteration variables.
                pushContext(token, token.kind, currentIndent+1, token.content)

            elseif contains("RETURN", token.kind) then
                setReturnType(token, "VALUE", context) -- RETURN implies the block yields a value.
                pushContext(token, token.kind, currentIndent+1, token.content)

            elseif contains("BREAK", token.kind) then
                if not (isInside("FOR") or isInside("WHILE")) then
                    plume.breakOutsideLoopError(token.source)
                end

                pushChild(token, "BREAK", "")

            else
                -- This indicates a token type that the parser doesn't know how to handle.
                -- It could be a new feature or a bug in the lexer.
                error("Not Implemented Yet: Parser does not handle token kind '" .. token.kind .. "'")
            end
        end

        -- Finalize by popping any remaining contexts, typically up to the root "BLOCK".
        popContext(-1, nil, true) -- -1 indent ensures all user-level contexts are popped.

        return context[1] -- Return the root AST node.
    end
end