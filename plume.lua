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

-- Get Plume's source directory. This is expected to be the first argument passed to this script.
local scriptDir = table.remove(arg, 1)

-- Modify package.path to allow Plume to find its modules relative to its source directory.
package.path = (scriptDir.."/?.lua;") .. package.path
local plume = require ("plume-engine/init") -- Load the Plume engine

-- Command-line interface documentation string
local help = [[
Usage: 
    INPUT
    plume file.plume
        Executes the given script.
    plume [-s --string] "..."
        Executes the given string.
    
    OUTPUT
    plume INPUT [-o --output] file.txt
        Saves the output to file.txt.
        Warning: The result is converted using 'tostring'.
        So if the script returns a table, the output in the file might not be directly usable.
    plume INPUT [-p --print]
        Print the output to the console.
    
    OTHER
    plume [-h --help]
        Displays this help message.
]]

local GITHUB = "https://github.com/ErwanBarbedor/PlumeScript"

--- Prints an error message and optionally the help text, then exits the program.
--- @param msg string The error message to display.
--- @param showHelp boolean? If true, the help text is displayed after the error message.
local function CLIError(msg, showHelp)
    print(msg)
    if showHelp then
        print(help)
    end
    os.exit(1) -- Exit with a non-zero status to indicate an error
end

-- Option configuration

-- Maps short option flags to their corresponding long option names.
local shortcut = {
    s = "string",
    o = "output",
    h = "help",
    p = "print"
}
-- A set of valid long option names.
local acceptedParameters = {
    string = true,
    output = true,
    help   = true,
    print  = true
}
-- Defines options that cannot be used together.
local exclusive = {
    string   = {filename=true, help=true},
    filename = {string=true, help=true},
    print    = {output=true, help=true},
    output   = {print=true, help=true},
    help     = {filename=true, string=true, output=true, print=true}
}
-- A set of option names that require an accompanying value.
local expectedValue = {
    string = true,
    output = true
}

-- Stores the parsed command-line options.
local options = {} 

--- Adds a parsed option to the `options` table, checking for conflicts.
--- @param name string The name of the option.
--- @param value string|boolean The value of the option.
local function addOption(name, value)
    if options[name] then
        CLIError("Error: Received multiple values for parameter '" .. name .. "'.", true)
    end

    -- Check for exclusivity with already added options
    for optionName, _ in pairs(options) do
        if exclusive[optionName] and exclusive[optionName][name] then 
            CLIError(
                "Error: Wrong usage, cannot provide both '"
                .. name
                .. "' and '"
                .. optionName
                .. "'.",
                true
            )
        end
    end

    options[name] = value
end

-- Read command line parameters
if #arg == 0 then
    CLIError("You must specify at least one parameter or use --help.", true)
end

while #arg > 0 do
    local parameter = table.remove(arg, 1)
    -- Parameter is an option (starts with '-')
    if parameter:match('^%-') then
        -- Extract option name, works for -o and --option
        local name = parameter:match('^%-%-?(.*)')
        -- Normalize short options to long names
        name = shortcut[name] or name

        if not acceptedParameters[name] then
            CLIError("Error: Unknown parameter '" .. name .. "'.", true)
        end

        local value
        if expectedValue[name] then 
            -- The next argument is the value
            value = table.remove(arg, 1)

            if not value then
                CLIError("Error: Expected a value after parameter '" .. parameter .. "'.", true)
            end
        else
            value = true
        end

        addOption(name, value)
    -- Parameter is not an option, assume it's a filename
    else 
        addOption("filename", parameter)
    end
end

-- Execute based on parsed options
if options.help then
    print(plume._VERSION)
    print(GITHUB)
    print()
    print(help)
else
    local result
    local codeToRun -- Variable to hold the Plume code string

    if options.string then
        codeToRun = options.string
        -- Run the string; "@input" is a conventional name for the chunk for error reporting.
        result = plume.run(codeToRun, "@input")
    elseif options.filename then
        local file = io.open(options.filename, "r")
        if not file then
            CLIError ("Error: Cannot open the file '" .. options.filename .. "'.")
        end
        codeToRun = file:read('*a')
        file:close()
        -- Run the file content; "@" prepended to filename is a lua convention for filename.
        result = plume.run(codeToRun, "@"..options.filename)
    else
        CLIError("Error: No input specified.", true)
    end

    -- Convert the result of the Plume script to a string for output.
    result = tostring(result)

    if options.output then
        local file, err = io.open(options.output, "w")
        if not file then
            CLIError ("Error: Cannot write to the file '" .. options.output .. "'. " .. (err or ""))
        end
        local ok, write_err = file:write(result)
        if not ok then
             CLIError ("Error: Failed to write to file '" .. options.output .. "'. " .. (write_err or ""))
        end
        file:close()
        print("Output successfully written to '".. options.output .."'." )
    elseif options.print then
        print(result)
    else
        print("Executed with sucess.")
    end
end
