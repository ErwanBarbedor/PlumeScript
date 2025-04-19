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

function plume.execute(code, filename, env)
    -- Lexical Analysis
    local tokens = plume.tokenize(code, filename)

    -- Parsing
    tokens = plume.parse(tokens)

    -- makeAST
    tokens = plume.makeAST(tokens)

    -- transpile
    local code, map = plume.transpileToLua(tokens)

    -- save map for debugging
    env.plume.package.map[filename] = map

    -- loadings and sandboxing
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

    if not compiledFunction then
        error(errorMessage, -1)
    end

    return compiledFunction()
end

-- Sandbox and run plume code
function plume.run(code, filename)
    local env = plume.initRuntime()

    if not filename then
        env.plume.package.anonymous = env.plume.package.anonymous + 1
        filename = "@<string_" .. env.plume.package.anonymous .. ">"
    end

    table.insert(env.plume.package.fileTrace, filename)

    --  Capture error to show it in the plume context
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
    
    table.remove(env.plume.package.fileTrace)

    return result
end

return plume