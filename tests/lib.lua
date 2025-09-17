-- Test engine loader and parser for the Plume language.
-- @module testLoader

local lfs = require("lfs")
local lpeg = require("lpeg")
local os = require("os")
local debug = require("debug")

local lib = {}

--- Normalizes a string by trimming whitespace and standardizing line endings to LF.
-- All line endings (\r\n, \r) are converted to \n. Leading and trailing
-- whitespace is removed.
-- @param s The input string or value to normalize.
-- @return The normalized string.
local function normalizeOutput(s)
    if s == false then
        s = "false"
    else
        s = tostring(s)
    end
    
    local withNl = s:gsub("\r\n", "\n"):gsub("\r", "\n")
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

    -- Capture the code block
    local codeContent = C((1 - (outputMarker + errorMarker))^0)

    -- Capture the expected result block
    local expectedContent = C((1 - endMarker)^0)

    -- A section representing expected output
    local outputSection = (outputMarker * expectedContent) / function(out)
        return { output = normalizeOutput(out), error = false }
    end

    -- A section representing an expected error
    local errorSection = (errorMarker * expectedContent) / function(err)
        return { output = normalizeOutput(err), error = true }
    end

    -- A complete test block
    local testBlock = (testHeader * codeContent * (outputSection + errorSection)) /
        function(testName, input, expectedData)
            return {
                key = testName,
                value = {
                    input = input,
                    expected = expectedData,
                    obtained = {},
                },
            }
        end

    -- Grammar for an entire file
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
        if filename ~= "." and filename ~= ".." and filename:match("%.plume$") then
            local fullPath = path .. "/" .. filename
            local file, err = io.open(fullPath, "r")

            if file then
                local content = file:read("*a")
                file:close()
                
                local parsedTests = parseTestFile(content)
                if parsedTests then
                    allTests[filename] = parsedTests
                else
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
-- @param allTests The table of tests loaded by `lib.loadTests`.
-- @param plumeEngine The Plume engine object. Must contain an `execute` method.
-- @return The `allTests` table, populated with execution results.
function lib.executeTests(allTests, plumeEngine)
    local TIMEOUT_SECONDS = 1
    
    for filename, tests in pairs(allTests) do
        if not tests.error then
            for testName, testData in pairs(tests) do
                
                -- Timeout implementation
                local start_time = os.clock()
                local function timeout_hook()
                    if os.clock() - start_time > TIMEOUT_SECONDS then
                        debug.sethook() -- Disable hook before erroring
                        error("timeout")
                    end
                end
                
                -- Set hook to run every 1,000,000 instructions
                debug.sethook(timeout_hook, "", 1000000)
                
                local chunk = plumeEngine.newPlumeExecutableChunk(true)
                chunk.name = "main"
                local x, y, z = pcall(
                    plumeEngine.execute,
                    testData.input,
                    testName,
                    chunk
                )
                
                -- CRITICAL: Always disable the hook after the pcall completes
                debug.sethook()

                if not x and y == "timeout" then
                    -- The test timed out
                    testData.obtained = {
                        output = string.format("TIMEOUT: Execution exceeded %d second(s).", TIMEOUT_SECONDS),
                        bytecode = nil,
                        error = true,
                    }
                else
                    -- Standard execution path (success or other error)
                    local success, result
                    if x then
                        success = y
                        result = z
                    else
                        success = false
                        result = y
                    end

                    if success then
                        result = plumeEngine.std.tostring.callable({table={result}})
                    end

                    -- Process bytecode state for single or multiple chunks
                    local bytecode_info
                    local numChunks = 0
                    if chunk and chunk.state then
                        numChunks = #chunk.state
                    end

                    if numChunks <= 1 then
                        bytecode_info = {
                            is_multi = false,
                            grid = chunk.bytecode and plumeEngine.debug.bytecodeGrid(chunk)
                        }
                    else
                        local chunks_list = {}
                        for _, subChunk in ipairs(chunk.state) do
                            if subChunk.bytecode and #subChunk.bytecode > 0 then
                                table.insert(chunks_list, {
                                    name = subChunk.name or "???",
                                    grid = plumeEngine.debug.bytecodeGrid(subChunk)
                                })
                            end
                        end
                        
                        table.sort(chunks_list, function(a, b) return a.name < b.name end)

                        if #chunks_list <= 1 then
                             bytecode_info = {
                                is_multi = false,
                                grid = chunks_list[1] and chunks_list[1].grid or nil
                            }
                        else
                            bytecode_info = {
                                is_multi = true,
                                chunks = chunks_list
                            }
                        end
                    end

                    testData.obtained = {
                        output = normalizeOutput(result),
                        bytecode = bytecode_info,
                        error = not success,
                    }
                end
            end
        end
    end
    
    return allTests
