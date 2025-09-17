--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

--[[
    Reforger Admin & Dev Commands
    - Provides admin-only developer utilities for debugging and controlling Reforger
    - Validation:
        * Reforger.AdminDevToolValidation(ply) → Ensures admin + devmode
    - Command Registration:
        * Reforger.CreateAdminCommand(name, desc, callback) → Creates prefixed admin command (dev.reforger.*)
    - Helper:
        * ValidateTraceEntity(ply) → Ensures player looks at a valid Reforger entity
    - Command Categories:
        * Framework:
            - framework.init → Manual Reforger init
            - framework.table → Print Reforger table
            - framework.reload → Reload framework & modules
        * Vehicle:
            - vehicle.destroy → Explodes/destroys entity
            - vehicle.type → Prints entity reforgerType
            - vehicle.base → Prints entity reforgerBase
            - vehicle.pair → Finds paired class objects in entity
        * Dump:
            - dump.net → Print entity ReforgerNet
            - dump.entity → Recursive dump of entity data
        * Data Ops:
            - search.data → Search entity table by key/value
        * Bot Ops:
            - bot.seat → Places bot into vehicle seat
    - Error Handling:
        * Safe pcall in commands
        * Logs internal errors to console & player
    - Networking:
        * Commands notify players via ChatPrint
]]

Reforger = Reforger or {}

function Reforger.AdminDevToolValidation(ply)
    if not IsValid(ply) then return false end
    if not ply:IsAdmin() and not ply:IsSuperAdmin() then Reforger.Log("You are not admin or either super admin.") return false end
    if GetConVar("developer"):GetInt() <= 0 then Reforger.Log("Developer mode disabled. Enable it => 'developer 1'") return false end

    return true
end

function Reforger.CreateAdminCommand(name, descOrCallback, maybeCallback)
    local desc, callback
    local namePrefixed = "dev.reforger."..name

    if isfunction(descOrCallback) then
        callback = descOrCallback
        desc = "No description"
    else
        desc = descOrCallback or "No description"
        callback = maybeCallback
    end

    if not isstring(name) or not isfunction(callback) then
        Reforger.ErrorLog("Failed to register command: invalid arguments. (name: ", name, ")")
        return
    end

    concommand.Add(namePrefixed, function(ply, cmd, args)
        if not Reforger.AdminDevToolValidation(ply) then return end

        local ok, err = pcall(callback, ply, cmd, args)
        if not ok then
            Reforger.SLog("DEV", "Error in admin command '", namePrefixed, "': ", err)
            if IsValid(ply) then ply:ChatPrint("Internal error in command.") end
        end
    end)

    Reforger.Commands = Reforger.Commands or {}
    table.insert(Reforger.Commands, { name = namePrefixed, desc = desc })

    Reforger.SLog("DEV", "Registered admin command: "..namePrefixed.." — "..desc)
end

local function ValidateTraceEntity(ply)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not Reforger.IsValidReforger(ent) then
        ply:ChatPrint("[Reforger] Invalid entity. Aim at reforger-compatible object.")
        return
    end

    return ent
end

--- [ FRAMEWORK COMMANDS ] ---

Reforger.CreateAdminCommand("framework.init", "Manual init reforger", function(ply)
    hook.Run("Reforger.Init")
    ply:ChatPrint("Manual reforge_init called")
end)

Reforger.CreateAdminCommand("framework.table", "Prints Reforger table", function(ply)
    PrintTable(Reforger)
end)

Reforger.CreateAdminCommand("framework.reload", "Reload whole reforger framework and modules including", function(ply)
    hook.Run("Reforger.Reload")
    ply:ChatPrint("Reforger scripts reloaded.")
end)

--- [ VEHICLE DIRECT COMMANDS ] ---

Reforger.CreateAdminCommand("vehicle.destroy", "Exploding entity that player looks at (entity should be valid for reforger)", function(ply)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    if ent.Destroy then ent:Destroy() end
    if ent.Explode then ent:Explode() end
    if ent.ExplodeVehicle then ent:ExplodeVehicle() end
end)

Reforger.CreateAdminCommand("vehicle.type", "Get type of entity (should be reforger valid entity)", function(ply)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    ply:ChatPrint("Vehicle Type Is " .. ent.reforgerType)
end)

Reforger.CreateAdminCommand("vehicle.base", "Get base of entity (should be reforger valid entity)", function(ply)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    ply:ChatPrint("Vehicle Base Is " .. ent.reforgerBase)
end)

