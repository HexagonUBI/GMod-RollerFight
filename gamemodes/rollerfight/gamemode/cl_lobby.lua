RF.Lobby = RF.Lobby or {}

local Lobby = RF.Lobby
local Panel

surface.CreateFont("RFTitle", { font = "Verdana", size = 21, weight = 800, antialias = true })
surface.CreateFont("RFHead", { font = "Verdana", size = 16, weight = 800, antialias = true })
surface.CreateFont("RFBody", { font = "Verdana", size = 14, weight = 500, antialias = true })
surface.CreateFont("RFSmall", { font = "Verdana", size = 12, weight = 500, antialias = true })

RF.UI = {
	BG = Color(18, 18, 18, 235),
	PANEL = Color(32, 32, 32, 255),
	HEAD = Color(10, 10, 10, 255),
	LINE = Color(70, 70, 70, 255),
	TEXT = Color(226, 226, 226),
	DIM = Color(150, 150, 150),
	ACCENT = Color(238, 130, 32),
	READY = Color(90, 190, 100)
}

local U = RF.UI
local Mats = {}

function RF.Mat(path)
	if not Mats[path] then Mats[path] = Material(path, "smooth") end

	return Mats[path]
end

function RF.Box(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

function RF.Outline(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
end

function RF.StyleButton(btn, accent)
	btn:SetFont("RFHead")
	btn:SetTextColor(U.TEXT)

	btn.Paint = function(self, w, h)
		local base = accent and U.ACCENT or U.PANEL

		if not self:IsEnabled() then
			base = Color(45, 45, 45)
		elseif self.Depressed then
			base = Color(base.r * 0.65, base.g * 0.65, base.b * 0.65)
		elseif self:IsHovered() then
			base = Color(math.min(255, base.r + 40), math.min(255, base.g + 40), math.min(255, base.b + 40))
		end

		RF.Box(0, 0, w, h, base)
		RF.Outline(0, 0, w, h, self:IsHovered() and U.ACCENT or U.LINE)

		if self:IsEnabled() then
			self:SetTextColor(accent and Color(20, 20, 20) or (self:IsHovered() and U.ACCENT or U.TEXT))
		else
			self:SetTextColor(U.DIM)
		end
	end
end

function Lobby.Send(name)
	net.Start(name)
	net.SendToServer()
end

local function BuildTypes(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(LEFT)
	wrap:SetWide(196)
	wrap:DockMargin(0, 0, 8, 0)
	wrap.Paint = function(self, w, h)
		RF.Box(0, 0, w, h, U.PANEL)
		RF.Outline(0, 0, w, h, U.LINE)
		draw.SimpleText("GAMETYPE", "RFHead", 12, 14, U.TEXT, 0, TEXT_ALIGN_CENTER)
	end

	local pad = wrap:Add("DPanel")
	pad:Dock(TOP)
	pad:SetTall(30)
	pad.Paint = function() end

	for index, gt in ipairs(RF.GameTypes) do
		local btn = wrap:Add("DButton")
		btn:Dock(TOP)
		btn:DockMargin(8, 3, 8, 0)
		btn:SetTall(34)
		btn:SetText("")

		btn.Paint = function(self, w, h)
			local picked = math.floor(RF.Get("GameType")) == index
			local base = picked and U.ACCENT or Color(44, 44, 44)

			if not picked and self:IsHovered() then base = Color(62, 62, 62) end

			RF.Box(0, 0, w, h, base)
			RF.Outline(0, 0, w, h, self:IsHovered() and U.ACCENT or U.LINE)

			if picked then RF.Box(0, 0, 3, h, Color(255, 255, 255, 200)) end

			draw.SimpleText(string.upper(gt.name), "RFBody", 12, h * 0.5,
				picked and Color(20, 20, 20) or (self:IsHovered() and U.ACCENT or U.TEXT), 0, TEXT_ALIGN_CENTER)
		end

		btn.DoClick = function()
			if not RF.IsAdmin(LocalPlayer()) then
				surface.PlaySound("buttons/button10.wav")
				chat.AddText(U.ACCENT, "[RollerFight] ", U.TEXT, "Only the host can change the gametype.")

				return
			end

			surface.PlaySound("buttons/button14.wav")
			net.Start("rf_gametype")
			net.WriteUInt(index, 4)
			net.SendToServer()
		end
	end

	local hint = wrap:Add("DLabel")
	hint:Dock(BOTTOM)
	hint:DockMargin(12, 4, 12, 10)
	hint:SetTall(34)
	hint:SetFont("RFSmall")
	hint:SetTextColor(U.DIM)
	hint:SetWrap(true)
	hint:SetText("The host picks the gametype for everyone.")

	return wrap
end

local function PlayerRow(parent, ply)
	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:SetTall(42)
	row:DockMargin(0, 0, 0, 4)
	row:SetMouseInputEnabled(true)

	local avatar = row:Add("AvatarImage")
	avatar:SetSize(32, 32)
	avatar:SetPos(6, 5)
	avatar:SetPlayer(ply, 32)
	avatar:SetMouseInputEnabled(false)

	row.Paint = function(self, w, h)
		local ready = RF.IsReady(ply)
		local training = RF.IsTraining(ply)
		local spectating = ply:GetNWBool("rf_spectating", false)

		RF.Box(0, 0, w, h, self:IsHovered() and Color(56, 56, 56) or Color(44, 44, 44))
		RF.Box(0, 0, 3, h, ready and U.READY or (training and U.ACCENT or Color(84, 84, 84)))

		if ply == LocalPlayer() then RF.Outline(0, 0, w, h, U.ACCENT) end

		draw.SimpleText(ply:Nick(), "RFBody", 46, 11, U.TEXT, 0, TEXT_ALIGN_CENTER)

		local ping = ply:Ping()
		local pingCol = ping < 80 and U.READY or (ping < 160 and U.ACCENT or Color(220, 90, 80))

		draw.SimpleText(ping .. " ms", "RFSmall", 46, 29, pingCol, 0, TEXT_ALIGN_CENTER)

		local tag = "NOT READY"
		local col = U.DIM

		if spectating then
			tag, col = "SPECTATING", U.DIM
		elseif training then
			tag, col = "TRAINING", U.ACCENT
		elseif ready then
			tag, col = "READY", U.READY
		end

		draw.SimpleText(tag, "RFSmall", w - 10, ply:IsListenServerHost() and 29 or (h * 0.5), col,
			TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		if ply:IsListenServerHost() then
			draw.SimpleText("HOST", "RFSmall", w - 10, 11, U.ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	return row
end

local function BuildPlayers(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(RIGHT)
	wrap:SetWide(258)
	wrap:DockMargin(8, 0, 0, 0)
	wrap.Paint = function(self, w, h)
		RF.Box(0, 0, w, h, U.PANEL)
		RF.Outline(0, 0, w, h, U.LINE)

		local ready, total = RF.ReadyCount()

		draw.SimpleText("PLAYERS", "RFHead", 12, 14, U.TEXT, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(ready .. " / " .. total, "RFSmall", w - 12, 14, U.ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local list = wrap:Add("DScrollPanel")
	list:Dock(FILL)
	list:DockMargin(8, 30, 8, 8)

	list.Rebuild = function()
		list:Clear()

		for _, ply in ipairs(player.GetAll()) do
			PlayerRow(list, ply)
		end
	end

	list.Rebuild()

	list.Think = function(self)
		local stamp = #player.GetAll()

		if self.Stamp ~= stamp then
			self.Stamp = stamp
			self.Rebuild()
		end
	end

	return wrap
end

local function BuildCenter(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(FILL)
	wrap.Paint = function(self, w, h)
		RF.Box(0, 0, w, h, U.PANEL)
		RF.Outline(0, 0, w, h, U.LINE)

		local gt = RF.GetGameType()
		local bw, bh = w - 16, 132

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(RF.Mat(gt.banner))
		surface.DrawTexturedRect(8, 8, bw, bh)
		RF.Outline(8, 8, bw, bh, U.LINE)

		RF.Box(8, 8 + bh - 32, bw, 32, Color(0, 0, 0, 195))
		draw.SimpleText(string.upper(gt.name), "RFTitle", 16, 8 + bh - 16, U.ACCENT, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(gt.blurb, "RFSmall", 8, 8 + bh + 9, U.DIM, 0, 0)
	end

	local settings = wrap:Add("DPanel")
	settings:Dock(BOTTOM)
	settings:SetTall(126)
	settings:DockMargin(8, 4, 8, 8)
	settings.Paint = function(self, w, h)
		RF.Box(0, 0, w, h, Color(26, 26, 26))
		RF.Outline(0, 0, w, h, U.LINE)

		local gt = RF.GetGameType()
		local rows = {
			{ "Round length", string.format("%d:%02d", math.floor(RF.Get("RoundTime") / 60), RF.Get("RoundTime") % 60) },
			{ "Score limit", RF.Get("ScoreLimit") > 0 and tostring(math.floor(RF.Get("ScoreLimit"))) or "off" },
			{ "Friendly fire", RF.Get("FriendlyFire") >= 1 and "ON" or "OFF" },
			{ "Players needed", string.format("%d of %d", #player.GetAll(), gt.minPlayers) }
		}

		draw.SimpleText("ROUND SETTINGS", "RFHead", 12, 12, U.TEXT, 0, 0)

		for i, row in ipairs(rows) do
			local y = 38 + (i - 1) * 21

			draw.SimpleText(row[1], "RFBody", 12, y, U.DIM, 0, 0)
			draw.SimpleText(row[2], "RFBody", w - 12, y, U.TEXT, TEXT_ALIGN_RIGHT, 0)
		end
	end

	return wrap
end

function Lobby.Close()
	if IsValid(Panel) then Panel:Remove() end

	Panel = nil
end

function Lobby.Open()
	if IsValid(Panel) then return end

	local w, h = 920, 452

	Panel = vgui.Create("DFrame")
	Panel:SetSize(w, h)
	Panel:SetPos((ScrW() - w) * 0.5, (ScrH() - h) * 0.5 - 20)
	Panel:SetTitle("")
	Panel:ShowCloseButton(false)
	Panel:SetDraggable(false)
	Panel:SetSizable(false)
	Panel:SetScreenLock(true)
	Panel:MakePopup()
	Panel:SetKeyboardInputEnabled(false)

	Panel.Paint = function(self, pw, ph)
		RF.Box(0, 0, pw, ph, U.BG)
		RF.Outline(0, 0, pw, ph, U.LINE)
		RF.Box(0, 0, pw, 34, U.HEAD)
		RF.Box(0, 33, pw, 1, U.ACCENT)

		draw.SimpleText("WAITING FOR PLAYERS", "RFTitle", pw * 0.5, 17, U.TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(game.GetMap(), "RFSmall", 12, 17, U.DIM, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText("TAB for scoreboard", "RFSmall", pw - 12, 17, U.DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local body = Panel:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(12, 42, 12, 6)
	body.Paint = function() end

	BuildTypes(body)
	BuildPlayers(body)
	BuildCenter(body)

	local ready = Panel:Add("DButton")
	ready:Dock(BOTTOM)
	ready:DockMargin(12, 3, 12, 10)
	ready:SetTall(40)
	ready:SetText("READY UP")
	RF.StyleButton(ready, true)

	ready.Think = function(self)
		local me = LocalPlayer()

		if RF.IsTraining(me) then
			self:SetText("LEAVE TRAINING TO READY UP")
			self:SetEnabled(false)
		else
			self:SetText(RF.IsReady(me) and "CANCEL READY" or "READY UP")
			self:SetEnabled(true)
		end
	end

	ready.DoClick = function()
		surface.PlaySound("buttons/button14.wav")
		Lobby.Send("rf_ready")
	end

	local row = Panel:Add("DPanel")
	row:Dock(BOTTOM)
	row:DockMargin(12, 0, 12, 0)
	row:SetTall(32)
	row.Paint = function() end

	local train = row:Add("DButton")
	train:Dock(LEFT)
	train:SetWide(440)
	train:SetText("TRAINING MODE")
	RF.StyleButton(train, false)

	train.Think = function(self)
		self:SetText(RF.IsTraining(LocalPlayer()) and "LEAVE TRAINING" or "TRAINING MODE")
	end

	train.DoClick = function()
		surface.PlaySound("buttons/button14.wav")
		Lobby.Send("rf_training")
	end

	local force = row:Add("DButton")
	force:Dock(FILL)
	force:DockMargin(8, 0, 0, 0)
	force:SetText("FORCE START")
	RF.StyleButton(force, false)

	force.Think = function(self)
		self:SetEnabled(RF.IsAdmin(LocalPlayer()))
	end

	force.DoClick = function()
		surface.PlaySound("buttons/button14.wav")
		Lobby.Send("rf_forcestart")
	end
end

function Lobby.Update()
	local me = LocalPlayer()
	if not IsValid(me) then return end

	local want = RF.GetState() == RF.STATE_WAITING
		and not RF.IsTraining(me)
		and not me:GetNWBool("rf_spectating", false)

	if want then Lobby.Open() else Lobby.Close() end
end

timer.Create("RF.LobbyWatch", 0.3, 0, Lobby.Update)

concommand.Add("rf_lobby", function()
	if IsValid(Panel) then Lobby.Close() else Lobby.Open() end
end)
