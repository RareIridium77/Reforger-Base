if not Reforger then return end

local function OnGlideEntityCreate(glide_entity)
    if not IsValid(glide_entity) then return end
    if not glide_entity.IsGlideVehicle then return end

    local offsets = glide_entity.EngineFireOffsets
    if not istable(offsets) then return end

    net.Start("Reforger.SendGlideOffsets")
        net.WriteEntity(glide_entity)
        net.WriteUInt(#offsets, 8)
        
        for _, data in ipairs(offsets) do
            net.WriteVector(data.offset or Vector(0, 0, 0))
        end

    net.SendToServer()
end

hook.Add("OnEntityCreated", "Reforger.Client_GlideSendOffsets", function(entity)
    if not IsValid(entity) then return end
    timer.Simple(0, function()
        if IsValid(entity) and entity.IsGlideVehicle and istable(entity.EngineFireOffsets) then
            OnGlideEntityCreate(entity)
        end
    end)
end)