end

--- Analyzes executed test results and calculates statistics.
-- This function modifies the input table in-place by adding a `status` field
-- to each test and `stats` tables at the global and file levels.
-- @param allTests The table of tests, populated by `lib.executeTests`.
-- @return The modified `allTests` table.
function lib.analyzeResults(allTests)
    allTests.stats = { success = 0, fails = 0, total = 0 }

    for filename, fileData in pairs(allTests) do
        if filename ~= "stats" then
            if fileData.error then
                -- Skip files that had loading or parsing errors
            else
                fileData.stats = { success = 0, fails = 0, total = 0 }

                for testName, testData in pairs(fileData) do
                    if testName ~= "stats" then
                        -- Both the result type (error/output) and content must match
                        local sameType = (testData.expected.error == testData.obtained.error)
                        local sameOutput = (testData.expected.output == testData.obtained.output)

                        if sameType and sameOutput then
                            testData.status = "pass"
                            fileData.stats.success = fileData.stats.success + 1
                        else
                            testData.status = "fail"
                            fileData.stats.fails = fileData.stats.fails + 1
                        end

                        fileData.stats.total = fileData.stats.total + 1
                    end
                end

                -- Aggregate file statistics into global statistics
                allTests.stats.success = allTests.stats.success + fileData.stats.success
                allTests.stats.fails = allTests.stats.fails + fileData.stats.fails
                allTests.stats.total = allTests.stats.total + fileData.stats.total
            end
        end
    end

    return allTests
end


--- Escapes special HTML characters in a string.
-- @local
-- @param str The string to escape.
-- @return The escaped string.
local function escapeHtml(str)
    if str == nil then return "" end
    local replacements = {
        ['&'] = '&amp;',
        ['<'] = '&lt;',
        ['>'] = '&gt;',
        ['"'] = '&quot;',
        ['\''] = '&#39;',
    }
    return (tostring(str)):gsub('[&<>"\']', replacements)
end

