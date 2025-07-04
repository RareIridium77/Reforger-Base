if CLIENT then return end

function Reforger.IsValidReforger(ent)
    if not IsValid(ent) then return false end
    return ent.LVS or ent.IsGlideVehicle or ent:GetClass() == "gmod_sent_vehicle_fphysics_base" or ent:GetClass() == "simfphys_tankprojectile"
end
