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

local plume = require("plume-engine/init")

--- Load test cases from specified files using custom comment syntax
---@param filenames string Space-separated list of base filenames
---@return table Array of test case objects with metadata
local function loadPlumeTests(filenames)
    local tests = {}

    for filename in filenames:gmatch("%S+") do
        local content = io.open("tests/plume/" .. filename .. ".plume"):read("*a"):gsub('\r', '')
        -- Test block structure:
        -- /// Test "Name"
        -- [code]
        -- /// ResultType (Error/Result)
        -- [expected output]
        -- /// End
        for name, code, resultKind, result in content:gmatch('/// Test "(.-)"\r?\n(.-)\r?\n/// (.-)\r?\n(.-)\r?\n/// End') do
            table.insert(tests, {
                file = filename,
                name = name,
                code = code,
                resultKind = resultKind,
                result = result,
                success = true,
                failInfos = {
                    resultKind = "",
                    result = ""
                }
            })
        end
    end
    return tests
end

--- Execute tests and validate against expected outcomes
---@param tests table Test cases from loadTests
---@return integer Number of successful tests
local function passPlumeTests(tests)
    local successCount = 0
    for _, test in ipairs(tests) do
        local success, result = pcall(plume.run, test.code, true, {caching=false}, "./")
        result = tostring(result)  -- Normalize output for comparison

        if test.resultKind == "Result" then
            -- Success requires both execution success AND matching output
            if not success then
                test.success = false
                test.failInfos.resultKind = "Error"
                test.failInfos.result = result
            elseif result ~= test.result then
                test.success = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            else
                successCount = successCount + 1
            end
        else  -- Error expectation tests
            if success then
                test.success = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            elseif result ~= test.result then
                test.success = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            else
                successCount = successCount + 1
            end
        end
    end
    return successCount
end

--- Display formatted test results with diff highlighting
---@param tests table Processed test cases
---@param successCount integer Number of successful tests
---@param maxErrorsShown integer|nil if given, limit the number of shown errors.
local function showPlumeTestsResult(tests, successCount, maxErrorsShown)
    print('Langage tests : ' 
        .. successCount .. "/" .. #tests 
        .. " passed.")
    
    local errorCount = 0
    if arg[1] ~= "silent" then
        for _, test in ipairs(tests) do
            if not test.success then
                errorCount = errorCount + 1
                -- Format expected/actual with error type annotations
                local expected = test.result
                local obtained = test.failInfos.result or ""

                -- Prefix error types for visual distinction
                expected = test.resultKind == "Error" and "(error)" .. expected or expected
                obtained = test.failInfos.resultKind == "Error" and "(error)" .. obtained or obtained

                -- hint: gsub used for multi-line result indentation
                print('Test "' .. test.file .. "/" .. test.name .. '" failed.')
                print("\tExpected:")
                print("\t\t" .. expected:gsub("\n", "\n\t\t"))
                print("\tObtained:")
                print("\t\t" .. obtained:gsub("\n", "\n\t\t"))

                if maxErrorsShown and maxErrorsShown == errorCount then
                    break
                end
            end
        end
    end
end

-- cli Test
local function loadCLITests(filenames)
    local tests = {}

    for filename in filenames:gmatch("%S+") do
        table.insert(tests, {
            name=filename,
            data=require("tests/cli/" .. filename),
            failInfos={nofiles={}, files={}}
        })
    end

    return tests
end

local function passCLITests(tests)
    local successCount = 0
    for _, test in ipairs(tests) do
        local success = true
        for filename, content in pairs(test.data.files or {}) do
            local f = io.open(filename, "w")
            -- indent utilisé pour la sibilité dans le fichier test
            content = content:gsub('            ', '')
            f:write(content)
            f:close()
        end

        local output = {}
        for _, command in ipairs(test.data.commands) do
            local f = io.popen(command.." 2>&1", "r")
            table.insert(output, f:read('*a'))
            f:close()
        end

        for filename, content in pairs(test.data.expected.files or {}) do
            local f = io.open(filename)
            if f then
                local rcontent = f:read("*a")
                if rcontent ~= content then
                    success = false
                    test.failInfos.files[filename] = rcontent
                end
                f:close ()
            else
                success = false
                table.insert(test.failInfos.nofiles, filename)
            end
        end

        local output = table.concat(output):gsub('\n$', '')-- trim output
        if output ~= test.data.expected.output then
            success = false
            test.failInfos.output = output
        end

        -- nettoyage
        for filename, _ in pairs(test.data.files or {}) do
            os.remove(filename)
        end
        for filename, _ in pairs(test.data.expected.files or {}) do
            os.remove(filename)
        end

        test.success = success
        if success then
            successCount = successCount + 1
        end
    end

    return successCount
end

local function showCLITestsResult(tests, successCount)
    print('CLI tests : ' 
        .. successCount .. "/" .. #tests 
        .. " passed.")

    local errorCount = 0

    if arg[1] ~= "silent" then
        for _, test in ipairs(tests) do
            if not test.success then
                errorCount = errorCount + 1
                
                print('Test "' .. test.name .. '" failed.')

                if test.failInfos.output then
                    print("\tExpected output: " .. test.data.expected.output)
                    print("\tObtained output: " .. test.failInfos.output)
                end

                for _, filename in ipairs(test.failInfos.nofiles) do
                    print("\tScript doesn't create the file '" .. filename .. "'.")
                end

                for filename, content in pairs(test.failInfos.files) do
                    print("\tError in file '" .. filename .. "' content.")
                    print("\t\tExpected content: " .. test.data.expected.files[filename])
                    print("\t\tObtained content: " .. content)
                end


                if maxErrorsShown and maxErrorsShown == errorCount then
                    break
                end
            end
        end
    end
end

-- Main execution flow

print("Test " .. plume._VERSION .. ' (luajit)')

local plumeTests = loadPlumeTests("void indent convert errors eval if files loops lua macros macros_syntax_error macros_vararg std suggestions table text variables issues")
local plumeSuccessCount = passPlumeTests(plumeTests)
showPlumeTestsResult(plumeTests, plumeSuccessCount)

local cliTests = loadCLITests("simple_execution option_output option_string option_print option_version")
local cliSuccessCount = passCLITests(cliTests)
showCLITestsResult(cliTests, cliSuccessCount)
