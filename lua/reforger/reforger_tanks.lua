if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Tanks special loaded")

function Reforger.CacheAmmorack(veh)
    local vehicle_type = Reforger.GetVehicleType(veh)
    local vehicle_base = Reforger.GetVehicleBase(veh)
    if vehicle_base ~= "lvs" then return end
    if vehicle_type ~= "armored" then return end

    if IsValid(veh.reforger_ammorack) then return end

    local ammorack_ent = Reforger.PairEntity(veh, "lvs_wheeldrive_ammorack")
    
    if IsValid(ammorack_ent) then
        if veh.reforger_ammorack == nil then
            veh.reforger_ammorack = ammorack_ent
        end
    end
end