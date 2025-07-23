if not LVS then return end

local runhook       = hook.Run
local rafunc        = Reforger.AddEntityFunction

--- [ LVS EXPLOSION ] ---

local function __lvs_explode(lvs)
    local oexplode = lvs.Explode

    lvs.Explode = function(self)
        if self.reforgerExploded then return end
        
        if oexplode then oexplode(self) end
        runhook("Reforger.LVS_Exploded", self)

        self.reforgerExploded = true
    end
end

local function __lvs_hooks(ent)
    if not IsValid(ent) or not ent.LVS then return end

    __lvs_explode(ent)
end

rafunc("Reforger.LVS_Explosion", __lvs_hooks)