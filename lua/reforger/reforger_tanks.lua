if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Tanks special loaded")

function Reforger.CacheAmmorack(veh)
    local vehicle_type = Reforger.GetVehicleType(veh)
    local vehicle_base = Reforger.GetVehicleBase(veh)
    if vehicle_base ~= "lvs" then return end
    if vehicle_type ~= "armored" then return end

    timer.Simple(0, function()
        if IsValid(veh.reforger_ammoracks) then return end
        local ammorack_ents = Reforger.PairEntityAll(veh, "lvs_wheeldrive_ammorack")

        if not istable(ammorack_ents) then return end

        if veh.reforger_ammoracks == nil then
            veh.reforger_ammoracks = ammorack_ents
        end
    end)
end

function Reforger.AmmoracksTakeTransmittedDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    if istable(veh.reforger_ammoracks) then
        for _, ammorack in ipairs(veh.reforger_ammoracks) do
            if IsValid(ammorack) and ammorack.TakeTransmittedDamage then
                ammorack:TakeTransmittedDamage(dmginfo)
                Reforger.DevLog(veh.PrintName, " gets ammorack damage. Damage: "..dmginfo:GetDamage())
            end
        end
    end
end

function Reforger.IsAmmorackDestroyed(veh)
    if not IsValid(veh) or veh.reforger_ammoracks == nil then return false end

    local destroyed = false

    for _, ammorack in ipairs(veh.reforger_ammoracks) do
        if ammorack:GetDestroyed() then
            destroyed = true 
            break 
        end
    end

    return destroyed
end

concommand.Add("reforger_check_ammorack", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) then
        ply:ChatPrint("Вы не смотрите на технику.")
        return
    end

    for _, ammorack in ipairs(ent.reforger_ammoracks) do
        print(ammorack)
    end
end)