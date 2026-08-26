RF.Stats = RF.Stats or {}

local Stats = RF.Stats
local Panel

local U = RF.UI

Stats.File = "rollerfight/profile.json"
Stats.Data = {}
Stats.Unlocked = {}
Stats.Dirty = false

function Stats.Load()
	local raw = file.Read(Stats.File, "DATA")
	local data = raw and util.JSONToTable(raw)

	Stats.Data = data and data.stats or {}
	Stats.Unlocked = data and data.achievements or {}
end

function Stats.Save()
	file.CreateDir("rollerfight")
	file.Write(Stats.File, util.TableToJSON({ stats = Stats.Data, achievements = Stats.Unlocked }))

	Stats.Dirty = false
end

function Stats.Get(key)
	return Stats.Data[key] or 0
end

function Stats.Unlock(entry)
	Stats.Unlocked[entry.id] = os.time()
	Stats.Save()

	surface.PlaySound("buttons/button9.wav")
	chat.AddText(RF.Hud.FG, "[Achievement] ", color_white, entry.name .. ", " .. entry.blurb)

	net.Start("rf_achievement")
	net.WriteString(entry.id)
	net.SendToServer()
end

function Stats.Check()
	for _, entry in ipairs(RF.Achievements) do
		if not Stats.Unlocked[entry.id] and Stats.Get(entry.stat) >= entry.goal then
			Stats.Unlock(entry)
		end
	end
end

function Stats.Add(key, amount)
	if amount <= 0 then return end

	Stats.Data[key] = Stats.Get(key) + amount
	Stats.Dirty = true

	Stats.Check()
end

function Stats.Best(key, value)
	if value <= Stats.Get(key) then return end

	Stats.Data[key] = value
	Stats.Dirty = true

	Stats.Check()
end

function RF.StatKill(entry)
	if entry.Mine then Stats.Add("kills", 1) end
	if entry.Assisted then Stats.Add("assists", 1) end
	if not entry.Died then return end

	Stats.Add("deaths", 1)

	if entry.Cause == "water" then Stats.Add("waterdeaths", 1) end
end

hook.Add("Think", "RF.StatsTrack", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local now = CurTime()
	local dt = now - (Stats.Tick or now)

	Stats.Tick = now

	local mine = ply:GetNWEntity("rf_mine")

	if not IsValid(mine) or dt <= 0 or dt > 1 then
		Stats.Pos = nil

		return
	end

	local pos = mine:GetPos()

	if Stats.Pos then Stats.Add("distance", pos:Distance(Stats.Pos)) end

	Stats.Pos = pos

	if RF.GetState() == RF.STATE_ACTIVE then Stats.Add("playtime", dt) end

	Stats.Best("topspeed", mine:GetVelocity():Length())

	if mine:GetAttackMode() then Stats.Add("attacktime", dt) end

	local buried = mine:GetBuried()

	if buried and not Stats.WasBuried then Stats.Add("burrows", 1) end

	Stats.WasBuried = buried

	local flat = mine:GetExhausted()

	if flat and not Stats.WasFlat then Stats.Add("exhausts", 1) end

	Stats.WasFlat = flat
end)

timer.Create("RF.StatsRound", 0.5, 0, function()
	local state = RF.GetState()

	if Stats.State ~= state then
		if state == RF.STATE_ACTIVE then Stats.Add("rounds", 1) end

		if state == RF.STATE_POST then
			local ply = LocalPlayer()

			if IsValid(ply) and IsValid(ply:GetNWEntity("rf_mine")) then Stats.Add("wins", 1) end
			if RF.LastRound() then Stats.Add("matches", 1) end
		end

		Stats.State = state
	end

	if Stats.Dirty then Stats.Save() end
end)

hook.Add("ShutDown", "RF.StatsSave", function()
	if Stats.Dirty then Stats.Save() end
end)

net.Receive("rf_achievement", function()
	local who = net.ReadEntity()
	local entry = RF.AchievementByID[net.ReadString()]

	if not entry or not IsValid(who) or who == LocalPlayer() then return end

	chat.AddText(RF.PlayerColor(who), who:Nick(), color_white, " unlocked ",
		RF.Hud.FG, entry.name)
end)

