util.AddNetworkString("rf_ready")
util.AddNetworkString("rf_training")
util.AddNetworkString("rf_gametype")
util.AddNetworkString("rf_forcestart")
util.AddNetworkString("rf_roundend")
util.AddNetworkString("rf_pause")
util.AddNetworkString("rf_spectate")
util.AddNetworkString("rf_anchors")

RF.Anchors = {}

local function AnchorAt(sample)
	if util.PointContents(sample) ~= CONTENTS_EMPTY then return end

	local tr = util.TraceLine({
		start = sample,
		endpos = sample - Vector(0, 0, 4096),
		mask = MASK_SOLID_BRUSHONLY
	})

	if not tr.Hit or tr.HitSky or tr.HitNormal.z < 0.7 then return end

	local eye = tr.HitPos + Vector(0, 0, RF.Get("LobbyCamHeight"))

	if not util.IsInWorld(eye) then return end
	if util.PointContents(eye) ~= CONTENTS_EMPTY then return end

	local head = util.TraceLine({
		start = tr.HitPos + Vector(0, 0, 16),
		endpos = eye + Vector(0, 0, 24),
		mask = MASK_SOLID_BRUSHONLY
	})

	if head.Fraction < 0.9 then return end

	return eye
end

function RF.BuildAnchors()
	RF.Anchors = {}

	for _, class in ipairs(RF.SpawnClasses) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			local point = AnchorAt(ent:GetPos() + Vector(0, 0, 48))
			if point then table.insert(RF.Anchors, point) end
		end
	end

	local mins, maxs = game.GetWorld():GetModelBounds()

	for _ = 1, 6000 do
		if #RF.Anchors >= 48 then break end

		local point = AnchorAt(Vector(
			math.Rand(mins.x, maxs.x),
			math.Rand(mins.y, maxs.y),
			math.Rand(mins.z, maxs.z)
		))

		if point then table.insert(RF.Anchors, point) end
	end

	MsgN("[RollerFight] built " .. #RF.Anchors .. " camera anchors")
end

function RF.SendAnchors(ply)
	if #RF.Anchors == 0 then return end

	net.Start("rf_anchors")
	net.WriteUInt(#RF.Anchors, 8)

	for _, point in ipairs(RF.Anchors) do
		net.WriteVector(point)
	end

	if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function RF.SetState(state, duration)
	SetGlobalInt("rf_state", state)
	SetGlobalFloat("rf_state_end", duration and (CurTime() + duration) or 0)
end

function RF.FreezeAll(state)
	for _, ply in ipairs(player.GetAll()) do
		local mine = ply.RFMine
		if IsValid(mine) then mine:SetFrozen(state) end
	end
end

function RF.SetPaused(state)
	if state == GetGlobalBool("rf_paused", false) then return end

	if state then
		SetGlobalFloat("rf_pause_left", math.max(0, GetGlobalFloat("rf_state_end", 0) - CurTime()))
	else
		local left = GetGlobalFloat("rf_pause_left", 0)
		if left > 0 then SetGlobalFloat("rf_state_end", CurTime() + left) end
	end

	SetGlobalBool("rf_paused", state)
	RF.FreezeAll(state)
end

function RF.SetSpectate(ply, state)
	ply:SetNWBool("rf_spectating", state)

	if state then
		RF.RemoveMine(ply)
		ply:SetNWBool("rf_ready", false)
		ply:SetNWBool("rf_training", false)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:SetViewOffset(Vector(0, 0, 64))
		ply:SetCurrentViewOffset(Vector(0, 0, 64))

		return
	end

	ply:SetViewOffset(vector_origin)
	ply:SetCurrentViewOffset(vector_origin)
	RF.DetachPlayer(ply)

	if RF.InRound() and RF.GetGameType().lives <= 0 then
		RF.GiveMine(ply, RF.SelectSpawnPos(ply))
	end
end

function RF.CleanUpMap()
	for _, ent in ipairs(ents.FindByClass("rf_mine")) do
		ent:Remove()
	end

	game.CleanUpMap(false, {
		"rf_mine",
		"predicted_viewmodel",
		"player_manager"
	})
end

function RF.ClearReady()
	for _, ply in ipairs(player.GetAll()) do
		ply:SetNWBool("rf_ready", false)
	end
end

function RF.StopTraining(ply)
	if not RF.IsTraining(ply) then return end

	ply:SetNWBool("rf_training", false)
	RF.RemoveMine(ply)
end

function RF.StartTraining(ply)
	if RF.GetState() ~= RF.STATE_WAITING then return end
	if RF.IsTraining(ply) then return end

	ply:SetNWBool("rf_training", true)
	ply:SetNWBool("rf_ready", false)
	RF.GiveMine(ply, RF.SelectSpawnPos(ply))
end

function RF.EnterWaiting()
	RF.SetPaused(false)
	RF.SetState(RF.STATE_WAITING)
	RF.ClearReady()
	RF.CleanUpMap()

	for _, ply in ipairs(player.GetAll()) do
		ply:SetNWBool("rf_training", false)
		ply:SetFrags(0)
		ply:SetDeaths(0)
		ply:SetNWInt("rf_lives", 0)
		RF.RemoveMine(ply)
	end
end

function RF.EnterIntermission()
	for _, ply in ipairs(player.GetAll()) do
		ply:SetNWBool("rf_training", false)
		RF.RemoveMine(ply)
	end

	RF.SetState(RF.STATE_INTERMISSION, RF.Get("IntermissionTime"))
	RF.BroadcastCue("intermission")
end

function RF.EnterCountdown()
	local gt = RF.GetGameType()

	RF.CleanUpMap()

	RF.SetState(RF.STATE_COUNTDOWN, RF.Get("CountdownTime"))

	for _, ply in ipairs(player.GetAll()) do
		ply:SetFrags(0)
		ply:SetDeaths(0)
		ply:SetNWInt("rf_lives", gt.lives)

		if gt.teams then
			RF.AssignTeam(ply)
		else
			ply:SetTeam(TEAM_FREE)
		end

		local mine = RF.GiveMine(ply, RF.SelectSpawnPos(ply))
		if IsValid(mine) then mine:SetFrozen(true) end
	end
end

function RF.EnterActive()
	RF.SetState(RF.STATE_ACTIVE, RF.Get("RoundTime"))

	for _, ply in ipairs(player.GetAll()) do
		local mine = ply.RFMine
		if IsValid(mine) then mine:SetFrozen(false) end
	end

	RF.BroadcastCue("roundstart")
end

function RF.EnterPost(reason)
	RF.SetState(RF.STATE_POST, RF.Get("PostTime"))

	for _, ply in ipairs(player.GetAll()) do
		local mine = ply.RFMine

		if IsValid(mine) then
			mine:SetFrozen(true)
			mine:ShowSelfDestruct()
		end
	end

	net.Start("rf_roundend")
	net.WriteString(reason or "")
	net.Broadcast()
end

function RF.AssignTeam(ply)
	local combine, rebel = 0, 0

	for _, other in ipairs(player.GetAll()) do
		if other ~= ply then
			if other:Team() == TEAM_COMBINE then combine = combine + 1 end
			if other:Team() == TEAM_REBEL then rebel = rebel + 1 end
		end
	end

	ply:SetTeam(combine <= rebel and TEAM_COMBINE or TEAM_REBEL)
end

function RF.BroadcastCue(cue)
	net.Start("rf_music_cue")
	net.WriteString(cue)
	net.Broadcast()
end

function RF.CanStart()
	local need = math.max(1, math.floor(RF.Get("MinPlayers")))
	local ready, total = RF.ReadyCount()

	if total < need then return false, "need " .. need .. " players" end
	if ready < need then return false, "need " .. need .. " ready" end

	return true
end

function RF.AliveCount()
	local alive, teams = 0, {}

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply.RFMine) or ply:GetNWInt("rf_lives", 0) > 0 then
			alive = alive + 1
			teams[ply:Team()] = (teams[ply:Team()] or 0) + 1
		end
	end

	return alive, teams
end

function RF.CheckWin()
	if RF.GetState() ~= RF.STATE_ACTIVE then return end

	local gt = RF.GetGameType()
	local limit = RF.Get("ScoreLimit")

	if limit > 0 and not gt.teams then
		for _, ply in ipairs(player.GetAll()) do
			if ply:Frags() >= limit then
				RF.EnterPost(ply:Nick() .. " reached the score limit")
				return
			end
		end
	end

	if gt.lives > 0 then
		local alive, teams = RF.AliveCount()

		if alive <= 1 then
			local winner

			for _, ply in ipairs(player.GetAll()) do
				if IsValid(ply.RFMine) then winner = ply end
			end

			RF.EnterPost(winner and (winner:Nick() .. " is the last one standing") or "Everyone was destroyed")
		end
	end
end

local function Tick()
	if GetGlobalBool("rf_paused", false) then return end

	local state = RF.GetState()

	if state == RF.STATE_WAITING then
		local ok = RF.CanStart()
		local ready, total = RF.ReadyCount()
		local autoAt = GetGlobalFloat("rf_autostart", 0)

		if ok and ready >= total then
			RF.EnterIntermission()
			SetGlobalFloat("rf_autostart", 0)

			return
		end

		if ok then
			if autoAt <= 0 then
				SetGlobalFloat("rf_autostart", CurTime() + RF.Get("AutoStartTime"))
			elseif CurTime() >= autoAt then
				RF.EnterIntermission()
				SetGlobalFloat("rf_autostart", 0)
			end
		else
			SetGlobalFloat("rf_autostart", 0)
		end

		return
	end

	if RF.StateTimeLeft() > 0 then
		if state == RF.STATE_ACTIVE then RF.CheckWin() end

		return
	end

	if state == RF.STATE_INTERMISSION then RF.EnterCountdown() return end
	if state == RF.STATE_COUNTDOWN then RF.EnterActive() return end
	if state == RF.STATE_ACTIVE then RF.EnterPost("Time up") return end
	if state == RF.STATE_POST then RF.EnterWaiting() return end
end

timer.Create("RF.RoundTick", 0.25, 0, Tick)

net.Receive("rf_ready", function(len, ply)
	if RF.GetState() ~= RF.STATE_WAITING then return end
	if RF.IsTraining(ply) then return end

	ply:SetNWBool("rf_ready", not RF.IsReady(ply))
end)

net.Receive("rf_training", function(len, ply)
	if RF.GetState() ~= RF.STATE_WAITING then return end

	if RF.IsTraining(ply) then
		RF.StopTraining(ply)
	else
		RF.StartTraining(ply)
	end
end)

net.Receive("rf_gametype", function(len, ply)
	if not RF.IsAdmin(ply) then return end
	if RF.GetState() ~= RF.STATE_WAITING then return end

	local index = math.Clamp(net.ReadUInt(4), 1, #RF.GameTypes)
	local cv = GetConVar("rf_gametype")

	if cv then cv:SetInt(index) end
end)

net.Receive("rf_pause", function(len, ply)
	if not RF.IsAdmin(ply) then return end

	RF.SetPaused(not GetGlobalBool("rf_paused", false))
end)

net.Receive("rf_spectate", function(len, ply)
	if not RF.IsAdmin(ply) then return end

	RF.SetSpectate(ply, not ply:GetNWBool("rf_spectating", false))
end)

net.Receive("rf_forcestart", function(len, ply)
	if not RF.IsAdmin(ply) then return end
	if RF.GetState() ~= RF.STATE_WAITING then return end

	RF.EnterIntermission()
end)

hook.Add("PlayerDisconnected", "RF.RoundLeave", function()
	timer.Simple(0.1, RF.CheckWin)
end)

hook.Add("InitPostEntity", "RF.RoundBoot", function()
	timer.Simple(1, RF.EnterWaiting)
	timer.Simple(2, function()
		RF.BuildAnchors()
		RF.SendAnchors()
	end)
end)

hook.Add("PlayerInitialSpawn", "RF.RoundAnchors", function(ply)
	timer.Simple(4, function()
		if not IsValid(ply) then return end
		if #RF.Anchors == 0 then RF.BuildAnchors() end

		RF.SendAnchors(ply)
	end)
end)
