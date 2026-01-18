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

local lfs = require("lfs")

local directory = "plume-data/engine/vm"

-- Fonction pour lire le contenu d'un fichier
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

-- Fonction de parsing principale
local function parse_file(filename, content)
    local results = {}
    
    -- Pattern pour capturer le bloc de commentaire avant une fonction
    -- On cherche @opcode suivi de tout jusqu'à "function"
    for block, func_name in content:gmatch("(%-%-%- @opcode.-)%s+function%s+([%w_]+)") do
        local entry = {
            name = func_name,
            comment = "",
            params = {}
        }
        
        -- Extraction du commentaire général (lignes commençant par --- sans @ ni --!)
        for line in block:gmatch("%-%-%-%s*([^\n@!]+)") do
            local clean_line = line:gsub("%s*$", "")
            if #clean_line > 0 then
            	if clean_line:sub(1, 1) == clean_line:sub(1, 1):upper() then
            		clean_line = "<br>" .. clean_line
            	end
                entry.comment = entry.comment .. clean_line .. " "
            end
        end

        -- Extraction des paramètres (@param name type COMMENT)
        for p_name, p_type, p_doc in block:gmatch("@param%s+([%w_]+)%s+([%w_]+)%s+([^\n]+)") do
            table.insert(entry.params, {
                name = p_name,
                type = p_type,
                doc = p_doc
            })
        end
        
        table.insert(results, entry)
    end
    
    return results
end

local opcodedoc = {}
-- Parcours du dossier
for file in lfs.dir(directory) do
    if file:match("^.*%.lua$") then
        local path = directory .. "/" .. file
        local content = read_file(path)
        
        if content then
            local data = parse_file(file, content)
            
            if #data > 0 then
                table.insert(opcodedoc, "\n### vm/" .. file .. "\n")
                
                for _, func in ipairs(data) do
                    table.insert(opcodedoc, "\n#### " .. func.name .. "\n")
                    table.insert(opcodedoc, func.comment  .. "\n")
                    
                    if #func.params > 0 then
                        table.insert(opcodedoc, "")
                        for _, p in ipairs(func.params) do
                            table.insert(opcodedoc, string.format("- **%s** *(%s)*: %s\n", p.name, p.type, p.doc))
                        end
                    end
                end
            end
        end
    end
end

local doc = table.concat(opcodedoc)

local f = io.open("build-tools/vm.md")
	local source = f:read("*a")
f:close()

f = io.open("doc/vm.md", "w")
	f:write((source:gsub('$', doc)))
f:close()