RF.Pick = RF.Pick or {}

local Pick = RF.Pick
local Panel

local U = RF.UI

local function Roster(parent, teamID)
	local wrap = parent:Add("DPanel")
	wrap.Paint = function(self, w, h)
		local col = RF.TeamColors[teamID] or U.TEXT
		local roster = RF.TeamRoster(teamID)
		local cap = RF.TeamCap()

		RF.Box(0, 0, w, h, U.PANEL)
		RF.Outline(0, 0, w, h, LocalPlayer():Team() == teamID and col or U.LINE)
		RF.Box(0, 0, w, 40, Color(20, 20, 20))
		RF.Box(0, 0, 5, 40, col)

		draw.SimpleText(string.upper(team.GetName(teamID) or ""), "RFTitle", 16, 20, col, 0, TEXT_ALIGN_CENTER)
		draw.SimpleText(#roster .. " / " .. cap, "RFHead", w - 14, 20, U.DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		for index, ply in ipairs(roster) do
			local y = 50 + (index - 1) * 30

			if y + 26 > h - 46 then
				draw.SimpleText("and " .. (#roster - index + 1) .. " more", "RFSmall", 16, y + 13, U.DIM, 0, TEXT_ALIGN_CENTER)
				break
			end

			RF.Box(10, y, w - 20, 26, ply == LocalPlayer() and Color(56, 56, 56) or Color(42, 42, 42))
			RF.Box(10, y, 3, 26, col)
			draw.SimpleText(ply:Nick(), "RFBody", 20, y + 13, U.TEXT, 0, TEXT_ALIGN_CENTER)

			if ply:IsBot() then
				draw.SimpleText("BOT", "RFSmall", w - 24, y + 13, U.DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		if #roster == 0 then
			draw.SimpleText("nobody yet", "RFSmall", 20, 63, U.DIM, 0, TEXT_ALIGN_CENTER)
		end
	end

	local join = wrap:Add("DButton")
	join:Dock(BOTTOM)
	join:DockMargin(10, 0, 10, 10)
	join:SetTall(36)
	join:SetText("JOIN " .. string.upper(team.GetName(teamID) or ""))
	RF.StyleButton(join, true)

	join.Think = function(self)
		local me = LocalPlayer()

		if me:Team() == teamID then
			self:SetText("YOU ARE ON THIS SIDE")
			self:SetEnabled(false)

			return
		end

		if #RF.TeamRoster(teamID) >= RF.TeamCap() then
			self:SetText("SIDE IS FULL")
			self:SetEnabled(false)

			return
		end

		self:SetText("JOIN " .. string.upper(team.GetName(teamID) or ""))
		self:SetEnabled(true)
	end

	join.DoClick = function()
		surface.PlaySound("buttons/button14.wav")
		net.Start("rf_jointeam")
		net.WriteUInt(teamID, 8)
		net.SendToServer()
	end

	return wrap
end

function Pick.Close()
	if IsValid(Panel) then Panel:Remove() end

	Panel = nil
end

function Pick.Open()
	if IsValid(Panel) then return end

	local w, h = 720, 400

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

	RF.PanelPause(Panel)

	Panel.Paint = function(self, pw, ph)
		RF.Box(0, 0, pw, ph, U.BG)
		RF.Outline(0, 0, pw, ph, U.LINE)
		RF.Box(0, 0, pw, 34, U.HEAD)
		RF.Box(0, 33, pw, 1, U.ACCENT)

		draw.SimpleText("CHOOSE YOUR SIDE", "RFTitle", pw * 0.5, 17, U.TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(RF.GetGameType().name, "RFSmall", 12, 17, U.DIM, 0, TEXT_ALIGN_CENTER)

		local left = math.ceil(RF.StateTimeLeft())

		draw.SimpleText(left .. "s", "RFHead", pw - 12, 17,
			left <= 5 and Color(240, 90, 70) or U.ACCENT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		draw.SimpleText("Anyone who has not picked is placed on the smaller side.", "RFSmall",
			pw * 0.5, ph - 18, U.DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local body = Panel:Add("DPanel")
	body:Dock(FILL)
	body:DockMargin(12, 42, 12, 30)
	body.Paint = function() end

	local combine = Roster(body, TEAM_COMBINE)
	local rebel = Roster(body, TEAM_REBEL)

	body.PerformLayout = function(self, bw, bh)
		local half = math.floor((bw - 10) * 0.5)

		combine:SetPos(0, 0)
		combine:SetSize(half, bh)
		rebel:SetPos(half + 10, 0)
		rebel:SetSize(bw - half - 10, bh)
	end
end

function Pick.Update()
	local me = LocalPlayer()
	if not IsValid(me) then return end

	local want = RF.GetState() == RF.STATE_TEAMPICK and not me:GetNWBool("rf_spectating", false)

	if want then Pick.Open() else Pick.Close() end
end

timer.Create("RF.PickWatch", 0.3, 0, Pick.Update)
