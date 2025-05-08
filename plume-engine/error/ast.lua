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

return function (plume)
    --- Throws an error when a block or context (like a macro argument list) isn't properly closed (e.g., missing 'end' or ')').
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param kind string A string identifying the kind of block or context that was unclosed (e.g., "IF_BLOCK", "MACRO_ARG_TABLE").
    function plume.unclosedContextError(source, kind)
        if kind == "MACRO_ARG_TABLE" then
            plume.sourcedError(source, 'Syntax error: ")" expected to close argument list.')
        else
            plume.sourcedError(source, string.format(
                "Syntax error: block '%s' never closed.",
                kind
            ))
        end
    end

    --- Indicates a type mismatch in a block (e.g., a list of expressions that are not of a consistent type).
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param expectedType string The expected type for expressions in the block.
    --- @param givenType string The type of the expression that caused the mismatch.
    function plume.mixedBlockError (source, expectedType, givenType)
        plume.sourcedError(source, string.format(
            "mixedBlockError: Given the previous expressions in this block, it was expected to be of type %s, but a %s expression has been supplied.",
            expectedType, givenType
        ))
    end

    --- Throws a syntax error for an invalid Lua identifier name.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param name string The invalid identifier name encountered.
    function plume.invalidLuaNameError(source, name)
        plume.sourcedError(source, string.format(
            "Syntax error: '%s' isn't a valid name.",
            name
        ))
    end
end