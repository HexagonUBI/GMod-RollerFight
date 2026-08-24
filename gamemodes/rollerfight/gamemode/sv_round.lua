util.AddNetworkString("rf_ready")
util.AddNetworkString("rf_training")
util.AddNetworkString("rf_gametype")
util.AddNetworkString("rf_forcestart")
util.AddNetworkString("rf_roundend")

function RF.SetState(state, duration)
	SetGlobalInt("rf_state", state)
	SetGlobalFloat("rf_state_end", duration and (CurTime() + duration) or 0)
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
	RF.SetState(RF.STATE_WAITING)
	RF.ClearReady()

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
		if IsValid(mine) then mine:SetFrozen(true) end
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
	local gt = RF.GetGameType()
	local ready, total = RF.ReadyCount()

	if total < gt.minPlayers then return false, "need " .. gt.minPlayers .. " players" end
	if ready < gt.minPlayers then return false, "need " .. gt.minPlayers .. " ready" end

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
end)
