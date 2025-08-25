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

--- Test engine loader and parser for the Plume language.
-- @module testLoader

local lfs = require("lfs")
local lpeg = require("lpeg")

local lib = {}

--- Normalizes a string by trimming whitespace and standardizing line endings to LF.
-- All line endings (\r\n, \r) are converted to \n. Leading and trailing
-- whitespace is removed.
-- @param str The input string or value to normalize. Can be any type, will be
-- converted to string.
-- @return The normalized string.
local function normalizeOutput(s)
    -- Ensure we are working with a string
    if s == false then
        s = "false"
    else
        s = tostring(s)
    end
    
    -- 1. Replace Windows-style newlines (\r\n) with Unix-style (\n)
    -- 2. Replace classic Mac-style newlines (\r) with Unix-style (\n)
    local withNl = s:gsub("\r\n", "\n"):gsub("\r", "\n")
    
    -- 3. Trim leading and trailing whitespace characters
    local trimmed = withNl:match("^%s*(.-)%s*$")
    
    return trimmed
end

--- Parses the content of a single test file.
-- @param content The string content of the test file.
-- @return A table of tests indexed by their names, or nil if parsing fails.
local function parseTestFile(content)
    local p = lpeg.P
    local R = lpeg.R
    local S = lpeg.S
    local C = lpeg.C
    local Ct = lpeg.Ct

    -- Basic patterns
    local ws = S(" \t")^0
    local nl = p("\r\n") + p("\n")
    local space = S(" \t\r\n")^0

    -- Capture the test name from the header
    local name = C((1 - nl)^1)
    local testHeader = p("/// Test ") * ws * name * nl

    -- Markers
    local outputMarker = p("/// Output") * nl
    local errorMarker = p("/// Error") * nl
    local endMarker = p("/// End")

    -- Capture the code block (anything until the next marker)
    local codeContent = C((1 - (outputMarker + errorMarker))^0)

    -- Capture the expected result block (anything until the end marker)
    local expectedContent = C((1 - endMarker)^0)

    -- A section representing expected output
    local outputSection = (outputMarker * expectedContent) / function(out)
        return { output = normalizeOutput(out), error = false }
    end

    -- A section representing an expected error
    local errorSection = (errorMarker * expectedContent) / function(err)
        return { output = normalizeOutput(err), error = true }
    end

    -- A complete test block from header to end marker
    local testBlock = (testHeader * codeContent * (outputSection + errorSection)) /
        function(testName, input, expectedData)
            -- Return key-value pair for easier table construction later
            return {
                key = testName,
                value = {
                    input = input,
                    expected = expectedData,
                    obtained = {},
                },
            }
        end

    -- Grammar for an entire file: zero or more test blocks
    local fileGrammar = space * Ct((testBlock * space * endMarker * space)^0)

    local parsed = fileGrammar:match(content)

    if not parsed then
        return nil
    end

    -- Convert the array of {key, value} tables into a dictionary
    local testsByName = {}
    for _, entry in ipairs(parsed) do
        testsByName[entry.key] = entry.value
    end

    return testsByName
end

--- Loads and parses all `.plume` test files from a given directory.
-- @param directory The path to the directory containing test files.
-- @return A table containing all parsed tests, organized by filename.
function lib.loadTests(directory)
    local allTests = {}
    local path = directory:gsub("/*$", "") -- Remove trailing slash if present

    for filename in lfs.dir(path) do
        -- Only process .plume files, ignore directories '.' and '..'
        if filename ~= "." and filename ~= ".." and filename:match("%.plume$") then
            local fullPath = path .. "/" .. filename
            local file, err = io.open(fullPath, "r")

            if file then
                local content = file:read("*a")
                file:close()
                
                local parsedTests = parseTestFile(content)
                if parsedTests then
                    -- Use filename without path as key
                    allTests[filename] = parsedTests
                else
                    -- Handle parsing failure for a specific file
                    allTests[filename] = { error = "Failed to parse file." }
                end
            else
                allTests[filename] = { error = "Failed to open file: " .. (err or "unknown error") }
            end
        end
    end

    return allTests
end

