Reforger = Reforger or {}

Reforger.Log("Reforger Pods Loaded")

local function AddPlayerCollision(ply, veh)
    if not IsValid(ply) or not IsValid(veh) then return end

    if IsValid(ply.reforgerPod) then
        Reforger.DevLog("[Pod] Collision already exists for: " .. tostring(ply))
        return
    end

    local pod = ents.Create("reforger_pod")
    if not IsValid(pod) then return end

    local baseVehicle = veh:GetParent()
    local base = baseVehicle and baseVehicle.reforgerBase or nil
    if base == nil then return end

    timer.Simple(0, function()
        if not IsValid(baseVehicle) or not IsValid(veh) or not IsValid(ply) then return end

        pod:SetVehicleBase(baseVehicle)
        pod:SetVehicle(veh)
        pod:SetPlayer(ply)
        pod:Spawn()

        ply.reforgerPod = pod

        veh.reforgerPods = veh.reforgerPods or {}
        veh.reforgerPods[ply] = pod
    end)
end

local function RemovePlayerCollision(ply, veh)
    if not IsValid(veh) or not veh.reforgerPods then return end

    local pod = veh.reforgerPods[ply]
    if IsValid(pod) then
        pod:Remove()
    end

    veh.reforgerPods[ply] = nil
end

hook.Add("PlayerEnteredVehicle", "Reforger.PlayerEnteredVehicle", function(ply, veh, r) AddPlayerCollision(ply, veh) end)
hook.Add("PlayerLeaveVehicle", "Reforger.PlayerLeaveVehicle", function(ply, veh) RemovePlayerCollision(ply, veh) end)