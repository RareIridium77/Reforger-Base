util.AddNetworkString("Reforger.SendGlideOffsets")

net.Receive("Reforger.SendGlideOffsets", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or not ent.IsGlideVehicle then return end

    local count = net.ReadUInt(8)
    if count <= 0 or count > 16 then
        Reforger.Log("Blocked suspicious offset packet from " .. tostring(ply))
        return
    end

    local offsets = {}

    for i = 1, count do
        local offset = net.ReadVector()

        if not isvector(offset) then
            Reforger.Log("Received non-vector offset. Player: " .. tostring(ply))
            return
        end

        offsets[i] = { offset = offset }
    end

    ent.EngineFireOffsets = offsets
end)
