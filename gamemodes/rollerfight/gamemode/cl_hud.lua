surface.CreateFont("RFHudSmall", { font = "Verdana", size = 17, weight = 700, antialias = true })

local function Bar(x, y, w, h, frac, col)
	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(col.r, col.g, col.b, 235)
	surface.DrawRect(x + 2, y + 2, (w - 4) * math.Clamp(frac, 0, 1), h - 4)

	surface.SetDrawColor(255, 255, 255, 40)
	surface.DrawOutlinedRect(x, y, w, h)
end

function GM:HUDPaint()
	local ply = LocalPlayer()
	local mine = ply:GetNWEntity("rf_mine")

	local x, y = 40, ScrH() - 130
	local w, h = 260, 22

	if not IsValid(mine) then
		draw.SimpleText("DESTROYED", "RFHudSmall", x, y, Color(255, 90, 70), 0, 0)
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
end
