--[[
Plume🪶 0.36
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

plume._VERSION = "Plume🪶-0.36"

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
    cache
    plumeDebug
]]):gmatch('%S+') do
    require("engine/" .. lib)(plume)
end

--- Transpile Plume code to Lua code.
--- @param string code            The Plume source code.
--- @param string filename        The filename (for error reporting).
--- @return string transpiledCode The resulting Lua code.
--- @return table map             Map between Lua and Plume code.
function plume.transpile(code, filename)
    local tokens = plume.tokenize(code, "@"..filename)
    tokens = plume.parse(tokens)
    tokens = plume.makeAST(tokens)
    local transpiledCode, map = plume.transpileToLua(tokens, filename)
    return transpiledCode, map
end

--- Execute Plume code inside a given environment.
--- @param filename string  Name of the file to run.
--- @param isString boolean Should the filename be considered as the script to run.
--- @param table env        The environment table to use during execution.
--- @return Value returner by the code.
function plume.execute(filename, isString, env)
    local luaCode, luaMap

    -- filename contain the code?
    if isString then
        local plumeCode = filename
        env.plume.package.anonymous = env.plume.package.anonymous + 1
        filename = "<string_" .. env.plume.package.anonymous .. ">"
        luaCode, luaMap = plume.transpile(plumeCode, filename)
    -- else load it from the file. Handle caching
    else
        luaCode, luaMap = plume.loadOrTranspile(filename, env)
    end

    -- Store source map for debugging purposes
    env.plume.package.map["@"..filename] = luaMap

    -- Compile Lua code using sandboxed environment
    local compiledFunction, errorMessage = loadstring(luaCode, "@"..filename)
    if compiledFunction then
        setfenv(compiledFunction, env)
    end

    if not compiledFunction then
        error(errorMessage, -1)
    end

    return compiledFunction()
end

--- Run Plume code; sets up environment and error handling.
--- @param filename string  Name of the file to run.
--- @param isString boolean Should the filename be considered as the script to run.
--- @param options table
function plume.run(filename, isString, options, scriptDir)
    options = options or {}

    local env = plume.initRuntime(scriptDir)
    env.plume.package.caching = options.caching
                
    -- Use xpcall for stack trace and context-aware error handling
    local success, result = xpcall(
        function()
            return plume.execute(filename, isString, env)
        end,
        function (err)
            return plume.errorHandler(err, env)
        end
    )

    if not success then
        error(result, -1)
    end

    return result
end

return plume
