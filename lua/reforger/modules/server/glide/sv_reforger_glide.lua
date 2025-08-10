--- [ Reforger Glide Recieve Offsets ] ---

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


--- [ Reforger Glide Fix Pod ] ---
local function Glide_ActivateFixator()
    local EntityMeta = FindMetaTable( "Entity" )
    local PlayerMeta = FindMetaTable( "Player" )

    local TraceLine = util.TraceLine
    local eyePos = EntityMeta.EyePos

    function PlayerMeta:GlideGetAimPos()
        local origin = eyePos( self )
        
        local glide_vehicle = self:GlideGetVehicle()
        if not IsValid(glide_vehicle) then return origin end

        local filters = { self, glide_vehicle }
        
        if istable(glide_vehicle.traceFilter) then
            for _, ent in ipairs(glide_vehicle.traceFilter) do
                table.insert(filters, ent)
            end
        end

        local trace = TraceLine({
            start = origin,
            endpos = origin + self:GlideGetCameraAngles():Forward() * 50000,
            filter = filters
        })

        return trace.HitPos
    end
end

hook.Add("Reforger.Init", "Glide.InitPodFixer", function()
    timer.Simple(5, function()
        Glide_ActivateFixator()
        Reforger.Log("Glide AIM Positioning fixed")
    end)
end)