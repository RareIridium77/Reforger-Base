-- TODO: Extend

local Weapons   = Reforger.Weapons or {}

local runhook   = hook.Run
local rafunc    = Reforger.AddEntityFunction

local function IsWeaponed(veh)
    return IsValid(veh) and veh.LVS and istable(veh.WEAPONS)
end

--- [ Global Reforger ] ---

function Weapons.IsWeaponed(veh)  return IsWeaponed(veh) end
function Weapons.Get(veh)
    if not IsWeaponed(veh) then return {} end
    return veh.WEAPONS
end
function Weapons.GetActive(veh)
	if not Weapons.IsWeaponed(veh) then return nil end

	local getSelected = isfunction(veh.GetSelectedWeapon) and veh.GetSelectedWeapon or veh.GetSelectedWeaponID
	if not isfunction(getSelected) then return nil end

	local selectedID = getSelected(veh)
	if not selectedID then return nil end

	local weaponGroups = veh.WEAPONS
	if not istable(weaponGroups) then return nil end

	local group = weaponGroups[selectedID]
	if istable(group) and istable(group[1]) then
		return group[1]
	elseif istable(group) then
		return group
	end

	return nil
end

--- [ LVS Weapons ] ---

local function __weapon_init(veh, weapon)
    if not IsValid(veh) then return end

    weapon.ReforgedVehicle = veh
    
    runhook("Reforger.LVS_WeaponInit", weapon, veh)
end

local function __weapon_aevents(weapon)
    if not istable(weapon) then return end

    local osattack = weapon.StartAttack
    local oattack = weapon.Attack
    local ofattack = weapon.FinishAttack

    weapon.StartAttack = function(ent)
        if osattack then osattack(ent) end
        runhook("Reforger.LVS_WeaponStartAttack", weapon, ent)
    end

    weapon.Attack = function(ent)
        local can = runhook("Reforger.LVS_WeaponCanAttack", weapon, ent)

        if can == false then
            Reforger.DevLog("[Reforger] Weapon attack prevented by hook")
            return
        end

        if oattack then oattack(ent) end
        runhook("Reforger.LVS_WeaponAttack", weapon, ent)
    end

    weapon.FinishAttack = function(ent)
        if ofattack then ofattack(ent) end
        runhook("Reforger.LVS_WeaponFinishAttack", weapon, ent)
    end
end

local function __weapon_hooks(ent)
    if not IsWeaponed(ent) then return end

    local lvsWeapons = ent.WEAPONS

    for outerIndex, weaponGroup in ipairs(ent.WEAPONS) do
        for innerIndex, weapon in pairs(weaponGroup) do
            __weapon_init(ent, weapon)
            __weapon_aevents(weapon)
        end
    end
end

rafunc("Reforger.LVS_Weapons", __weapon_hooks)
Reforger.Weapons = Weapons