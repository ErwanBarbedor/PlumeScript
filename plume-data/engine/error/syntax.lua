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
    function plume.unexpectedTokenError (source, expected, given, infos)
        if infos then
            infos = " (" .. infos .. ")"
        else
            infos = ""
        end
        
        plume.sourcedError(source, string.format(
            "Syntax error: expected %s, not \"%s\"%s.",
            expected, given, infos
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

    --- Throws an error if several commands with the same name are chained in a single line.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param name string The name of the command that is chained.
    function plume.cannotChainSeveralCommand(source, name)
        plume.sourcedError(source, "Syntax error: cannot chains several '" .. name .. "' commands in the same line." )
    end

    --- Throws an error if several different commands are chained in a single line.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param ... string The names of the commands that are chained.
    function plume.cannotChainCommands(source, ...)
        local names = {...}
        local nameList = {}
        
        -- Build a grammatically correct list of command names
        for i=1, #names do
            table.insert(nameList, "'" .. names[i].."'")
            if i < #names-1 then
                table.insert(nameList, ", ")
            elseif i == #names-1 then
                table.insert(nameList, " and ")
            end
        end

        plume.sourcedError(source, "Syntax error: cannot chains " .. table.concat(nameList) .. " commands in the same line." )
    end

    --- Throws an error when a command that can be followed by either text or an indented block is followed by both.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param name string The name of the command.
    function plume.cannotOpenBlockError(source, name)
        plume.sourcedError(source, "Syntax error: command '" .. name .."' can be followed by text or by an indented block, but not both." )
    end

    --- Throws an error when a 'break' statement is used outside of a loop.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param kind string
    function plume.outsideLoopError(source, kind)
        -- Error when 'break' or 'continue' is used outside a loop.
        plume.sourcedError(source, "Syntax error: '"..kind.."' command cannot be use outside of a loop." )
    end

    --- Throws an error when multiple arguments with the same name are used in a function call.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param name string The duplicated argument name.
    function plume.multipleArgumentSameName(source, name)
        -- Reports the error regarding the duplicated argument name.
        plume.sourcedError(source, "Syntax error: multiple use of the argument '" .. name .."' in the same call." )
    end

    --- Throws an error when multiple arguments with the same name are used in a function call.
    --- @param source table Source metadata, as expected by `getSourceLine`.
    --- @param name string The duplicated argument name.
    function plume.multipleArgumentSameName(source, name)
        -- Reports the error regarding the duplicated argument name.
        plume.sourcedError(source, "Syntax error: multiple use of the argument '" .. name .."' in the same call." )
    end

    function plume.cannotUseSelfError(source)
        plume.sourcedError(source, "Syntax error: cannot use 'self' as variable name." )
    end

    function plume.mustLineBreakError(source, name)
        plume.sourcedError(source, "Syntax error: '"..name.."' must end the line." )
    end

    function plume.cannotMixEvalMetaError(source)
        plume.sourcedError(source, "Syntax error: a hash key cannot both be a meta field and be evaluated." )
    end

    function plume.unknownMetaFieldError(source, name)
        plume.sourcedError(source, "Syntax error: '"..name.."' is not a valid metafield name.\nValid names are: add call index le len lt mul newindex tostring unm." )
    end

    function plume.metaWrongArgumentNumber(source, name, obtained, expected)
        plume.sourcedError(source, "Syntax error: Wrong number of arguments for meta field '" .. name .. "': expected " .. expected ..", obtained " .. obtained .. "." )
    end

    function plume.metaCannotUseNamedArguments(source)
        plume.sourcedError(source, "Syntax error: Cannot use named argument in a meta field." )
    end

end