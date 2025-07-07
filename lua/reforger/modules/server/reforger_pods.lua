if not Reforger then return end

Reforger.Log("Reforger Pods loaded")

function Reforger.AddPlayerCollision(ply, veh)
    if not IsValid(ply) or not IsValid(veh) then return end

    local pod = ents.Create("reforger_pod")

    if not IsValid(pod) then return end

    local base = Reforger.GetVehicleBase(veh:GetParent())

    if base == nil then return end
    
    pod:SetVehicleBase(veh:GetParent())
    pod:SetVehicle(veh)
    pod:SetPlayer(ply)
    pod:Spawn()

    ply.reforgerPod = pod

    veh.reforgerPods = veh.reforgerPods or {}
    veh.reforgerPods[ply] = pod
end

function Reforger.RemovePlayerCollision(ply, veh)
    if not IsValid(veh) or not veh.reforgerPods then return end

    local pod = veh.reforgerPods[ply]
    if IsValid(pod) then
        pod:Remove()
    end

    veh.reforgerPods[ply] = nil
end

hook.Add("PlayerEnteredVehicle", "Reforger.PlayerEnteredVehicle", function(ply, veh, r) Reforger.AddPlayerCollision(ply, veh) end)
hook.Add("PlayerLeaveVehicle", "Reforger.PlayerLeaveVehicle", function(ply, veh) Reforger.RemovePlayerCollision(ply, veh) end)