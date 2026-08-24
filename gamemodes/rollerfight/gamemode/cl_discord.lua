RF.Discord = RF.Discord or {}

local Discord = RF.Discord
local Platforms = { "win64", "win32", "linux64", "linux", "osx64", "osx" }

local Adapters = {
	{
		module = "drpc",
		global = "DiscordRPC",
		Init = function(api, id) api.Initialize(id) end,
		Update = function(api, data) api.UpdatePresence(data) end,
		Shutdown = function(api) if api.Shutdown then api.Shutdown() end end
	},
	{
		module = "discordrpc",
		global = "discordRPC",
		Init = function(api, id) api.initialize(id, true) end,
		Update = function(api, data) api.updatePresence(data) end,
		Shutdown = function(api) if api.shutdown then api.shutdown() end end
	},
	{
		module = "gdiscord",
		global = "discord",
		Init = function(api, id) api.Init(id) end,
		Update = function(api, data) api.SetPresence(data) end,
		Shutdown = function(api) if api.Shutdown then api.Shutdown() end end
	}
}

Discord.Adapter = nil
Discord.API = nil
Discord.Ready = false
Discord.Scanned = false
Discord.Started = CurTime()

local function ModuleInstalled(name)
	for _, platform in ipairs(Platforms) do
		if file.Exists("lua/bin/gmcl_" .. name .. "_" .. platform .. ".dll", "GAME") then return true end
	end

	return file.Exists("includes/modules/" .. name .. ".lua", "LUA")
end

function Discord.Detect()
	if Discord.Adapter then return true end
	if Discord.Scanned then return false end

	Discord.Scanned = true

	for _, adapter in ipairs(Adapters) do
		if _G[adapter.global] == nil and ModuleInstalled(adapter.module) then
			pcall(require, adapter.module)
		end

		if _G[adapter.global] ~= nil then
			Discord.Adapter = adapter
			Discord.API = _G[adapter.global]

			return true
		end
	end

	MsgN("[RollerFight] no Discord RPC binary module in lua/bin, presence stays off. See rf_discord_status.")

	return false
end

function Discord.Enabled()
	return RF.Get("Discord") >= 1
end

function Discord.Start()
	if Discord.Ready then return true end
	if RF.DiscordAppID == "" then return false end
	if not Discord.Detect() then return false end

	Discord.Ready = pcall(Discord.Adapter.Init, Discord.API, RF.DiscordAppID)

	return Discord.Ready
end

function Discord.Stop()
	if not Discord.Ready then return end

	pcall(Discord.Adapter.Shutdown, Discord.API)
	Discord.Ready = false
end

function Discord.BuildPresence()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local gt = RF.GetGameType()
	local round = RF.GetState()
	local details, state

	if round == RF.STATE_WAITING then
		details = "Waiting For Players"
		state = RF.IsTraining(ply) and "Training" or game.GetMap()
	elseif round == RF.STATE_POST then
		details = "Round Over"
		state = string.format("%d kills, %d deaths", ply:Frags(), ply:Deaths())
	else
		details = gt.name
		state = IsValid(ply:GetNWEntity("rf_mine"))
			and string.format("%d kills, %d deaths", ply:Frags(), ply:Deaths())
			or "Destroyed"
	end

	local teamName = team.GetName(ply:Team()) or "Fighters"

	return {
		details = details,
		state = state,
		large_image_key = "rf_logo",
		large_image_text = "RollerFight",
		small_image_key = RF.DiscordTeamIcon[ply:Team()] or "rf_free",
		small_image_text = teamName,
		largeImageKey = "rf_logo",
		largeImageText = "RollerFight",
		smallImageKey = RF.DiscordTeamIcon[ply:Team()] or "rf_free",
		smallImageText = teamName,
		party_size = #player.GetAll(),
		party_max = game.MaxPlayers(),
		startTimestamp = math.floor(os.time() - (CurTime() - Discord.Started))
	}
end

function Discord.Refresh()
	if not Discord.Enabled() then
		Discord.Stop()
		return
	end

	if not Discord.Start() then return end

	local presence = Discord.BuildPresence()
	if not presence then return end

	pcall(Discord.Adapter.Update, Discord.API, presence)
end

function Discord.Toggle()
	RunConsoleCommand("rf_discord", Discord.Enabled() and "0" or "1")

	timer.Simple(0.1, function()
		Discord.Refresh()
		chat.AddText(Color(120, 200, 255), "[RollerFight] ", color_white,
			"Discord presence " .. (Discord.Enabled() and "on" or "off"))
	end)
end

concommand.Add("rf_discord_toggle", Discord.Toggle)

concommand.Add("rf_discord_status", function()
	Discord.Detect()

	MsgN("[RollerFight] discord enabled: " .. tostring(Discord.Enabled()))
	MsgN("[RollerFight] app id: " .. (RF.DiscordAppID == "" and "not set" or RF.DiscordAppID))
	MsgN("[RollerFight] binary module: " .. (Discord.Adapter and Discord.Adapter.global or "none installed"))
	MsgN("[RollerFight] connected: " .. tostring(Discord.Ready))

	for _, adapter in ipairs(Adapters) do
		MsgN("    looked for lua/bin/gmcl_" .. adapter.module .. "_<platform>.dll")
	end
end)

timer.Create("RF.DiscordRefresh", 15, 0, function()
	if not IsValid(LocalPlayer()) then return end
	if not Discord.Enabled() then return end
	if not Discord.Adapter and Discord.Scanned then return end

	Discord.Refresh()
end)

hook.Add("InitPostEntity", "RF.DiscordStart", function()
	timer.Simple(3, Discord.Refresh)
end)

hook.Add("ShutDown", "RF.DiscordStop", Discord.Stop)
