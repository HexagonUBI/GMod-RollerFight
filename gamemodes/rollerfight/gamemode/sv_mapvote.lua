util.AddNetworkString("rf_mapvote")
util.AddNetworkString("rf_mapvote_pick")
util.AddNetworkString("rf_mapvote_tally")

RF.MapChoices = {}
RF.MapVotes = {}
RF.MapVoteDone = false

function RF.MapAllowed(name)
	if not string.match(name, "^[%w_%-]+$") then return false end

	for _, pattern in ipairs(RF.MapPatterns) do
		if string.match(name, pattern) then return true end
	end

	return false
end

function RF.MapPool()
	local pool = {}

	for _, name in ipairs(file.Find("maps/*.bsp", "GAME") or {}) do
		local map = string.StripExtension(name)

		if RF.MapAllowed(map) then table.insert(pool, map) end
	end

	table.sort(pool)

	return pool
end

function RF.PickMapChoices()
	local pool = RF.MapPool()
	local cap = math.floor(RF.Get("MapVoteChoices"))

	if cap <= 0 or #pool <= cap then return pool end

	table.Shuffle(pool)

	local cut = {}

	for index = 1, cap do
		table.insert(cut, pool[index])
	end

	table.sort(cut)

	return cut
end

function RF.SendMapChoices(ply)
	net.Start("rf_mapvote")
	net.WriteUInt(#RF.MapChoices, 9)

	for _, map in ipairs(RF.MapChoices) do
		net.WriteString(map)
	end

	if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function RF.MapTally()
	local counts = {}

	for index = 1, #RF.MapChoices + 1 do
		counts[index] = 0
	end

	for ply, index in pairs(RF.MapVotes) do
		if IsValid(ply) and counts[index] then counts[index] = counts[index] + 1 end
	end

	return counts
end

function RF.SendMapTally()
	local list = {}

	for ply, index in pairs(RF.MapVotes) do
		if IsValid(ply) then table.insert(list, { ply, index }) end
	end

	net.Start("rf_mapvote_tally")
	net.WriteUInt(#list, 8)

	for _, entry in ipairs(list) do
		net.WriteEntity(entry[1])
		net.WriteUInt(entry[2], 9)
	end

	net.Broadcast()
end

function RF.EnterMapVote()
	if RF.Get("MapVote") < 1 then
		RF.EnterWaiting()

		return
	end

	RF.MapChoices = RF.PickMapChoices()

	if #RF.MapChoices == 0 then
		MsgN("[RollerFight] no maps matched RF.MapPatterns, skipping the vote")
		RF.EnterWaiting()

		return
	end

	RF.MapVotes = {}
	RF.MapVoteDone = false

	for _, ply in ipairs(player.GetAll()) do
		ply:SetNWBool("rf_training", false)
		RF.RemoveMine(ply)
	end

	RF.SetState(RF.STATE_MAPVOTE, RF.Get("MapVoteTime"))
	RF.SendMapChoices()
	RF.SendMapTally()
end

function RF.MapVoteWinner()
	local counts = RF.MapTally()
	local best, top = {}, -1

	for index, total in ipairs(counts) do
		if total > top then
			best, top = { index }, total
		elseif total == top then
			table.insert(best, index)
		end
	end

	local pick = RF.MapChoices[best[math.random(#best)]]
	if pick then return pick end

	local pool = RF.MapPool()

	return #pool > 0 and pool[math.random(#pool)] or game.GetMap()
end

function RF.FinishMapVote()
	if RF.MapVoteDone then return end

	RF.MapVoteDone = true

	local map = RF.MapVoteWinner()

	MsgN("[RollerFight] map vote picked " .. map)
	game.ConsoleCommand("changelevel " .. map .. "\n")
end

net.Receive("rf_mapvote_pick", function(len, ply)
	if RF.GetState() ~= RF.STATE_MAPVOTE then return end

	local index = net.ReadUInt(9)
	if index < 1 or index > #RF.MapChoices + 1 then return end
	if RF.MapVotes[ply] == index then return end

	RF.MapVotes[ply] = index
	RF.SendMapTally()
end)

hook.Add("PlayerDisconnected", "RF.MapVoteLeave", function(ply)
	if not RF.MapVotes[ply] then return end

	RF.MapVotes[ply] = nil

	timer.Simple(0.1, function()
		if RF.GetState() == RF.STATE_MAPVOTE then RF.SendMapTally() end
	end)
end)

hook.Add("PlayerInitialSpawn", "RF.MapVoteJoin", function(ply)
	timer.Simple(3, function()
		if not IsValid(ply) then return end
		if RF.GetState() ~= RF.STATE_MAPVOTE then return end

		RF.SendMapChoices(ply)
		RF.SendMapTally()
	end)
end)

concommand.Add("rf_maps", function(ply)
	if IsValid(ply) and not RF.IsAdmin(ply) then return end

	local pool = RF.MapPool()

	MsgN("[RollerFight] " .. #pool .. " maps match RF.MapPatterns:")

	for _, map in ipairs(pool) do
		MsgN("    " .. map)
	end
end)
