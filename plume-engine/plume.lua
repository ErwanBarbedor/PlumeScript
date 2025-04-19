local function importFunction (f)
    return function(...) return f((unpack or table.unpack)(...)) end
end

local function importAllFunction (t, tcache, tcacheNames)
    local result = {}
    tcache = tcache or {}
    tcacheNames = tcacheNames or {}

    for k, v in pairs(t) do
        if type(v) == "function" then
            result[k] = importFunction(v)
        elseif type(v) == "table" then
            if not tcacheNames[v] then
                tcacheNames[v] = true
                tcache[v] = importAllFunction (v, tcache, tcacheNames)
            end
            result[k] = tcache[v]
        end
    end

    return result
end

return function(plume)
    plume.plumeStdLib = {table={}, _VERSION = plume._VERSION}

    plume.luaStdLib = importAllFunction(_G)
    plume.envStdLib    = {}

    if table.move then
        function plume.plumeStdLib.table.merge(...)
            local result = {}
            local index = 1

            for i = 1, select('#', ...) do
                local tbl = select(i, ...)
                if tbl then
                    local len = #tbl
                    table.move(tbl, 1, len, index, result)
                    index = index + len
                end
            end

          return result
        end
    else
        function plume.plumeStdLib.table.merge(...)
            local result = {}
            local index = 1

            for _, tbl in ipairs({...}) do
                if tbl then
                    for j = 1, #tbl do
                        result[index] = tbl[j]
                        index = index + 1
                    end
                end
            end

            return result
        end
    end
    
    function plume.initRuntime ()
        local result = {plume = {}, __lua = _G}

        for k, v in pairs(plume.plumeStdLib) do
            result.plume[k] = v
        end

        for k, v in pairs(plume.luaStdLib) do
            result[k] = v
        end

        for k, v in pairs(plume.envStdLib) do
            result[k] = function (...) return v(result, ...) end
        end

        result.plume.package = {
            loaded = {},
            path   = {"./<name>.<ext>"}
        }

        result._G = result

        return result
    end

    function plume.plumeStdLib.checkConcat(x)
        local t = type(x)
        if t == "nil" then
            return ""
        elseif t == "table" then
            if type(getmetatable(t).__tostring) == "function" then
                return tostring(t)
            else
                error("Cannot convert table to string implicitly.", 2)
            end
        else
            return x
        end
    end

    function plume.envStdLib.require(env, __plume_args)
        local libname     = __plume_args[1]
        local exts        = __plume_args[2] or __plume_args.ext or 'plume lua'
        local triedPath   = {}
        local file, filename, fileext

        for ext in exts:gmatch "%S+" do
            for _, basepath in ipairs(env.plume.package.path) do
                local path = basepath:gsub('<name>', libname):gsub('<ext>', ext)
                file = io.open(path)

                if file then
                    filename, fileext = path, ext
                    break
                else
                    table.insert(triedPath, path)
                end
            end

            if file then
                break
            end
        end

        if file then
            if fileext == "plume" then
                local code = file:read("*a")
                file:close()
                return plume.run(code, filename, env)
            elseif fileext == "lua" then
                file:close()
                local code, err
                
                if _VERSION == "Lua 5.1" or jit then
                    chunk, err = loadfile(filename)
                    if not chunk then
                        error("Error when loading '" .. filename .. "': " .. tostring(err))
                    end
                    setfenv(chunk, env)
                    return chunk()
                -- Lua 5.2+
                else
                    chunk, err = loadfile(filename, "t", env)
                    if not chunk then
                        error("Error when loading '" .. filename .. "': " .. tostring(err))
                    end
                    return chunk()
                end
            else
                -- error
                error("File '" .. filename .. "' found, but plume doesn't know how to handle '" .. fileext .. "' files.")
            end
        else
            msg = {"Module '" .. libname .. "' not found:"}
            for _, path in ipairs(triedPath) do
                table.insert(msg, "    no file '" .. path .. "'")
            end
            error(table.concat(msg, "\n"))
        end
    end
end