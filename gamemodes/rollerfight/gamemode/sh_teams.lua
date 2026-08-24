TEAM_COMBINE = 1
TEAM_REBEL = 2
TEAM_FREE = 3

RF.TeamColors = {
	[TEAM_COMBINE] = Color(80, 150, 255),
	[TEAM_REBEL] = Color(255, 150, 15),
	[TEAM_FREE] = Color(210, 210, 210)
}

function GM:CreateTeams()
	team.SetUp(TEAM_COMBINE, "Combine", RF.TeamColors[TEAM_COMBINE])
	team.SetUp(TEAM_REBEL, "Rebels", RF.TeamColors[TEAM_REBEL])
	team.SetUp(TEAM_FREE, "Fighters", RF.TeamColors[TEAM_FREE])

	team.SetSpawnPoint(TEAM_COMBINE, { "info_player_start", "info_player_combine", "info_player_deathmatch" })
	team.SetSpawnPoint(TEAM_REBEL, { "info_player_start", "info_player_rebel", "info_player_deathmatch" })
	team.SetSpawnPoint(TEAM_FREE, { "info_player_start", "info_player_deathmatch" })
end
