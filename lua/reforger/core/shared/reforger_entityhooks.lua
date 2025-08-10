--[[-------------------------------------------------------------------------
    [Reforger] Base (Framework)

    Unified system for advanced vehicle logic and damage simulation.
    Supports LVS / Simfphys / Gmod Glide. Open-source.

    Created by RareIridium77
    https://github.com/RareIridium77

-------------------------------------------------------------------------]]

Reforger = Reforger or {}
Reforger._internal = Reforger._internal or {}
Reforger.EntityHooks = Reforger.EntityHooks or {}

-- Define default networked params and their types
Reforger._internal.netParams = {
    reforgerArmorCount = { default = 0, type = "int" },
    reforgerType = { default = "undefined", type = "string" },
    reforgerBase = { default = "undefined", type = "string" },
}

-- Index mappings for compact network transmission
local paramIndexMap = {}
local indexParamMap = {}

do
    local idx = 0
    for k in pairs(Reforger._internal.netParams) do
        paramIndexMap[k] = idx
        indexParamMap[idx] = k
        idx = idx + 1
    end
end

-- Net write/read functions by type
local netWriters = {
    int = function(v) net.WriteInt(v, 16) end,
    string = function(v) net.WriteString(v) end,
}

local netReaders = {
    int = function() return net.ReadInt(16) end,
    string = function() return net.ReadString() end,
}

-- Write entity network data (only changed from default)
function Reforger._internal:WriteEntityNetData(ent)
    local changedKeys = {}

    for key, info in pairs(self.netParams) do
        local val = ent[key]
        if val ~= nil and val ~= info.default then
            table.insert(changedKeys, key)
        end
    end

    net.WriteUInt(#changedKeys, 6) -- send how many params we will send

    for _, key in ipairs(changedKeys) do
        local index = paramIndexMap[key]
        net.WriteUInt(index, 6)

        local typ = self.netParams[key].type
        netWriters[typ](ent[key])
    end
end

-- Read entity network data
function Reforger._internal:ReadEntityNetData(ent)
    for key, info in pairs(self.netParams) do
        ent[key] = info.default
    end

    local count = net.ReadUInt(6)
    for i = 1, count do
        local index = net.ReadUInt(6)
        local key = indexParamMap[index]
        if key then
            local typ = self.netParams[key].type
            ent[key] = netReaders[typ]()
        end
    end
end

function Reforger:AddEntityModule(idf, func)
    if not isstring(idf) or not isfunction(func) then return end
    self.EntityHooks[idf] = func
end

function Reforger._internal:InitializeEntity(ent)
    ref = Reforger
    if not ref.IsValidReforger(ent) then return end
    if not istable(ref.EntityHooks) then return end

    if SERVER then
        timer.Simple(0.2, function() -- // NOTE LVS have delayed initialization for armor parts and other things some reason
            local armorParts = ent._armorParts
            local armorCount = istable(armorParts) and #armorParts or 0

            ent.reforgerArmorCount = armorCount

            ent.reforgerType = ref.GetVehicleType(ent)
            ent.reforgerBase = ref.GetVehicleBase(ent)

            ref.Armored._internal:CacheAmmorack(ent)
            ref.Engines._internal:CacheEngine(ent)
            ref.Rotors._internal:CacheRotors(ent)

            net.Start("Reforger.InitializeEntity")
            net.WriteEntity(ent)

            -- Write networked params compactly
            self:WriteEntityNetData(ent)

            net.Broadcast()
        end)
    end

    for idf, func in pairs(ref.EntityHooks) do
        if isfunction(func) then
            local success, err = pcall(func, ent)
            if not success then
                ref.DevLog("Error in EntityHook ["..idf.."]: "..tostring(err))
            end
        end
    end

    hook.Run("Reforger.EntityInitialized", ent)
end

function Reforger:InitializeEntity(ent)
    Reforger._internal:InitializeEntity(ent)
end

if CLIENT then
    net.Receive("Reforger.InitializeEntity", function(len)
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end

        -- Read net data and apply to entity
        Reforger._internal:ReadEntityNetData(ent)

        -- Run hooks after setting data
        Reforger._internal:InitializeEntity(ent)
    end)
end