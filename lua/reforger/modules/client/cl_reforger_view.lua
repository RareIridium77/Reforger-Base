local plyMeta = FindMetaTable("Player")

function plyMeta:ReforgerShakeView(intensity, duration)
    local scale = intensity or 1
    local time = duration or 0.5

    util.ScreenShake(self:GetPos(), scale * 5, 5, time, 100)
end

concommand.Add("TestShake_Reforger", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local intensity = tonumber(args[1]) or 1
    local duration = tonumber(args[2]) or 0.5

    ply:ReforgerShakeView(intensity, duration)
end)
