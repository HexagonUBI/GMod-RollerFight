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

local CARD_H = 62
local AVATAR = 18
local MAX_AVATARS = 5

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

	Vote.NextSend = CurTime() + 0.2
	Vote.Picked = index

	surface.PlaySound("buttons/button14.wav")

	net.Start("rf_mapvote_pick")
	net.WriteUInt(index, 7)
	net.SendToServer()
end

net.Receive("rf_mapvote", function()
	local count = net.ReadUInt(7)

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
		local index = net.ReadUInt(7)

		Vote.Counts[index] = (Vote.Counts[index] or 0) + 1
		Vote.Voters[index] = Vote.Voters[index] or {}

		table.insert(Vote.Voters[index], ply)

		if ply == me then Vote.Picked = index end
	end

	Vote.Version = Vote.Version + 1
end)

local function Avatars(panel, index, size, count)
	if panel.StampV == Vote.Version and panel.StampI == index then return false end

	panel.StampV, panel.StampI = Vote.Version, index
	panel.Pics = panel.Pics or {}

	local voters = Vote.Voters[index] or {}

	for slot = 1, count do
		local pic = panel.Pics[slot]

		if not IsValid(pic) then
			pic = vgui.Create("AvatarImage", panel)
			pic:SetSize(size, size)
			pic:SetMouseInputEnabled(false)
			panel.Pics[slot] = pic
		end

		local ply = voters[slot]

		if IsValid(ply) then
			if pic.RFPly ~= ply then
				pic:SetPlayer(ply, 32)
				pic.RFPly = ply
			end

			pic:SetVisible(true)
		else
			pic:SetVisible(false)
		end
	end

	panel.Extra = math.max(0, #voters - count)
	panel.Shown = math.min(#voters, count)

	return true
end

local function LayoutAvatars(panel, size, gap, right, bottom)
	for slot = 1, panel.Shown or 0 do
		local pic = panel.Pics[slot]

		if IsValid(pic) then
			pic:SetPos(right - slot * (size + gap) + gap, bottom - size)
		end
	end
end

local function Card(parent, index)
	local card = parent:Add("DButton")
	card:SetText("")

	card.OnCursorEntered = function()
		Vote.Focus = index
	end

	card.Think = function(self)
		if Avatars(self, index, AVATAR, MAX_AVATARS) then
			LayoutAvatars(self, AVATAR, 3, self:GetWide() - 6, self:GetTall() - 25)
		end
	end

	card.Paint = function(self, w, h)
		local mine = Vote.Picked == index
		local count = Vote.Counts[index] or 0
		local strip = 20

		if Vote.IsRandom(index) then
			RF.Box(0, 0, w, h, Color(30, 25, 14))
			surface.SetDrawColor(Hud.FG.r, Hud.FG.g, Hud.FG.b, 30)

			for i = -h, w, 20 do
				surface.DrawLine(i, h, i + h, 0)
			end
		else
			RF.MapPlate(Vote.Choices[index], 0, 0, w, h, 34)
		end

		RF.FadeY(0, h - strip - 20, w, 20, Color(0, 0, 0, 210), true)
		RF.Box(0, h - strip, w, strip, Color(0, 0, 0, 210))

		if mine then
			RF.Box(0, 0, w, h, Color(Hud.FG.r, Hud.FG.g, Hud.FG.b, 34))
		elseif self:IsHovered() then
			RF.Box(0, 0, w, h, Color(255, 255, 255, 22))
		end

		RF.Outline(0, 0, w, h, mine and Hud.FG or (Vote.Focus == index and Color(150, 130, 70) or U.LINE))
		RF.Box(0, 0, 3, h, mine and Hud.FG or Color(64, 60, 48))

		draw.SimpleText(string.upper(Vote.Label(index)), "RFHudTag", 10, h - strip * 0.5,
			mine and Hud.FG or Hud.LABEL, 0, TEXT_ALIGN_CENTER)

		if count > 0 then
			draw.RoundedBox(3, w - 30, 5, 25, 21, Hud.BG)
			draw.SimpleText(count, "RFHudMini", w - 17, 15, Hud.FG, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if (self.Extra or 0) > 0 then
			draw.SimpleText("+" .. self.Extra, "RFHudTag",
				w - 6 - (self.Shown or 0) * (AVATAR + 3) - 2, h - strip - 4 - AVATAR * 0.5,
				Hud.LABEL, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	card.DoClick = function()
		Vote.Send(index)
	end

	return card
end

local function BuildGrid(parent)
	local list = parent:Add("DScrollPanel")
	list:Dock(FILL)
	list:DockMargin(0, 0, 6, 0)

	list.Rebuild = function()
		list:Clear()

		local canvas = list:GetCanvas()
		local width = RF.ListWidth(list, 2)
		local gap = 6
		local cols = math.Clamp(math.floor(width / 300), 2, 4)
		local cardW = math.floor((width - gap * (cols - 1)) / cols)
		local total = #Vote.Choices + 1
		local rows = math.ceil(total / cols)

		canvas:SetTall(rows * (CARD_H + gap))

		for index = 1, total do
			local card = Card(canvas, index)
			local col = (index - 1) % cols
			local row = math.floor((index - 1) / cols)

			card:SetSize(cardW, CARD_H)
			card:SetPos(col * (cardW + gap), row * (CARD_H + gap))
		end
	end

	list.Think = function(self)
		local stamp = #Vote.Choices .. "x" .. self:GetWide()

		if self.Stamp == stamp then return end

		self.Stamp = stamp
		RF.DeferRebuild(self)
	end

	return list
end

local function BuildDetail(parent)
	local wrap = parent:Add("DPanel")
	wrap:Dock(RIGHT)
	wrap:SetWide(math.Clamp(math.floor(ScrW() * 0.24), 300, 460))

	wrap.Paint = function(self, w, h)
		local index = Vote.Focus
		local random = Vote.IsRandom(index)
		local shot = math.floor(w * 0.72)

		draw.RoundedBox(6, 0, 0, w, h, Hud.BG)
		RF.Box(0, 0, w, 40, Color(0, 0, 0, 150))
		RF.Box(0, 39, w, 1, Hud.FG)

		draw.SimpleText(string.upper(Vote.Label(index)), "RFVoteName", 14, 20, Hud.FG, 0, TEXT_ALIGN_CENTER)

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
	end

	local rows = wrap:Add("DPanel")
	rows:SetPos(0, 0)
	rows.Paint = function() end

	rows.Think = function(self)
		local index = Vote.Focus
		local shot = math.floor(wrap:GetWide() * 0.72)
		local top = 46 + shot + 60

		self:SetPos(0, top)
		self:SetSize(wrap:GetWide(), math.max(0, wrap:GetTall() - top))

		if not Avatars(self, index, 26, 8) then return end

		for slot = 1, self.Shown or 0 do
			local pic = self.Pics[slot]

			if IsValid(pic) then pic:SetPos(14 + (slot - 1) * 30, 0) end
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
	Panel:SetScreenLock(true)
	Panel:MakePopup()
	Panel:SetKeyboardInputEnabled(false)

	Panel.Think = RF.PanelPause

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
		local col = left <= 5 and Hud.CAUTION or Hud.FG

		draw.SimpleText("NEXT MAP IN", "RFHudTag", pw - 26, 26, Hud.LABEL, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		draw.SimpleText(left, "RFHudHugeGlow", pw - 26, 48, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText(left, "RFHudHuge", pw - 26, 48, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

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
