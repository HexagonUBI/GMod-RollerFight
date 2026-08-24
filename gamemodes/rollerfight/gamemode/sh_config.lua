RF = RF or {}

RF.MineModel = "models/roller.mdl"
RF.SpikeModel = "models/roller_spikes.mdl"
RF.BodyTexture = "models/roller/rollermine_sheet"
RF.BodyNormal = "models/roller/rollermine_normal"
RF.GlowTexture = "models/roller/rollermine_glow"
RF.DeathColor = Color(255, 55, 45)
RF.MineRadius = 12.56

local r = RF.MineRadius
local ring = r * 0.6
local ringDepth = math.sqrt(r * r - ring * ring)

RF.GroundSamples = {
	{ offset = Vector(0, 0, 0), depth = r },
	{ offset = Vector(ring, 0, 0), depth = ringDepth },
	{ offset = Vector(-ring, 0, 0), depth = ringDepth },
	{ offset = Vector(0, ring, 0), depth = ringDepth },
	{ offset = Vector(0, -ring, 0), depth = ringDepth }
}

RF.SpawnClasses = {
	"info_player_start",
	"info_player_deathmatch",
	"info_player_combine",
	"info_player_rebel",
	"info_player_counterterrorist",
	"info_player_terrorist",
	"gmod_player_start"
}

RF.DiscordAppID = "1541518230764658788"

RF.DiscordTeamIcon = {
	[1] = "rf_combine",
	[2] = "rf_rebel",
	[3] = "rf_free"
}

RF.MusicBedVolume = 0.75
RF.MusicDuck = 0.25
RF.MusicDuckTime = 4
RF.MusicStingGap = 6

RF.MusicBeds = {
	lobby = {
		"music/hl2_song2.mp3",
		"music/hl2_song3.mp3",
		"music/hl2_song26_trainstation1.mp3"
	},
	waiting = {
		"music/hl2_song2.mp3",
		"music/hl2_song3.mp3",
		"music/hl2_song4.mp3",
		"music/hl2_song26_trainstation1.mp3"
	},
	combat = {
		"music/hl2_song15.mp3",
		"music/hl2_song14.mp3",
		"music/hl2_song12_long.mp3",
		"music/hl2_song17.mp3",
		"music/hl2_song31.mp3"
	},
	danger = {
		"music/hl2_song20_submix0.mp3",
		"music/hl2_song20_submix4.mp3",
		"music/hl2_song29.mp3",
		"music/ravenholm_1.mp3"
	}
}

RF.MusicStings = {
	spawn = "music/stingers/hl1_stinger_song7.mp3",
	kill = "music/stingers/hl1_stinger_song8.mp3",
	death = "music/stingers/hl1_stinger_song16.mp3",
	intermission = "music/stingers/hl1_stinger_song27.mp3",
	roundstart = "music/stingers/hl1_stinger_song28.mp3"
}

RF.BodyBias = Vector(0.49, 0.93, 1.00)
RF.GlowBias = Vector(0.45, 0.95, 1.00)

RF.Diggable = {
	[MAT_DIRT] = true,
	[MAT_SAND] = true,
	[MAT_GRASS] = true,
	[MAT_SNOW] = true
}

