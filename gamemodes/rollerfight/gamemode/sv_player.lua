function RF.MusicCue(ply, cue)
	if not IsValid(ply) then return end

	net.Start("rf_music_cue")
	net.WriteString(cue)
	net.Send(ply)
end

function RF.DetachPlayer(ply)
	ply:DrawShadow(false)
	ply:SetSolid(SOLID_BBOX)
	ply:SetCollisionBounds(Vector(-8, -8, -8), Vector(8, 8, 8))
	ply:SetViewOffset(vector_origin)
	ply:SetViewOffsetDucked(vector_origin)
	ply:SetCurrentViewOffset(vector_origin)
	ply:AllowFlashlight(true)

	RF.EnforceDetached(ply)
end

function RF.EnforceDetached(ply)
	if not ply:GetNoDraw() then ply:SetNoDraw(true) end
	if ply:GetMoveType() ~= MOVETYPE_NONE then ply:SetMoveType(MOVETYPE_NONE) end
	if ply:GetCollisionGroup() ~= COLLISION_GROUP_IN_VEHICLE then ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) end

	ply:SetNotSolid(true)

	if ply:FlashlightIsOn() then ply:Flashlight(false) end
	if IsValid(ply:GetVehicle()) then ply:ExitVehicle() end
end

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
	RF.MusicCue(ply, "spawn")

	return mine
end

function RF.OnMineDestroyed(mine, attacker)
	local ply = mine:GetDriver()

	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker == ply then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)
			RF.MusicCue(attacker, "kill")
		end
	end

	if not IsValid(ply) then return end

	ply.RFMine = nil
	ply:SetNWEntity("rf_mine", NULL)
	ply:AddDeaths(1)
	RF.MusicCue(ply, "death")

	if RF.IsTraining(ply) then
		timer.Simple(1, function()
			if IsValid(ply) and RF.IsTraining(ply) then RF.GiveMine(ply, RF.SelectSpawnPos(ply)) end
		end)

		return
	end

	if not RF.InRound() then return end

	local lives = ply:GetNWInt("rf_lives", 0)

	if RF.GetGameType().lives > 0 then
		ply:SetNWInt("rf_lives", math.max(0, lives - 1))
		timer.Simple(0.2, RF.CheckWin)

		return
	end

	local delay = RF.Get("RespawnTime")
	if delay <= 0 then delay = 0.1 end

	timer.Simple(delay, function()
		if not IsValid(ply) or not ply:Alive() then return end
		if not RF.InRound() then return end

		RF.GiveMine(ply, RF.SelectSpawnPos(ply))
	end)
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_FREE)
end

function GM:PlayerSpawn(ply, transition)
	self.BaseClass.PlayerSpawn(self, ply, transition)
	RF.DetachPlayer(ply)

	if RF.InRound() and RF.GetGameType().lives <= 0 then
		RF.GiveMine(ply, RF.SelectSpawnPos(ply))
	end
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

function GM:SetupPlayerVisibility(ply)
	local mine = ply.RFMine
	if not IsValid(mine) then return end

	AddOriginToPVS(mine:GetPos())
end

function GM:PlayerSwitchFlashlight(ply, on)
	local mine = ply.RFMine
	if IsValid(mine) then mine:ToggleLamp() end

	return false
end

concommand.Add("rf_lamp", function(ply)
	local mine = IsValid(ply) and ply.RFMine
	if IsValid(mine) then mine:ToggleLamp() end
end)

function GM:PlayerEnteredVehicle(ply, vehicle)
	timer.Simple(0, function()
		if IsValid(ply) and IsValid(ply:GetVehicle()) then ply:ExitVehicle() end
	end)
end

function GM:PlayerUse(ply, ent)
	if not IsValid(ent) then return true end

	local class = ent:GetClass()

	if string.find(class, "vehicle") or string.find(class, "chair") then return false end

	return true
end
