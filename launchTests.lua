local plume = require("plume-engine/init")

--- Load test cases from specified files
--- Parses test files following specific comment patterns to extract test metadata
---@param filenames string Space-separated list of base filenames (without extension)
---@return table Array of test objects containing code and expected results
local function loadTests(filenames)
    local tests = {}

    for filename in filenames:gmatch("%S+") do
        -- Read test file content (potential error if file missing - hint: add error handling)
        local content = io.open("tests/" .. filename .. ".plume"):read("*a")
        -- Pattern matches test blocks with specific comment syntax:
        -- /// Test "name"
        -- code
        -- /// ResultType (Error/Result)
        -- expected_output
        -- /// End
        for name, code, resultKind, result in content:gmatch('/// Test "(.-)"\n(.-)\n/// (.-)\n(.-)\n/// End') do
            table.insert(
                tests,
                {
                    file = filename,
                    name = name,
                    code = code,
                    resultKind = resultKind,
                    result = result,
                    sucess = true,
                    failInfos = {
                        resultKind = "",
                        result = ""
                    }
                }
            )
        end
    end
    return tests
end

--- Execute tests and validate results against expectations
---@param tests table Test cases loaded by loadTests
---@return integer Number of successful tests
local function passTests(tests)
    local sucessCount = 0
    for _, test in ipairs(tests) do
        -- Safely execute test code using plume engine
        local sucess, result = pcall(plume.execute, test.code)
        result = tostring(result)  -- Convert all results to strings for comparison

        -- Logic for 'expect valid result' tests
        if test.resultKind == "Result" then
            if not sucess then
                test.sucess = false
                test.failInfos.resultKind = "Error"
                test.failInfos.result = result
            elseif result ~= test.result then
                test.sucess = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            else
                sucessCount = sucessCount + 1
            end
        -- Logic for 'expect error' tests
        else
            if sucess then
                test.sucess = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            elseif result ~= test.result then
                test.sucess = false
                test.failInfos.resultKind = "Result"
                test.failInfos.result = result
            else
                sucessCount = sucessCount + 1
            end
        end
    end

    return sucessCount
end

--- Display test results with detailed failure information
---@param tests table Test cases after execution
---@param sucessCount integer Number of successful tests
function showTestsResult(tests, sucessCount)
    local _VERSION = _VERSION

    -- Detect LuaJIT environment
    if jit then
        _VERSION = "LuaJIT"
    end

    print(
        plume._VERSION .. ' (' .. _VERSION .. ") : " 
            .. sucessCount .. "/" .. #tests 
        .. " tests passed.\n"
    )

    -- Print detailed failure information for each failed test
    for _, test in ipairs(tests) do
        if not test.sucess then
            -- Format expected/obtained values with error type annotations
            local expected = test.result
            local obtained = test.failInfos.result or ""

            -- Add error context prefixes
            if test.resultKind == "Error" then
                expected = "(error)" .. expected
            end
            if test.failInfos.resultKind == "Error" then
                obtained = "(error)" .. obtained
            end

            -- Print multi-line results with indentation
            print('Test "' .. test.file .. "/" .. test.name .. '" failed.')
            print("\tExpected:")
            print("\t\t" .. expected:gsub("\n", "\n\t\t") .. "")
            print("\tObtained:")
            print("\t\t" .. obtained:gsub("\n", "\n\t\t") .. "")
        end
    end
end

-- Load and execute tests
local tests = loadTests("block errors eval if loops macros table text variables")
local sucessCount = passTests(tests)
showTestsResult(tests, sucessCount)