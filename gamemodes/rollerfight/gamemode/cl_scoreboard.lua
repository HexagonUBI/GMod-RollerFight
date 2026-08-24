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
		if a:Frags() == b:Frags() then return a:Deaths() < b:Deaths() end

		return a:Frags() > b:Frags()
	end)

	return list
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

local function BuildScores(parent)
	local page = vgui.Create("DPanel", parent)
	page.Paint = function() end

	local head = page:Add("DPanel")
	head:Dock(TOP)
	head:SetTall(24)
	head:DockMargin(0, 0, 0, 4)
	head.Paint = function(self, w, h)
		Box(0, 0, w, h, Color(24, 24, 24))

		draw.SimpleText("PLAYER", "RFSmall", 40, h * 0.5, COL_DIM, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText("KILLS", "RFSmall", w - 250, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("DEATHS", "RFSmall", w - 170, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("RATIO", "RFSmall", w - 95, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("PING", "RFSmall", w - 25, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local list = page:Add("DScrollPanel")
	list:Dock(FILL)

	list.Rebuild = function()
		list:Clear()

		for index, ply in ipairs(Sorted()) do
			local row = list:Add("DPanel")
			row:Dock(TOP)
			row:SetTall(30)
			row:DockMargin(0, 0, 0, 2)

			row.Paint = function(self, w, h)
				Box(0, 0, w, h, index % 2 == 0 and COL_ROWALT or COL_ROW)

				local col = RF.TeamColors[ply:Team()] or COL_DIM
				Box(0, 0, 4, h, col)

				if ply == LocalPlayer() then
					Outline(0, 0, w, h, COL_ACCENT)
				end

				draw.SimpleText(index, "RFSmall", 20, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ply:Nick(), "RFBody", 40, h * 0.5, COL_TEXT, 0, TEXT_ALIGN_CENTER)

				local kills, deaths = ply:Frags(), ply:Deaths()
				local ratio = deaths > 0 and string.format("%.2f", kills / deaths) or tostring(kills)

				draw.SimpleText(kills, "RFBody", w - 250, h * 0.5, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(deaths, "RFBody", w - 170, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ratio, "RFBody", w - 95, h * 0.5, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(ply:Ping(), "RFSmall", w - 25, h * 0.5, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				local gt = RF.GetGameType()

				if gt.lives > 0 and RF.InRound() then
					local alive = IsValid(ply:GetNWEntity("rf_mine"))

					draw.SimpleText(alive and "ALIVE" or "OUT", "RFSmall", w - 320, h * 0.5,
						alive and Color(90, 190, 100) or Color(200, 80, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end
		end
	end

	list.Rebuild()
	list.Think = function(self)
		if (self.Next or 0) > CurTime() then return end

		self.Next = CurTime() + 1
		self.Rebuild()
	end

	local back = page:Add("DButton")
	back:Dock(BOTTOM)
	back:DockMargin(0, 6, 0, 0)
	back:SetTall(34)
	back:SetText("BACK TO READY UP")
	RF.StyleButton(back, true)

	back.Think = function(self)
		local me = LocalPlayer()

		self:SetVisible(RF.IsTraining(me) or me:GetNWBool("rf_spectating", false))
		self:SetText(RF.IsTraining(me) and "LEAVE TRAINING, BACK TO READY UP" or "LEAVE SPECTATOR, BACK TO READY UP")
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

	Board.Paint = function(self, pw, ph)
		Box(0, 0, pw, ph, COL_BG)
		Outline(0, 0, pw, ph, COL_LINE)

		Box(0, 0, pw, 72, Color(10, 10, 10, 255))

		surface.SetDrawColor(255, 255, 255, 26)
		surface.SetMaterial(RF.Mat("rollerfight/gt_dm.jpg"))
		surface.DrawTexturedRect(0, 0, pw, 72)

		Box(0, 70, pw, 2, COL_ACCENT)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(RF.Mat("rollerfight/logo.png"))
		surface.DrawTexturedRect(14, 12, 132, 48)

		draw.SimpleText(RF.GetGameType().name .. "  |  " .. game.GetMap(), "RFSmall", 156, 44, COL_ACCENT, 0, 0)

		local state = RF.StateNames[RF.GetState()] or ""
		local left = RF.StateTimeLeft()

		if GetGlobalBool("rf_paused", false) then state = "Paused" end

		draw.SimpleText(string.upper(state), "RFHead", pw - 16, 22, COL_TEXT, TEXT_ALIGN_RIGHT, 0)

		if left > 0 then
			draw.SimpleText(string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60)),
				"RFSmall", pw - 16, 44, COL_ACCENT, TEXT_ALIGN_RIGHT, 0)
		end
	end

	local tabs = Board:Add("DPanel")
	tabs:Dock(TOP)
	tabs:DockMargin(10, 80, 10, 6)
	tabs:SetTall(28)
	tabs.Paint = function() end

	local body = Board:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(10, 0, 10, 10)
	body.Paint = function() end

	local pages = {
		{ name = "SCORES", build = BuildScores },
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