RF.VarList = {
	{ key = "MineMass", group = "Physics", label = "Mine Mass", default = 90, min = 10, max = 400, respawn = true },
	{ key = "RollPower", group = "Physics", label = "Roll Power", default = 14000, min = 500, max = 60000 },
	{ key = "SprintPower", group = "Physics", label = "Sprint Roll Power", default = 22000, min = 500, max = 90000 },
	{ key = "RotCap", group = "Physics", label = "Angular Speed Cap", default = 1500, min = 100, max = 6000 },
	{ key = "SprintRotCap", group = "Physics", label = "Sprint Angular Cap", default = 2600, min = 100, max = 9000 },
	{ key = "JumpForce", group = "Physics", label = "Jump Force", default = 24113, min = 0, max = 90000 },
	{ key = "JumpCooldown", group = "Physics", label = "Jump Cooldown", default = 0.03, min = 0, max = 5 },
	{ key = "DashForce", group = "Physics", label = "Dash Force", default = 55000, min = 0, max = 250000 },
	{ key = "DashCooldown", group = "Physics", label = "Dash Cooldown", default = 1.4, min = 0, max = 10 },
	{ key = "Traction", group = "Physics", label = "Traction On Slippery Ground", default = 3, min = 0, max = 30 },
	{ key = "TractionSlip", group = "Physics", label = "Slip Before Traction Helps", default = 25, min = 1, max = 400 },
	{ key = "GroundSlack", group = "Physics", label = "Ground Contact Slack", default = 2, min = 0.5, max = 16 },
	{ key = "Debug", group = "Physics", label = "Show Debug Readout", default = 0, min = 0, max = 1, realm = "client" },
	{ key = "GroundBrake", group = "Physics", label = "Ground Brake When Idle", default = 0, min = 0, max = 8 },

	{ key = "MoveMode", group = "Arcade", label = "Move Mode (0 physics, 1 arcade)", default = 0, min = 0, max = 1 },
	{ key = "ArcadeSpeed", group = "Arcade", label = "Arcade Top Speed", default = 430, min = 50, max = 2000 },
	{ key = "ArcadeSprintSpeed", group = "Arcade", label = "Arcade Sprint Speed", default = 720, min = 50, max = 3000 },
	{ key = "ArcadeAccel", group = "Arcade", label = "Arcade Ground Accel", default = 2600, min = 100, max = 20000 },
	{ key = "ArcadeAirAccel", group = "Arcade", label = "Arcade Air Control", default = 900, min = 0, max = 20000 },
	{ key = "ArcadeJumpSpeed", group = "Arcade", label = "Arcade Jump Speed", default = 300, min = 0, max = 1200 },
	{ key = "ArcadeSpin", group = "Arcade", label = "Arcade Visual Spin", default = 5000, min = 0, max = 40000 },

	{ key = "MineHealth", group = "Combat", label = "Mine Health", default = 100, min = 1, max = 500, respawn = true },
	{ key = "HitDamage", group = "Combat", label = "Contact Damage", default = 15, min = 0, max = 200 },
	{ key = "DashDamage", group = "Combat", label = "Dash Damage", default = 25, min = 0, max = 200 },
	{ key = "HitForce", group = "Combat", label = "Contact Knockback", default = 50210, min = 0, max = 200000 },
	{ key = "HitCooldown", group = "Combat", label = "Per Target Hit Delay", default = 0.6, min = 0.05, max = 5 },
	{ key = "DashWindow", group = "Combat", label = "Dash Hit Window", default = 0.9, min = 0, max = 5 },
	{ key = "DashAttackHold", group = "Combat", label = "Dash Attack Hold", default = 1, min = 0, max = 10 },
	{ key = "FriendlyFire", group = "Combat", label = "Friendly Fire", default = 0, min = 0, max = 1 },
	{ key = "WaterKillLevel", group = "Combat", label = "Water Kill Level", default = 1, min = 0, max = 3 },
	{ key = "DeathJumpForce", group = "Combat", label = "Death Jump Force", default = 30000, min = 0, max = 150000 },
	{ key = "DeathDelay", group = "Combat", label = "Death Blink Time", default = 0.7, min = 0.1, max = 5 },
	{ key = "ShockSize", group = "Combat", label = "Shock Beam Width", default = 18, min = 1, max = 60 },
	{ key = "ShockBranchLength", group = "Combat", label = "Shock Branch Length", default = 55, min = 0, max = 400 },
	{ key = "ShockBranchCount", group = "Combat", label = "Shock Branch Count", default = 0, min = 0, max = 12 },
	{ key = "HitNPCs", group = "Combat", label = "Damage NPCs", default = 1, min = 0, max = 1 },
	{ key = "SpeedDamageRef", group = "Combat", label = "Speed For Full Bonus", default = 700, min = 50, max = 3000 },
	{ key = "SpeedDamageBonus", group = "Combat", label = "Max Speed Damage Bonus", default = 0.5, min = 0, max = 3 },

	{ key = "MaxEnergy", group = "Energy", label = "Max Energy", default = 150, min = 1, max = 500 },
	{ key = "SprintDrain", group = "Energy", label = "Sprint Drain", default = 24, min = 0, max = 200 },
	{ key = "AttackDrain", group = "Energy", label = "Attack Mode Drain", default = 4, min = 0, max = 100 },
	{ key = "DashCost", group = "Energy", label = "Dash Cost", default = 34, min = 0, max = 200 },
	{ key = "EnergyRegen", group = "Energy", label = "Energy Regen", default = 18, min = 0, max = 200 },
	{ key = "EnergyRegenDelay", group = "Energy", label = "Regen Delay", default = 0.8, min = 0, max = 10 },
	{ key = "ExhaustRecoverAt", group = "Energy", label = "Exhaust Recovery", default = 35, min = 0, max = 500 },
	{ key = "DashAttackLock", group = "Energy", label = "Dash Attack Lockout", default = 3, min = 0, max = 20 },

	{ key = "BurrowExposed", group = "Digging", label = "Visible Above Ground", default = 4, min = 0, max = 24 },
	{ key = "BurrowCooldown", group = "Digging", label = "Burrow Cooldown", default = 1, min = 0, max = 10 },

	{ key = "RespawnTime", group = "Round", label = "Respawn Seconds", default = 10, min = 0, max = 120 },
	{ key = "GameType", group = "Round", label = "Gametype (1 DM, 2 TDM, 3 LOTS)", default = 1, min = 1, max = 3 },
	{ key = "RoundTime", group = "Round", label = "Round Length", default = 300, min = 30, max = 3600 },
	{ key = "ScoreLimit", group = "Round", label = "Score Limit (0 off)", default = 15, min = 0, max = 200 },
	{ key = "AutoStartTime", group = "Round", label = "Auto Start Countdown", default = 30, min = 5, max = 300 },
	{ key = "IntermissionTime", group = "Round", label = "Intermission Length", default = 8, min = 2, max = 30 },
	{ key = "CountdownTime", group = "Round", label = "Countdown Length", default = 3, min = 1, max = 10 },
	{ key = "PostTime", group = "Round", label = "Stats Screen Length", default = 12, min = 3, max = 60 },

	{ key = "CameraDistance", group = "Camera", label = "Camera Distance", default = 95, min = 40, max = 400, realm = "client" },
	{ key = "CameraHeight", group = "Camera", label = "Camera Height", default = 22, min = -50, max = 150, realm = "client" },
	{ key = "CameraSmooth", group = "Camera", label = "Camera Smoothing", default = 9, min = 1, max = 60, realm = "client" },
	{ key = "CameraSmoothVertical", group = "Camera", label = "Vertical Smoothing", default = 4, min = 1, max = 60, realm = "client" },
	{ key = "LobbyShot", group = "Camera", label = "Lobby Shot Length", default = 14, min = 3, max = 60, realm = "client" },
	{ key = "IntermissionShot", group = "Camera", label = "Intermission Shot Length", default = 1.6, min = 0.4, max = 6, realm = "client" },
	{ key = "LobbyCamHeight", group = "Camera", label = "Lobby Camera Height", default = 70, min = 8, max = 300, realm = "client" },

	{ key = "TeamTint", group = "Look", label = "Team Color Strength", default = 1.2, min = 0.2, max = 4, realm = "client" },
	{ key = "GlowSize", group = "Look", label = "Glow Sprite Size", default = 34, min = 0, max = 120, realm = "client" },
	{ key = "LampSize", group = "Look", label = "Lamp Radius", default = 420, min = 50, max = 1500, realm = "client" },
	{ key = "LampBrightness", group = "Look", label = "Lamp Brightness", default = 3, min = 0.2, max = 12, realm = "client" },

	{ key = "MusicVolume", group = "Audio", label = "Music Volume (x game music slider)", default = 0.8, min = 0, max = 1, realm = "client" },
	{ key = "MusicDangerAt", group = "Audio", label = "Danger Music Below Health", default = 0.35, min = 0, max = 1, realm = "client" },
	{ key = "Discord", group = "Audio", label = "Discord Rich Presence", default = 1, min = 0, max = 1, realm = "client" },

	{ key = "CompatStrip", group = "Compat", label = "Remove Conflicting Addon Hooks", default = 1, min = 0, max = 1 }
}

RF.VarByKey = {}
RF.VarGroups = {}

for _, v in ipairs(RF.VarList) do
	v.name = "rf_" .. string.lower(v.key)
	RF.VarByKey[v.key] = v

	if not table.HasValue(RF.VarGroups, v.group) then
		table.insert(RF.VarGroups, v.group)
	end

	if v.realm == "client" then
		if CLIENT then
			CreateConVar(v.name, tostring(v.default), { FCVAR_ARCHIVE }, v.label, v.min, v.max)
		end
	elseif SERVER then
		CreateConVar(v.name, tostring(v.default), { FCVAR_REPLICATED, FCVAR_NOTIFY }, v.label, v.min, v.max)
	end
end

function RF.Get(key)
	local v = RF.VarByKey[key]
	if not v then return 0 end

	local cv = GetConVar(v.name)
	if not cv then return v.default end

	return cv:GetFloat()
end
