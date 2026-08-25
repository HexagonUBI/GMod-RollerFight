RF.Feed = RF.Feed or {}

local Feed = RF.Feed

Feed.Entries = {}


RF.CauseIcon = {
	contact = "contact",
	dash = "dash",
	blast = "blast",
	water = "water",
	world = "world",
	zone = "zone",
	self = "self"
}

RF.CauseText = {
	contact = "rammed",
	dash = "dashed into",
	blast = "blew up",
	water = "drowned",
	world = "wrecked",
	zone = "left the arena",
	self = "self destructed"
}

local function Push(entry)
	entry.Born = CurTime()
	table.insert(Feed.Entries, 1, entry)

	while #Feed.Entries > RF.Get("FeedMax") do
		table.remove(Feed.Entries)
	end
end

function Feed.Clear()
	Feed.Entries = {}
end

net.Receive("rf_kill", function()
	local entry = {
		Killer = net.ReadString(),
		KillerTeam = net.ReadUInt(8),
		KillerColor = net.ReadUInt(8),
		Victim = net.ReadString(),
		VictimTeam = net.ReadUInt(8),
		VictimColor = net.ReadUInt(8),
		Cause = net.ReadString(),
		Assist = net.ReadString()
	}

	local me = LocalPlayer()

	if IsValid(me) then
		local nick = me:Nick()

		entry.Mine = entry.Killer == nick
		entry.Died = entry.Victim == nick
		entry.Assisted = entry.Assist == nick
	end

	Push(entry)
end)

net.Receive("rf_feedclear", Feed.Clear)

local function FeedColor(entry, victim)
	local col = victim and entry.VictimColor or entry.KillerColor

	if col and col ~= 0 then
		local picked = RF.FFAColors[col]
		if picked then return picked end
	end

	return RF.TeamColors[victim and entry.VictimTeam or entry.KillerTeam] or Color(210, 210, 210)
end

function GM:HUDDrawTargetID()
	return true
end

local function Fade(col, alpha)
	return Color(col.r, col.g, col.b, math.min(col.a or 255, alpha))
end

hook.Add("HUDPaint", "RF.Killfeed", function()
	if RF.Get("FeedShow") < 1 then return end
	if #Feed.Entries == 0 then return end

	local Hud = RF.Hud
	local S = Hud.Scale
	local ROW, ICON, PAD = S(20), S(15), S(6)
	local life = RF.Get("FeedTime")
	local right = ScrW() - S(16)
	local top = S(62)
	local now = CurTime()

	for index = #Feed.Entries, 1, -1 do
		if now - Feed.Entries[index].Born > life then table.remove(Feed.Entries, index) end
	end

	for index, entry in ipairs(Feed.Entries) do
		local age = now - entry.Born
		local alpha = 255

		if age > life - 1 then alpha = 255 * math.max(0, life - age) end

		local icon = RF.Mat("rollerfight/feed/" .. (RF.CauseIcon[entry.Cause] or "world") .. ".png")
		local parts = {}

		if entry.Killer ~= "" then
			table.insert(parts, { text = entry.Killer, col = FeedColor(entry, false) })
		end

		table.insert(parts, { icon = true })
		table.insert(parts, { text = entry.Victim, col = FeedColor(entry, true) })

		if entry.Assist ~= "" then
			table.insert(parts, { text = "+" .. entry.Assist, col = Hud.LABEL })
		end

		surface.SetFont("RFFeed")

		local width = PAD

		for _, part in ipairs(parts) do
			width = width + (part.icon and ICON or select(1, surface.GetTextSize(part.text))) + PAD
		end

		local rowY = top + (index - 1) * (ROW + S(3))
		local rowX = right - width
		local involved = entry.Mine or entry.Died or entry.Assisted

		draw.RoundedBox(S(3), rowX, rowY, width, ROW, Fade(Hud.BG, involved and 190 or 110))

		if involved then
			surface.SetDrawColor(Fade(entry.Died and Hud.DAMAGED or Hud.FG, alpha))
			surface.DrawRect(rowX, rowY, S(2), ROW)
		end

		local cursor = rowX + PAD

		for _, part in ipairs(parts) do
			if part.icon then
				surface.SetDrawColor(Fade(Hud.LABEL, alpha))
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(cursor, rowY + (ROW - ICON) * 0.5, ICON, ICON)
				cursor = cursor + ICON + PAD
			else
				draw.SimpleText(part.text, "RFFeed", cursor, rowY + ROW * 0.5, Fade(part.col, alpha),
					TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				cursor = cursor + select(1, surface.GetTextSize(part.text)) + PAD
			end
		end
	end
end)

concommand.Add("rf_feed_clear", Feed.Clear)
