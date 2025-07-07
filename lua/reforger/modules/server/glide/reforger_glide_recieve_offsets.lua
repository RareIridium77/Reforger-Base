util.AddNetworkString("Reforger.SendGlideOffsets")

net.Receive("Reforger.SendGlideOffsets", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    if not ent.IsGlideVehicle then return end

    local count = net.ReadUInt(8)
    ent.EngineFireOffsets = {}

    for i = 1, count do
        local offset = net.ReadVector()
        ent.EngineFireOffsets[i] = { offset = offset }
    end

    print("[Reforger] Сервер получил EngineFireOffsets от клиента. Сущность: " .. tostring(ent))
end)
