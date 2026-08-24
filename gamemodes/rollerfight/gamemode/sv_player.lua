function RF.DetachPlayer(ply)
	ply:SetNoDraw(true)
	ply:DrawShadow(false)
	ply:SetNotSolid(true)
	ply:SetSolid(SOLID_NONE)
	ply:SetMoveType(MOVETYPE_NONE)
	ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	ply:SetCollisionBounds(Vector(-1, -1, -1), Vector(1, 1, 1))
end

RF.SpawnClasses = {
	"info_player_start",
	"info_player_deathmatch",
	"info_player_combine",
	"info_player_rebel",
	"info_player_counterterrorist",
	"info_player_terrorist",
	"gmod_player_start"
}

function RF.SpawnClear(pos)
	for _, ent in ipairs(ents.FindInSphere(pos, 56)) do
		if ent:GetClass() == "rf_mine" then return false end
	end

	return true
end

function RF.SelectSpawnPos(ply)
	local points = {}

	for _, class in ipairs(RF.SpawnClasses) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			table.insert(points, ent)
		end
	end

	if #points == 0 then return ply:GetPos() + Vector(0, 0, 24) end

	table.Shuffle(points)

	for _, point in ipairs(points) do
		local pos = point:GetPos() + Vector(0, 0, 26)
		if RF.SpawnClear(pos) then return pos end
	end

	return points[1]:GetPos() + Vector(0, 0, 26)
end

function RF.RemoveMine(ply)
	local mine = ply.RFMine

	ply.RFMine = nil
	ply:SetNWEntity("rf_mine", NULL)

	if IsValid(mine) then
		mine:SetDriver(NULL)
		mine:Remove()
	end
end

function RF.GiveMine(ply, pos)
	RF.RemoveMine(ply)

	local mine = ents.Create("rf_mine")
	if not IsValid(mine) then return end

	mine:SetPos(pos or (ply:GetPos() + Vector(0, 0, 24)))
	mine:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	mine:Spawn()
	mine:Activate()
	mine:SetDriver(ply)
	mine:SetMineTeam(ply:Team())

	ply.RFMine = mine
	ply:SetNWEntity("rf_mine", mine)
	RF.DetachPlayer(ply)

	return mine
end

function RF.OnMineDestroyed(mine, attacker)
	local ply = mine:GetDriver()

	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker == ply then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)
		end
	end

	if not IsValid(ply) then return end

	ply.RFMine = nil
	ply:SetNWEntity("rf_mine", NULL)
	ply:AddDeaths(1)

	local delay = RF.Get("RespawnTime")
	if delay <= 0 then delay = 0.1 end

	timer.Simple(delay, function()
		if IsValid(ply) and ply:Alive() then RF.GiveMine(ply, RF.SelectSpawnPos(ply)) end
	end)
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_FREE)
end

function GM:PlayerSpawn(ply, transition)
	self.BaseClass.PlayerSpawn(self, ply, transition)
	RF.GiveMine(ply)
end

function GM:PlayerLoadout(ply)
	ply:StripWeapons()
	return true
end

function GM:PlayerSetModel(ply)
	ply:SetModel("models/player/kleiner.mdl")
end

function GM:PlayerShouldTakeDamage(ply, attacker)
	return false
end

function GM:StartCommand(ply, cmd)
	local mine = ply.RFMine
	if not IsValid(mine) then return end

	mine:ReadCommand(cmd)
end

function GM:PlayerDisconnected(ply)
	RF.RemoveMine(ply)
end
