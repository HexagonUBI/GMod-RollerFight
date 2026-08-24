RF.Feed = RF.Feed or {}

local Feed = RF.Feed

Feed.Entries = {}

surface.CreateFont("RFFeed", { font = "Verdana", size = 15, weight = 700, antialias = true })

local ROW, ICON = 24, 20

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

hook.Add("HUDPaint", "RF.Killfeed", function()
	if RF.Get("FeedShow") < 1 then return end
	if #Feed.Entries == 0 then return end

	local life = RF.Get("FeedTime")
	local x = ScrW() - 24
	local y = 96
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
			table.insert(parts, { text = "+" .. entry.Assist, col = Color(150, 150, 150) })
		end

		surface.SetFont("RFFeed")

		local pad = 8
		local width = 0

		for _, part in ipairs(parts) do
			width = width + (part.icon and ICON or select(1, surface.GetTextSize(part.text))) + pad
		end

		local rowY = y + (index - 1) * (ROW + 4)

		local involved = entry.Mine or entry.Died or entry.Assisted
		local accent = Color(238, 130, 32)

		if entry.Died then
			accent = Color(220, 70, 60)
		elseif entry.Mine then
			accent = Color(110, 210, 120)
		end

		if involved then
			surface.SetDrawColor(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, math.min(235, alpha))
		else
			surface.SetDrawColor(12, 12, 12, math.min(200, alpha))
		end

		surface.DrawRect(x - width - 10, rowY, width + 14, ROW)

		if involved then
			surface.SetDrawColor(accent.r, accent.g, accent.b, math.min(255, alpha))
			surface.DrawOutlinedRect(x - width - 10, rowY, width + 14, ROW)
		end

		surface.SetDrawColor(accent.r, accent.g, accent.b, math.min(230, alpha))
		surface.DrawRect(x + 4, rowY, involved and 4 or 2, ROW)

		local cursor = x - width - 2

		for _, part in ipairs(parts) do
			if part.icon then
				surface.SetDrawColor(255, 255, 255, alpha)
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(cursor, rowY + (ROW - ICON) * 0.5, ICON, ICON)
				cursor = cursor + ICON + pad
			else
				draw.SimpleText(part.text, "RFFeed", cursor, rowY + ROW * 0.5,
					Color(part.col.r, part.col.g, part.col.b, alpha), 0, TEXT_ALIGN_CENTER)
				cursor = cursor + select(1, surface.GetTextSize(part.text)) + pad
			end
		end
	end
end)

concommand.Add("rf_feed_clear", Feed.Clear)
