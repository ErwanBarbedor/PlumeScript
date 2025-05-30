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

-- This module provides caching functionality for the Plume transpilation process.
-- It allows storing and retrieving transpiled Lua code and source maps to avoid
-- redundant transpilation of unchanged Plume source files.

return function (plume)
    local buffer = require("string.buffer")
    local bit = require("bit")
    local lfs = require("lfs")

    -- Constants for the FNV-1a 32-bit hash algorithm.
    -- FNV-1a is a non-cryptographic hash function valued for speed and good distribution.
    local FNV1A_32_OFFSET_BASIS = 2166136261 -- 0x811c9dc5, the initial hash value (offset basis).
    local FNV1A_32_PRIME        = 16777619   -- 0x01000193, the prime multiplier for FNV-1a.

    --- Computes the FNV-1a 32-bit hash of a given string.
    --- The hash is returned as an 8-character, zero-padded hexadecimal string.
    --- @param s string The input string to hash.
    --- @return string The FNV-1a 32-bit hash value, formatted as an 8-digit hexadecimal string.
    function fnv1a32(s)
        local hash = FNV1A_32_OFFSET_BASIS

        for i = 1, #s do
            local byte_value = string.byte(s, i)
            hash = bit.bxor(hash, byte_value) -- XOR the current hash with the current byte.
            
            -- Multiply by the FNV prime.
            -- bit.tobit ensures the result is truncated to a 32-bit integer
            hash = bit.tobit(hash * FNV1A_32_PRIME)
        end

        -- Format the 32-bit integer hash
        return string.format("%08x", hash)
    end

    --- Loads the Plume cache index
    --- @return table {filename={date=date, plumeVersion}}
    function plume.loadCache()
        -- The cache index is expected to be stored at '.plume-cache/index'.
        -- Open for reading ('r' is default, but explicit can be clearer).
        local f = io.open('.plume-cache/index') 
        local index = {}
        if f then
            local content = f:read("*a")
            f:close()
            
            for line in content:gmatch('[^\n]+') do
                -- Each line is expected to be in the format: <hashed_filename> <plume_version_string> <timestamp_string>
                local filename, plumeVersion, os, date = line:match('(%S+)%s+(%S+)%s+(%S+)%s+(%S+)')
                if filename then
                    index[filename] = {
                        plumeVersion = plumeVersion,
                        date         = tonumber(date),
                        os           = os
                    }
                end
            end
        end
        -- If the file doesn't exist or io.open failed, 'f' is nil, and an empty index is returned.
        return index
    end

    --- Saves the Plume cache index and any new transpiled files to the filesystem.
    --- @param index table
    function plume.saveCache(index)
        local f
        lfs.mkdir(".plume-cache")

        f = io.open('.plume-cache/index', "w")
        if f then
            for filename, infos in pairs(index) do

                f:write(table.concat({filename, infos.plumeVersion, infos.os, infos.date}, " ") .. "\n")

                -- Save newCode and newMap if exists
                if infos.newCode then
                    local code_file = io.open('.plume-cache/' .. filename .. ".lua", "w")
                    if code_file then -- Check if file opened successfully
                        code_file:write(infos.newCode)
                        code_file:close()
                    end
                end
                if infos.newMap then
                    local map_file = io.open('.plume-cache/' .. filename .. ".map", "w")
                    if map_file then
                        map_file:write(buffer.encode(infos.newMap))
                        map_file:close()
                    end
                end
            end
            f:close()
        else
            error("Cannot write '.plume-cache/index'.")
        end
    end

    --- Loads transpiled Lua code and its source map for a given Plume file from the cache.
    --- @param filename string The path to the original Plume source file 
    --- @return string The transpiled Lua code.
    --- @return table? The source map data for the transpiled code
    function plume.loadOrTranspile(filename, env)
        local luaCode, luaMap, cache, index, internalFilename

        if env.config.package.caching then
            -- hash the filename
            internalFilename = fnv1a32(filename)
            index = plume.loadCache()
            cache = index[internalFilename]
        end

        -- Check if cache is valid
        -- check version
        if cache and plume._VERSION ~= cache.plumeVersion then
            cache = nil
        end

        -- check os (luajit serialization not compatible between differents OS)
        if cache and cache.os ~= jit.os then
            cache = nil
        end

        -- check modification
        if cache then
            local date = lfs.attributes(filename, "modification")
            if date > cache.date then
                cache = nil
            end
        end

        if cache then
            local luaCodePath = '.plume-cache/' .. internalFilename .. ".lua"
            local mapPath     = '.plume-cache/' .. internalFilename .. ".map"

            local f = io.open(luaCodePath)
            if f then
                luaCode = f:read("*a")
                f:close()
            else
                cache = nil
            end

            f = io.open(mapPath)
            if f then
                luaMap = buffer.decode(f:read("*a"))
                f:close()
            else
                cache = nil 
            end
        end

        -- If no valid cache entry was found , transpile the source file.
        if not cache then
            local plume_source_file = io.open(filename)
            if not plume_source_file then
                error("Cannot open file '" .. filename .. "'")
            end
            local plumeCode = plume_source_file:read('*a')
            plume_source_file:close()

            luaCode, luaMap = plume.transpile(plumeCode, filename)

            if env.config.package.caching then 
                -- Cache informations
                index[internalFilename] = {
                    date         = os.time(), 
                    plumeVersion = plume._VERSION,
                    newCode      = luaCode,
                    newMap       = luaMap,
                    os           = jit.os
                }
                
                plume.saveCache(index)
            end
        end
        
        return luaCode, luaMap
    end
end
