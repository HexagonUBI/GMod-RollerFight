RF.Vote = RF.Vote or {}

local Vote = RF.Vote
local Panel

local U = RF.UI
local Hud = RF.Hud

surface.CreateFont("RFVoteTitle", { font = "Verdana", size = 30, weight = 900, italic = true, antialias = true })
surface.CreateFont("RFVoteName", { font = "Verdana", size = 19, weight = 900, antialias = true })

Vote.Choices = {}
Vote.Counts = {}
Vote.Voters = {}
Vote.Picked = 0
Vote.Version = 0
Vote.Focus = 1

local AVATAR = 20
local MAX_AVATARS = 4

function Vote.Total()
	local total = 0

	for _, list in pairs(Vote.Voters) do
		total = total + #list
	end

	return total
end

function Vote.IsRandom(index)
	return index > #Vote.Choices
end

function Vote.Label(index)
	return Vote.Choices[index] or "Random map"
end

function Vote.Send(index)
	if Vote.Picked == index then return end
	if CurTime() < (Vote.NextSend or 0) then return end

	Vote.NextSend = CurTime() + 0.15
	Vote.Picked = index

	surface.PlaySound("buttons/button14.wav")

	net.Start("rf_mapvote_pick")
	net.WriteUInt(index, 9)
	net.SendToServer()
end

net.Receive("rf_mapvote", function()
	local count = net.ReadUInt(9)

	Vote.Choices = {}
	Vote.Counts = {}
	Vote.Voters = {}
	Vote.Picked = 0
	Vote.Focus = 1
	Vote.Version = Vote.Version + 1

	for _ = 1, count do
		table.insert(Vote.Choices, net.ReadString())
	end

	if IsValid(Panel) then Panel:Remove() end

	Panel = nil
end)

net.Receive("rf_mapvote_tally", function()
	local count = net.ReadUInt(8)
	local me = LocalPlayer()

	Vote.Counts = {}
	Vote.Voters = {}
	Vote.Picked = 0

	for _ = 1, count do
		local ply = net.ReadEntity()
		local index = net.ReadUInt(9)

		Vote.Counts[index] = (Vote.Counts[index] or 0) + 1
		Vote.Voters[index] = Vote.Voters[index] or {}

		table.insert(Vote.Voters[index], ply)

		if ply == me then Vote.Picked = index end
	end

	Vote.Version = Vote.Version + 1
end)

local function Fit(text, font, max)
	surface.SetFont(font)

	if surface.GetTextSize(text) <= max then return text end

	while string.len(text) > 1 do
		text = string.sub(text, 1, string.len(text) - 1)

		if surface.GetTextSize(text .. "..") <= max then return text .. ".." end
	end

	return text
end

local function Pics(panel, size)
	if panel.PicVersion == Vote.Version then return end

	panel.PicVersion = Vote.Version
	panel.Pics = panel.Pics or {}

	local want = {}

	for _, voters in pairs(Vote.Voters) do
		for _, ply in ipairs(voters) do
			if IsValid(ply) then want[ply] = true end
		end
	end

	for ply, pic in pairs(panel.Pics) do
		if not want[ply] then
			if IsValid(pic) then pic:Remove() end

			panel.Pics[ply] = nil
		end
	end

	for ply in pairs(want) do
		if not IsValid(panel.Pics[ply]) then
			local pic = vgui.Create("AvatarImage", panel)

			pic:SetSize(size, size)
			pic:SetPlayer(ply, 32)
			pic:SetMouseInputEnabled(false)
			pic:SetPaintedManually(true)

			panel.Pics[ply] = pic
		end
	end
end

