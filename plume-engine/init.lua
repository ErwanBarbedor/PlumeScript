--[[
Plume🪶 0.35
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

-- This file initializes the Plume environment by loading all its core components
-- and provides the primary public API functions for transpiling and executing
-- Plume code. It sets up the runtime environment, handles error trapping during
-- execution, and manages file tracing for module loading.

local plume = {}

plume._VERSION = "Plume🪶 0.35"

-- Load core components using dependency injection pattern
for lib in ([[
    utils
    patterns
    tokenizer
    parser/init
    makeAST
    plume
    transpiler/init
    suggestion
    error/init
    plumeDebug
]]):gmatch('%S+') do
    require("plume-engine/" .. lib)(plume)
end

--- Transpile Plume code to Lua code.
--- @param string code            The Plume source code.
--- @param string filename        The filename (for error reporting).
--- @return string transpiledCode The resulting Lua code.
--- @return table map             Map between Lua and Plume code.
function plume.transpile(code, filename)
    local tokens = plume.tokenize(code, filename)
    tokens = plume.parse(tokens)
    tokens = plume.makeAST(tokens)
    local transpiledCode, map = plume.transpileToLua(tokens)
    return transpiledCode, map
end

--- Execute Plume code inside a given environment.
--- @param string code       The Plume source code.
--- @param string filename   The filename (for source mapping and messages errors).
--- @param table env         The environment table to use during execution.
--- @return Value returner by the code.
function plume.execute(code, filename, env)
    -- Get transpiled Lua code and source map
    local transpiledCode, map = plume.transpile(code, filename)

    -- Store source map for debugging purposes
    env.plume.package.map[filename] = map

    -- Compile Lua code using sandboxed environment
    local compiledFunction, errorMessage = loadstring(transpiledCode, filename)
    if compiledFunction then
        setfenv(compiledFunction, env)
    end

    if not compiledFunction then
        error(errorMessage, -1)
    end

    return compiledFunction()
end

--- Run Plume code; sets up environment, error handling, and file tracing.
--- @param string code       The Plume source code.
--- @param string? filename The filename. If omitted, a unique name is generated.
--- @return The result of running the code.
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