Reforger.CreateAdminCommand("vehicle.pair", "Pairing and searching class in entity", function(ply, cmd, args)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    local classToFind = args[1]

    if not classToFind or classToFind == "" then
        ply:ChatPrint("Send argument of class. Example: dev.reforger.pair lvs_wheeldrive_ammorack")
        return
    end

    local found = Reforger.PairEntityAll(ent, classToFind)

    if not istable(found) or #found == 0 then
        ply:ChatPrint("Nothing found for: " .. classToFind)
        return
    end

    ply:ChatPrint("Found " .. #found .. " objects of class: " .. classToFind)
    for _, paired in ipairs(found) do
        local desc = "[" .. tostring(paired) .. "]"
        if isfunction(paired.GetHP) then desc = desc .. " HP: " .. tostring(paired:GetHP()) end
        if isfunction(paired.GetDestroyed) then desc = desc .. " Destroyed: " .. tostring(paired:GetDestroyed()) end
        ply:ChatPrint(desc)
    end
end)

--- [ DUMP COMMANDS ] ---

Reforger.CreateAdminCommand("dump.net", "Dump ReforgerNet of entity", function(ply)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    Reforger.Log("Dump ReforgerNet:")
    for k, v in pairs(ent.ReforgerNet or {}) do
        print("  " .. k .. " [" .. v.Type .. "] = " .. tostring(v.Value))
    end
end)

Reforger.CreateAdminCommand("dump.entity", "Recursive dump of vehicle / entity", function(ply)
    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    local function FormatValue(v)
        if isvector(v) then return string.format("Vector(%.2f, %.2f, %.2f)", v.x, v.y, v.z)
        elseif isangle(v) then return string.format("Angle(%.2f, %.2f, %.2f)", v.p, v.y, v.r)
        elseif isentity(v) and IsValid(v) then return "Entity [" .. v:GetClass() .. "]"
        elseif istable(v) then return "table (" .. tostring(v) .. ")"
        elseif type(v) == "string" then return "\"" .. v .. "\""
        else return tostring(v) end
    end

    local function PrintTableRecursive(tbl, indent, visited)
        visited = visited or {}
        indent = indent or 0
        local prefix = string.rep("  ", indent)

        for k, v in pairs(tbl) do
            if type(v) ~= "function" then
                local keyStr = tostring(k)
                if istable(v) and not visited[v] then
                    visited[v] = true
                    print(prefix .. keyStr .. " = {")
                    PrintTableRecursive(v, indent + 1, visited)
                    print(prefix .. "}")
                else
                    print(prefix .. keyStr .. " = " .. FormatValue(v))
                end
            end
        end
    end

    ply:ChatPrint("[Reforger] Printing Table...")
    print("[Reforger] --- ENTITY TABLE --- [" .. tostring(ent) .. "] ---")
    PrintTableRecursive(ent:GetTable())
    print("[Reforger] --- END ---")
    ply:ChatPrint("[Reforger] Ready.")
end)

--- [ OPERATION WITH DATA COMMANDS ] ---

Reforger.CreateAdminCommand("search.data", "Searh data by key in entity table (entity should be valid for reforger)", function(ply, cmd, args)
    local search = args[1]

    local ent = ValidateTraceEntity(ply)
    if not IsValid(ent) then return end

    if not search or search == "" then
        ply:ChatPrint("[Reforger] Send key word in arguments (only one argument)")
        return
    end

    local function FormatValue(v)
        if isvector(v) then return string.format("Vector(%.2f, %.2f, %.2f)", v.x, v.y, v.z)
        elseif isangle(v) then return string.format("Angle(%.2f, %.2f, %.2f)", v.p, v.y, v.r)
        elseif isentity(v) and IsValid(v) then return "Entity [" .. v:GetClass() .. "]"
        elseif istable(v) then return "table (" .. tostring(v) .. ")"
        elseif type(v) == "string" then return "\"" .. v .. "\""
        else return tostring(v) end
    end

    local function SearchTable(tbl, searchTerm, path, visited)
        visited = visited or {}
        searchTerm = string.lower(searchTerm)

        for k, v in pairs(tbl) do
            local keyStr = tostring(k)
            local currentPath = path .. "." .. keyStr

            if type(v) ~= "function" then
                local valStr = FormatValue(v)
                if string.find(string.lower(keyStr), searchTerm, 1, true) or
                   string.find(string.lower(valStr), searchTerm, 1, true) then
                    print(currentPath .. " = " .. valStr)
                end

                if istable(v) and not visited[v] then
                    visited[v] = true
                    SearchTable(v, searchTerm, currentPath, visited)
                end
            end
        end
    end

    ply:ChatPrint("[Reforger] Searching for \"" .. search .. "\"...")
    SearchTable(ent:GetTable(), search, ent:GetClass())
    ply:ChatPrint("[Reforger] Searching end.")
end)

Reforger.CreateAdminCommand("bot.seat", "Seats bot in vehicle", function(ply, cmd, args)
    local vehicle = ValidateTraceEntity(ply)
    if not IsValid(vehicle) then return end

    local vehicleBase = vehicle.reforgerBase

    local bot
    for _, v in ipairs(player.GetBots()) do
        if IsValid(v) and not v:InVehicle() then
            bot = v
            break
        end
    end

    if not IsValid(bot) then
        ply:ChatPrint("[Reforger] No bots available.")
        return
    end

    local seats = {}

    if vehicleBase == "lvs" and vehicle.GetDriverSeat then
        local dSeat = vehicle:GetDriverSeat()
        local pSeats = vehicle:GetPassengerSeats() or {}

        if IsValid(dSeat) then
            table.insert(seats, dSeat)
        end

        for _, seat in ipairs(pSeats) do
            if IsValid(seat) then
                table.insert(seats, seat)
            end
        end
    elseif vehicleBase == "simfphys" then
        local dSeat = vehicle:GetDriverSeat()
        local pSeats = vehicle:GetPassengerSeats() or {}

        if IsValid(dSeat) then
            table.insert(seats, dSeat)
        end

        for _, seat in ipairs(pSeats) do
            if IsValid(seat) then
                table.insert(seats, seat)
            end
        end
    elseif vehicleBase == "glide" and vehicle.GetFreeSeat then
        local freeSeat = vehicle:GetFreeSeat()
        
        if IsValid(freeSeat) then
            table.insert(seats, freeSeat)
        end
    end

    if #seats == 0 then
        table.insert(seats, vehicle)
    end

    for _, seat in ipairs(seats) do
        if IsValid(seat) and seat:IsVehicle() and not IsValid(seat:GetDriver()) then
            bot:EnterVehicle(seat)
            ply:ChatPrint("[Reforger] Bot successfully seated in vehicle.")
            return
        end
    end

    ply:ChatPrint("[Reforger] No available seat found.")
end)
