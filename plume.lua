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

    PLUME MANAGEMENT
    plume --install
    plume --install directory
        Install plume in the given directory (~/.local/bin by default)
    
    OTHER
    plume [-h --help]
        Displays this help message.
    plume [-v --version]
        Displays current Plume version
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

--- Displays the command-line interface help message.
-- This function prints the Plume version, a link to the GitHub repository,
-- and a general help text.
local function CLIHelp ()
    print(plume._VERSION)
    print(GITHUB)
    print()
    print(help)
end

--- Displays the Plume version.
local function CLIVersion ()
    print(plume._VERSION)
end

local function checkDirOnPath(dir)
    local home = os.getenv("HOME")
    local resdir = dir:gsub('~', home)
    local paths = os.getenv("PATH")
    
    for path in paths:gmatch('[^:]+') do
        if path == dir then
            return true
        end
    end

    return false
end

--- Executes Plume code provided either as a string or from a file.
--- @param options table A table containing execution options
function CLIExec (options)
    local result
    local codeToRun -- Variable to hold the Plume code string to be executed.

    if options.string then
        codeToRun = options.string
        -- Run the code string; "@input" is a conventional name for the chunk for error reporting.
        result = plume.run(codeToRun, "@input")
    elseif options.filename then
        -- Attempt to open the specified file for reading.
        local file, err_open = io.open(options.filename, "r")
        if not file then
            CLIError ("Error: Cannot open the file '" .. options.filename .. "'. " .. (err_open or ""))
        end

        codeToRun = file:read('*a')
        file:close()
        -- Run the file content; prepending "@" to the filename is a Lua convention for chunk names,
        -- useful for error reporting.
        result = plume.run(codeToRun, "@"..options.filename)
    else
        -- If no input (string or filename) is provided, report an error.
        CLIError("Error: No input specified.", true)
    end

    -- Convert the result of the Plume script execution to a string for output.
    result = tostring(result)

    if options.output then
        -- If an output file is specified, attempt to write the result to it.
        local file, err_open_output = io.open(options.output, "w")
        if not file then
            -- If the output file cannot be opened for writing, report an error.
            CLIError ("Error: Cannot write to the file '" .. options.output .. "'. " .. (err_open_output or ""))
        end
        -- Write the result to the file.
        local ok, err_write = file:write(result)
        if not ok then
            -- If writing to the file fails, report an error.
             CLIError ("Error: Failed to write to file '" .. options.output .. "'. " .. (err_write or ""))
        end
        file:close()
        print("Output successfully written to '".. options.output .."'." )
    elseif options.print then
        print(result)
    else
        print("Executed with success.")
    end
end

--- Installs the Plume CLI tools.
---@param dir string The directory to install to. Defaults to '~/.local/bin'.
local function CLIInstall(dir)
    if dir == true then
        dir = "~/.local/bin"
    end

    -- Check if source files exist
    for filename in ("plume plume-engine plume.lua"):gmatch("%S+") do
        local file = io.open(filename)
        if not file then
            CLIError("'" .. filename .. "' not found, abort.")
        end
        file:close()
    end

    -- Copy files to the installation directory
    for filename in ("plume plume-engine plume.lua"):gmatch("%S+") do
        local p = io.popen("cp -r " .. filename .. " " .. dir .. "/" .. filename .. " 2>&1")
        local result = p:read("*a")
        if #result > 0 then
            CLIError("Error during copy: " .. result)
        end
    end

    -- check if dir is in the path and warn if not
    if not checkDirOnPath(dir) then
        print("Warning: '" .. dir .."' is not on PATH.")
    end

    print("Plume installed in '" .. dir .. "' with success.")
end

-- Option configuration

-- Maps short option flags to their corresponding long option names.
local shortcut = {
    s = "string",
    o = "output",
    h = "help",
    p = "print",
    v = "version"
}
-- A set of valid long option names.
local acceptedParameters = {
    string  = true,
    output  = true,
    help    = true,
    print   = true,
    version = true,
    install = true
}
-- Defines options that cannot be used together.
local exclusive = {
    string   = {filename=true},
    filename = {string=true},
    print    = {output=true},
    output   = {print=true},
}
local all_exclusive = {
    help=true,
    version=true
}
-- A set of option names that require an accompanying value.
local expectedValue = {
    string  = true,
    output  = true
}

local optionalValue = {
    install = true
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
        if  (exclusive[optionName] and exclusive[optionName][name])
            or all_exclusive[optionName]
            or all_exclusive[name] then 
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
        elseif optionalValue[name] then
            if #arg>0 and not arg[#arg]:match('^%-') then
                value = table.remove(arg, 1)
            else
                value = true
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
    CLIHelp()
elseif options.version then
    CLIVersion()
elseif options.install then
    CLIInstall(options.install)
else
    CLIExec(options)
end