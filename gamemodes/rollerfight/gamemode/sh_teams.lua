TEAM_COMBINE = 1
TEAM_REBEL = 2
TEAM_FREE = 3

RF.TeamColors = {
	[TEAM_COMBINE] = Color(80, 150, 255),
	[TEAM_REBEL] = Color(255, 150, 15),
	[TEAM_FREE] = Color(210, 210, 210)
}

RF.FFAColors = {
	Color(235, 80, 60),
	Color(80, 150, 255),
	Color(90, 205, 105),
	Color(245, 200, 50),
	Color(200, 110, 235),
	Color(80, 220, 220),
	Color(250, 140, 40),
	Color(240, 120, 180),
	Color(155, 225, 70),
	Color(140, 140, 245),
	Color(230, 230, 230),
	Color(180, 130, 80)
}

function RF.PlayerColor(ply)
	if not IsValid(ply) then return RF.TeamColors[TEAM_FREE] end

	if ply:Team() == TEAM_FREE then
		local col = RF.FFAColors[ply:GetNWInt("rf_color", 0)]
		if col then return col end
	end

	return RF.TeamColors[ply:Team()] or RF.TeamColors[TEAM_FREE]
end

function RF.Playing(ply)
	return IsValid(ply) and not ply:GetNWBool("rf_spectating", false)
end

function RF.TeamRoster(teamID)
	local list = {}

	for _, ply in ipairs(player.GetAll()) do
		if RF.Playing(ply) and ply:Team() == teamID then table.insert(list, ply) end
	end

	table.sort(list, function(a, b) return a:EntIndex() < b:EntIndex() end)

	return list
end

function RF.TeamCap()
	local total = 0

	for _, ply in ipairs(player.GetAll()) do
		if RF.Playing(ply) then total = total + 1 end
	end

	return math.max(1, math.ceil(total * 0.5))
end

function RF.CanJoinTeam(ply, teamID)
	if teamID ~= TEAM_COMBINE and teamID ~= TEAM_REBEL then return false end
	if not RF.Playing(ply) then return false end
	if ply:Team() == teamID then return false end

	return #RF.TeamRoster(teamID) < RF.TeamCap()
end

function GM:CreateTeams()
	team.SetUp(TEAM_COMBINE, "Combine", RF.TeamColors[TEAM_COMBINE])
	team.SetUp(TEAM_REBEL, "Rebels", RF.TeamColors[TEAM_REBEL])
	team.SetUp(TEAM_FREE, "Fighters", RF.TeamColors[TEAM_FREE])

	team.SetSpawnPoint(TEAM_COMBINE, { "info_player_start", "info_player_combine", "info_player_deathmatch" })
	team.SetSpawnPoint(TEAM_REBEL, { "info_player_start", "info_player_rebel", "info_player_deathmatch" })
	team.SetSpawnPoint(TEAM_FREE, { "info_player_start", "info_player_deathmatch" })
end
