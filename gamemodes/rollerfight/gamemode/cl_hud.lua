surface.CreateFont("RFHudSmall", { font = "Verdana", size = 17, weight = 700, antialias = true })
surface.CreateFont("RFHudTimer", { font = "Verdana", size = 30, weight = 800, antialias = true })
surface.CreateFont("RFCount", { font = "Verdana", size = 86, weight = 800, antialias = true })

local function Bar(x, y, w, h, frac, col)
	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(col.r, col.g, col.b, 235)
	surface.DrawRect(x + 2, y + 2, (w - 4) * math.Clamp(frac, 0, 1), h - 4)

	surface.SetDrawColor(255, 255, 255, 40)
	surface.DrawOutlinedRect(x, y, w, h)
end

local function RoundBanner()
	local state = RF.GetState()

	if GetGlobalBool("rf_paused", false) then
		draw.SimpleText("PAUSED", "RFHudTimer", ScrW() * 0.5, 26, Color(238, 130, 32),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if state == RF.STATE_WAITING then
		local auto = GetGlobalFloat("rf_autostart", 0)
		if auto <= 0 then return end

		local left = math.max(0, auto - CurTime())

		draw.SimpleText("MATCH STARTS IN", "RFHudSmall", ScrW() * 0.5, 22,
			Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.format("%d", math.ceil(left)), "RFHudTimer", ScrW() * 0.5, 48,
			left < 6 and Color(240, 90, 70) or Color(238, 130, 32), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	end

	if state == RF.STATE_COUNTDOWN then
		local left = math.ceil(RF.StateTimeLeft())
		if left <= 0 then return end

		local pulse = 1 - (RF.StateTimeLeft() % 1)

		draw.SimpleText(left, "RFCount", ScrW() * 0.5, ScrH() * 0.36,
			Color(238, 130, 32, 255 - pulse * 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("GET READY", "RFHudSmall", ScrW() * 0.5, ScrH() * 0.36 + 60,
			Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	end

	if state == RF.STATE_INTERMISSION then
		draw.SimpleText(string.upper(RF.GetGameType().name), "RFCount", ScrW() * 0.5, ScrH() * 0.5,
			Color(238, 130, 32), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	end

	if state == RF.STATE_POST then
		draw.SimpleText("ROUND OVER", "RFCount", ScrW() * 0.5, ScrH() * 0.2,
			Color(238, 130, 32), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if RF.RoundReason and RF.RoundReason ~= "" then
			draw.SimpleText(RF.RoundReason, "RFHudTimer", ScrW() * 0.5, ScrH() * 0.2 + 62,
				Color(230, 230, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		draw.SimpleText("Scoreboard is on TAB", "RFHudSmall", ScrW() * 0.5, ScrH() * 0.2 + 96,
			Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	end

	if state ~= RF.STATE_ACTIVE then return end

	local left = RF.StateTimeLeft()

	draw.SimpleText(string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60)),
		"RFHudTimer", ScrW() * 0.5, 24, left < 30 and Color(240, 90, 70) or Color(230, 230, 230),
		TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

net.Receive("rf_roundend", function()
	RF.RoundReason = net.ReadString()
end)

function GM:HUDPaint()
	if RF.Score and RF.Score.IsOpen and RF.Score.IsOpen() then return end

	RoundBanner()

	local ply = LocalPlayer()
	local mine = ply:GetNWEntity("rf_mine")

	local x, y = 40, ScrH() - 130
	local w, h = 260, 22

	if not IsValid(mine) then
		if RF.GetState() == RF.STATE_ACTIVE then
			draw.SimpleText("DESTROYED", "RFHudSmall", x, y, Color(255, 90, 70), 0, 0)
		end

		return
	end

	local health = mine:Health() / math.max(1, mine:GetMaxHealth())
	local energy = mine:GetEnergy() / math.max(1, RF.Get("MaxEnergy"))

	Bar(x, y, w, h, health, Color(200, 60, 50))
	Bar(x, y + h + 8, w, h, energy, mine:GetExhausted() and Color(120, 90, 40) or Color(230, 180, 50))

	draw.SimpleText(math.ceil(mine:Health()), "RFHudSmall", x + w + 12, y + 2, color_white, 0, 0)
	draw.SimpleText(math.ceil(mine:GetEnergy()), "RFHudSmall", x + w + 12, y + h + 10, color_white, 0, 0)

	local state = "PASSIVE"
	local col = mine:GetTeamColor()

	if mine:GetBuried() then
		state = "BURIED"
	elseif mine:GetAttackMode() then
		state = "ATTACK"
	elseif CurTime() < mine:GetAttackLockEnd() then
		state = "LOCKED " .. string.format("%.1f", mine:GetAttackLockEnd() - CurTime())
	elseif mine:GetExhausted() then
		state = "EXHAUSTED"
	end

	draw.SimpleText(state, "RFHudSmall", x, y - 26, col, 0, 0)

	if RF.Get("Debug") < 1 then return end

	local speed = mine:GetVelocity():Length()
	local gap = mine:GetNWFloat("rf_gap", -1)
	local grounded = mine:GetNWBool("rf_grounded", false)

	local contact = mine:GetNWFloat("rf_contact", 999)
	local byContact = mine:GetNWBool("rf_bycontact", false)

	local lines = {
		"grounded  " .. tostring(grounded) .. (byContact and "  (contact)" or "  (ray)"),
		"contact   " .. (contact >= 900 and "never" or string.format("%.2fs ago", contact)),
		"gap       " .. (gap >= 9000 and "none" or string.format("%.2f", gap)),
		"speed     " .. string.format("%.0f", speed),
		"attack    " .. tostring(mine:GetAttackMode()),
		"model     " .. string.GetFileFromFilename(mine:GetModel() or "?"),
		"mode      " .. (RF.Get("MoveMode") >= 1 and "arcade" or "physics")
	}

	for i, line in ipairs(lines) do
		draw.SimpleText(line, "RFHudSmall", x, y - 60 - (#lines - i) * 18,
			grounded and Color(120, 240, 140) or Color(255, 170, 120), 0, 0)
	end
end
