--[[
Plume🪶 0.26
Copyright (C) 2024-2025 Erwan Barbedor

Check https://github.com/ErwanBarbedor/Plume
for documentation, tutorials, or to report issues.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
]]

local plume = {}

plume._VERSION = "Plume🪶 0.26"

-- Load core components using dependency injection pattern
require "plume-engine/utils"         (plume)
require "plume-engine/patterns"      (plume)
require "plume-engine/tokenizer"     (plume)
require "plume-engine/parser/parser" (plume)
require "plume-engine/makeAST"       (plume)
require "plume-engine/plume"         (plume)
require "plume-engine/luaTranspiler" (plume)
require "plume-engine/error"         (plume)
require "plume-engine/luaBuilder"    (plume)
require "plume-engine/plumeDebug"    (plume)

--- Transpiles Plume code to Lua code.
---@param text string The Plume code to transpile.
---@param filename string filename for error reporting.
---@return string, table The transpiled Lua code and the source map.
function plume.transpile(text, filename)
    local sucess, tokens, ast, code, map
    -- Lexical Analysis
    -- plume.tokenize should never raise an exception
    sucess, tokens = pcall(plume.tokenize, text, filename)
    if not sucess then
        error("Unexpected error during tokenization:\n" .. tokens)
    end

    -- Syntax Analysis
    tokens = plume.parse (tokens)

    -- Abstract Syntax Tree Construction
    ast = plume.makeAST(tokens)

    -- Code Generation and Source Map Creation
    -- (plume.transpileToLua should never raise an exception
    sucess, code, map = pcall(plume.transpileToLua, ast)
    if not sucess then
        error("Unexpected error during transpilation:\n" .. code)
    end

    return code, map, filename
end

--- Executes the given Lua code in a sandboxed environment.
---@param code string The Lua code to execute.
---@param env table environnement to use
---@param filename string
---@return any The result of the Lua code execution.
function plume.execute(code, env, filename)
    -- Compilation and Execution in a Sandboxed Environment
    local compiledFunction, errorMessage
    -- Lua 5.1 compatible compilation using load and a custom environment
    if setfenv then
        compiledFunction, errorMessage = loadstring(code, filename)
        if compiledFunction then
            setfenv(compiledFunction, env)
        end
    -- Lua 5.2+ compatible compilation using loadstring and setfenv
    else  
        compiledFunction, errorMessage = load(code, filename, nil, env)
    end

    -- Error Handling during Compilation
    if not compiledFunction then
        -- Catch error and try to find the plume line
        -- corresponding to the lua line of the error
        error(plume.convertLuaError(nil, nil, errorMessage, env.plume.package.map[filename], true, true), 0) 
    end

    -- Execution and Error Handling
    local success, result = xpcall(compiledFunction, function (err) return plume.errorHandler (err, env, false) end)
    if success then
        return result
    else
        error(result, 0)
    end
end

--- Runs Plume code by transpiling and executing it.
---@param text string The Plume code to run.
---@param filename string Optional filename for error reporting.
---@param env table Optional environnement to use
---@return any The result of the Plume code execution.
function plume.run(text, filename, env)
    local env = env or plume.initRuntime()

    if not filename then
        env.plume.package.anonymous = env.plume.package.anonymous + 1
        filename = "@<string_" .. env.plume.package.anonymous .. ">"
    end

    local code, map, filename = plume.transpile(text, filename)
    env.plume.package.map[filename] = map
    return plume.execute(code, env, filename)
end

return plume