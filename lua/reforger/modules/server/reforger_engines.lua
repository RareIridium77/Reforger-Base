-- Engines for simfphys and glide (damage and etc)

local Engines = {}
Engines._internal = {}

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

function Engines._internal:CacheEngine(veh)
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
    Reforger.DevLog("Engine Cached and Spawned")
end

Reforger.Engines = Engines