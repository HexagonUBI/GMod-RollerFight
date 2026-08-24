RF.Lobby = RF.Lobby or {}

local Lobby = RF.Lobby
local Panel

surface.CreateFont("RFTitle", { font = "Verdana", size = 21, weight = 800, antialias = true })
surface.CreateFont("RFHead", { font = "Verdana", size = 16, weight = 800, antialias = true })
surface.CreateFont("RFBody", { font = "Verdana", size = 14, weight = 500, antialias = true })
surface.CreateFont("RFSmall", { font = "Verdana", size = 12, weight = 500, antialias = true })

local COL_BG = Color(18, 18, 18, 235)
local COL_PANEL = Color(32, 32, 32, 255)
local COL_HEAD = Color(10, 10, 10, 255)
local COL_LINE = Color(70, 70, 70, 255)
local COL_TEXT = Color(226, 226, 226)
local COL_DIM = Color(150, 150, 150)
local COL_ACCENT = Color(238, 130, 32)
local COL_READY = Color(90, 190, 100)

local Banners = {}

local function Banner(path)
	if not Banners[path] then Banners[path] = Material(path, "smooth") end

	return Banners[path]
end

local function Box(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

local function Outline(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
end

local function StyleButton(btn, accent)
	btn.Paint = function(self, w, h)
		local base = accent and COL_ACCENT or COL_PANEL

		if not self:IsEnabled() then
			base = Color(45, 45, 45)
		elseif self.Depressed then
			base = Color(base.r * 0.7, base.g * 0.7, base.b * 0.7)
		elseif self:IsHovered() then
			base = Color(math.min(255, base.r + 26), math.min(255, base.g + 26), math.min(255, base.b + 26))
		end

		Box(0, 0, w, h, base)
		Outline(0, 0, w, h, COL_LINE)
	end

	btn:SetFont("RFHead")
	btn:SetTextColor(COL_TEXT)
end

function Lobby.Send(name)
	net.Start(name)
	net.SendToServer()
end

local function BuildTypes(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(LEFT)
	wrap:SetWide(190)
	wrap:DockMargin(0, 0, 6, 0)
	wrap.Paint = function(self, w, h)
		Box(0, 0, w, h, COL_PANEL)
		Outline(0, 0, w, h, COL_LINE)
	end

	local title = wrap:Add("DLabel")
	title:Dock(TOP)
	title:DockMargin(10, 8, 10, 4)
	title:SetTall(22)
	title:SetFont("RFHead")
	title:SetTextColor(COL_TEXT)
	title:SetText("GAMETYPE")

	for index, gt in ipairs(RF.GameTypes) do
		local btn = wrap:Add("DButton")
		btn:Dock(TOP)
		btn:DockMargin(8, 2, 8, 2)
		btn:SetTall(30)
		btn:SetText("")

		btn.Paint = function(self, w, h)
			local picked = math.floor(RF.Get("GameType")) == index

			Box(0, 0, w, h, picked and COL_ACCENT or Color(44, 44, 44))
			Outline(0, 0, w, h, COL_LINE)
			draw.SimpleText(string.upper(gt.name), "RFBody", 10, h * 0.5,
				picked and Color(20, 20, 20) or COL_TEXT, 0, TEXT_ALIGN_CENTER)
		end

		btn.DoClick = function()
			if not RF.IsAdmin(LocalPlayer()) then
				chat.AddText(COL_ACCENT, "[RollerFight] ", COL_TEXT, "Only the host can change the gametype.")
				return
			end

			net.Start("rf_gametype")
			net.WriteUInt(index, 4)
			net.SendToServer()
		end
	end

	local hint = wrap:Add("DLabel")
	hint:Dock(BOTTOM)
	hint:DockMargin(10, 4, 10, 8)
	hint:SetTall(30)
	hint:SetFont("RFSmall")
	hint:SetTextColor(COL_DIM)
	hint:SetWrap(true)
	hint:SetText("Host picks the gametype.")

	return wrap
end

local function BuildPlayers(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(RIGHT)
	wrap:SetWide(250)
	wrap:DockMargin(6, 0, 0, 0)
	wrap.Paint = function(self, w, h)
		Box(0, 0, w, h, COL_PANEL)
		Outline(0, 0, w, h, COL_LINE)
	end

	local list = wrap:Add("DScrollPanel")
	list:Dock(FILL)
	list:DockMargin(6, 6, 6, 6)

	list.Rebuild = function()
		list:Clear()

		for _, ply in ipairs(player.GetAll()) do
			local row = list:Add("DPanel")
			row:Dock(TOP)
			row:SetTall(30)
			row:DockMargin(0, 0, 0, 3)

			row.Paint = function(self, w, h)
				Box(0, 0, w, h, Color(44, 44, 44))

				local ready = RF.IsReady(ply)
				local training = RF.IsTraining(ply)

				Box(0, 0, 4, h, ready and COL_READY or (training and COL_ACCENT or Color(80, 80, 80)))
				draw.SimpleText(ply:Nick(), "RFBody", 12, h * 0.5, COL_TEXT, 0, TEXT_ALIGN_CENTER)

				local tag = ready and "READY" or (training and "TRAINING" or "")

				if ply:IsListenServerHost() then
					draw.SimpleText("HOST", "RFSmall", w - 8, h * 0.5 - 7, COL_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					draw.SimpleText(tag, "RFSmall", w - 8, h * 0.5 + 7, ready and COL_READY or COL_ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				else
					draw.SimpleText(tag, "RFSmall", w - 8, h * 0.5, ready and COL_READY or COL_ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
			end
		end
	end

	list.Rebuild()
	list.Think = function(self)
		if (self.NextSync or 0) > CurTime() then return end

		self.NextSync = CurTime() + 1
		self.Rebuild()
	end

	return wrap
end

local function BuildCenter(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(FILL)
	wrap.Paint = function(self, w, h)
		Box(0, 0, w, h, COL_PANEL)
		Outline(0, 0, w, h, COL_LINE)

		local gt = RF.GetGameType()
		local bw, bh = w - 16, 128

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(Banner(gt.banner))
		surface.DrawTexturedRect(8, 8, bw, bh)
		Outline(8, 8, bw, bh, COL_LINE)

		Box(8, 8 + bh - 30, bw, 30, Color(0, 0, 0, 190))
		draw.SimpleText(string.upper(gt.name), "RFTitle", 16, 8 + bh - 15, COL_ACCENT, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(gt.blurb, "RFSmall", 8, 8 + bh + 8, COL_DIM, 0, 0)
	end

	local settings = wrap:Add("DPanel")
	settings:Dock(BOTTOM)
	settings:SetTall(120)
	settings:DockMargin(8, 4, 8, 8)
	settings.Paint = function(self, w, h)
		Box(0, 0, w, h, Color(26, 26, 26))
		Outline(0, 0, w, h, COL_LINE)

		local gt = RF.GetGameType()
		local rows = {
			{ "Round length", string.format("%d min %02d sec", math.floor(RF.Get("RoundTime") / 60), RF.Get("RoundTime") % 60) },
			{ "Score limit", RF.Get("ScoreLimit") > 0 and tostring(math.floor(RF.Get("ScoreLimit"))) or "off" },
			{ "Friendly fire", RF.Get("FriendlyFire") >= 1 and "ON" or "OFF" },
			{ "Players", string.format("%d, needs %d", #player.GetAll(), gt.minPlayers) }
		}

		draw.SimpleText("ROUND SETTINGS", "RFHead", 10, 10, COL_TEXT, 0, 0)

		for i, row in ipairs(rows) do
			local y = 34 + (i - 1) * 21

			draw.SimpleText(row[1], "RFBody", 10, y, COL_DIM, 0, 0)
			draw.SimpleText(row[2], "RFBody", w - 10, y, COL_TEXT, TEXT_ALIGN_RIGHT, 0)
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

	local w, h = 900, 430
	Panel = vgui.Create("DFrame")
	Panel:SetSize(w, h)
	Panel:SetPos((ScrW() - w) * 0.5, (ScrH() - h) * 0.5 - 30)
	Panel:SetTitle("")
	Panel:ShowCloseButton(false)
	Panel:SetDraggable(false)
	Panel:SetSizable(false)
	Panel:SetScreenLock(true)
	Panel:MakePopup()
	Panel:SetKeyboardInputEnabled(false)

	Panel.Paint = function(self, pw, ph)
		Box(0, 0, pw, ph, COL_BG)
		Outline(0, 0, pw, ph, COL_LINE)
		Box(0, 0, pw, 32, COL_HEAD)
		Box(0, 31, pw, 1, COL_ACCENT)

		local ready, total = RF.ReadyCount()
		local auto = GetGlobalFloat("rf_autostart", 0)
		local title = "WAITING FOR PLAYERS"

		if auto > 0 then
			title = string.format("STARTING IN %d", math.max(0, math.ceil(auto - CurTime())))
		end

		draw.SimpleText(title, "RFTitle", pw * 0.5, 16, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(game.GetMap(), "RFSmall", 10, 16, COL_DIM, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(ready .. " / " .. total .. " ready", "RFSmall", pw - 10, 16, COL_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local body = Panel:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(10, 40, 10, 6)
	body.Paint = function() end

	BuildTypes(body)
	BuildPlayers(body)
	BuildCenter(body)

	local ready = Panel:Add("DButton")
	ready:Dock(BOTTOM)
	ready:DockMargin(10, 2, 10, 8)
	ready:SetTall(38)
	ready:SetText("READY UP")
	StyleButton(ready, true)

	ready.Think = function(self)
		local me = LocalPlayer()

		if RF.IsTraining(me) then
			self:SetText("LEAVE TRAINING TO READY UP")
			self:SetEnabled(false)
		else
			self:SetText(RF.IsReady(me) and "NOT READY" or "READY UP")
			self:SetEnabled(true)
		end
	end

	ready.DoClick = function() Lobby.Send("rf_ready") end

	local row = Panel:Add("DPanel")
	row:Dock(BOTTOM)
	row:DockMargin(10, 0, 10, 0)
	row:SetTall(30)
	row.Paint = function() end

	local train = row:Add("DButton")
	train:Dock(LEFT)
	train:SetWide(430)
	train:SetText("TRAINING MODE")
	StyleButton(train, false)

	train.Think = function(self)
		self:SetText(RF.IsTraining(LocalPlayer()) and "LEAVE TRAINING" or "TRAINING MODE")
	end

	train.DoClick = function() Lobby.Send("rf_training") end

	local force = row:Add("DButton")
	force:Dock(FILL)
	force:SetText("FORCE START")
	StyleButton(force, false)

	force.Think = function(self)
		self:SetEnabled(RF.IsAdmin(LocalPlayer()))
	end

	force.DoClick = function() Lobby.Send("rf_forcestart") end
end

function Lobby.Update()
	local me = LocalPlayer()
	if not IsValid(me) then return end

	local want = RF.GetState() == RF.STATE_WAITING and not RF.IsTraining(me)

	if want then
		Lobby.Open()
	else
		Lobby.Close()
	end
end

timer.Create("RF.LobbyWatch", 0.3, 0, Lobby.Update)

concommand.Add("rf_lobby", function()
	if IsValid(Panel) then Lobby.Close() else Lobby.Open() end
end)
