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
local function loadTests(filenames)
    local tests = {}

    for filename in filenames:gmatch("%S+") do
        local content = io.open("tests/" .. filename .. ".plume"):read("*a"):gsub('\r', '')
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
local function passTests(tests)
    local successCount = 0
    for _, test in ipairs(tests) do
        local success, result = pcall(plume.run, test.code)
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
function showTestsResult(tests, successCount)
    local _VERSION = _VERSION
    if jit then  -- Detect LuaJIT runtime
        _VERSION = "Lua JIT"
    end

    print(plume._VERSION .. ' (' .. _VERSION .. ") : " 
        .. successCount .. "/" .. #tests 
        .. " tests passed.")

    if arg[1] ~= "silent" then
        for _, test in ipairs(tests) do
            if not test.success then
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
            end
        end
    end
end

-- Main execution flow
local tests = loadTests("block errors eval if loops macros std table text variables issues")
local successCount = passTests(tests)
showTestsResult(tests, successCount)