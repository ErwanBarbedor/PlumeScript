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

return function(plume)
    require "engine/transpiler/lua/builder" (plume)
    require "engine/transpiler/lua/tokenHandlers" (plume)
    require "engine/transpiler/lua/transpileBlock" (plume)

    --- Transpiles a single AST node by dispatching to a registered handler.
    ---@param ast table The AST node to transpile.
    function plume.transpileASTToLua(ast, builder, accName, isValue)
        if plume.tokenHandlers[ast.kind] then
            return plume.tokenHandlers[ast.kind](ast, builder, accName, isValue)
        else
            error("NIY: Transpilation for AST node kind '" .. (ast.kind or "???") .. "' is not implemented yet.")
        end
    end

    function plume.transpileAllToLua(children, builder, accName, isValue)
        for _, child in ipairs(children) do
            plume.transpileASTToLua(child, builder, accName, isValue)
        end
    end

    function plume.transpileToLua (ast, filename)
        local dir = filename:gsub('[^\\/]+$', '')
        dir = dir:gsub('[\\/]$', '')
        if #dir == 0 then
            dir = "."
        end
        
        builder = plume.builder()
        
        builder:write(nil, "local _FILE = \"" .. filename .. "\"")
        builder:write(nil, "local _DIR  = \"" .. dir .. "\"")
        plume.transpileASTToLua(ast, builder)

        builder:finalize()
        return builder.code, builder.map
    end
end