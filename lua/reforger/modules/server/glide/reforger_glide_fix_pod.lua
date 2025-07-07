if not Glide then return end

-- Fixes Aim steering
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
    end)
end)

do
    Glide_ActivateFixator()
end