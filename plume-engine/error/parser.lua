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
    --- Throws an error if an unexpected token is encountered by the parser (e.g., wrong value or type).
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param expected string A description of the expected token or syntax element.
    --- @param given string The actual token value or type that was encountered.
    function plume.unexpectedTokenError (source, expected, given)
        plume.sourcedError(source, string.format(
            "Syntax error: expected %s, not \"%s\".",
            expected, given
        ))
    end

    --- Throws an error if a vararg ('...') is used in an incorrect position (e.g., not as the last parameter).
    --- @param source table Source metadata, as expected by `getSourceLine`.
    function plume.unexpectedVarargError(source)
        plume.sourcedError(source, "Syntax error: vararg ('...') must be the last parameter in a parameter list.")
    end

    --- Throws an error if a return statement is not the last statement in its block.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    function plume.followedReturnError(source)
        plume.sourcedError(source, "Syntax error: no statements can follow a 'return' statement in the same block.")
    end

    --- Throws an error if multiline evaluation syntax (e.g., `$var[[...]]`) is followed by a newline immediately after the opening delimiter.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param sep string The separator/delimiter used in the multiline eval syntax (e.g., "[[", "{").
    function plume.multilineEvalError(source, sep)
        plume.sourcedError(source, "Syntax error: '$var" .. sep .. "' multiline evaluation syntax cannot be followed immediately by a line break.")
    end
end