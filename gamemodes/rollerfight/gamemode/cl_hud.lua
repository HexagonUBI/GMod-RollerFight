surface.CreateFont("RFHudTimer", { font = "Verdana", size = 30, weight = 800, antialias = true })

RF.Hud = RF.Hud or {}

local Hud = RF.Hud

Hud.FG = Color(255, 208, 64)
Hud.LABEL = Color(255, 220, 0, 220)
Hud.DIM = Color(255, 208, 64, 55)
Hud.BG = Color(0, 0, 0, 110)
Hud.ALERT = Color(0, 0, 0, 175)
Hud.CAUTION = Color(255, 48, 0)
Hud.DAMAGED = Color(210, 40, 30)

function Hud.Scale(value)
	return math.max(1, math.floor(value * ScrH() / 600))
end

local S = Hud.Scale

Hud.Digits = {
	{ "RFHudBig", 32, 0 },
	{ "RFHudBigGlow", 32, 4 },
	{ "RFHudHuge", 76, 0 },
	{ "RFHudHugeGlow", 76, 6 }
}

Hud.Glowing = {
	RFHudBig = true,
	RFHudHuge = true
}

function Hud.BuildFonts()
	for _, f in ipairs(Hud.Digits) do
		surface.CreateFont(f[1], {
			font = "HalfLife2",
			size = S(f[2]),
			weight = 0,
			blursize = f[3],
			scanlines = f[3] > 0 and 2 or 0,
			additive = true,
			antialias = true
		})
	end

	surface.CreateFont("RFHudWord", { font = "Verdana", size = S(15), weight = 800, antialias = true })
	surface.CreateFont("RFHudBanner", { font = "Verdana", size = S(40), weight = 800, antialias = true })
	surface.CreateFont("RFHudTag", { font = "Verdana", size = S(9), weight = 700, antialias = true })
	surface.CreateFont("RFFeed", { font = "Verdana", size = S(10), weight = 800, antialias = true })
	surface.CreateFont("RFHudMini", { font = "HalfLife2", size = S(12), weight = 0, additive = true, antialias = true })
end

Hud.BuildFonts()

hook.Add("OnScreenSizeChanged", "RF.HudFonts", Hud.BuildFonts)

local function Panel(x, y, w, h, col)
	draw.RoundedBox(S(4), x, y, w, h, col or Hud.BG)
end