local function StatsPage(parent)
	local page = vgui.Create("DScrollPanel", parent)

	for index, entry in ipairs(RF.StatList) do
		local row = page:Add("DPanel")
		row:Dock(TOP)
		row:SetTall(30)
		row:DockMargin(0, 0, 6, 3)

		row.Paint = function(self, w, h)
			RF.Box(0, 0, w, h, index % 2 == 0 and Color(38, 38, 38) or Color(44, 44, 44))
			RF.Box(0, 0, 3, h, U.ACCENT)

			draw.SimpleText(entry.label, "RFBody", 12, h * 0.5, U.TEXT, 0, TEXT_ALIGN_CENTER)
			draw.SimpleText(RF.StatFormat(entry.kind, Stats.Get(entry.key)), "RFHead", w - 12, h * 0.5,
				U.ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	return page
end

local function AchievementsPage(parent)
	local page = vgui.Create("DScrollPanel", parent)

	for _, entry in ipairs(RF.Achievements) do
		local row = page:Add("DPanel")
		row:Dock(TOP)
		row:SetTall(62)
		row:DockMargin(0, 0, 6, 4)

		row.Paint = function(self, w, h)
			local got = Stats.Unlocked[entry.id]
			local have = math.min(Stats.Get(entry.stat), entry.goal)
			local frac = have / entry.goal

			RF.Box(0, 0, w, h, got and Color(46, 42, 30) or Color(38, 38, 38))
			RF.Outline(0, 0, w, h, got and U.ACCENT or U.LINE)

			surface.SetDrawColor(255, 255, 255, got and 255 or 70)
			surface.SetMaterial(RF.Mat("rollerfight/ach/" .. entry.icon .. ".png"))
			surface.DrawTexturedRect(9, 7, 48, 48)

			draw.SimpleText(entry.name, "RFHead", 68, 16, got and U.ACCENT or U.TEXT, 0, TEXT_ALIGN_CENTER)
			draw.SimpleText(entry.blurb, "RFSmall", 68, 33, U.DIM, 0, TEXT_ALIGN_CENTER)

			RF.Box(68, 46, w - 82, 8, Color(24, 24, 24))
			RF.Box(68, 46, (w - 82) * frac, 8, got and U.ACCENT or Color(110, 110, 110))

			local kind = RF.StatKind[entry.stat]

			draw.SimpleText(RF.StatFormat(kind, have) .. " / " .. RF.StatFormat(kind, entry.goal),
				"RFSmall", w - 14, 34, got and U.ACCENT or U.DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	return page
end

function Stats.Close()
	if IsValid(Panel) then Panel:Remove() end

	Panel = nil
end

function Stats.Open()
	if IsValid(Panel) then
		Stats.Close()

		return
	end

	local w, h = 620, 520

	Panel = vgui.Create("DFrame")
	Panel:SetSize(w, h)
	Panel:Center()
	Panel:SetTitle("")
	Panel:ShowCloseButton(false)
	Panel:SetDraggable(false)
	Panel:SetSizable(false)
	Panel:MakePopup()
	Panel:SetKeyboardInputEnabled(false)

	RF.PanelPause(Panel)

	local done = 0

	for _, entry in ipairs(RF.Achievements) do
		if Stats.Unlocked[entry.id] then done = done + 1 end
	end

	Panel.Paint = function(self, pw, ph)
		RF.Box(0, 0, pw, ph, U.BG)
		RF.Outline(0, 0, pw, ph, U.LINE)
		RF.Box(0, 0, pw, 34, U.HEAD)
		RF.Box(0, 33, pw, 1, U.ACCENT)

		draw.SimpleText("YOUR PROFILE", "RFTitle", pw * 0.5, 17, U.TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(LocalPlayer():Nick(), "RFSmall", 12, 17, U.DIM, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(done .. " / " .. #RF.Achievements .. " unlocked", "RFSmall", pw - 12, 17,
			U.ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local tabs = Panel:Add("DPanel")
	tabs:Dock(TOP)
	tabs:DockMargin(12, 42, 12, 6)
	tabs:SetTall(28)
	tabs.Paint = function() end

	local body = Panel:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(12, 0, 12, 10)
	body.Paint = function() end

	local close = Panel:Add("DButton")
	close:Dock(BOTTOM)
	close:DockMargin(12, 0, 12, 10)
	close:SetTall(30)
	close:SetText("CLOSE")
	RF.StyleButton(close, false)
	close.DoClick = Stats.Close

	local pages = {
		{ name = "STATS", build = StatsPage },
		{ name = "ACHIEVEMENTS", build = AchievementsPage }
	}

	Panel.Page = 1

	for index, def in ipairs(pages) do
		local panel = def.build(body)
		panel:Dock(FILL)
		def.panel = panel

		local btn = tabs:Add("DButton")
		btn:Dock(LEFT)
		btn:SetWide(150)
		btn:DockMargin(0, 0, 4, 0)
		btn:SetText(def.name)
		btn:SetFont("RFHead")

		btn.Paint = function(self, bw, bh)
			local on = Panel.Page == index

			RF.Box(0, 0, bw, bh, on and U.ACCENT or Color(40, 40, 40))
			RF.Outline(0, 0, bw, bh, U.LINE)
			self:SetTextColor(on and Color(20, 20, 20) or (self:IsHovered() and U.ACCENT or U.TEXT))
		end

		btn.DoClick = function()
			Panel.Page = index

			for other, entry in ipairs(pages) do
				entry.panel:SetVisible(other == index)
			end
		end
	end

	for index, def in ipairs(pages) do
		def.panel:SetVisible(index == 1)
	end
end

Stats.Load()

concommand.Add("rf_profile", Stats.Open)

concommand.Add("rf_profile_reset", function()
	Stats.Data = {}
	Stats.Unlocked = {}
	Stats.Save()

	chat.AddText(RF.Hud.FG, "[RollerFight] ", color_white, "Profile reset")
end)
