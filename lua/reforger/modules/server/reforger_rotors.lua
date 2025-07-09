if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger Rotors Loaded")

local VehBase = Reforger.VehicleBases
local VehType = Reforger.VehicleTypes

function Reforger.RotorsGetDamage(veh, dmginfo)
    if not IsValid(veh) then return end

    local rotor = Reforger.FindRotorsAlongRay(veh, dmginfo)

    if not IsValid(rotor) then return end
    if not Reforger.IsRotorSpinning(veh, rotor) then return end

    if rotor.rotorHealth == nil and veh.reforgerBase == VehBase.LVS then
        if rotor.GetHP then
            Reforger.DevLog("[Rotor Init] Использован метод rotor:GetHP()")
            rotor.rotorHealth = rotor:GetHP()
        else
            Reforger.DevLog("[Rotor Init] Использовано Reforger.GetHealth(veh) * 0.15")
            rotor.rotorHealth = Reforger.GetHealth(veh) * 0.15
        end
    end

    rotor.rotorHealth = rotor.rotorHealth - dmginfo:GetDamage()

    if rotor.rotorHealth <= 0 and isfunction(rotor.Destroy) then
        rotor:Destroy()
    end
end

function Reforger.IsRotorSpinning(veh, rotor)
    if not IsValid(veh) or not IsValid(rotor) then
        Reforger.DevLog("Vehicle or rotors are not valid: false")
        return false
    end

    local vehBase = veh.reforgerBase
    local isSpinning = false
    
    if vehBase == VehBase.Glide then
        isSpinning = rotor.spinMultiplier > 0.2
    elseif vehBase == VehBase.LVS then
        local base = rotor:GetBase()
        isSpinning = base:GetThrottle() > 0.5
    end

    return isSpinning
end

function Reforger.FindRotorsAlongRay(veh, dmginfo)
    if not IsValid(veh) then return nil end

    local rotors = Reforger.GetRotors(veh)
    if not istable(rotors) or #rotors == 0 then return nil end
    
    local classname = nil

    if veh.IsGlideVehicle then
        classname = "glide_rotor"
    elseif veh.LVS then 
        classname = "lvs_helicopter_rotor"
    end

    if not isstring(classname) then return nil end
    return Reforger.FindClosestByClass(veh, dmginfo, classname)
end

function Reforger.FindRotors(veh)
    if not IsValid(veh) then return {} end

    if istable(veh.reforgerRotors) then return veh.reforgerRotors end

    local rotors = {}
    local vehicle_type = veh.reforgerType

    if veh.reforgerBase == VehBase.Glide then
        if IsValid(veh.mainRotor) then table.insert(rotors, veh.mainRotor) end
        if IsValid(veh.tailRotor) then table.insert(rotors, veh.tailRotor) end

        if #rotors == 0 and vehicle_type == VehType.PLANE then
            rotors = Reforger.PairEntityAll(veh, "glide_rotor")
        end
    end

    if veh.reforgerBase == VehBase.LVS then
        local lvs_rotors = {}

        if veh.TailRotor then table.insert(lvs_rotors, veh.TailRotor) end
        if veh.Rotor then
            veh.Rotor.reforgerMainRotor = true
            table.insert(lvs_rotors, veh.Rotor)
        end

        if istable(lvs_rotors) then rotors = lvs_rotors end

        if #rotors == 0 then
            rotors = Reforger.PairEntityAll(veh, "lvs_helicopter_rotor")
        end
    end

    return rotors
end

function Reforger.RepairRotors(veh)
    if veh.reforgerType ~= VehType.PLANE then return end

    for _, rotor in ipairs(Reforger.GetRotors(veh)) do
        if rotor.Repair then rotor:Repair() end
    end
end

function Reforger.CacheRotors(veh)
    if not IsValid(veh) then return end

    Reforger.DevLog("Tring to cache rotors for ", veh)

    if veh.reforgerBase == VehBase.Simfphys then return end
    if veh.reforgerType ~= VehType.HELICOPTER and veh.reforgerType ~=VehType.PLANE then return end

    timer.Simple(0, function()
        veh.reforgerRotors = Reforger.FindRotors(veh)

        Reforger.DevLog("Cached " .. #veh.reforgerRotors .. " rotors for " .. tostring(veh))

        hook.Run("Reforger.RotorsCached", veh, veh.reforgerRotors)
    end)
end

function Reforger.GetRotors(veh)
    if not IsValid(veh) then return {} end
    return veh.reforgerRotors or {}
end

concommand.Add("reforger.check.rotors", function(ply, cmd)
    if not Reforger.AdminDevToolValidation(ply) then return end

    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then PrintTable(rotors) end
end)

concommand.Add("reforger.check.rotors.table", function(ply, cmd)
    if not Reforger.AdminDevToolValidation(ply) then return end

    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    if not IsValid(tr.Entity) then return end

    local rotors = Reforger.FindRotors(tr.Entity)

    if istable(rotors) then
        for _, rotor in ipairs(rotors) do
            if IsValid(rotor) then
                print("----------------------------------------------------------")
                print("----------------------------------------------------------")
                print("----------------------------------------------------------")
                PrintTable(rotor:GetTable())
            end
        end
    end
end)