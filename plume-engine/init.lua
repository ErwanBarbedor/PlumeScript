--[[
Plume🪶 0.20
Copyright (C) 2024-2025 Erwan Barbedor

Check https://github.com/ErwanBarbedor/Plume
for documentation, tutorial or to report issues.

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

plume._VERSION = "Plume🪶 0.20"

require "plume-engine/utils"         (plume)
require "plume-engine/patterns"      (plume)
require "plume-engine/tokenizer"     (plume)
require "plume-engine/parser/parser" (plume)
require "plume-engine/makeAST"       (plume)
require "plume-engine/plume"         (plume)
require "plume-engine/LuaTranspiler" (plume)
require "plume-engine/error"         (plume)
require "plume-engine/beautifier"    (plume)
require "plume-engine/plumeDebug"    (plume)

function plume.execute(text)
    local tokens = plume.tokenize(text)
    tokens       = plume.parse(tokens)
    local ast    = plume.makeAST(tokens)

    local code   = plume.transpileToLua(ast)
    code         = plume.beautifier(code)

    local f = load(code)

    local env = setmetatable({
        plume = plume.plumeStdLib
    }, {__index = _G})
    setfenv(f, setmetatable({}, {__index = env}))
    return f()
end


return plume