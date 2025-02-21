local file_list = {
    "parser/expressionPatterns",
    "parser/parser",
    "parser/statementPatterns",
    "beautifier",
    "error",
    "init",
    "luaTranspiler",
    "makeAST",
    "patterns",
    "plume",
    "plumeDebug",
    "tokenizer",
    "utils"
}

local plume_code = {}
for _, path in ipairs(file_list) do
    local source = io.open("plume-engine/" .. path .. ".lua"):read "*a"

    -- Remove license
    source = source:gsub('^%-%-%[%[.-%]%]', '')

    -- Extract version
    version = version or source:match('plume%._VERSION = "Plume🪶 (.-)"')
    if path == "init" then
        print()
    end

    table.insert(plume_code, "\nplume_files['plume-engine/" .. path.. "'] = function ()\n")
    table.insert(plume_code, source)
    table.insert(plume_code, "\nend\n")
end

table.insert(plume_code, "plume = require('plume-engine/init')")

local html = io.open("website/template.html"):read('*a')

html = html:gsub('{{VERSION}}', function () return version end)
html = html:gsub('{{PLUME}}', function () return table.concat(plume_code) end)
html = html:gsub('{{CSS}}', function () return io.open("website/style.css"):read('*a') end)

io.open("website/plume.html", "w"):write(html)