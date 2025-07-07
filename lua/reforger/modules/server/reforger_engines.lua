if not Reforger then return end

-- Engines for simfphys and glide (damage and etc)

Reforger.Log("Reforger Engines loaded")

local function SpawnEngine(veh, offset)
    if not IsValid(veh) then return end

    local classname = "reforger_engine"
    local reforger_engine = ents.Create(classname)
    reforger_engine:SetMoveParent(veh)
    reforger_engine:SetVehicleBase(veh)
    reforger_engine:SetEngineData(veh.reforgerEngine)
    reforger_engine:Spawn()
    
    veh.reforgerEngine.entity = reforger_engine
end

function Reforger.CacheEngine(veh)
    if not Reforger.IsValidReforger(veh) then return end

    local base = Reforger.GetVehicleBase(veh)
    if base == "lvs" or base == nil then return end

    if veh.reforgerEngine and IsValid(veh.reforgerEngine.entity) then
        veh.reforgerEngine.entity:Remove()
        veh.reforgerEngine.entity = nil
    end

    local engine_offset = Vector(0, 0, 0)
    local isWorld = false

    if base == "simfphys" and veh.EnginePos ~= nil then
        engine_offset = veh.EnginePos
        isWorld = true
    end

    if base == "glide" and istable(veh.EngineFireOffsets) and istable(veh.EngineFireOffsets[1]) then
        local worldOffset = veh.EngineFireOffsets[1].offset
        engine_offset = veh:LocalToWorld(worldOffset)
    end

    veh.reforgerEngine = {
        offset = engine_offset,
        world_coords = isWorld
    }

    debugoverlay.Sphere(veh:GetPos(), 10, 2, Color(25, 25, 255), true)
    debugoverlay.Line(veh:GetPos(), engine_offset, 2, Color(255, 0, 0), true)
    debugoverlay.Sphere(engine_offset, 10, 2, Color(25, 255, 25), true)

    SpawnEngine(veh, engine_offset)
end

concommand.Add("reforger_debug_enginepos", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) then
        ply:ChatPrint("[Reforger] Наведись на транспорт.")
        return
    end

    local class = ent:GetClass()
    local base = Reforger.GetVehicleBase and Reforger.GetVehicleBase(ent) or "unknown"
    local pos = ent:GetPos()
    local offset = Vector(0, 0, 0)
    local label = "[Reforger]"

    if base == "simfphys" then
        if ent.EnginePos then
            offset = ent.EnginePos
            label = "[simfphys]"
        else
            ply:ChatPrint("[Reforger] [simfphys] Поле EnginePos отсутствует у сущности.")
            return
        end

    elseif base == "glide" then
        if not istable(ent.EngineFireOffsets) then
            ply:ChatPrint("[Reforger] [glide] EngineFireOffsets не является таблицей.")
            return
        end

        if not istable(ent.EngineFireOffsets[1]) then
            ply:ChatPrint("[Reforger] [glide] EngineFireOffsets[1] не является таблицей.")
            return
        end

        local worldOffset = ent.EngineFireOffsets[1].offset
        if not isvector(worldOffset) then
            ply:ChatPrint("[Reforger] [glide] Offset в EngineFireOffsets[1] не является Vector.")
            return
        end

        offset = worldOffset
        label = "[glide]"

    else
        ply:ChatPrint("[Reforger] Неизвестная система транспорта: " .. base)
        return
    end


    local isWorld = (base == "simfphys") -- Glide даёт world coords
    local enginePos = isWorld and offset or ent:LocalToWorld(offset)

    debugoverlay.Sphere(enginePos, 8, 3, Color(255, 0, 0), true)
    debugoverlay.Line(pos, enginePos, 3, Color(0, 255, 0), true)

    ply:ChatPrint(label .. " Позиция двигателя: " .. tostring(enginePos))
    print(label, ent, "Engine Pos:", enginePos, "| Local Offset:", offset)
end)

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
        local keyStr = tostring(k)
        local valueType = type(v)

        if valueType ~= "function" then
            if istable(v) then
                print(prefix .. keyStr .. " = {")
                if not visited[v] then
                    visited[v] = true
                    PrintTableRecursive(v, indent + 1, visited)
                else
                    print(prefix .. "  [Цикл обнаружен]")
                end
                print(prefix .. "}")
            else
                print(prefix .. keyStr .. " = " .. FormatValue(v))
            end
        end
    end
end

concommand.Add("reforger_vehicle_table", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) then
        ply:ChatPrint("[Reforger] Наведись на машину.")
        return
    end

    if not ent:IsVehicle() and not Reforger.IsValidReforger(ent) then
        ply:ChatPrint("[Reforger] Это не транспортная сущность.")
        return
    end

    ply:ChatPrint("[Reforger] Вывод содержимого таблицы сущности...")
    print("[Reforger] --- ENTITY TABLE --- [" .. tostring(ent) .. "] ---")

    PrintTableRecursive(ent:GetTable(), 0)

    print("[Reforger] --- END ---")
    ply:ChatPrint("[Reforger] Готово.")
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

concommand.Add("reforger_search_data", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) then
        ply:ChatPrint("[Reforger] Наведись на машину.")
        return
    end

    if not ent:IsVehicle() and not Reforger.IsValidReforger(ent) then
        ply:ChatPrint("[Reforger] Это не транспортная сущность.")
        return
    end

    local search = args[1]
    if not search or search == "" then
        ply:ChatPrint("[Reforger] Укажи ключевое слово для поиска.")
        return
    end

    ply:ChatPrint("[Reforger] Поиск по слову \"" .. search .. "\"...")

    local tbl = ent:GetTable()
    SearchTable(tbl, search, ent:GetClass())

    ply:ChatPrint("[Reforger] Поиск завершён.")
end)