--- Executes a collection of tests using the provided Plume engine.
-- This function iterates through all loaded tests, executes the code for each,
-- captures the output or error, normalizes it, and stores it in the
-- `obtained` field of each test object.
-- @param allTests The table of tests loaded by `lib.loadTests`.
-- @param plumeEngine The Plume engine object. Must contain an `execute` method
-- that takes `(code, sourceName)` as arguments.
-- @return The `allTests` table, now populated with execution results.
function lib.executeTests(allTests, plumeEngine)
    for filename, tests in pairs(allTests) do
        -- Only process files that were loaded and parsed correctly
        if not tests.error then
            for testName, testData in pairs(tests) do
                -- Use pcall to safely execute the Plume code and capture errors
                local success, result = pcall(plumeEngine.execute, testData.input, testName)
                
                if success then
                    testData.obtained = {
                        output = normalizeOutput(result),
                        error = false,
                    }
                else
                    -- 'result' contains the error message
                    testData.obtained = {
                        output = normalizeOutput(result),
                        error = true,
                    }
                end
            end
        end
    end
    
    return allTests
end

-- File: lib.lua (addition)

--- Analyzes executed test results, calculates statistics, and annotates the
-- input table with the results.
-- This function modifies the input table in-place by adding a `status` field
-- to each test and `stat` tables at the global and file levels.
-- @param allTests The table of tests, populated with `obtained` results by
-- `lib.executeTests`.
-- @return The modified `allTests` table.
function lib.analyzeResults(allTests)
    -- Initialize the global statistics object at the root of the table
    allTests.stats = { success = 0, fails = 0, total = 0 }

    -- Iterate over each file in the test suite
    for filename, fileData in pairs(allTests) do
        -- We only process file tables, not the global stat table itself
        if filename ~= "stats" then

            -- Skip files that had loading or parsing errors
            if fileData.error then
                -- For now, we do not count file-level errors in stats,
                -- but this could be changed later if needed.
            else
                -- Initialize the statistics object for the current file
                fileData.stats = { success = 0, fails = 0, total = 0 }

                -- Iterate over each test within the file
                for testName, testData in pairs(fileData) do
                    -- We only process test data, not the file's stat table
                    if testName ~= "stats" then
                        local isSuccess = false

                        -- Perform the comparison
                        -- Both the result type (error/output) and content must match
                        local sameType = (testData.expected.error == testData.obtained.error)
                        local sameOutput = (testData.expected.output == testData.obtained.output)

                        if sameType and sameOutput then
                            isSuccess = true
                        end

                        -- Update status and counters based on the result
                        if isSuccess then
                            testData.status = "pass"
                            fileData.stats.success = fileData.stats.success + 1
                        else
                            testData.status = "fail"
                            fileData.stats.fails = fileData.stats.fails + 1
                        end

                        fileData.stats.total = fileData.stats.total + 1
                    end
                end

                -- Aggregate the file's statistics into the global statistics
                allTests.stats.success = allTests.stats.success + fileData.stats.success
                allTests.stats.fails = allTests.stats.fails + fileData.stats.fails
                allTests.stats.total = allTests.stats.total + fileData.stats.total
            end
        end
    end

    return allTests
end

--- Escapes special HTML characters in a string to prevent misinterpretation by browsers.
-- This is a security and rendering prerequisite before inserting arbitrary
-- text into an HTML document.
-- @local
-- @param str The string to escape.
-- @return The escaped string.
local function escapeHtml(str)
    local replacements = {
        ['&'] = '&amp;',
        ['<'] = '&lt;',
        ['>'] = '&gt;',
        ['"'] = '&quot;',
        ['\''] = '&#39;', -- &apos; is not supported in all HTML versions
    }
    return (tostring(str)):gsub('[&<>"]', replacements)..""
end

