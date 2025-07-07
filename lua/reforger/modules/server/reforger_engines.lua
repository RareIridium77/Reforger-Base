if not Reforger then return end

-- Engines for simfphys and glide (damage and etc)

Reforger.Log("Reforger Engines loaded")

local function SpawnEngine(veh, pos)
    if not IsValid(veh) then return end

    local classname = "reforger_engine"
    local reforger_engine = ents.Create(classname)
    reforger_engine:SetMoveParent(veh)
    reforger_engine:SetVehicleBase(veh)
    reforger_engine:Spawn()
end

function Reforger.CacheEngine(veh)
    if not Reforger.IsValidReforger(veh) then return end

    local base = Reforger.GetVehicleBase(veh)

    if base == "lvs" or base == nil then return end -- LVS not supported by this module

    local engine_pos = veh:GetPos()

    if base == "simfphys" and veh.EnginePos ~= nil then
        engine_pos = veh.EnginePos
    end

    if base == "glide" and istable(veh.EngineFireOffsets) and next(veh.EngineFireOffsets) ~= nil then
        engines_pos = veh.EngineFireOffsets[1].offset
    end

    SpawnEngine(veh, Vector(engines_pos))
end