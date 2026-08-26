RF.Score = RF.Score or {}

local Score = RF.Score
local Board

local COL_BG = Color(16, 16, 16, 240)
local COL_PANEL = Color(30, 30, 30, 255)
local COL_ROW = Color(42, 42, 42, 255)
local COL_ROWALT = Color(36, 36, 36, 255)
local COL_LINE = Color(70, 70, 70, 255)
local COL_TEXT = Color(228, 228, 228)
local COL_DIM = Color(150, 150, 150)
local COL_ACCENT = Color(238, 130, 32)

local function Box(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

local function Outline(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
end

local function Sorted()
	local list = player.GetAll()

	table.sort(list, function(a, b)
		local downA, downB = RF.IsDown(a), RF.IsDown(b)

		if downA ~= downB then return downB end
		if a:Frags() == b:Frags() then return a:Deaths() < b:Deaths() end

		return a:Frags() > b:Frags()
	end)

	return list
end

local function Sink(col, fade)
	return Color(col.r * fade, col.g * fade, col.b * fade, col.a or 255)
end

local function StyleTab(btn)
	btn:SetFont("RFHead")
	btn:SetTextColor(COL_TEXT)
	btn.Paint = function(self, w, h)
		local on = self.Active and self:Active()

		Box(0, 0, w, h, on and COL_ACCENT or Color(40, 40, 40))
		Outline(0, 0, w, h, COL_LINE)

		if on then
			self:SetTextColor(Color(20, 20, 20))
		else
			self:SetTextColor(self:IsHovered() and COL_ACCENT or COL_TEXT)
		end
	end
end

local ROW, GAP = 46, 3

local function Column(parent, teamID, wide)
	local wrap = parent:Add("DPanel")

	if wide then
		wrap:Dock(FILL)
	else
		wrap:Dock(LEFT)
		wrap:SetWide(wide == false and 0 or 0)
	end

	wrap.Paint = function() end

	local head = wrap:Add("DPanel")
	head:Dock(TOP)
	head:SetTall(26)
	head:DockMargin(0, 0, 0, 4)
	head.Paint = function(self, w, h)
		Box(0, 0, w, h, Color(24, 24, 24))

		if teamID then
			Box(0, 0, 4, h, RF.TeamColors[teamID] or COL_DIM)
			draw.SimpleText(string.upper(team.GetName(teamID) or ""), "RFHead", 14, h * 0.5,
				RF.TeamColors[teamID] or COL_TEXT, 0, TEXT_ALIGN_CENTER)
			draw.SimpleText("K   D", "RFSmall", w - 14, h * 0.5, COL_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			return
		end

		draw.SimpleText("PLAYER", "RFSmall", 80, h * 0.5, COL_DIM, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText("KILLS", "RFSmall", w - 250, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("DEATHS", "RFSmall", w - 170, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("RATIO", "RFSmall", w - 95, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("PING", "RFSmall", w - 25, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local list = wrap:Add("DScrollPanel")
	list:Dock(FILL)

	list.Rebuild = function()
		list:Clear()

		local canvas = list:GetCanvas()
		local width = RF.ListWidth(list, 2)
		local players = {}

		for _, ply in ipairs(Sorted()) do
			if not teamID or ply:Team() == teamID then table.insert(players, ply) end
		end

		canvas:SetTall(#players * (ROW + GAP))

		for index, ply in ipairs(players) do
			local row = vgui.Create("DPanel", canvas)
			row:SetSize(width, ROW)
			row:SetPos(0, (index - 1) * (ROW + GAP))
			row:SetMouseInputEnabled(true)

			local avatar = vgui.Create("AvatarImage", row)
			avatar:SetSize(32, 32)
			avatar:SetPos(teamID and 10 or 38, 7)
			avatar:SetPlayer(ply, 64)
			avatar:SetMouseInputEnabled(false)

			row.PaintOver = function(self, w, h)
				if not RF.IsDown(ply) then return end

				surface.SetDrawColor(16, 16, 16, 170)
				surface.DrawRect(teamID and 10 or 38, 7, 32, 32)
			end

			row.Paint = function(self, w, h)
				local down = RF.IsDown(ply)
				local fade = down and 0.42 or 1
				local main = down and Color(126, 126, 126) or COL_TEXT
				local sub = down and Color(96, 96, 96) or COL_DIM

				Box(0, 0, w, h, self:IsHovered() and Color(54, 54, 54) or (index % 2 == 0 and COL_ROWALT or COL_ROW))
				Box(0, 0, 4, h, Sink(RF.PlayerColor(ply), fade))
				Outline(teamID and 8 or 36, 5, 36, 36, Color(90 * fade, 90 * fade, 90 * fade))

				if ply == LocalPlayer() then Outline(0, 0, w, h, COL_ACCENT) end

				local textX = teamID and 52 or 80

				if not teamID then
					draw.SimpleText(index, "RFHead", 20, h * 0.5, sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

				draw.SimpleText(ply:Nick(), "RFBody", textX, h * 0.5 - 8, main, 0, TEXT_ALIGN_CENTER)

				local gt = RF.GetGameType()
				local note = ply:Ping() .. " ms"

				if RF.GetState() == RF.STATE_WAITING then
					note = RF.IsReady(ply) and "ready" or (RF.IsTraining(ply) and "training" or "not ready")
				elseif gt.lives > 0 and RF.InRound() then
					note = IsValid(ply:GetNWEntity("rf_mine")) and "alive" or "eliminated"
				elseif not IsValid(ply:GetNWEntity("rf_mine")) and RF.InRound() then
					note = "respawning"
				end

				draw.SimpleText(note, "RFSmall", textX, h * 0.5 + 10,
					down and Color(210, 120, 90) or COL_DIM, 0, TEXT_ALIGN_CENTER)

				local kills, deaths = ply:Frags(), ply:Deaths()

				if teamID then
					draw.SimpleText(kills .. "   " .. deaths, "RFHead", w - 14, h * 0.5,
						main, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

					return
				end

				local ratio = deaths > 0 and string.format("%.2f", kills / deaths) or tostring(kills)
				local ping = ply:Ping()

				local pingCol = ping < 80 and Color(90, 190, 100) or (ping < 160 and COL_ACCENT or Color(220, 90, 80))

				draw.SimpleText(kills, "RFHead", w - 250, h * 0.5, main, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(deaths, "RFBody", w - 170, h * 0.5, sub, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ratio, "RFBody", w - 95, h * 0.5, main, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ping, "RFSmall", w - 25, h * 0.5, down and Sink(pingCol, fade) or pingCol,
					TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	list.Think = function(self)
		local stamp = #player.GetAll() .. "x" .. self:GetWide() .. "x" .. RF.GetState()

		if self.Stamp == stamp and (self.Next or 0) > CurTime() then return end

		self.Stamp = stamp
		self.Next = CurTime() + 1
		RF.DeferRebuild(self)
	end

	return wrap
end

local function BuildScores(parent)
	local page = vgui.Create("DPanel", parent)
	page.Paint = function() end

	local footer = page:Add("DPanel")
	footer:Dock(BOTTOM)
	footer:SetTall(34)
	footer:DockMargin(0, 6, 0, 0)
	footer.Paint = function() end

	local back = footer:Add("DButton")
	back:Dock(FILL)
	back:SetText("BACK TO READY UP")
	RF.StyleButton(back, true)

	back.Think = function(self)
		local me = LocalPlayer()
		local show = RF.IsTraining(me) or me:GetNWBool("rf_spectating", false)

		self:SetVisible(show)
		self:SetText(RF.IsTraining(me) and "LEAVE TRAINING" or "LEAVE FREECAM")
	end

	back.DoClick = function()
		surface.PlaySound("buttons/button14.wav")

		if RF.IsTraining(LocalPlayer()) then
			net.Start("rf_training")
		else
			net.Start("rf_spectate")
		end

		net.SendToServer()
		RF.Score.Close()
	end

	local body = page:Add("DPanel")
	body:Dock(FILL)
	body.Paint = function() end

	local solo = Column(body, nil, true)
	local left = Column(body, TEAM_COMBINE)
	local right = Column(body, TEAM_REBEL)

	body.PerformLayout = function(self, w, h)
		local teams = RF.GetGameType().teams

		solo:SetVisible(not teams)
		left:SetVisible(teams)
		right:SetVisible(teams)

		if teams then
			local half = math.floor((w - 10) * 0.5)

			left:SetPos(0, 0)
			left:SetSize(half, h)
			right:SetPos(half + 10, 0)
			right:SetSize(w - half - 10, h)
		else
			solo:SetPos(0, 0)
			solo:SetSize(w, h)
		end
	end

	return page
end

local function AdminButton(parent, label, action)
	local btn = parent:Add("DButton")
	btn:Dock(TOP)
	btn:DockMargin(0, 0, 0, 4)
	btn:SetTall(30)
	btn:SetText(label)
	btn:SetFont("RFBody")
	btn:SetTextColor(COL_TEXT)

	btn.Paint = function(self, w, h)
		Box(0, 0, w, h, self:IsHovered() and Color(60, 60, 60) or Color(42, 42, 42))
		Outline(0, 0, w, h, self:IsHovered() and COL_ACCENT or COL_LINE)
		self:SetTextColor(self:IsHovered() and COL_ACCENT or COL_TEXT)
	end

	btn.DoClick = action

	return btn
end

local function MatchStat(panel, y, label, value)
	draw.SimpleText(label, "RFSmall", 12, y, COL_DIM, 0, 0)
	draw.SimpleText(value, "RFBody", panel:GetWide() - 12, y - 1, COL_TEXT, TEXT_ALIGN_RIGHT, 0)
end

local function BuildMatch(parent)
	local page = vgui.Create("DPanel", parent)
	page.Paint = function(self, w, h)
		if RF.IsAdmin(LocalPlayer()) then return end

		draw.SimpleText("Host and superadmin only.", "RFHead", w * 0.5, h * 0.5, COL_DIM,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local left = page:Add("DPanel")
	left:Dock(LEFT)
	left:SetWide(300)
	left:DockMargin(0, 0, 8, 0)
	left.Paint = function() end
	left.Think = function(self) self:SetVisible(RF.IsAdmin(LocalPlayer())) end

	local status = left:Add("DPanel")
	status:Dock(TOP)
	status:SetTall(126)
	status:DockMargin(0, 0, 0, 8)
	status.Paint = function(self, w, h)
		Box(0, 0, w, h, Color(26, 26, 26))
		Outline(0, 0, w, h, COL_LINE)
		Box(0, 0, 4, h, COL_ACCENT)

		draw.SimpleText("MATCH", "RFHead", 12, 10, COL_ACCENT, 0, 0)

		local paused = GetGlobalBool("rf_paused", false)
		local left2 = RF.StateTimeLeft()

		MatchStat(self, 36, "State", paused and "Paused" or (RF.StateNames[RF.GetState()] or ""))
		MatchStat(self, 56, "Round", RF.RoundNumber() .. " of " .. RF.RoundsPerMatch())
		MatchStat(self, 76, "Time left", left2 > 0 and string.format("%d:%02d", math.floor(left2 / 60), math.floor(left2 % 60)) or "none")
		MatchStat(self, 96, "Players", tostring(#player.GetAll()))
	end

	local function Act(label, id, live)
		local btn = AdminButton(left, label, function()
			net.Start("rf_admin_action")
			net.WriteString(id)
			net.SendToServer()
		end)

		if live then btn.Think = live end

		return btn
	end

	local force = AdminButton(left, "Force Start Match", function()
		net.Start("rf_forcestart")
		net.SendToServer()
	end)

	force.Think = function(self)
		self:SetEnabled(RF.GetState() == RF.STATE_WAITING)
	end

	local pause = AdminButton(left, "Pause Match", function()
		net.Start("rf_pause")
		net.SendToServer()
	end)

	pause.Think = function(self)
		self:SetText(GetGlobalBool("rf_paused", false) and "Resume Match" or "Pause Match")
	end

	Act("End Round Now", "endround", function(self) self:SetEnabled(RF.InRound()) end)
	Act("End Match Now", "endmatch", function(self) self:SetEnabled(RF.InRound()) end)
	Act("Start Map Vote", "mapvote", function(self) self:SetEnabled(RF.GetState() ~= RF.STATE_MAPVOTE) end)
	Act("Finish Map Vote", "endvote", function(self) self:SetEnabled(RF.GetState() == RF.STATE_MAPVOTE) end)
	Act("Back To Lobby", "lobby")

	local right = page:Add("DPanel")
	right:Dock(FILL)
	right.Paint = function(self, w, h)
		Box(0, 0, w, h, Color(26, 26, 26))
		Outline(0, 0, w, h, COL_LINE)

		draw.SimpleText("ROUND SETTINGS", "RFHead", 12, 10, COL_ACCENT, 0, 0)
	end

	right.Think = function(self) self:SetVisible(RF.IsAdmin(LocalPlayer())) end

	local rows = right:Add("DPanel")
	rows:Dock(FILL)
	rows:DockMargin(6, 34, 6, 6)
	rows.Paint = function() end

	RF.SettingRow(rows, "Rounds per match", "RoundsPerMatch", 1, function(v) return tostring(math.floor(v)) end)
	RF.SettingRow(rows, "Round length", "RoundTime", 15, function(v)
		return string.format("%d:%02d", math.floor(v / 60), v % 60)
	end)
	RF.SettingRow(rows, "Score limit", "ScoreLimit", 1, function(v)
		return v > 0 and tostring(math.floor(v)) or "off"
	end)
	RF.SettingRow(rows, "Stats screen", "PostTime", 1, function(v) return math.floor(v) .. "s" end)
	RF.SettingRow(rows, "Respawn delay", "RespawnTime", 1, function(v) return math.floor(v) .. "s" end)
	RF.SettingRow(rows, "Players needed", "MinPlayers", 1, function(v)
		return string.format("%d of %d here", math.floor(v), #player.GetAll())
	end)
	RF.SettingRow(rows, "Friendly fire", "FriendlyFire", 1, function(v) return v >= 1 and "ON" or "OFF" end)
	RF.SettingRow(rows, "Map vote", "MapVote", 1, function(v) return v >= 1 and "ON" or "OFF" end)
	RF.SettingRow(rows, "Map vote length", "MapVoteTime", 5, function(v) return math.floor(v) .. "s" end)
	RF.SettingRow(rows, "Maps on the vote", "MapVoteChoices", 4, function(v) return tostring(math.floor(v)) end)

	return page
end

local function BuildAdmin(parent)
	local page = vgui.Create("DPanel", parent)
	page.Paint = function(self, w, h)
		if RF.IsAdmin(LocalPlayer()) then return end

		draw.SimpleText("Host and superadmin only.", "RFHead", w * 0.5, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local left = page:Add("DScrollPanel")
	left:Dock(LEFT)
	left:SetWide(260)
	left:DockMargin(0, 0, 8, 0)

	local right = page:Add("DScrollPanel")
	right:Dock(FILL)

	left.Think = function(self) self:SetVisible(RF.IsAdmin(LocalPlayer())) end
	right.Think = function(self) self:SetVisible(RF.IsAdmin(LocalPlayer())) end

	local roundLabel = left:Add("DLabel")
	roundLabel:Dock(TOP)
	roundLabel:SetTall(22)
	roundLabel:SetFont("RFHead")
	roundLabel:SetTextColor(COL_ACCENT)
	roundLabel:SetText("ROUND")

	AdminButton(left, "Force Start Round", function()
		net.Start("rf_forcestart")
		net.SendToServer()
	end)

	AdminButton(left, "Toggle Training", function()
		net.Start("rf_training")
		net.SendToServer()
	end)

	local pause = AdminButton(left, "Pause Match", function()
		net.Start("rf_pause")
		net.SendToServer()
	end)

	pause.Think = function(self)
		self:SetText(GetGlobalBool("rf_paused", false) and "Resume Match" or "Pause Match")
	end

	local spec = AdminButton(left, "Spectator Freecam", function()
		net.Start("rf_spectate")
		net.SendToServer()
	end)

	spec.Think = function(self)
		self:SetText(LocalPlayer():GetNWBool("rf_spectating", false) and "Leave Freecam" or "Spectator Freecam")
	end

	local toolLabel = left:Add("DLabel")
	toolLabel:Dock(TOP)
	toolLabel:SetTall(26)
	toolLabel:SetFont("RFHead")
	toolLabel:SetTextColor(COL_ACCENT)
	toolLabel:SetText("TOOLS")

	for _, action in ipairs({
		{ "Respawn Mine", "respawn" },
		{ "Refill Health / Energy", "refill" },
		{ "Toggle Godmode", "god" },
		{ "Teleport To Aim", "teleport" },
		{ "Spawn Target Dummy", "dummy" },
		{ "Remove All Dummies", "clear" },
		{ "Reset Server Settings", "reset" }
	}) do
		AdminButton(left, action[1], function()
			net.Start("rf_admin_action")
			net.WriteString(action[2])
			net.SendToServer()
		end)
	end

	local groups = {}

	for _, v in ipairs(RF.VarList) do
		groups[v.group] = groups[v.group] or {}
		table.insert(groups[v.group], v)
	end

	for _, group in ipairs(RF.VarGroups) do
		local header = right:Add("DLabel")
		header:Dock(TOP)
		header:DockMargin(0, 6, 0, 2)
		header:SetTall(20)
		header:SetFont("RFHead")
		header:SetTextColor(COL_ACCENT)
		header:SetText(string.upper(group))

		for _, v in ipairs(groups[group] or {}) do
			local slider = right:Add("DNumSlider")
			slider:Dock(TOP)
			slider:DockMargin(0, 1, 12, 1)
			slider:SetText(v.label)
			slider:SetMin(v.min)
			slider:SetMax(v.max)
			slider:SetDecimals(v.default % 1 == 0 and 0 or 2)
			slider:SetValue(RF.Get(v.key))
			slider.Label:SetTextColor(COL_TEXT)
			slider.Label:SetFont("RFSmall")

			if v.realm == "client" then
				slider:SetConVar(v.name)
			else
				slider.OnValueChanged = function(_, value)
					timer.Create("rf_sb_" .. v.key, 0.15, 1, function()
						net.Start("rf_admin_setvar")
						net.WriteString(v.key)
						net.WriteFloat(value)
						net.SendToServer()
					end)
				end
			end
		end
	end

	return page
end

function Score.IsOpen()
	return IsValid(Board)
end

function Score.Open()
	if IsValid(Board) then return end

	local w, h = math.min(960, ScrW() - 80), math.min(640, ScrH() - 80)

	Board = vgui.Create("DFrame")
	Board:SetSize(w, h)
	Board:Center()
	Board:SetTitle("")
	Board:ShowCloseButton(false)
	Board:SetDraggable(false)
	Board:SetSizable(false)
	Board:MakePopup()
	Board:SetKeyboardInputEnabled(false)
	RF.PanelPause(Board)

	Board.Paint = function(self, pw, ph)
		Box(0, 0, pw, ph, COL_BG)
		Outline(0, 0, pw, ph, COL_LINE)

		Box(0, 0, pw, 96, Color(10, 10, 10, 255))

		local thumb = RF.MapThumb(game.GetMap())

		if thumb then
			local tile = 232
			local from = pw - tile

			surface.SetDrawColor(255, 255, 255, 255)
			RF.DrawCover(thumb, from, 0, tile, 96)
			Box(from, 0, tile, 96, Color(6, 6, 8, 85))
			RF.FadeX(from, 0, 96, 96, Color(10, 10, 10, 255), false, 96)
		else
			surface.SetDrawColor(255, 255, 255, 70)
			surface.SetMaterial(RF.Mat("rollerfight/sb_header.png"))
			surface.DrawTexturedRect(0, 0, pw, 96)
		end

		Box(0, 94, pw, 2, COL_ACCENT)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(RF.Mat("rollerfight/logo_wide.png"))
		surface.DrawTexturedRect(20, 18, 250, 60)

		Box(288, 26, 2, 44, Color(90, 90, 90))

		local title = RF.GetGameType().name

		if RF.RoundsPerMatch() > 1 then
			title = title .. "   Round " .. RF.RoundNumber() .. " of " .. RF.RoundsPerMatch()
		end

		draw.SimpleText(title, "RFHead", 304, 34, COL_TEXT, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(game.GetMap(), "RFSmall", 304, 60, COL_ACCENT, 0, TEXT_ALIGN_CENTER)

		local state = RF.StateNames[RF.GetState()] or ""
		local left = RF.StateTimeLeft()

		if GetGlobalBool("rf_paused", false) then state = "Paused" end

		draw.SimpleText(string.upper(state), "RFHudTag", pw - 20, 24, RF.Hud.LABEL, TEXT_ALIGN_RIGHT, 0)

		if left > 0 then
			RF.HudClock(left, pw - 20, 62, left < 30 and RF.Hud.CAUTION or RF.Hud.FG)
		end

	end

	local tabs = Board:Add("DPanel")
	tabs:Dock(TOP)
	tabs:DockMargin(12, 104, 12, 6)
	tabs:SetTall(28)
	tabs.Paint = function() end

	local body = Board:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(12, 0, 12, 12)
	body.Paint = function() end

	local pages = {
		{ name = "SCORES", build = BuildScores },
		{ name = "MATCH", build = BuildMatch },
		{ name = "ADMIN", build = BuildAdmin }
	}

	Board.Page = 1

	for index, def in ipairs(pages) do
		local panel = def.build(body)
		panel:Dock(FILL)
		def.panel = panel

		local btn = tabs:Add("DButton")
		btn:Dock(LEFT)
		btn:SetWide(120)
		btn:DockMargin(0, 0, 4, 0)
		btn:SetText(def.name)
		btn.Active = function() return Board.Page == index end
		StyleTab(btn)

		btn.DoClick = function()
			Board.Page = index

			for i, other in ipairs(pages) do
				other.panel:SetVisible(i == index)
			end
		end
	end

	for i, def in ipairs(pages) do
		def.panel:SetVisible(i == 1)
	end
end

function Score.Close()
	if IsValid(Board) then Board:Remove() end

	Board = nil
end

function GM:ScoreboardShow()
	Score.Open()

	return true
end

function GM:ScoreboardHide()
	if Score.Forced then return true end

	Score.Close()

	return true
end

timer.Create("RF.ScoreAuto", 0.3, 0, function()
	if not IsValid(LocalPlayer()) then return end

	local post = RF.GetState() == RF.STATE_POST

	if post and not IsValid(Board) then
		Score.Open()
		Score.Forced = true
	elseif not post and Score.Forced then
		Score.Forced = false
		Score.Close()
	end
end)

concommand.Add("rf_scoreboard", function()
	if IsValid(Board) then Score.Close() else Score.Open() end
end)
