RF.STATE_WAITING = 0
RF.STATE_INTERMISSION = 1
RF.STATE_COUNTDOWN = 2
RF.STATE_ACTIVE = 3
RF.STATE_POST = 4
RF.STATE_TEAMPICK = 5
RF.STATE_MAPVOTE = 6

RF.StateNames = {
	[RF.STATE_WAITING] = "Waiting For Players",
	[RF.STATE_TEAMPICK] = "Choosing Teams",
	[RF.STATE_MAPVOTE] = "Map Vote",
	[RF.STATE_INTERMISSION] = "Starting",
	[RF.STATE_COUNTDOWN] = "Get Ready",
	[RF.STATE_ACTIVE] = "Round In Progress",
	[RF.STATE_POST] = "Round Over"
}

RF.GameTypes = {
	{
		id = "dm",
		name = "Deathmatch",
		blurb = "Everyone for themselves. Every mine its own colour.",
		banner = "rollerfight/gt_dm.png",
		teams = false,
		lives = 0,
		minPlayers = 2,
		maxPlayers = 10
	},
	{
		id = "tdm",
		name = "Team Deathmatch",
		blurb = "Combine against Rebels. Friendly fire is off by default.",
		banner = "rollerfight/gt_tdm.png",
		teams = true,
		lives = 0,
		minPlayers = 2,
		maxPlayers = 10
	},
	{
		id = "lots",
		name = "Last One To Stand",
		blurb = "One life. No respawns. Last mine rolling takes it.",
		banner = "rollerfight/gt_lots.png",
		teams = false,
		lives = 1,
		minPlayers = 3,
		maxPlayers = 20
	}
}

RF.GameTypeByID = {}
RF.GameTypeOrder = {}

for index, gt in ipairs(RF.GameTypes) do
	gt.index = index
	RF.GameTypeByID[gt.id] = gt
	RF.GameTypeOrder[index] = gt.id
end

function RF.GetGameType()
	local index = math.Clamp(math.floor(RF.Get("GameType")), 1, #RF.GameTypes)

	return RF.GameTypes[index]
end

function RF.GetState()
	return GetGlobalInt("rf_state", RF.STATE_WAITING)
end

function RF.StateEndsAt()
	return GetGlobalFloat("rf_state_end", 0)
end

function RF.StateTimeLeft()
	return math.max(0, RF.StateEndsAt() - CurTime())
end

function RF.InRound()
	local state = RF.GetState()

	return state == RF.STATE_ACTIVE or state == RF.STATE_COUNTDOWN
end

function RF.IsTraining(ply)
	return IsValid(ply) and ply:GetNWBool("rf_training", false)
end

function RF.RoundsPerMatch()
	return math.max(1, math.floor(RF.Get("RoundsPerMatch")))
end

function RF.RoundNumber()
	return math.max(1, GetGlobalInt("rf_round", 1))
end

function RF.LastRound()
	return GetGlobalBool("rf_lastround", false)
end

function RF.IsDown(ply)
	if not IsValid(ply) then return false end
	if not RF.InRound() then return false end
	if ply:GetNWBool("rf_spectating", false) then return false end

	return not IsValid(ply:GetNWEntity("rf_mine"))
end

function RF.IsReady(ply)
	return IsValid(ply) and ply:GetNWBool("rf_ready", false)
end

function RF.ReadyCount()
	local ready, total = 0, 0

	for _, ply in ipairs(player.GetAll()) do
		total = total + 1
		if RF.IsReady(ply) then ready = ready + 1 end
	end

	return ready, total
end
