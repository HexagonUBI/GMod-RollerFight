util.AddNetworkString("rf_admin_setvar")
util.AddNetworkString("rf_admin_action")
util.AddNetworkString("rf_admin_notify")

function RF.Notify(ply, text)
	net.Start("rf_admin_notify")
	net.WriteString(text)
	net.Send(ply)
end

local function AimPos(ply)
	local mine = ply.RFMine
	local origin = IsValid(mine) and mine:GetPos() or ply:EyePos()

	local tr = util.TraceLine({
		start = origin,
		endpos = origin + ply:EyeAngles():Forward() * 8000,
		filter = { ply, mine },
		mask = MASK_SOLID
	})

	return tr.HitPos + tr.HitNormal * 40
end

RF.AdminActions = {}

RF.AdminActions.respawn = function(ply)
	RF.GiveMine(ply, RF.SelectSpawnPos(ply))
	RF.Notify(ply, "Respawned")
end

RF.AdminActions.refill = function(ply)
	local mine = ply.RFMine
	if not IsValid(mine) then return end

	mine:SetHealth(RF.Get("MineHealth"))
	mine:SetEnergy(RF.Get("MaxEnergy"))
	mine:SetExhausted(false)
	mine:SetAttackLockEnd(0)
	RF.Notify(ply, "Health and energy refilled")
end

RF.AdminActions.god = function(ply)
	ply.RFGod = not ply.RFGod
	RF.Notify(ply, "Godmode " .. (ply.RFGod and "on" or "off"))
end

RF.AdminActions.teleport = function(ply)
	local mine = ply.RFMine
	if not IsValid(mine) then return end

	mine:SetPos(AimPos(ply))

	local phys = mine:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(vector_origin)
		phys:Wake()
	end
end

RF.AdminActions.dummy = function(ply)
	local mine = ents.Create("rf_mine")
	if not IsValid(mine) then return end

	mine:SetPos(AimPos(ply))
	mine:Spawn()
	mine:Activate()
	mine:SetMineTeam(TEAM_FREE)

	RF.Notify(ply, "Spawned target dummy")
end

RF.AdminActions.clear = function(ply)
	local count = 0

	for _, ent in ipairs(ents.FindByClass("rf_mine")) do
		if not IsValid(ent:GetDriver()) then
			ent:Remove()
			count = count + 1
		end
	end

	RF.Notify(ply, "Removed " .. count .. " dummies")
end

RF.AdminActions.endround = function(ply)
	if not RF.InRound() then return end

	RF.EnterPost("Round ended by " .. ply:Nick())
	RF.Notify(ply, "Round ended")
end

RF.AdminActions.endmatch = function(ply)
	if not RF.InRound() then return end

	RF.MatchEnded = true
	RF.EnterPost("Match ended by " .. ply:Nick())
	RF.Notify(ply, "Match ended, map vote is next")
end

RF.AdminActions.lobby = function(ply)
	RF.EnterWaiting()
	RF.Notify(ply, "Back to the lobby")
end

RF.AdminActions.mapvote = function(ply)
	if RF.GetState() == RF.STATE_MAPVOTE then return end

	RF.MatchEnded = true
	RF.EnterMapVote()
	RF.Notify(ply, "Map vote started")
end

RF.AdminActions.endvote = function(ply)
	if RF.GetState() ~= RF.STATE_MAPVOTE then return end

	RF.Notify(ply, "Changing map")
	RF.FinishMapVote()
end

RF.AdminActions.reset = function(ply)
	for _, v in ipairs(RF.VarList) do
		if v.realm ~= "client" then
			local cv = GetConVar(v.name)
			if cv then cv:SetFloat(v.default) end
		end
	end

	RF.Notify(ply, "Server settings reset to defaults")
end

RF.AdminActions.team_combine = function(ply) RF.SetPlayerTeam(ply, TEAM_COMBINE) end
RF.AdminActions.team_rebel = function(ply) RF.SetPlayerTeam(ply, TEAM_REBEL) end
RF.AdminActions.team_free = function(ply) RF.SetPlayerTeam(ply, TEAM_FREE) end

function RF.SetPlayerTeam(ply, id)
	ply:SetTeam(id)
	RF.GiveMine(ply)
	RF.Notify(ply, "Joined " .. team.GetName(id))
end

net.Receive("rf_admin_setvar", function(len, ply)
	if not RF.IsAdmin(ply) then return end

	local key = net.ReadString()
	local value = net.ReadFloat()
	local v = RF.VarByKey[key]

	if not v or v.realm == "client" then return end

	local cv = GetConVar(v.name)
	if not cv then return end

	cv:SetFloat(math.Clamp(value, v.min, v.max))
end)

net.Receive("rf_admin_action", function(len, ply)
	if not RF.IsAdmin(ply) then return end

	local action = RF.AdminActions[net.ReadString()]
	if action then action(ply) end
end)

function GM:EntityTakeDamage(ent, dmg)
	if ent:GetClass() ~= "rf_mine" then return end

	local driver = ent:GetDriver()
	if IsValid(driver) and driver.RFGod then dmg:SetDamage(0) end
end
