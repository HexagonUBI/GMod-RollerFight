RF.ConflictHooks = {
	"CalcView",
	"CalcViewModelView",
	"ShouldDrawLocalPlayer",
	"SetupMove",
	"Move",
	"FinishMove",
	"PlayerTick",
	"CreateMove",
	"StartCommand",
	"PlayerPostThink",
	"PlayerFootstep",
	"PlayerStepSoundTime",
	"GetFallDamage"
}

RF.CompatAllow = {
	"rf",
	"rollerfight",
	"ulib",
	"ulx"
}

local function Allowed(name)
	local lower = string.lower(name)

	for _, prefix in ipairs(RF.CompatAllow) do
		if string.sub(lower, 1, string.len(prefix)) == prefix then return true end
	end

	return false
end

function RF.ScanConflicts()
	local found = {}
	local all = hook.GetTable()

	for _, event in ipairs(RF.ConflictHooks) do
		local tbl = all[event]

		if tbl then
			for name in pairs(tbl) do
				if isstring(name) and not Allowed(name) then
					table.insert(found, { event = event, name = name })
				end
			end
		end
	end

	return found
end

function RF.FindSiblings(names)
	local extra = {}

	for event, tbl in pairs(hook.GetTable()) do
		for name in pairs(tbl) do
			if isstring(name) and names[name] then
				table.insert(extra, { event = event, name = name })
			end
		end
	end

	return extra
end

function RF.StripConflicts()
	local found = RF.ScanConflicts()
	local names = {}

	for _, entry in ipairs(found) do
		names[entry.name] = true
	end

	for _, entry in ipairs(RF.FindSiblings(names)) do
		table.insert(found, entry)
	end

	local seen = {}
	local removed = {}

	for _, entry in ipairs(found) do
		local id = entry.event .. "/" .. entry.name

		if not seen[id] then
			seen[id] = true
			hook.Remove(entry.event, entry.name)
			table.insert(removed, entry)
		end
	end

	return removed
end

function RF.ReportConflicts(strip)
	local found = strip and RF.StripConflicts() or RF.ScanConflicts()
	local realm = SERVER and "server" or "client"

	if #found == 0 then
		MsgN("[RollerFight] no addon hook conflicts on the " .. realm)
		return found
	end

	MsgN("[RollerFight] " .. (strip and "removed " or "found ") .. #found .. " addon hooks on the " .. realm .. ":")

	for _, entry in ipairs(found) do
		MsgN("    " .. entry.event .. "  ->  " .. entry.name)
	end

	return found
end

local function Sweep()
	RF.ReportConflicts(RF.Get("CompatStrip") >= 1)
end

hook.Add("InitPostEntity", "RF.CompatSweep", function()
	Sweep()
	timer.Simple(2, Sweep)
	timer.Simple(10, Sweep)
end)

if CLIENT then
	concommand.Add("rf_conflicts", function()
		RF.ReportConflicts(false)
	end)
end
