if not Reforger then return end -- overthinker moment

Reforger.Log("Reforger_Scanners Initialized")

function Reforger.PairEntity(parent, className)
    if not IsValid(parent) or not isstring(className) then return nil end

    for _, child in ipairs(parent:GetChildren()) do
        if IsValid(child) and child:GetClass() == className then
            return child
        end
    end

    return nil
end

function Reforger.PairEntityAll(parent, className)
    if not IsValid(parent) or not isstring(className) then return {} end

    local result = {}

    local children = parent:GetChildren()
    if not istable(children) or #children == 0 then return {} end

    for _, child in ipairs(children) do
        if IsValid(child) and child:GetClass() == className then
            table.insert(result, child)
        end
    end

    return result
end

function Reforger.FindClosestByClass(veh, dmginfo, className)
    if not IsValid(veh) or not isstring(className) then return nil end

    local Len = veh:BoundingRadius() or 10
    local dmgPos = dmginfo:GetDamagePosition()
    local dmgDir = dmginfo:GetDamageForce():GetNormalized()

    local dmgStart = dmgPos - dmgDir * (Len * 0.5)

    local closestEnt = nil
    local closestDist = Len * 2

    for _, ent in ipairs(Reforger.PairEntityAll(veh, className)) do
        if not IsValid(ent) then continue end
        if ent:GetParent() ~= veh then continue end

        local mins, maxs = ent:OBBMins() / 2, ent:OBBMaxs() / 1.5
        local pos, ang = ent:GetPos(), ent:GetAngles()

        if dmgPos:Distance(veh:GetPos()) > Len * 5 then
            dmgPos = ent:GetPos()
        end

        local HitPos = util.IntersectRayWithOBB(dmgStart, dmgDir * Len * 1.5, pos, ang, mins, maxs)

        if HitPos then
            debugoverlay.BoxAngles(pos, mins, maxs, ang, 1, Color(255, 0, 0, 50))

            local dist = (HitPos - dmgPos):Length()

            if dist < closestDist then
                closestEnt = ent
                closestDist = dist
            end
        end
    end

    return closestEnt
end

function Reforger.GetEveryone(veh)
    if not IsValid(veh) then return {} end

    local players = {}

    if veh.IsSimfphyscar then
        local driver = veh:GetDriver()
        if IsValid(driver) and driver:IsPlayer() and veh.RemoteDriver ~= driver then
            table.insert(players, driver)
        end

        local pSeats = veh:GetPassengerSeats()

        if istable(pSeats) then
            for _, seat in pairs(pSeats) do
                local passenger = seat:GetDriver()

                if not IsValid(passenger) then continue end

                table.insert(players, passenger)
            end
        end

    elseif veh.IsGlideVehicle and isfunction(veh.GetAllPlayers) then
        local list = veh:GetAllPlayers()
        if istable(list) then
            for _, ply in ipairs(list) do
                if IsValid(ply) and ply:IsPlayer() then
                    table.insert(players, ply)
                end
            end
        end

    elseif veh.LVS and isfunction(veh.GetEveryone) then
        local list = veh:GetEveryone()
        if istable(list) then
            for _, ply in ipairs(list) do
                if IsValid(ply) and ply:IsPlayer() then
                    table.insert(players, ply)
                end
            end
        end
    end

    return players
end