local function DrawAvatars(panel, index, right, bottom, size)
	local voters = Vote.Voters[index]

	if not voters or not panel.Pics then return end

	local shown = math.min(#voters, MAX_AVATARS)

	for slot = 1, shown do
		local pic = panel.Pics[voters[slot]]

		if IsValid(pic) then
			pic:SetSize(size, size)
			pic:SetPos(right - slot * (size + 3) + 3, bottom - size)
			pic:PaintManual()
		end
	end

	if #voters > shown then
		draw.SimpleText("+" .. (#voters - shown), "RFHudTag",
			right - shown * (size + 3) - 1, bottom - size * 0.5,
			Hud.LABEL, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

local function BuildGrid(parent)
	local grid = parent:Add("DPanel")
	grid:Dock(FILL)
	grid:DockMargin(0, 0, 10, 0)
	grid:SetMouseInputEnabled(true)

	grid.Scroll = 0
	grid.Names = {}

	grid.Relayout = function(self)
		local w = self:GetWide()
		local cols = math.Clamp(math.floor(w / 250), 2, 6)
		local gap = 8
		local cardW = math.floor((w - gap * (cols - 1)) / cols)

		self.Cols, self.Gap = cols, gap
		self.CardW, self.CardH = cardW, math.floor(cardW / 1.75)
		self.Rows = math.ceil((#Vote.Choices + 1) / cols)
		self.Full = self.Rows * (self.CardH + gap)
		self.Names = {}
		self.Stamp = #Vote.Choices .. "x" .. w
	end

	grid.Hit = function(self, mx, my)
		if not self.CardW then return end
		if mx < 0 or my < 0 or mx > self:GetWide() or my > self:GetTall() then return end

		local stepX, stepY = self.CardW + self.Gap, self.CardH + self.Gap
		local col = math.floor(mx / stepX)
		local row = math.floor((my + self.Scroll) / stepY)

		if col < 0 or col >= self.Cols or row < 0 then return end
		if mx - col * stepX > self.CardW then return end
		if (my + self.Scroll) - row * stepY > self.CardH then return end

		local index = row * self.Cols + col + 1

		if index < 1 or index > #Vote.Choices + 1 then return end

		return index
	end

	grid.OnCursorMoved = function(self, mx, my)
		local index = self:Hit(mx, my)

		if index then Vote.Focus = index end
	end

	grid.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end

		local index = self:Hit(self:CursorPos())

		if index then Vote.Send(index) end
	end

	grid.OnMouseWheeled = function(self, delta)
		self.Scroll = math.Clamp(self.Scroll - delta * 70, 0, math.max(0, (self.Full or 0) - self:GetTall()))

		return true
	end

	grid.Think = function(self)
		if self.Stamp ~= #Vote.Choices .. "x" .. self:GetWide() then self:Relayout() end

		Pics(self, AVATAR)

		self.Scroll = math.Clamp(self.Scroll, 0, math.max(0, (self.Full or 0) - self:GetTall()))
	end

	grid.Paint = function(self, w, h)
		if not self.CardW then return end

		local stepX, stepY = self.CardW + self.Gap, self.CardH + self.Gap
		local strip = 22

		for index = 1, #Vote.Choices + 1 do
			local col = (index - 1) % self.Cols
			local row = math.floor((index - 1) / self.Cols)
			local x = col * stepX
			local y = row * stepY - self.Scroll

			if y + self.CardH >= 0 and y <= h then
				local cw, ch = self.CardW, self.CardH
				local mine = Vote.Picked == index
				local focus = Vote.Focus == index
				local count = Vote.Counts[index] or 0

				if Vote.IsRandom(index) then
					RF.Box(x, y, cw, ch, Color(32, 26, 14))
					surface.SetDrawColor(Hud.FG.r, Hud.FG.g, Hud.FG.b, 40)

					for i = -ch, cw, 18 do
						surface.DrawLine(x + i, y + ch, x + i + ch, y)
					end
				else
					RF.MapPlate(Vote.Choices[index], x, y, cw, ch, mine and 0 or 26)
				end

				RF.FadeY(x, y + ch - strip - 24, cw, 24, Color(0, 0, 0, 225), true)
				RF.Box(x, y + ch - strip, cw, strip, Color(0, 0, 0, 225))

				if mine then
					RF.Box(x, y, cw, ch, Color(Hud.FG.r, Hud.FG.g, Hud.FG.b, 38))
				elseif focus then
					RF.Box(x, y, cw, ch, Color(255, 255, 255, 26))
				end

				RF.Outline(x, y, cw, ch, mine and Hud.FG or (focus and Color(160, 140, 80) or U.LINE))

				if not self.Names[index] then
					self.Names[index] = Fit(string.upper(Vote.Label(index)), "RFHudTag", cw - 18)
				end

				draw.SimpleText(self.Names[index], "RFHudTag", x + 9, y + ch - strip * 0.5 - 1,
					mine and Hud.FG or Hud.LABEL, 0, TEXT_ALIGN_CENTER)

				if count > 0 then
					RF.Box(x + cw - 32, y + 6, 26, 22, Color(0, 0, 0, 200))
					RF.HudNumber(tostring(count), "RFHudMini", x + cw - 11, y + 17, Hud.FG, TEXT_ALIGN_RIGHT)
				end

				DrawAvatars(self, index, x + cw - 6, y + ch - strip - 6, AVATAR)
			end
		end

		local max = math.max(0, (self.Full or 0) - h)

		if max <= 0 then return end

		local bar = math.max(30, h * (h / self.Full))

		RF.Box(w - 3, 0, 3, h, Color(0, 0, 0, 120))
		RF.Box(w - 3, (h - bar) * (self.Scroll / max), 3, bar, Hud.FG)
	end

	return grid
end

local function BuildDetail(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(RIGHT)
	wrap:SetWide(math.Clamp(math.floor(ScrW() * 0.24), 300, 460))

	wrap.Think = function(self)
		Pics(self, 30)
	end

	wrap.Paint = function(self, w, h)
		local index = Vote.Focus
		local random = Vote.IsRandom(index)
		local shot = w

		draw.RoundedBox(6, 0, 0, w, h, Hud.BG)
		RF.Box(0, 0, w, 40, Color(0, 0, 0, 150))
		RF.Box(0, 39, w, 1, Hud.FG)

		draw.SimpleText(Fit(string.upper(Vote.Label(index)), "RFVoteName", w - 28), "RFVoteName",
			14, 20, Hud.FG, 0, TEXT_ALIGN_CENTER)

		if random then
			RF.Box(0, 40, w, shot, Color(24, 20, 12))
			surface.SetDrawColor(255, 255, 255, 220)
			surface.SetMaterial(RF.Mat("rollerfight/logo.png"))
			surface.DrawTexturedRect((w - 162) * 0.5, 40 + (shot - 64) * 0.5, 162, 64)
		else
			RF.MapPlate(Vote.Choices[index], 0, 40, w, shot)
		end

		RF.Outline(0, 40, w, shot, Color(0, 0, 0, 160))

		local y = 40 + shot + 14

		draw.SimpleText(random and "THE SERVER PICKS ANY MAP FROM THE POOL"
			or (RF.MapThumb(Vote.Choices[index]) and "PREVIEW FROM THE INSTALLED CONTENT"
			or "NO PREVIEW SHIPPED WITH THIS MAP"), "RFHudTag", 14, y, Hud.LABEL, 0, 0)

		y = y + 26

		local voters = Vote.Voters[index] or {}

		draw.SimpleText(#voters == 0 and "NO VOTES" or (#voters .. (#voters == 1 and " VOTE" or " VOTES")),
			"RFVoteName", 14, y, #voters > 0 and Hud.FG or Hud.LABEL, 0, 0)

		y = y + 32

		if not self.Pics then return end

		for slot = 1, math.min(#voters, 8) do
			local pic = self.Pics[voters[slot]]

			if IsValid(pic) then
				pic:SetSize(30, 30)
				pic:SetPos(14 + (slot - 1) * 34, y)
				pic:PaintManual()
			end
		end
	end

	return wrap
end

function Vote.Close()
	if IsValid(Panel) then Panel:Remove() end

	Panel = nil
end

function Vote.Open()
	if IsValid(Panel) then return end
	if #Vote.Choices == 0 then return end

	Panel = vgui.Create("DFrame")
	Panel:SetSize(ScrW(), ScrH())
	Panel:SetPos(0, 0)
	Panel:SetTitle("")
	Panel:ShowCloseButton(false)
	Panel:SetDraggable(false)
	Panel:SetSizable(false)
	Panel:MakePopup()
	Panel:SetKeyboardInputEnabled(false)

	RF.PanelPause(Panel)

	Panel.Paint = function(self, pw, ph)
		RF.Box(0, 0, pw, ph, Color(0, 0, 0, 200))
		RF.Box(0, 0, pw, 84, Color(0, 0, 0, 165))
		RF.Box(0, 83, pw, 1, Hud.FG)

		draw.SimpleText("VOTES", "RFHudTag", 22, 26, Hud.LABEL, 0, TEXT_ALIGN_BOTTOM)
		draw.SimpleText(Vote.Total() .. " / " .. #player.GetAll(), "RFVoteName", 22, 32, Hud.FG, 0, 0)
		draw.SimpleText(string.upper(game.GetMap()), "RFHudTag", 22, 68, Hud.LABEL, 0, TEXT_ALIGN_BOTTOM)

		draw.SimpleText(string.upper(RF.GetGameType().name), "RFHudTag", pw * 0.5, 26,
			Hud.LABEL, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
		draw.SimpleText("SELECT A MAP", "RFVoteTitle", pw * 0.5, 52, Hud.FG,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local left = math.ceil(RF.StateTimeLeft())

		draw.SimpleText("NEXT MAP IN", "RFHudTag", pw - 26, 26, Hud.LABEL, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		RF.HudNumber(tostring(left), "RFHudBig", pw - 26, 54, left <= 5 and Hud.CAUTION or Hud.FG,
			TEXT_ALIGN_RIGHT)
	end

	local body = Panel:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(24, 96, 24, 24)
	body.Paint = function() end

	BuildDetail(body)
	BuildGrid(body)
end

function Vote.Update()
	if not IsValid(LocalPlayer()) then return end

	if RF.GetState() == RF.STATE_MAPVOTE then Vote.Open() else Vote.Close() end
end

timer.Create("RF.VoteWatch", 0.3, 0, Vote.Update)

concommand.Add("rf_vote", function(ply, cmd, args)
	local index = tonumber(args[1] or "")

	if not index then
		for slot = 1, #Vote.Choices + 1 do
			MsgN(string.format("    %-4d %s", slot, Vote.Label(slot)))
		end

		MsgN("[RollerFight] rf_vote <number> to vote")

		return
	end

	Vote.Send(math.Clamp(math.floor(index), 1, #Vote.Choices + 1))
end)

concommand.Add("rf_votedebug", function()
	MsgN("[RollerFight] state " .. RF.GetState() .. ", mapvote is " .. RF.STATE_MAPVOTE)
	MsgN("    choices " .. #Vote.Choices .. ", picked " .. Vote.Picked .. ", votes " .. Vote.Total())
	MsgN("    panel " .. tostring(IsValid(Panel)))

	if not IsValid(Panel) then return end

	MsgN("    visible " .. tostring(Panel:IsVisible()) .. ", mouse " .. tostring(Panel:IsMouseInputEnabled()))
	MsgN("    cursor " .. tostring(vgui.CursorVisible()) .. ", hovered " .. tostring(vgui.GetHoveredPanel()))
end)
