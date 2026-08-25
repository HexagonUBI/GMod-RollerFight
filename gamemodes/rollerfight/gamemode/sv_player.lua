function RF.HideBody(ply)
	if not ply:GetNoDraw() then ply:SetNoDraw(true) end

	ply:SetNotSolid(true)
	ply:DrawShadow(false)
	RF.DropHands(ply)
end

function RF.RideMine(ply, mine)
	ply:StripWeapons()
	ply:AllowFlashlight(true)
	RF.HideBody(ply)
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(mine)
end

function RF.FreeRoam(ply)
	ply:StripWeapons()
	RF.HideBody(ply)
	ply:Spectate(OBS_MODE_ROAMING)
	ply:SpectateEntity(NULL)
end

function RF.DetachPlayer(ply)
	ply:DrawShadow(false)

	local mine = ply.RFMine

	if IsValid(mine) then
		RF.RideMine(ply, mine)
	else
		RF.FreeRoam(ply)
	end
end

function RF.EnforceDetached(ply)
	RF.HideBody(ply)

	if ply:GetNWBool("rf_spectating", false) then return end

	local mine = ply.RFMine

	if IsValid(mine) then
		if ply:GetObserverMode() ~= OBS_MODE_CHASE or ply:GetObserverTarget() ~= mine then
			RF.RideMine(ply, mine)
		end
	elseif ply:GetObserverMode() == OBS_MODE_NONE then
		RF.FreeRoam(ply)
	end

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

	if IsValid(ply) and not ply:GetNWBool("rf_spectating", false) then
		RF.FreeRoam(ply)
	end
end

function RF.AssignColor(ply)
	if ply:GetNWInt("rf_color", 0) > 0 then return end

	local taken = {}

	for _, other in ipairs(player.GetAll()) do
		if other ~= ply then taken[other:GetNWInt("rf_color", 0)] = true end
	end

	for index = 1, #RF.FFAColors do
		if not taken[index] then
			ply:SetNWInt("rf_color", index)
			return
		end
	end

	ply:SetNWInt("rf_color", math.random(#RF.FFAColors))
end

function RF.GiveMine(ply, pos)
	RF.RemoveMine(ply)

	local mine = ents.Create("rf_mine")
	if not IsValid(mine) then return end

	mine:SetPos(pos or (ply:GetPos() + Vector(0, 0, 24)))
	mine:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	mine:Spawn()
	mine:Activate()
	RF.AssignColor(ply)

	mine:SetDriver(ply)
	mine:SetMineTeam(ply:Team())
	mine:SetColorIndex(ply:GetNWInt("rf_color", 0))

	ply.RFMine = mine
	ply:SetNWEntity("rf_mine", mine)
	RF.RideMine(ply, mine)

	return mine
end

function RF.KillFeed(killer, victim, cause, assist)
	net.Start("rf_kill")
	net.WriteString(IsValid(killer) and killer:Nick() or "")
	net.WriteUInt(IsValid(killer) and killer:Team() or 0, 8)
	net.WriteUInt(IsValid(killer) and killer:GetNWInt("rf_color", 0) or 0, 8)
	net.WriteString(IsValid(victim) and victim:Nick() or "A rollermine")
	net.WriteUInt(IsValid(victim) and victim:Team() or 0, 8)
	net.WriteUInt(IsValid(victim) and victim:GetNWInt("rf_color", 0) or 0, 8)
	net.WriteString(cause or "world")
	net.WriteString(IsValid(assist) and assist:Nick() or "")
	net.Broadcast()
end

function RF.OnMineDestroyed(mine, attacker, cause, assist)
	local ply = mine:GetDriver()

	RF.KillFeed(attacker ~= ply and attacker or nil, ply, cause, assist)

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
	RF.AssignColor(ply)
end

function RF.DropHands(ply)
	local hands = ply:GetHands()

	if IsValid(hands) then hands:Remove() end

	ply.RFHands = nil
end

function GM:PlayerSpawn(ply, transition)
	ply:UnSpectate()
	ply:StripWeapons()
	ply:SetModel("models/player/kleiner.mdl")
	ply:SetMoveType(MOVETYPE_NOCLIP)
	ply:SetNoDraw(true)
	ply:SetNotSolid(true)
	ply:DrawShadow(false)
	ply:SetHealth(100)

	RF.DropHands(ply)
	RF.DetachPlayer(ply)

	if RF.InRound() and RF.GetGameType().lives <= 0 then
		RF.GiveMine(ply, RF.SelectSpawnPos(ply))
	end
end

function GM:PlayerSetHandsModel(ply, hands)
	if IsValid(hands) then hands:Remove() end
end

function GM:GetFallDamage()
	return 0
end

function GM:CanPlayerSuicide()
	return false
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
