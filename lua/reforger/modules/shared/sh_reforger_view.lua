--- shared

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

local plyMeta = FindMetaTable("Player")

function plyMeta:ReforgerView()
    local pod = self:GetVehicle()

    if IsValid(pod) then
        return pod:GetThirdPersonMode() and View.Type.TPV or View.Type.FPV
    end

    return View.Type.UV
end
