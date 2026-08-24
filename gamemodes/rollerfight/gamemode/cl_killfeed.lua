RF.Feed = RF.Feed or {}

local Feed = RF.Feed

Feed.Entries = {}

surface.CreateFont("RFFeed", { font = "Verdana", size = 15, weight = 700, antialias = true })

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
	Push({
		Killer = net.ReadString(),
		KillerTeam = net.ReadUInt(8),
		Victim = net.ReadString(),
		VictimTeam = net.ReadUInt(8),
		Cause = net.ReadString(),
		Assist = net.ReadString()
	})
end)

net.Receive("rf_feedclear", Feed.Clear)

local function TeamColor(id)
	return RF.TeamColors[id] or Color(210, 210, 210)
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

		local verb = RF.CauseText[entry.Cause] or "destroyed"
		local killer = entry.Killer
		local parts = {}

		if killer == "" then
			parts = {
				{ verb, Color(210, 190, 120, alpha) },
				{ " " .. entry.Victim, TeamColor(entry.VictimTeam) }
			}
		else
			parts = {
				{ killer, TeamColor(entry.KillerTeam) },
				{ "  " .. verb .. "  ", Color(210, 190, 120, alpha) },
				{ entry.Victim, TeamColor(entry.VictimTeam) }
			}
		end

		if entry.Assist ~= "" then
			table.insert(parts, { "  (+" .. entry.Assist .. ")", Color(150, 150, 150, alpha) })
		end

		local width = 0

		surface.SetFont("RFFeed")

		for _, part in ipairs(parts) do
			width = width + select(1, surface.GetTextSize(part[1]))
		end

		local rowY = y + (index - 1) * 24

		surface.SetDrawColor(12, 12, 12, math.min(190, alpha))
		surface.DrawRect(x - width - 12, rowY - 3, width + 16, 22)

		surface.SetDrawColor(238, 130, 32, math.min(220, alpha))
		surface.DrawRect(x + 2, rowY - 3, 2, 22)

		local cursor = x - width - 4

		for _, part in ipairs(parts) do
			local col = part[2]

			draw.SimpleText(part[1], "RFFeed", cursor, rowY, Color(col.r, col.g, col.b, alpha), 0, 0)
			cursor = cursor + select(1, surface.GetTextSize(part[1]))
		end
	end
end)

concommand.Add("rf_feed_clear", Feed.Clear)
