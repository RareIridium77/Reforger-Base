if not Reforger then return end

-- Engines for simfphys and glide (damage and etc)

Reforger.Log("Reforger Engines Loaded (Simfphys, Glide)")

local VehBase = Reforger.VehicleBases

local function SpawnEngine(veh, offset)
    if not IsValid(veh) then return end

    local ent = ents.Create("reforger_engine")
    ent:SetVehicleBase(veh)
    ent:SetEngineData(veh.reforgerEngine)
    ent:Spawn()

    veh.reforgerEngine.entity = ent
end

function Reforger.CacheEngine(veh)
    if not Reforger.IsValidReforger(veh) then return end
    local base = veh.reforgerBase
    if base == VehBase.LVS or base == nil then return end

    if veh.reforgerEngine and IsValid(veh.reforgerEngine.entity) then
        veh.reforgerEngine.entity:Remove()
        veh.reforgerEngine.entity = nil
    end

    local engine_offset = Vector(0, 0, 0)

    if base == VehBase.Simfphys and veh.EnginePos then
        engine_offset = veh.EnginePos
    elseif base == VehBase.Glide and istable(veh.EngineFireOffsets) and istable(veh.EngineFireOffsets[1]) then
        engine_offset = veh:LocalToWorld(veh.EngineFireOffsets[1].offset)
    end

    veh.reforgerEngine = {
        offset = engine_offset,
        world_coords = false
    }
    
    SpawnEngine(veh, engine_offset)
end

-- shit is lower

local function FormatValue(v)
    if isvector(v) then
        return string.format("Vector(%.2f, %.2f, %.2f)", v.x, v.y, v.z)
    elseif isangle(v) then
        return string.format("Angle(%.2f, %.2f, %.2f)", v.p, v.y, v.r)
    elseif isentity(v) and IsValid(v) then
        return "Entity [" .. v:GetClass() .. "]"
    elseif istable(v) then
        return "table (" .. tostring(v) .. ")"
    elseif type(v) == "string" then
        return "\"" .. v .. "\""
    else
        return tostring(v)
    end
end

local function PrintTableRecursive(tbl, indent, visited)
    visited = visited or {}
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    for k, v in pairs(tbl) do
        if type(v) ~= "function" then
            local keyStr = tostring(k)
            if istable(v) then
                print(prefix .. keyStr .. " = {")
                if not visited[v] then
                    visited[v] = true
                    PrintTableRecursive(v, indent + 1, visited)
                else
                    print(prefix .. "  ")
                end
                print(prefix .. "}")
            else
                print(prefix .. keyStr .. " = " .. FormatValue(v))
            end
        end
    end
end

concommand.Add("reforger.dump.vehicle", function(ply)
    if not Reforger.AdminDevToolValidation(ply) then return end

    local ent = ply:GetEyeTrace().Entity
    if not Reforger.IsValidReforger(ent) then return ply:ChatPrint("[Reforger] Aim at Vehicle.") end

    ply:ChatPrint("[Reforger] Printing Table...")
    print("[Reforger] --- ENTITY TABLE --- [" .. tostring(ent) .. "] ---")
    PrintTableRecursive(ent:GetTable())
    print("[Reforger] --- END ---")
    ply:ChatPrint("[Reforger] Ready.")
end)

local function SearchTable(tbl, searchTerm, path, visited)
    visited = visited or {}
    searchTerm = string.lower(searchTerm)

    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        local currentPath = path .. "." .. keyStr

        if type(v) ~= "function" then
            local match = false

            if string.find(string.lower(keyStr), searchTerm, 1, true) then
                match = true
            end

            local valStr = FormatValue(v)
            if string.find(string.lower(valStr), searchTerm, 1, true) then
                match = true
            end

            if match then
                print(currentPath .. " = " .. valStr)
            end

            if istable(v) and not visited[v] then
                visited[v] = true
                SearchTable(v, searchTerm, currentPath, visited)
            end
        end
    end
end

concommand.Add("reforger.search.data", function(ply, cmd, args)
    if not Reforger.AdminDevToolValidation(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not Reforger.IsValidReforger(ent) then
        ply:ChatPrint("[Reforger] Aim at vehicle.")
        return
    end

    local search = args[1]
    if not search or search == "" then
        ply:ChatPrint("[Reforger] Send key word in arguments (only one argument)")
        return
    end

    ply:ChatPrint("[Reforger] Searching for \"" .. search .. "\"...")

    local tbl = ent:GetTable()
    SearchTable(tbl, search, ent:GetClass())

    ply:ChatPrint("[Reforger] Searching end.")
end)