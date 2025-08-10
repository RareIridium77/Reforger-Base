// SECTION Reforger View Shared
local View = Reforger.View or {}

View.Type = {
    TPV = "tpv",  -- third-person view
    FPV = "fpv",  -- first-person view
    UV  = "uv"    -- undefined view
}

Reforger.View = View

function Reforger.View:GetViewType(ply)
    return ply.ReforgerView and ply:ReforgerView() or View.Type.FPV
end

local function IsClient() return CLIENT end
local function IsServer() return SERVER end

local plyMeta = FindMetaTable("Player")

function plyMeta:ReforgerView()
    local pod = self:GetVehicle()

    if IsValid(pod) then
        return pod:GetThirdPersonMode() and View.Type.TPV or View.Type.FPV
    end

    return View.Type.UV
end

function plyMeta:ReforgerShakeView(intensity) --// NOTE Does nothing on client
    if IsClient() then return end

    local scale = intensity or 1

    local pitch = math.Rand(-1, 1) * scale
    local yaw = math.Rand(-1, 1) * scale
    local roll = math.Rand(-1, 1) * scale

    local punchAngle = Angle(pitch, yaw, roll)
    self:ViewPunch(punchAngle)
end

concommand.Add(".testpunch", function(ply)
    if not Reforger.IsDeveloper() then return end
    
    if not IsValid(ply) then return end
    ply:ReforgerShakeView(1)
end)

// !SECTION

// SECTION Reforger LVS View
if IsServer() then return end

local function __lvs_weapon_view(weapon) // ANCHOR Weapon View
    if weapon and weapon.CalcView then
        local oldCalcView = lvs.CalcView
        if not oldCalcView then return end

        weapon.CalcView = function(self, ply, pos, angles, fov, pod)
            local view = oldCalcView(self, ply, pos, angles, fov, pod)
            view.angles = ply:GetViewPunchAngles() + view.angles
            print("Weapon calc")
            return
        end
    end
end

local function __lvs_view(lvs) // ANCHOR Main view calc
    local oldCalcView = lvs.CalcView
    local activeWeapon = lvs:GetActiveWeapon()

    if not oldCalcView then return end
    print(lvs, activeWeapon)
    
    lvs.CalcView = function(self, ply, pos, angles, fov, pod)
        local view = oldCalcView(self, ply, pos, angles, fov, pod)
        view.angles = ply:GetViewPunchAngles() + view.angles
        print("Lvs calc")
        return view
    end

    __lvs_weapon_view(activeWeapon)
end

local function __lvs_init_view(ent)
    if not ent.LVS then return end
    __lvs_view(ent)
end

Reforger:AddEntityModule("Reforger.LVS_View", __lvs_init_view)

// !SECTION