local function Tag(text, x, y, col)
	draw.SimpleText(text, "RFHudTag", x, y, col or Hud.LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end

local function Glow(text, font, x, y, col, xalign, yalign)
	if Hud.Glowing[font] then
		draw.SimpleText(text, font .. "Glow", x, y, col, xalign, yalign)
	end

	draw.SimpleText(text, font, x, y, col, xalign, yalign)
end

Hud.DigitTop = 0.226
Hud.DigitCap = 0.586

function RF.HudClock(left, x, y, col)
	local mins = string.format("%d", math.floor(left / 60))
	local secs = string.format("%02d", math.floor(left % 60))

	surface.SetFont("RFHudBig")

	local secsW, tall = surface.GetTextSize(secs)
	local cap = tall * Hud.DigitCap
	local top = y + tall * Hud.DigitTop
	local dot = math.max(2, math.floor(cap * 0.14))
	local slot = dot * 4
	local colonX = math.floor(x - secsW - slot + (slot - dot) * 0.5)

	Glow(secs, "RFHudBig", x, y, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	Glow(mins, "RFHudBig", x - secsW - slot, y, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	surface.SetDrawColor(col)
	surface.DrawRect(colonX, math.floor(top + cap * 0.30 - dot * 0.5), dot, dot)
	surface.DrawRect(colonX, math.floor(top + cap * 0.78 - dot * 0.5), dot, dot)
end

local function DigitBlock(text, font, cx, top, height, col)
	surface.SetFont(font)

	local _, tall = surface.GetTextSize(text)

	Glow(text, font, cx, top + (height - tall * Hud.DigitCap) * 0.5 - tall * Hud.DigitTop, col,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function StatBox(x, y, w, h, label, value, col)
	Panel(x, y, w, h)
	Tag(label, x + S(8), y + h - S(7))
	Glow(tostring(value), "RFHudBig", x + w - S(8), y + S(1), col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

local function WordBox(x, y, w, h, label, word, note, col)
	Panel(x, y, w, h)
	Tag(label, x + S(8), y + h - S(7))
	draw.SimpleText(word, "RFHudWord", x + w - S(8), y + S(6), col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	if not note then return end

	draw.SimpleText(note, "RFHudTag", x + w - S(8), y + h - S(7), Hud.LABEL,
		TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
end

local function ChunkBar(x, y, w, h, label, frac, col)
	Panel(x, y, w, h)
	Tag(label, x + S(8), y + S(15))

	local inset = S(8)
	local chunkW, gap, thick = S(6), S(3), S(4)
	local count = math.max(1, math.floor((w - inset * 2 + gap) / (chunkW + gap)))
	local filled = math.ceil(math.Clamp(frac, 0, 1) * count)
	local barY = y + h - S(9)

	for i = 0, count - 1 do
		surface.SetDrawColor(i < filled and col or Hud.DIM)
		surface.DrawRect(x + inset + i * (chunkW + gap), barY, chunkW, thick)
	end
end

local function MineState(mine)
	if mine:GetBuried() then return "BURIED", "UNDERGROUND", Hud.FG end
	if mine:GetAttackMode() then return "ATTACK", "SPIKES OUT", Hud.FG end
	if mine:GetExhausted() then return "EXHAUSTED", "RECOVERING", Hud.DAMAGED end

	local lock = mine:GetAttackLockEnd() - CurTime()

	if lock > 0 then return "LOCKED", string.format("%.1f", lock), Hud.DAMAGED end

	return "PASSIVE", "READY", Hud.FG
end

local function TeamScore(id)
	local total = 0

	for _, ply in ipairs(player.GetAll()) do
		if ply:Team() == id then total = total + ply:Frags() end
	end

	return total
end

local function MineHud(ply, mine)
	local margin, boxW, boxH, gap = S(16), S(102), S(36), S(6)
	local barH = S(26)
	local y = ScrH() - S(12) - boxH
	local barY = y - S(4) - barH

	local health = mine:Health()
	local maxHealth = math.max(1, mine:GetMaxHealth())
	local exhausted = mine:GetExhausted()

	ChunkBar(margin, barY, boxW * 2 + gap, barH,
		exhausted and "ENERGY DEPLETED" or "ENERGY",
		mine:GetEnergy() / math.max(1, RF.Get("MaxEnergy")),
		exhausted and Hud.DAMAGED or Hud.FG)

	StatBox(margin, y, boxW, boxH, "HEALTH", math.ceil(health),
		health / maxHealth <= 0.25 and Hud.CAUTION or Hud.FG)

	if RF.GetGameType().lives > 0 then
		StatBox(margin + boxW + gap, y, boxW, boxH, "LIVES", ply:GetNWInt("rf_lives", 0), Hud.FG)
	else
		StatBox(margin + boxW + gap, y, boxW, boxH, "SCORE", ply:Frags(), Hud.FG)
	end

	local stateW = S(140)
	local word, note, col = MineState(mine)

	WordBox(ScrW() - margin - stateW, y, stateW, boxH, "STATUS", word, note, col)
end

local function DeadHud()
	local margin, boxW, boxH = S(16), S(150), S(36)

	WordBox(margin, ScrH() - S(12) - boxH, boxW, boxH, "MINE", "DESTROYED", nil, Hud.DAMAGED)
end

local function TeamChip(x, y, w, h, id, label)
	local col = RF.TeamColors[id] or Hud.FG

	Panel(x, y, w, h)
	Tag(label, x + S(7), y + h - S(6), col)
	Glow(tostring(TeamScore(id)), "RFHudBig", x + w - S(7), y + S(1), col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

local function RoundStrip()
	local state = RF.GetState()
	local w, h = S(140), S(40)
	local x, y = math.floor((ScrW() - w) * 0.5), S(12)

	if state == RF.STATE_WAITING then
		local auto = GetGlobalFloat("rf_autostart", 0)
		if auto <= 0 then return end

		Panel(x, y, w, h)
		Tag("MATCH STARTS IN", x + S(8), y + h - S(6))
		Glow(tostring(math.ceil(math.max(0, auto - CurTime()))), "RFHudBig",
			x + w - S(8), y + S(1), Hud.FG, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		return
	end

	if state == RF.STATE_TEAMPICK then
		Panel(x, y, w, h)
		Tag("CHOOSING TEAMS", x + S(8), y + h - S(6))
		Glow(tostring(math.ceil(RF.StateTimeLeft())), "RFHudBig",
			x + w - S(8), y + S(1), Hud.FG, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		return
	end

	if state ~= RF.STATE_ACTIVE then return end

	local left = RF.StateTimeLeft()
	local total = RF.RoundsPerMatch()
	local label = string.upper(RF.GetGameType().name)

	if total > 1 then label = label .. "   " .. RF.RoundNumber() .. "/" .. total end

	Panel(x, y, w, h)
	Tag(label, x + S(8), y + h - S(6))
	RF.HudClock(left, x + w - S(8), y + S(1), left < 30 and Hud.CAUTION or Hud.FG)

	if not RF.GetGameType().teams then return end

	local cw = S(74)

	TeamChip(x - S(6) - cw, y, cw, h, TEAM_COMBINE, "COMBINE")
	TeamChip(x + w + S(6), y, cw, h, TEAM_REBEL, "REBELS")
end

local function RespawnClock()
	local ply = LocalPlayer()

	if IsValid(ply:GetNWEntity("rf_mine")) then return end
	if RF.GetState() ~= RF.STATE_ACTIVE then return end

	if RF.GetGameType().lives > 0 then
		local w, h = S(160), S(34)
		local x, y = math.floor((ScrW() - w) * 0.5), math.floor(ScrH() * 0.38)

		Panel(x, y, w, h, Hud.ALERT)
		draw.SimpleText("ELIMINATED", "RFHudWord", x + w * 0.5, y + h * 0.5, Hud.DAMAGED,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		return
	end

	local left = ply:GetNWFloat("rf_respawn", 0) - CurTime()
	if left <= 0 then return end

	local w, h, band = S(130), S(56), S(17)
	local x, y = math.floor((ScrW() - w) * 0.5), math.floor(ScrH() * 0.36)

	Panel(x, y, w, h, Hud.ALERT)
	draw.SimpleText("RESPAWNING IN", "RFHudTag", x + w * 0.5, y + band - S(4), Hud.LABEL,
		TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	DigitBlock(tostring(math.ceil(left)), "RFHudBig", x + w * 0.5, y + band, h - band - S(6), Hud.FG)
end

local function Centred(text, font, y, col)
	Glow(text, font, ScrW() * 0.5, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function Banner()
	local state = RF.GetState()

	if GetGlobalBool("rf_paused", false) then
		Centred("PAUSED", "RFHudBanner", S(80), Hud.FG)
	end

	if state == RF.STATE_COUNTDOWN then
		local left = math.ceil(RF.StateTimeLeft())
		if left <= 0 then return end

		Centred(tostring(left), "RFHudHuge", ScrH() * 0.36, Hud.FG)
		Centred("GET READY", "RFHudWord", ScrH() * 0.36 + S(58), Hud.LABEL)

		return
	end

	if state == RF.STATE_INTERMISSION then
		Centred(string.upper(RF.GetGameType().name), "RFHudBanner", ScrH() * 0.5, Hud.FG)

		return
	end

	if state == RF.STATE_MAPVOTE then return end
	if state ~= RF.STATE_POST then return end

	Centred(RF.LastRound() and "MATCH OVER" or "ROUND OVER", "RFHudBanner", ScrH() * 0.22, Hud.FG)

	if RF.RoundReason and RF.RoundReason ~= "" then
		Centred(string.upper(RF.RoundReason), "RFHudWord", ScrH() * 0.22 + S(40), Hud.LABEL)
	end

	Centred("SCOREBOARD IS ON TAB", "RFHudTag", ScrH() * 0.22 + S(62), Hud.LABEL)
end

net.Receive("rf_roundend", function()
	RF.RoundReason = net.ReadString()
end)

local function SpectateBar()
	local ply = LocalPlayer()
	if IsValid(ply:GetNWEntity("rf_mine")) then return end
	if not RF.InRound() then return end

	local watch = ply:GetNWEntity("rf_watch")
	local w, h = S(300), S(40)
	local x, y = math.floor((ScrW() - w) * 0.5), ScrH() - S(100)

	if not IsValid(watch) then
		WordBox(x, y, w, h, "SPECTATING", "NOBODY LEFT TO WATCH", nil, Hud.LABEL)

		return
	end

	WordBox(x, y, w, h, "SPECTATING", string.upper(watch:Nick()),
		"LEFT CLICK NEXT   RIGHT CLICK PREVIOUS", RF.PlayerColor(watch))
end

local function Debug(mine)
	if RF.Get("Debug") < 1 then return end

	local gap = mine:GetNWFloat("rf_gap", -1)
	local contact = mine:GetNWFloat("rf_contact", 999)
	local grounded = mine:GetNWBool("rf_grounded", false)

	local lines = {
		"grounded  " .. tostring(grounded) .. (mine:GetNWBool("rf_bycontact", false) and "  (contact)" or "  (ray)"),
		"contact   " .. (contact >= 900 and "never" or string.format("%.2fs ago", contact)),
		"gap       " .. (gap >= 9000 and "none" or string.format("%.2f", gap)),
		"speed     " .. string.format("%.0f", mine:GetVelocity():Length()),
		"attack    " .. tostring(mine:GetAttackMode()),
		"model     " .. string.GetFileFromFilename(mine:GetModel() or "?"),
		"mode      " .. (RF.Get("MoveMode") >= 1 and "arcade" or "physics")
	}

	local step = S(11)
	local y = ScrH() - S(12) - S(36) - S(4) - S(26) - S(12) - #lines * step

	for i, line in ipairs(lines) do
		draw.SimpleText(line, "RFHudTag", S(16), y + (i - 1) * step,
			grounded and Color(120, 240, 140) or Color(255, 170, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

function GM:HUDPaint()
	if RF.Score and RF.Score.IsOpen and RF.Score.IsOpen() then return end

	Banner()
	RoundStrip()
	RespawnClock()
	SpectateBar()

	local ply = LocalPlayer()
	local mine = ply:GetNWEntity("rf_mine")

	if not IsValid(mine) then
		if RF.GetState() == RF.STATE_ACTIVE then DeadHud() end

		return
	end

	MineHud(ply, mine)
	Debug(mine)
end