--- Compares two strings and generates HTML to visually highlight their differences.
-- @param expectedStr The expected string result.
-- @param obtainedStr The obtained string result.
-- @return A table `{ expectedHtml = "...", obtainedHtml = "..." }`.
function lib.generateDiffHtml(expectedStr, obtainedStr)
    expectedStr = tostring(expectedStr or "")
    obtainedStr = tostring(obtainedStr or "")
    
    if expectedStr == obtainedStr then
        local escapedContent = escapeHtml(expectedStr)
        local html = ""
        if #escapedContent > 0 then
            html = "<span class=\"diff-match\">" .. escapedContent .. "</span>"
        end
        return { expectedHtml = html, obtainedHtml = html }
    end
    
    local minLen = math.min(#expectedStr, #obtainedStr)
    local diffIndex = minLen + 1
    for i = 1, minLen do
        if expectedStr:byte(i) ~= obtainedStr:byte(i) then
            diffIndex = i
            break
        end
    end
    
    local matchPartStr = expectedStr:sub(1, diffIndex - 1)
    local expectedDiffPartStr = expectedStr:sub(diffIndex)
    local obtainedDiffPartStr = obtainedStr:sub(diffIndex)
    
    local matchHtmlPart = escapeHtml(matchPartStr)
    local expectedDiffHtmlPart = escapeHtml(expectedDiffPartStr)
    local obtainedDiffHtmlPart = escapeHtml(obtainedDiffPartStr)
    
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

--- Generates HTML for the content of a bytecode grid.
-- @param bytecodeGrid The bytecode table.
-- @return A string containing the formatted HTML lines.
local function formatBytecodeGrid(bytecodeGrid)
    if not bytecodeGrid or #bytecodeGrid == 0 then
        return '<span class="no-bytecode">Bytecode not generated or unavailable.</span>'
    end

    local htmlLines = {}
    for i, op in ipairs(bytecodeGrid) do
        local lineParts = {}
        
        -- Line number
        table.insert(lineParts, string.format('<span class="bc-line-num">%03d</span>', i))
        
        -- Opcode name (fixed column for alignment)
        table.insert(lineParts, string.format('<span class="bc-opcode">%-16s</span>', escapeHtml(op[2])))
        
        -- Arguments
        local args = {}
        if op[3] ~= nil then table.insert(args, escapeHtml(op[3])or"") end
        if op[4] ~= nil then table.insert(args, escapeHtml(op[4])or"") end
        if #args > 0 then
            table.insert(lineParts, string.format('<span class="bc-arg">%s</span>', table.concat(args, " ")))
        end
        
        -- Optional info (like a comment)
        if op[5] and #op[5]>0 then
            table.insert(lineParts, string.format('<span class="bc-info">; %s</span>', escapeHtml(op[5])))
        end
        
        table.insert(htmlLines, table.concat(lineParts, " "))
    end
    
    return table.concat(htmlLines, "\n")
end

local bytecodeTabCounter = 0
--- Generates the complete HTML for displaying bytecode, handling single or multiple chunks.
-- @param bytecode_info The bytecode info structure.
-- @return A string containing the formatted HTML block.
local function generateBytecodeDisplayHtml(bytecode_info)
    if not bytecode_info or (not bytecode_info.is_multi and not bytecode_info.grid) then
        return '<pre><code class="language-bytecode"><span class="no-bytecode">Bytecode not generated or unavailable.</span></code></pre>'
    end

    if not bytecode_info.is_multi then
        local grid_html = formatBytecodeGrid(bytecode_info.grid)
        return string.format("<pre><code class=\"language-bytecode\">%s</code></pre>", grid_html)
    end

    if not bytecode_info.chunks or #bytecode_info.chunks == 0 then
        return '<pre><code class="language-bytecode"><span class="no-bytecode">No bytecode chunks found.</span></code></pre>'
    end
    
    bytecodeTabCounter = bytecodeTabCounter + 1
    local id_prefix = "bc_tabs_" .. bytecodeTabCounter

    local html = {}
    table.insert(html, '<div class="tab-container">')
    
    -- Tab headers
    table.insert(html, '<div class="tab-headers">')
    for i, chunkData in ipairs(bytecode_info.chunks) do
        local tabId = id_prefix .. "_content_" .. i
        local activeClass = (i == 1) and " active" or ""
        table.insert(html, string.format(
            '<button class="tab-link%s" onclick="openBytecodeTab(event, \'%s\')">%s</button>',
            activeClass, tabId, escapeHtml(chunkData.name)
        ))
    end
    table.insert(html, '</div>')

    -- Tab content
    for i, chunkData in ipairs(bytecode_info.chunks) do
        local tabId = id_prefix .. "_content_" .. i
        local displayStyle = (i == 1) and "block" or "none"
        table.insert(html, string.format('<div id="%s" class="tab-content" style="display: %s;">', tabId, displayStyle))
        
        local grid_html = formatBytecodeGrid(chunkData.grid)
        table.insert(html, string.format("<pre><code class=\"language-bytecode\">%s</code></pre>", grid_html))

        table.insert(html, '</div>')
    end

    table.insert(html, '</div>')
    return table.concat(html, '\n')
end

--- Generates the complete HTML block for a single test result.
-- @param testName The name of the test.
-- @param testData A table containing the test's data and results.
-- @return A string containing the complete HTML for the test block.
function lib.generateTestBlockHtml(testName, testData)
    local htmlParts = {}
    
    local isFail = (testData.status == "fail")
    local detailsTag = isFail and "<details open>" or "<details>"
    local summaryClass = isFail and "status-fail" or "status-pass"
    local summaryIcon = isFail and "✗" or "✓"
    
    table.insert(htmlParts, detailsTag)
    
    table.insert(htmlParts, "<summary>")
    table.insert(htmlParts, string.format(
        "<span class=\"status-icon %s\">%s</span> %s",
        summaryClass, summaryIcon, escapeHtml(testName)
    ))
    table.insert(htmlParts, "</summary>")
    
    table.insert(htmlParts, "<div class=\"test-content\">")
    table.insert(htmlParts, "<div class=\"code-grid\">")
    
    -- Column 1: Plume source code
    table.insert(htmlParts, "<div>")
    table.insert(htmlParts, "<h4>Code</h4>")
    table.insert(htmlParts, "<pre><code class=\"language-plume\">")
    table.insert(htmlParts, escapeHtml(testData.input) or "")
    table.insert(htmlParts, "</code></pre>")
    table.insert(htmlParts, "</div>")

    -- Column 2: Bytecode (now capable of showing tabs)
    table.insert(htmlParts, "<div>")
    table.insert(htmlParts, "<h4>Bytecode</h4>")
    table.insert(htmlParts, generateBytecodeDisplayHtml(testData.obtained.bytecode))
    table.insert(htmlParts, "</div>")

    table.insert(htmlParts, "</div>") -- close code-grid

    if isFail then
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
        table.insert(htmlParts, "<h4>Expected</h4>")
        table.insert(htmlParts, "<h4>Obtained</h4>")
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
        local resultType = testData.expected.error and "Error" or "Output"
        table.insert(htmlParts, string.format("<h4>%s</h4>", resultType))
        table.insert(htmlParts, "<pre><code>")
        table.insert(htmlParts, escapeHtml(testData.expected.output)or"")
        table.insert(htmlParts, "</code></pre>")
    end
    
    table.insert(htmlParts, "</div>") 
    table.insert(htmlParts, "</details>")
    
    return table.concat(htmlParts, "\n")
end

--- Helper function to get tests from a file, sorted by status (fails first).
-- @local
-- @param fileData The table containing tests for a single file.
-- @return A new table containing the sorted test entries.
local function getSortedTests(fileData)
    local tests = {}
    for testName, testData in pairs(fileData) do
        if testName ~= "stats" then
            table.insert(tests, { name = testName, data = testData })
        end
    end
    
    table.sort(tests, function(a, b)
        if a.data.status == "fail" and b.data.status ~= "fail" then return true end
        if a.data.status ~= "fail" and b.data.status == "fail" then return false end
        return a.name < b.name
    end)
    
    return tests
end

local function generateStatsString(stats)
    local parts = {}
    if stats.success > 0 then
        table.insert(parts, string.format('%d passed', stats.success))
    end
    if stats.fails > 0 then
        table.insert(parts, string.format('<span class="fail-count">%d</span> failed', stats.fails))
    end
    
    local text = table.concat(parts, " and ")
    
    local final_text
    if text == "" then
        if stats.total > 0 then
            final_text = string.format('out of %d tests', stats.total)
        else
            final_text = "0 tests"
        end
    else
        final_text = string.format('%s out of %d tests', text, stats.total)
    end
    
    return string.format('<span style="font-weight: normal;">%s</span>', final_text)
end

--- Generates a static HTML report file from the executed test results.
-- @param allTests The main test table, populated with results and statistics.
-- @param outputPath The file path where the HTML report will be saved.
-- @return boolean, string `true` on success, or `false` and an error message on failure.
function lib.generateReport(allTests, outputPath)
    local htmlParts = {}
    
    table.insert(htmlParts, [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Plume Test Report</title>
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
        .test-content { padding: 15px; border-top: 1px solid #ddd; }
        h4 { margin-top: 5px; margin-bottom: 5px; font-weight: bold; font-size: 1.1em; }
        pre { background-color: #fdfdfd; color: #000; padding: 15px; border-radius: 4px;
            white-space: pre-wrap; word-wrap: break-word; font-family: "Courier New", Courier, monospace; border: 1px solid #ddd; }
        
        .code-grid {
            display: grid;
            /* MODIFICATION : La 1ère colonne (Code) prend l'espace restant, la 2ème (Bytecode) a une largeur fixe. */
            grid-template-columns: 1fr 500px;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .code-grid > div {
            display: flex;
            flex-direction: column;
        }

        .code-grid h4 { 
            margin: 0 0 8px 0; 
            flex-shrink: 0;
        }

        .code-grid > div > pre, .code-grid > div > .tab-container {
            flex-grow: 1;
            min-height: 0;
            margin: 0;
        }
        .code-grid > div > .tab-container .tab-content {
             max-height: 400px;
             overflow: auto;
             display: flex;
             flex-direction: column;
        }
        .code-grid > div > .tab-container .tab-content pre {
            flex-grow: 1;
        }
        
        .code-grid > div > pre {
            max-height: 400px;
            overflow: auto;
        }

        .language-bytecode { white-space: pre; }
        .no-bytecode { color: #888; font-style: italic; }
        .bc-line-num { color: #999; }
        .raw-opcode { color: #999; }
        .bc-opcode { color: #0d47a1; font-weight: bold; }
        .bc-arg { color: #d81b60; }
        .bc-info { color: #4caf50; font-style: italic; }

        .comparison-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 15px; }
        .comparison-grid h4 { margin: 0 0 5px 0; }
        .comparison-grid > div { border: 1px solid #ddd; padding: 8px; border-radius: 4px; background-color: #fdfdfd; }
        .comparison-grid > div {position: relative}
        .comparison-grid pre { padding: 8px; border: none; background-color: transparent; overflow-y: auto; max-height: 400px; }
        .diff-match { background-color: rgba(46, 125, 50, 0.1); }
        .diff-expected { background-color: rgba(25, 118, 210, 0.1); }
        .diff-obtained { background-color: rgba(198, 40, 40, 0.1);}
        .result-type-header { font-size: 0.85em; color: #555; font-style: italic; margin-bottom: 4px; padding-left: 2px; position: absolute; top:0; left: 50%; transform: translate(-50%,-50%); background: white;}
        .result-type-mismatch { color: #c62828; font-weight: bold; }

        /* Styles for Bytecode Tabs */
        .tab-container { border: 1px solid #ddd; border-radius: 4px; overflow: hidden; }
        .tab-headers { display: flex; flex-wrap: wrap; background-color: #f1f1f1; border-bottom: 1px solid #ddd; }
        .tab-link { background-color: inherit; border: none; outline: none; cursor: pointer; padding: 8px 12px; transition: 0.2s; font-size: 0.9em; }
        .tab-link:hover { background-color: #ddd; }
        .tab-link.active { background-color: #fff; font-weight: bold; position: relative; }
        .tab-content { display: none; padding: 0; }
        .tab-content pre { margin: 0; border: none; border-radius: 0; }
    </style>
</head>
<body>
<div class="container">
    ]])
    
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
    
    table.insert(htmlParts, [[
</div>

<script>
function openBytecodeTab(evt, tabId) {
    var i, tabcontent, tablinks;
    var container = evt.currentTarget.closest('.tab-container');
    if (!container) return;

    tabcontent = container.getElementsByClassName("tab-content");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }

    tablinks = container.getElementsByClassName("tab-link");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }

    var tabToShow = document.getElementById(tabId);
    if(tabToShow) {
        tabToShow.style.display = "block";
    }
    evt.currentTarget.className += " active";
}
</script>

</body></html>
    ]])
    
    local finalHtml = table.concat(htmlParts, "\n")
    local file, err = io.open( outputPath, "w" )
    
    if not file then
        return false, "Failed to open output file: " .. tostring(err)
    end
    
    file:write(finalHtml)
    file:close()
    
    return true
end

return lib