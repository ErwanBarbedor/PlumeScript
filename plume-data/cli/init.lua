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
local plume = require ("engine/init") -- Load the Plume engine

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
    plume INPUT --no-cache
        Dont read nor write caching informations

    PLUME MANAGEMENT
    plume --install
    plume --install directory
        Install plume in the given directory (~/.local/bin by default)
    plume --remove
        Remove plume installation
    plume --update
        Download new plume version from github
    plume --remove-cache
        Delete all cached file

    
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

--- Executes Plume code provided either as a string or from a file.
--- @param options table A table containing execution options
function CLIExec (options)
    local result

    if options.string then
        result = plume.run(
            options.string,
            true, 
            {caching = not options["no-cache"]},
            scriptDir
        )
    elseif options.filename then
        -- Attempt to open the specified file for reading.
        local file, err_open = io.open(options.filename)
        if not file then
            CLIError ("Error: Cannot open the file '" .. options.filename .. "'. " .. (err_open or ""))
        end
        file:close()

        result = plume.run(
            options.filename,
            false, 
            {caching = not options["no-cache"]},
            scriptDir
        )
    else
        -- If no input (string or filename) is provided, report an error.
        CLIError("Error: No input specified.", true)
    end

    -- Convert the result of the Plume script execution to a string for output.
    result = tostring(result)

    if options.output then
        local file, err_open_output = io.open(options.output, "w")
        if not file then
            CLIError ("Error: Cannot write to the file '" .. options.output .. "'. " .. (err_open_output or ""))
        end
        local ok, err_write = file:write(result)
        if not ok then
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

local function CLIRemoveCache()
    os.execute("rm -rf .plume-cache")
end

local function checkDirOnPath(dir)
    local home = os.getenv("HOME")
    local resdir = dir:gsub('~', home)
    local paths = os.getenv("PATH")
    
    for path in paths:gmatch('[^:]+') do
        if path == resdir then
            return true
        end
    end

    return false
end

local plumeFiles = {"plume", "plume-engine", "plume.lua"}
--- Installs the Plume CLI tools.
---@param dir string The directory to install to. Defaults to '~/.local/bin'.
---@param src string
---@param showSuccessMessage bool
local function CLIInstall(dir, src, showSuccessMessage)
    if dir == true then
        dir = "~/.local/bin"
    end

    -- Check if source files exist
    for _, filename in ipairs(plumeFiles) do
        print("Check: " .. src .. filename)
        local file = io.open(src..filename)
        if not file then
            CLIError("'" .. src .. filename .. "' not found, abort.")
        end
        file:close()
    end

    -- Copy files to the installation directory
    for _, filename in ipairs(plumeFiles) do
        local srcPath  = src .. filename
        local distPath = dir .. "/" .. filename
        print("Copy: " .. srcPath .. " -> " .. distPath)
        local p = io.popen("cp -r " .. srcPath .. " " .. distPath .. " 2>&1")
        local result = p:read("*a")
        if #result > 0 then
            CLIError("Error during copy: " .. result)
        end
    end

    print("Make Plume executable.")
    io.popen("chmod +x " .. dir .. "/plume")

    -- check if dir is in the path and warn if not
    if not checkDirOnPath(dir) then
        print("Warning: '" .. dir .."' is not on PATH.")
    end

    if showSuccessMessage then
        print("Plume installed in '" .. dir .. "' with success.")
    end
end

local function CLIRemove ()
    for _, filename in ipairs(plumeFiles) do
        print("Remove: " .. scriptDir .. "/" .. filename)
        local p = io.popen("rm -r " .. scriptDir .. "/" .. filename .. " 2>&1")
        local result = p:read("*a")
        if #result > 0 then
            CLIError("Error during supression: " .. result)
        end
    end
end

local function CLIUpdate ()
    local command = "git ls-remote --tags --sort=-v:refname " .. GITHUB .. " | head -n 1"
    local tag = io.popen(command):read("*a")

    if not tag then
        CLIError("Cannot fetch data")
    end

    local gitVersion = tag:match('([%.0-9]+)%s*$')
    local curVersion = plume._VERSION:match('[%.0-9]+$')

    if gitVersion == curVersion then
        print("Plume is up to date.")
    else
        io.write("Update plume from version '" .. curVersion .."' to '" .. gitVersion .. "'? y/n: ")
        local answer = io.read()

        if answer == "y" or answer == "yes" then
            os.execute("rm -rf PlumeScript")
            os.execute("git clone " .. GITHUB )

            CLIRemove()
            CLIInstall(scriptDir, "PlumeScript/", false)

            print("Remove git clone")
            os.execute("rm -rf PlumeScript")

            print("Plume updated with success to version '" .. gitVersion .. "'.")
        end
    end
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
    string           = true,
    output           = true,
    help             = true,
    print            = true,
    version          = true,
    install          = true,
    remove           = true,
    update           = true,
    ["remove-cache"] = true,
    ["no-cache"]     = true
}
-- Defines options that cannot be used together.
local exclusive = {
    string   = {filename=true},
    filename = {string=true},
    print    = {output=true},
    output   = {print=true},
}
local all_exclusive = {
    help    = true,
    version = true,
    install = true,
    remove  = true,
    update  = true
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
    CLIInstall(options.install, "./", true)
elseif options.remove then
    CLIRemove()
elseif options.update then
    CLIUpdate()
elseif options["remove-cache"] then
    CLIRemoveCache()
else
    CLIExec(options)
end