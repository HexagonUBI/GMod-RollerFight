function RF.BotThink(ply, mine, cmd)
	local brain = ply.RFBrain

	if not brain then
		brain = { next = 0, jump = 0, dash = 0, target = NULL, wander = VectorRand() }
		ply.RFBrain = brain
	end

	local now = CurTime()
	local pos = mine:GetPos()

	if now >= brain.next then
		brain.next = now + math.Rand(0.4, 0.9)
		brain.target = RF.BotTarget(ply, mine)
		brain.wander = VectorRand()
		brain.wander.z = 0
	end

	local goal = brain.wander
	local target = brain.target

	if IsValid(target) then
		goal = target:GetPos() - pos
		goal.z = 0
	end

	if goal:LengthSqr() < 1 then goal = Vector(1, 0, 0) end

	goal:Normalize()

	local ang = goal:Angle()
	cmd:SetViewAngles(ang)
	cmd:SetForwardMove(400)
	cmd:SetSideMove(0)

	local buttons = 0
	local dist = IsValid(target) and pos:Distance(target:GetPos()) or 99999

	if dist < RF.Get("BotAttackRange") then
		buttons = buttons + IN_ATTACK
	end

	if dist > 300 and RF.Get("BotSprint") >= 1 then
		buttons = buttons + IN_SPEED
	end

	if mine.Grounded and now >= brain.jump and math.random() < RF.Get("BotJumpChance") then
		brain.jump = now + math.Rand(1.5, 4)
		buttons = buttons + IN_JUMP
	end

	if dist < RF.Get("BotDashRange") and now >= brain.dash then
		brain.dash = now + math.Rand(2, 5)
		buttons = buttons + IN_ATTACK2
	end

	cmd:SetButtons(buttons)
end

function RF.BotTarget(ply, mine)
	local best, bestDist

	for _, other in ipairs(ents.FindByClass("rf_mine")) do
		if other ~= mine and not other:GetBuried() then
			local driver = other:GetDriver()
			local friendly = IsValid(driver) and driver:Team() == ply:Team() and ply:Team() ~= TEAM_FREE

			if not friendly then
				local dist = mine:GetPos():DistToSqr(other:GetPos())

				if not bestDist or dist < bestDist then
					best, bestDist = other, dist
				end
			end
		end
	end

	return best or NULL
end

function RF.BotToggleAttack(ply, mine)
	if mine:GetAttackMode() then return end
	if mine:GetExhausted() then return end
	if CurTime() < mine:GetAttackLockEnd() then return end

	local target = ply.RFBrain and ply.RFBrain.target

	if IsValid(target) and mine:GetPos():Distance(target:GetPos()) < RF.Get("BotAttackRange") then
		mine:ToggleAttack()
	end
end

hook.Add("StartCommand", "RF.Bots", function(ply, cmd)
	if not ply:IsBot() then return end
	if RF.Get("BotsEnabled") < 1 then return end

	local mine = ply.RFMine

	if not IsValid(mine) then
		cmd:ClearButtons()
		cmd:ClearMovement()

		return
	end

	RF.BotThink(ply, mine, cmd)
	RF.BotToggleAttack(ply, mine)
end)

hook.Add("PlayerInitialSpawn", "RF.BotReady", function(ply)
	if not ply:IsBot() then return end

	timer.Simple(2, function()
		if not IsValid(ply) then return end

		ply:SetNWBool("rf_ready", true)
	end)
end)

timer.Create("RF.BotReadyKeep", 2, 0, function()
	if RF.Get("BotsEnabled") < 1 then return end
	if RF.GetState() ~= RF.STATE_WAITING then return end

	for _, ply in ipairs(player.GetAll()) do
		if ply:IsBot() and not RF.IsReady(ply) then
			ply:SetNWBool("rf_ready", true)
		end
	end
end)
