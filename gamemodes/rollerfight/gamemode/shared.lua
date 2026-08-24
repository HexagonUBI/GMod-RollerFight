DeriveGamemode("base")

GM.Name = "RollerFight"
GM.Author = "Hexagon"
GM.TeamBased = true

RF = RF or {}

include("sh_config.lua")
include("sh_teams.lua")
include("sh_compat.lua")

function RF.IsAdmin(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() then return true end

	return ply:IsSuperAdmin() or ply:IsListenServerHost()
end

function GM:PlayerNoClip()
	return false
end

function GM:PlayerCanPickupWeapon()
	return false
end

function GM:PlayerFootstep()
	return true
end

function GM:PhysgunPickup()
	return false
end

function GM:GravGunPickupAllowed()
	return false
end

function GM:GravGunPunt()
	return false
end

function GM:AllowPlayerPickup()
	return false
end

function GM:CanTool()
	return false
end

function GM:CanProperty()
	return false
end

function GM:CanEditVariable()
	return false
end
