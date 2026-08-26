RF.UnitsPerKm = 52493

RF.StatList = {
	{ key = "playtime", label = "Time in a round", kind = "time" },
	{ key = "distance", label = "Distance rolled", kind = "dist" },
	{ key = "topspeed", label = "Top speed", kind = "speed" },
	{ key = "kills", label = "Mines destroyed" },
	{ key = "deaths", label = "Times destroyed" },
	{ key = "assists", label = "Assists" },
	{ key = "rounds", label = "Rounds played" },
	{ key = "matches", label = "Matches finished" },
	{ key = "wins", label = "Rounds survived" },
	{ key = "attacktime", label = "Time with spikes out", kind = "time" },
	{ key = "burrows", label = "Times burrowed" },
	{ key = "exhausts", label = "Times run flat" }
}

RF.Achievements = {
	{
		id = "rolling",
		name = "Getting Rolling",
		blurb = "Play a round.",
		icon = "roll",
		stat = "rounds",
		goal = 1
	},
	{
		id = "firstblood",
		name = "First Blood",
		blurb = "Destroy a rollermine.",
		icon = "kill",
		stat = "kills",
		goal = 1
	},
	{
		id = "wrecker",
		name = "Wrecker",
		blurb = "Destroy ten rollermines.",
		icon = "wreck",
		stat = "kills",
		goal = 10
	},
	{
		id = "demolition",
		name = "Demolition Crew",
		blurb = "Destroy a hundred rollermines.",
		icon = "demo",
		stat = "kills",
		goal = 100
	},
	{
		id = "kilometre",
		name = "First Kilometre",
		blurb = "Roll one kilometre.",
		icon = "km",
		stat = "distance",
		goal = RF.UnitsPerKm
	},
	{
		id = "longhaul",
		name = "Long Haul",
		blurb = "Roll ten kilometres.",
		icon = "haul",
		stat = "distance",
		goal = RF.UnitsPerKm * 10
	},
	{
		id = "speeddemon",
		name = "Speed Demon",
		blurb = "Reach nine hundred units per second.",
		icon = "speed",
		stat = "topspeed",
		goal = 900
	},
	{
		id = "businessend",
		name = "Business End",
		blurb = "Spend ten minutes in attack mode.",
		icon = "spikes",
		stat = "attacktime",
		goal = 600
	},
	{
		id = "groundhog",
		name = "Groundhog",
		blurb = "Burrow twenty five times.",
		icon = "dig",
		stat = "burrows",
		goal = 25
	},
	{
		id = "deepsix",
		name = "Deep Six",
		blurb = "Sink to the bottom.",
		icon = "water",
		stat = "waterdeaths",
		goal = 1
	},
	{
		id = "runflat",
		name = "Running On Empty",
		blurb = "Run your energy flat twenty five times.",
		icon = "empty",
		stat = "exhausts",
		goal = 25
	},
	{
		id = "laststanding",
		name = "Last One Rolling",
		blurb = "Survive five rounds.",
		icon = "survive",
		stat = "wins",
		goal = 5
	},
	{
		id = "veteran",
		name = "Veteran",
		blurb = "Play twenty five rounds.",
		icon = "veteran",
		stat = "rounds",
		goal = 25
	},
	{
		id = "teamplayer",
		name = "Team Player",
		blurb = "Pick up twenty five assists.",
		icon = "assist",
		stat = "assists",
		goal = 25
	}
}

RF.AchievementByID = {}
RF.StatKind = {}

for _, entry in ipairs(RF.Achievements) do
	RF.AchievementByID[entry.id] = entry
end

for _, entry in ipairs(RF.StatList) do
	RF.StatKind[entry.key] = entry.kind
end

function RF.StatFormat(kind, value)
	if kind == "time" then
		local total = math.floor(value)
		local hours = math.floor(total / 3600)
		local mins = math.floor(total % 3600 / 60)

		if hours > 0 then return hours .. "h " .. mins .. "m" end

		return mins .. "m " .. (total % 60) .. "s"
	end

	if kind == "dist" then
		return string.format("%.2f km", value / RF.UnitsPerKm)
	end

	if kind == "speed" then
		return math.floor(value) .. " u/s"
	end

	return tostring(math.floor(value))
end
