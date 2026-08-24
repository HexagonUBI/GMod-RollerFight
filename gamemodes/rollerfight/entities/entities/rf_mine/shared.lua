ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Rollermine"
ENT.Author = "Hexagon"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Driver")
	self:NetworkVar("Bool", 0, "AttackMode")
	self:NetworkVar("Bool", 1, "Exhausted")
	self:NetworkVar("Bool", 2, "Buried")
	self:NetworkVar("Bool", 3, "Dying")
	self:NetworkVar("Bool", 4, "Lamp")
	self:NetworkVar("Bool", 5, "Locked")
	self:NetworkVar("Float", 0, "Energy")
	self:NetworkVar("Float", 1, "AttackLockEnd")
	self:NetworkVar("Int", 0, "MineTeam")
	self:NetworkVar("Int", 1, "ColorIndex")
end

function ENT:GetTeamColor()
	if self:GetMineTeam() == TEAM_FREE then
		local col = RF.FFAColors[self:GetColorIndex()]
		if col then return col end
	end

	return RF.TeamColors[self:GetMineTeam()] or RF.TeamColors[TEAM_FREE]
end
