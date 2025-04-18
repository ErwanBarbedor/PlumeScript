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

--- Transpile Plume code to Lua code.
-- @function plume.transpile
-- @tparam string code       The Plume source code.
-- @tparam string filename   The filename (for error reporting).
-- @treturn string transpiledCode  The resulting Lua code.
-- @treturn table map             Source map.
function plume.transpile(code, filename)
    local tokens = plume.tokenize(code, filename)
    tokens = plume.parse(tokens)
    tokens = plume.makeAST(tokens)
    local transpiledCode, map = plume.transpileToLua(tokens)
    return transpiledCode, map
end

--- Execute Plume code inside a given environment.
-- @function plume.execute
-- @tparam string code       The Plume source code.
-- @tparam string filename   The filename (for source mapping).
-- @tparam table env         The environment table to use during execution.
-- @return The result of running the code.
function plume.execute(code, filename, env)
    -- Get transpiled Lua code and source map
    local transpiledCode, map = plume.transpile(code, filename)

    -- Store source map for debugging purposes
    env.plume.package.map[filename] = map

    -- Compile Lua code using sandboxed environment
    local compiledFunction, errorMessage
    if setfenv then -- Lua 5.1
        compiledFunction, errorMessage = loadstring(transpiledCode, filename)
        if compiledFunction then
            setfenv(compiledFunction, env)
        end
    else -- Lua 5.2+
        compiledFunction, errorMessage = load(transpiledCode, filename, nil, env)
    end

    if not compiledFunction then
        error(errorMessage, -1)
    end

    return compiledFunction()
end

--- Run Plume code; sets up environment, error handling, and file tracing.
-- @function plume.run
-- @tparam string code       The Plume source code.
-- @tparam[opt] string filename The filename. If omitted, a unique name is generated.
-- @return The result of running the code.
function plume.run(code, filename)
    local env = plume.initRuntime()

    -- Generate unique filename if not provided
    if not filename then
        env.plume.package.anonymous = env.plume.package.anonymous + 1
        filename = "@<string_" .. env.plume.package.anonymous .. ">"
    end

    table.insert(env.plume.package.fileTrace, filename)

    -- Use xpcall for stack trace and context-aware error handling
    local success, result = xpcall(
        function()
            return plume.execute(code, filename, env)
        end,
        function (err)
            return plume.errorHandler(err, env)
        end
    )

    if not success then
        error(result, -1)
    end

    -- Clean up file trace stack
    table.remove(env.plume.package.fileTrace)

    return result
end

return plume