--- Compares two strings and generates HTML to visually highlight their differences.
--
-- Matched parts are wrapped in a `<span class="diff-match">`.
-- The first differing part of the expected string is wrapped in `<span class="diff-expected">`.
-- The first differing part of the obtained string is wrapped in `<span class="diff-obtained">`.
--
-- @param expectedStr The expected string result.
-- @param obtainedStr The obtained string result.
-- @return A table `{ expectedHtml = "...", obtainedHtml = "..." }` containing the
-- generated HTML for each string.
function lib.generateDiffHtml(expectedStr, obtainedStr)
    -- Gracefully handle nil or non-string inputs.
    expectedStr = tostring(expectedStr or "")
    obtainedStr = tostring(obtainedStr or "")
    
    -- If strings are identical, the whole string is a match.
    if expectedStr == obtainedStr then
        local escapedContent = escapeHtml(expectedStr)
        local html = ""
        if #escapedContent > 0 then
            html = "<span class=\"diff-match\">" .. escapedContent .. "</span>"
        end
        return { expectedHtml = html, obtainedHtml = html }
    end
    
    -- Find the first index where the strings diverge.
    local minLen = math.min(#expectedStr, #obtainedStr)
    local diffIndex = minLen + 1
    for i = 1, minLen do
        if expectedStr:byte(i) ~= obtainedStr:byte(i) then
            diffIndex = i
            break
        end
    end
    
    -- Split strings into matching and differing parts.
    local matchPartStr = expectedStr:sub(1, diffIndex - 1)
    local expectedDiffPartStr = expectedStr:sub(diffIndex)
    local obtainedDiffPartStr = obtainedStr:sub(diffIndex)
    
    -- Escape all parts for safe HTML rendering.
    local matchHtmlPart = escapeHtml(matchPartStr)
    local expectedDiffHtmlPart = escapeHtml(expectedDiffPartStr)
    local obtainedDiffHtmlPart = escapeHtml(obtainedDiffPartStr)
    
    -- Build the final HTML strings.
    local commonHtml = ""
    if #matchHtmlPart > 0 then
        commonHtml = "<span class=\"diff-match\">" .. matchHtmlPart .. "</span>"
    end
    
    local expectedHtml = commonHtml
    if #expectedDiffHtmlPart > 0 then
        expectedHtml = expectedHtml .. "<span class=\"diff-expected\">" .. expectedDiffHtmlPart .. "</span>"
    end
    
    local obtainedHtml = commonHtml
    if #obtainedDiffHtmlPart > 0 then
        obtainedHtml = obtainedHtml .. "<span class=\"diff-obtained\">" .. obtainedDiffHtmlPart .. "</span>"
    end
    
    return {
        expectedHtml = expectedHtml,
        obtainedHtml = obtainedHtml,
    }
end

--- Generates the complete HTML block for a single test result.
-- The output is a `<details>` block that is either collapsed (on pass) or
-- expanded (on fail). It includes the test name, status, source code, and a
-- detailed comparison view for failed tests.
-- @param testName A string representing the name of the test.
-- @param testData A table containing the test's `input`, `expected` result,
-- `obtained` result, and calculated `status` ("pass" or "fail").
-- @return A string containing the complete HTML for the test block.
function lib.generateTestBlockHtml(testName, testData)
    local htmlParts = {}
    
    local isFail = (testData.status == "fail")
    local detailsTag = isFail and "<details open>" or "<details>"
    local summaryClass = isFail and "status-fail" or "status-pass"
    local summaryIcon = isFail and "✗" or "✓"
    
    table.insert(htmlParts, detailsTag)
    
    -- 1. Create the summary (the clickable title bar)
    table.insert(htmlParts, "<summary>")
    table.insert(htmlParts, string.format(
        "<span class=\"status-icon %s\">%s</span> %s",
        summaryClass, summaryIcon, escapeHtml(testName)
    ))
    table.insert(htmlParts, "</summary>")
    
    -- 2. Create the content block inside <details>
    table.insert(htmlParts, "<div class=\"test-content\">")
    
    -- 2.1 Always show the Plume source code
    table.insert(htmlParts, "<h4>Code</h4>")
    table.insert(htmlParts, "<pre><code class=\"language-plume\">")
    table.insert(htmlParts, escapeHtml(testData.input))
    table.insert(htmlParts, "</code></pre>")
    
    if isFail then
        -- 2.2 For failed tests, show a detailed comparison grid
        local expectedType = testData.expected.error and "Error" or "Output"
        local obtainedType = testData.obtained.error and "Error" or "Output"

        local typeMismatchClass_Expected = ""
        local typeMismatchClass_Obtained = ""
        if testData.expected.error ~= testData.obtained.error then
            typeMismatchClass_Expected = " result-type-mismatch"
            typeMismatchClass_Obtained = " result-type-mismatch"
        end

        local diff = lib.generateDiffHtml(testData.expected.output, testData.obtained.output)
        
        table.insert(htmlParts, "<div class=\"comparison-grid\">")
        -- Headers
        table.insert(htmlParts, "<h4>Attendu</h4>")
        table.insert(htmlParts, "<h4>Obtenu</h4>")
        -- Content
        table.insert(htmlParts, string.format(
            "<div><div class=\"result-type-header%s\">%s</div><pre><code>%s</code></pre></div>",
            typeMismatchClass_Expected,
            expectedType,
            diff.expectedHtml
        ))
        table.insert(htmlParts, string.format(
            "<div><div class=\"result-type-header%s\">%s</div><pre><code>%s</code></pre></div>",
            typeMismatchClass_Obtained,
            obtainedType,
            diff.obtainedHtml
        ))
        table.insert(htmlParts, "</div>") 
    else
        -- 2.3 For passed tests, show the simple (correct) result
        local resultType = testData.expected.error and "Error" or "Output"
        table.insert(htmlParts, string.format("<h4>%s</h4>", resultType))
        table.insert(htmlParts, "<pre><code>")
        table.insert(htmlParts, escapeHtml(testData.expected.output))
        table.insert(htmlParts, "</code></pre>")
    end
    
    table.insert(htmlParts, "</div>") -- close test-content
    table.insert(htmlParts, "</details>")
    
    return table.concat(htmlParts, "\n")
end

--- A helper function to get tests from a file, sorted by status (fails first).
-- @local
-- @param fileData The table containing tests for a single file.
-- @return A new table containing the sorted test entries.
local function getSortedTests(fileData)
    local tests = {}
    for testName, testData in pairs(fileData) do
        -- We only want the test data, not the 'stats' key
        if testName ~= "stats" then
            table.insert(tests, { name = testName, data = testData })
        end
    end
    
    table.sort(tests, function(a, b)
        -- Fails first
        if a.data.status == "fail" and b.data.status ~= "fail" then return true end
        if a.data.status ~= "fail" and b.data.status == "fail" then return false end
        -- If status is the same, sort alphabetically by name for consistency
        return a.name < b.name
    end)
    
    return tests
end

local function generateStatsString(stats)
    local parts = {}
    if stats.success > 0 then
        table.insert(parts, string.format('%d success', stats.success))
    end
    if stats.fails > 0 then
        table.insert(parts, string.format('<span class="fail-count">%d</span> fails', stats.fails))
    end
    
    local text = table.concat(parts, " and ")
    
    local final_text
    if text == "" then
        if stats.total > 0 then
            final_text = string.format('on %d tests', stats.total)
        else
            final_text = "0 tests"
        end
    else
        final_text = string.format('%s on %d tests', text, stats.total)
    end
    
    return string.format('<span style="font-weight: normal;">%s</span>', final_text)
end

--- Generates a static HTML report file from the executed test results.
-- The function creates a self-contained HTML file with embedded CSS.
-- Tests within files are sorted with fails first.
-- Files are sorted by number of fails, descending.
-- @param allTests The main test table, populated with execution results and statistics.
-- It must contain a `stats` table at the root, and a `stats` table for each file entry.
-- @param outputPath The file path where the HTML report will be saved (e.g., "testReport.html").
-- @return boolean, string `true` on success, or `false` and an error message on failure.
function lib.generateReport(allTests, outputPath)
    local htmlParts = {}
    
    -- 1. HTML HEAD with embedded CSS
    table.insert(htmlParts, [[
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Test Plume</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f4f4f9; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; background-color: #fff;
            padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2 { padding-bottom: 0px; margin-bottom: 0px}
        h1 { font-size: 28px; } h2 { font-size: 24px; margin-top: 40px; }
        .fail-count { color: #c62828; font-weight: bold; }
        .progress-bar { display: flex; height: 8px; border-radius: 4px; overflow: hidden; background: #e0e0e0; margin-top: 5px; margin-bottom: 20px;}
        .progress-success { background-color: #2e7d32; }
        .progress-fail { background-color: #c62828; }
        details { border: 1px solid #ddd; border-radius: 4px; margin-bottom: 10px; overflow: hidden; }
        summary { cursor: pointer; padding: 12px; font-weight: bold; list-style: none; background-color: #fafafa}
        summary::-webkit-details-marker { display: none; }
        .status-icon { display: inline-block; width: 20px; text-align: center; font-weight: bold; }
        .status-pass { background-color: #e8f5e9; }
        .status-fail { background-color: #ffebee; }
        .status-pass .status-icon { color: #2e7d32; }
        .status-fail .status-icon { color: #c62828; }
        .test-content { padding: 0 15px 15px 15px; border-top: 1px solid #ddd; }
        h4 { margin-top: 15px; margin-bottom: 5px; font-weight: bold; font-size: 1.1em; }
        pre { background-color: #fdfdfd; color: #000; padding: 15px; border-radius: 4px;
            white-space: pre-wrap; word-wrap: break-word; font-family: "Courier New", Courier, monospace; border: 1px solid #ddd}
        .comparison-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 15px; }
        .comparison-grid h4 { margin: 0 0 5px 0; }
        .comparison-grid > div { border: 1px solid #ddd; padding: 8px; border-radius: 4px; background-color: #fdfdfd; }
        .comparison-grid pre { margin: 0; padding: 8px; border: none; background-color: transparent; }
        .diff-match { background-color: rgba(46, 125, 50, 0.1); }
        .diff-expected { background-color: rgba(25, 118, 210, 0.1); }
        .diff-obtained { background-color: rgba(198, 40, 40, 0.1);}
        .result-type-header { font-size: 0.85em; color: #555; font-style: italic; margin-bottom: 4px; padding-left: 2px; position: absolute; top:0; left: 50%; transform: translate(-50%,-50%); background: white;}
        .result-type-mismatch { color: #c62828; font-weight: bold; }
        .comparison-grid > div {position: relative}
    </style>
</head>
<body>
<div class="container">
    ]])
    
    -- 2. Global Header and Progress Bar
    local globalStats = allTests.stats or { success = 0, fails = 0, total = 0 }
    table.insert(htmlParts, string.format("<h1>Global: %s</h1>", generateStatsString(globalStats)))
    if globalStats.total > 0 then
        local successPercent = globalStats.success / globalStats.total * 100
        local failPercent = globalStats.fails / globalStats.total * 100
        table.insert(htmlParts, string.format(
            '<div class="progress-bar"><div class="progress-success" style="width: %.2f%%"></div><div class="progress-fail" style="width: %.2f%%"></div></div>',
            successPercent, failPercent
        ))
    end
    
    -- 3. Collect and sort files by number of fails (descending)
    local fileEntries = {}
    for fileName, fileData in pairs(allTests) do
        if fileName ~= "stats" and type(fileData) == 'table' then
            table.insert(fileEntries, { name = fileName, data = fileData })
        end
    end
    
    table.sort(fileEntries, function(a, b)
        local failsA = (a.data.stats and a.data.stats.fails) or 0
        local failsB = (b.data.stats and b.data.stats.fails) or 0
        if failsA ~= failsB then
            return failsA > failsB -- Sort by number of fails, descending
        end
        return a.name < b.name
    end)
    
    -- 4. Iterate through sorted files and their tests
    for _, entry in ipairs(fileEntries) do
        local fileName = entry.name
        local fileData = entry.data
        
        if fileData.stats then
            local cleanFileName = fileName:gsub("%.plume$", "")
            table.insert(htmlParts, string.format("<h2>%s: %s</h2>", escapeHtml(cleanFileName), generateStatsString(fileData.stats)))
            if fileData.stats.total > 0 then
                local successPercent = fileData.stats.success / fileData.stats.total * 100
                local failPercent = fileData.stats.fails / fileData.stats.total * 100
                table.insert(htmlParts, string.format(
                    '<div class="progress-bar"><div class="progress-success" style="width: %.2f%%"></div><div class="progress-fail" style="width: %.2f%%"></div></div>',
                    successPercent, failPercent
                ))
            end

            local sortedTests = getSortedTests(fileData)
            for _, test in ipairs(sortedTests) do
                table.insert(htmlParts, lib.generateTestBlockHtml(test.name, test.data))
            end
        end
    end
    
    -- 5. Close HTML tags
    table.insert(htmlParts, "</div></body></html>")
    
    -- 6. Write to file
    local finalHtml = table.concat(htmlParts, "\n")
    local file, err = io.open(outputPath, "w")
    
    if not file then
        return false, "Failed to open output file: " .. tostring(err)
    end
    
    file:write(finalHtml)
    file:close()
    
    return true
end

return lib