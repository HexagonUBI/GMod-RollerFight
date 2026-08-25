AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel(RF.MineModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)

	self:RefreshRadius()
	self.RFInput = { Forward = 0, Side = 0, Yaw = 0, Pitch = 0 }
	self.LastButtons = 0
	self.Sprinting = false
	self.Grounded = false
	self.HitTimes = {}
	self.DamageLog = {}
	self.LastThink = CurTime()
	self.Drain = 0
	self.NextHeal = 0

	self:SetEnergy(RF.Get("MaxEnergy"))
	self:SetAttackMode(false)
	self:SetExhausted(false)
	self:SetBuried(false)
	self:SetAttackLockEnd(0)
	self:SetHealth(RF.Get("MineHealth"))
	self:SetMaxHealth(RF.Get("MineHealth"))

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(RF.Get("MineMass"))
		phys:EnableDrag(false)
		phys:Wake()
	end

	self:NextThink(CurTime())
end

function ENT:RefreshRadius()
	local maxs = self:OBBMaxs()

	self.Radius = math.max(maxs.x, maxs.y, maxs.z)
	self.PhysRadius = RF.MineRadius
end

function ENT:SetFrozen(state)
	self:SetLocked(state)

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	if state then
		phys:EnableMotion(false)
	else
		phys:EnableMotion(true)
		phys:Wake()
	end
end

function ENT:LockInput(state)
	self:SetLocked(state)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) and not state then phys:Wake() end
end

function ENT:ReadCommand(cmd)
	if self.Detonating or self:GetLocked() then return end

	local buttons = cmd:GetButtons()
	local pressed = bit.band(buttons, bit.bnot(self.LastButtons))
	local eye = cmd:GetViewAngles()

	self.RFInput.Forward = cmd:GetForwardMove()
	self.RFInput.Side = cmd:GetSideMove()
	self.RFInput.Yaw = eye.y
	self.RFInput.Pitch = math.Clamp(eye.p, -35, 35)
	self.Sprinting = bit.band(buttons, IN_SPEED) ~= 0 and not self:GetExhausted()

	if bit.band(pressed, IN_JUMP) ~= 0 then self:TryJump() end
	if bit.band(pressed, IN_ATTACK2) ~= 0 then self:TryDash() end
	if bit.band(pressed, IN_ATTACK) ~= 0 then self:ToggleAttack() end
	if bit.band(pressed, IN_DUCK) ~= 0 then self:TryBurrow() end

	if cmd:GetImpulse() == 100 then self:ToggleLamp() end

	self.LastButtons = buttons
end

function ENT:ToggleLamp()
	if CurTime() < (self.NextLamp or 0) then return end

	self.NextLamp = CurTime() + 0.25
	self:SetLamp(not self:GetLamp())
	self:EmitSound("items/flashlight1.wav", 60, 100)
end

function ENT:GetWishDirection()
	if self:GetBuried() then return vector_origin end

	local ang = Angle(0, self.RFInput.Yaw, 0)
	local wish = ang:Forward() * math.Clamp(self.RFInput.Forward / 400, -1, 1)
		+ ang:Right() * math.Clamp(self.RFInput.Side / 400, -1, 1)

	wish.z = 0
	if wish:Length() < 0.05 then return vector_origin end

	wish:Normalize()

	return wish
end

function ENT:SurfaceTrace()
	local pos = self:GetPos()

	return util.TraceLine({
		start = pos,
		endpos = pos - Vector(0, 0, self.PhysRadius + 8),
		filter = { self, self:GetDriver() },
		mask = MASK_SOLID
	})
end

function ENT:RayGap()
	local pos = self:GetPos()
	local filter = { self, self:GetDriver() }
	local best = 9999

	for _, sample in ipairs(RF.GroundSamples) do
		local start = pos + sample.offset

		local tr = util.TraceLine({
			start = start,
			endpos = start - Vector(0, 0, sample.depth + 96),
			filter = filter,
			mask = MASK_SOLID
		})

		if tr.Hit and tr.HitNormal.z > 0.4 then
			local gap = (start.z - tr.HitPos.z) - sample.depth

			if gap < best then best = gap end
		end
	end

	return best
end

function ENT:UpdateGround()
	local now = CurTime()
	local contactAge = now - (self.LastFloorHit or -999)
	local byContact = contactAge <= RF.Get("ContactMemory")

	self.GroundGap = self:RayGap()

	local byRay = self.GroundGap <= RF.Get("GroundSlack")

	self.Grounded = byContact or byRay
	self.ContactAge = contactAge

	self:SetNWBool("rf_grounded", self.Grounded)
	self:SetNWFloat("rf_gap", self.GroundGap)
	self:SetNWFloat("rf_contact", contactAge)
	self:SetNWBool("rf_bycontact", byContact)
end

function ENT:SetAttack(on)
	if self:GetAttackMode() == on then return end

	self:SetAttackMode(on)
	self:SetModel(on and RF.SpikeModel or RF.MineModel)
	self:RefreshRadius()
	self:EmitSound(on and "npc/roller/mine/rmine_blades_out1.wav" or "npc/roller/mine/rmine_blades_in1.wav", 75, 100)
end

function ENT:ToggleAttack()
	if self:GetBuried() then return end

	if self:GetAttackMode() then
		self:SetAttack(false)
		return
	end

	if self:GetExhausted() then return end
	if CurTime() < self:GetAttackLockEnd() then return end

	self:SetAttack(true)
end

function ENT:TryJump()
	if CurTime() < (self.NextJump or 0) then return end

	if self:GetBuried() then
		self:Unburrow()
		return
	end

	if not self.Grounded then return end

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	if phys:GetVelocity().z > RF.Get("JumpRiseGate") then return end

	local mode = RF.GetMoveMode()

	self.NextJump = CurTime() + RF.Get("JumpCooldown")

	if mode then mode.Jump(self, phys) end

	self:EmitSound("npc/roller/mine/rmine_tossed1.wav", 70, 100)
end

function ENT:TryDash()
	if self:GetBuried() then return end
	if CurTime() < (self.NextDash or 0) then return end
	if self:GetEnergy() < RF.Get("DashCost") then return end

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local now = CurTime()

	self.NextDash = now + RF.Get("DashCooldown")
	self.DashHitUntil = now + RF.Get("DashWindow")

	self:SetEnergy(self:GetEnergy() - RF.Get("DashCost"))

	if self:GetAttackMode() then
		self.DashAttackUntil = now + RF.Get("DashAttackHold")
	end

	phys:ApplyForceCenter(Angle(self.RFInput.Pitch, self.RFInput.Yaw, 0):Forward() * RF.Get("DashForce"))
	self:EmitSound("npc/roller/mine/rmine_blip1.wav", 75, 90)
end

function ENT:TryBurrow()
	if self:GetBuried() then return end
	if CurTime() < (self.NextBurrow or 0) then return end
	if self:GetMoveType() ~= MOVETYPE_VPHYSICS then return end

	local tr = self:SurfaceTrace()
	if not tr.Hit or not RF.Diggable[tr.MatType] then return end

	local pos = self:GetPos()

	self.NextBurrow = CurTime() + RF.Get("BurrowCooldown")
	self.BurrowSurface = tr.HitPos.z

	self:SetAttack(false)
	self:SetBuried(true)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetPos(Vector(pos.x, pos.y, tr.HitPos.z + RF.Get("BurrowExposed") - self.Radius))
	self:EmitSound("npc/roller/mine/combine_mine_deactivate1.wav", 70, 100)
end

function ENT:Unburrow()
	if not self:GetBuried() then return end

	self.NextJump = CurTime() + RF.Get("JumpCooldown")

	local pos = self:GetPos()
	local surface = self.BurrowSurface or pos.z

	self:SetBuried(false)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetPos(Vector(pos.x, pos.y, surface + self.Radius + 4))

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:ApplyForceCenter(Vector(0, 0, RF.Get("JumpForce")))
	end

	self:EmitSound("npc/roller/mine/rmine_predetonate.wav", 75, 100)
end

function ENT:DriveRoll()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local mode = RF.GetMoveMode()
	if not mode then return end

	local wish = self:GetWishDirection()
	local moving = not wish:IsZero()

	if moving then
		if phys:IsAsleep() then phys:Wake() end

		mode.Drive(self, phys, wish)
		RF.ApplyTraction(self, phys, wish)
	else
		RF.ApplyBrake(self, phys)
	end
end

function ENT:EndDashAttack()
	if not self.DashAttackUntil then return end

	self.DashAttackUntil = nil

	self:SetAttack(false)
	self:SetAttackLockEnd(CurTime() + RF.Get("DashAttackLock"))
end

function ENT:UpdateDashAttack()
	if not self.DashAttackUntil then return end
	if CurTime() < self.DashAttackUntil then return end

	self:EndDashAttack()
end

function ENT:UpdateEnergy(dt)
	local drain = 0

	if self.Sprinting and self.Grounded and not self:GetWishDirection():IsZero() then drain = drain + RF.Get("SprintDrain") end
	if self:GetAttackMode() then drain = drain + RF.Get("AttackDrain") end

	self.Drain = drain

	if drain > 0 then
		self:SetEnergy(math.max(0, self:GetEnergy() - drain * dt))
		self.NextRegen = CurTime() + RF.Get("EnergyRegenDelay")
	elseif CurTime() >= (self.NextRegen or 0) then
		self:SetEnergy(math.min(RF.Get("MaxEnergy"), self:GetEnergy() + RF.Get("EnergyRegen") * dt))
	end

	if self:GetEnergy() <= 0 and not self:GetExhausted() then
		self:SetExhausted(true)
		self:SetAttack(false)
		self.Sprinting = false
		self:EmitSound("npc/roller/mine/rmine_blip3.wav", 70, 80)
	elseif self:GetExhausted() and self:GetEnergy() >= RF.Get("ExhaustRecoverAt") then
		self:SetExhausted(false)
	end
end

function ENT:UpdateHealth(dt)
	local rate = RF.Get("HealthRegen")
	if rate <= 0 then return end

	if self.Detonating or self:GetDying() then return end
	if self:GetBuried() or self:GetAttackMode() then return end
	if (self.Drain or 0) > 0 then return end
	if CurTime() < (self.NextHeal or 0) then return end

	local max = self:GetMaxHealth()
	if self:Health() >= max then return end

	self:SetHealth(math.min(max, self:Health() + rate * dt))
end

function ENT:Think()
	local now = CurTime()
	local dt = math.min(now - self.LastThink, 0.2)
	self.LastThink = now

	self:NextThink(now)

	local driver = self:GetDriver()
	if not IsValid(driver) then return true end

	if RF.EnforceDetached then RF.EnforceDetached(driver) end

	if not self:GetBuried() and not self.Detonating and not self:GetLocked() then
		self:UpdateGround()
		self:DriveRoll()
		self:UpdateDashAttack()
		self:CheckWater()
	end

	self:UpdateEnergy(dt)
	self:UpdateHealth(dt)

	return true
end

function ENT:CheckWater()
	local level = RF.Get("WaterKillLevel")
	if level <= 0 or self.Detonating then return end
	if self:WaterLevel() < level then return end

	self:LogDamage(nil, "water")
	self:SetHealth(0)
	self:BeginDetonate(nil)
end

function ENT:LogDamage(attacker, cause)
	self.LastCause = cause

	if IsValid(attacker) and attacker:IsPlayer() then
		table.insert(self.DamageLog, 1, { who = attacker, cause = cause, when = CurTime() })

		while #self.DamageLog > 6 do
			table.remove(self.DamageLog)
		end
	end
end

function ENT:FindAssist(killer)
	local window = RF.Get("AssistWindow")
	if window <= 0 then return end

	for _, entry in ipairs(self.DamageLog or {}) do
		if CurTime() - entry.when > window then break end

		if IsValid(entry.who) and entry.who ~= killer then return entry.who end
	end
end

function ENT:CanHit(other)
	if not self:GetAttackMode() then return false end
	if self:GetBuried() then return false end
	if not IsValid(other) then return false end

	if other:GetClass() == "rf_mine" then
		if other:GetBuried() then return false end

		if RF.Get("FriendlyFire") < 1 then
			local ours, theirs = self:GetMineTeam(), other:GetMineTeam()
			if ours == theirs and ours ~= TEAM_FREE then return false end
		end

		return true
	end

	if RF.Get("HitNPCs") >= 1 and (other:IsNPC() or other:IsNextBot()) then
		return other:Health() > 0
	end

	return false
end

function ENT:HitMine(other, pos)
	local now = CurTime()
	if (self.HitTimes[other] or 0) > now then return end

	self.HitTimes[other] = now + RF.Get("HitCooldown")

	local dashing = now < (self.DashHitUntil or 0)
	local dir = other:GetPos() - self:GetPos()
	dir.z = 0
	dir:Normalize()

	local speed = self:GetVelocity():Length()
	local ramp = 1 + math.Clamp(speed / math.max(1, RF.Get("SpeedDamageRef")), 0, 1) * RF.Get("SpeedDamageBonus")
	local base = dashing and RF.Get("DashDamage") or RF.Get("HitDamage")

	local dmg = DamageInfo()
	dmg:SetDamage(base * ramp)
	dmg:SetDamageType(DMG_SHOCK)
	dmg:SetInflictor(self)
	dmg:SetAttacker(IsValid(self:GetDriver()) and self:GetDriver() or self)
	dmg:SetDamagePosition(pos)
	dmg:SetDamageForce(dir * RF.Get("HitForce"))

	if other.LogDamage then
		other:LogDamage(self:GetDriver(), dashing and "dash" or "contact")
	end

	other:TakeDamageInfo(dmg)
	self:EmitSound("npc/roller/mine/rmine_explode_shock1.wav", 75, 100)

	self:EndDashAttack()

	local shock = EffectData()
	shock:SetEntity(self)
	shock:SetStart(self:GetPos())
	shock:SetOrigin(other:GetPos())
	shock:SetScale(RF.Get("ShockSize"))
	shock:SetMagnitude(RF.Get("ShockBranchLength"))
	shock:SetRadius(RF.Get("ShockBranchCount"))
	util.Effect("rf_shock", shock)

	local spark = EffectData()
	spark:SetOrigin(pos)
	spark:SetNormal(dir)
	spark:SetMagnitude(3)
	spark:SetScale(2)
	util.Effect("ElectricSpark", spark)
end

RF.DoorClasses = {
	prop_door_rotating = "Open",
	func_door = "Open",
	func_door_rotating = "Open",
	func_movelinear = "Open",
	func_button = "Press",
	momentary_rot_button = "Press"
}

function ENT:TouchDoor(other, speed)
	if RF.Get("DoorPush") < 1 then return end
	if speed < RF.Get("DoorSpeed") then return end
	if not IsValid(other) then return end

	local input = RF.DoorClasses[other:GetClass()]
	if not input then return end

	self.DoorTimes = self.DoorTimes or {}

	local now = CurTime()
	if (self.DoorTimes[other] or 0) > now then return end

	self.DoorTimes[other] = now + 1.5

	local driver = self:GetDriver()

	other:Fire(input, "", 0, IsValid(driver) and driver or self, self)
end

function ENT:PhysicsCollide(data, phys)
	local down = data.HitPos - self:GetPos()

	if down:Length() > 1 then
		down:Normalize()

		if -down.z >= RF.Get("ContactDot") then
			self.LastFloorHit = CurTime()
		end
	end

	self.LastImpact = CurTime()

	local other = data.HitEntity

	if IsValid(other) then self:TouchDoor(other, data.Speed or 0) end
	if not self:CanHit(other) then return end

	local pos = data.HitPos

	timer.Simple(0, function()
		if not IsValid(self) or not IsValid(other) then return end
		if not self:CanHit(other) then return end

		self:HitMine(other, pos)
	end)
end

function ENT:OnTakeDamage(dmg)
	if self:GetBuried() or self.Detonating then return end

	self.NextHeal = CurTime() + RF.Get("HealthRegenDelay")

	local inflictor = dmg:GetInflictor()

	if dmg:IsDamageType(DMG_BLAST) and not (IsValid(inflictor) and inflictor:GetClass() == "rf_mine") then
		self:LogDamage(dmg:GetAttacker(), "blast")
		self:SetHealth(0)
		self:BeginDetonate(dmg:GetAttacker())

		return
	end

	if not self.LastCause then self:LogDamage(dmg:GetAttacker(), "world") end

	self:SetHealth(self:Health() - dmg:GetDamage())

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:ApplyForceCenter(dmg:GetDamageForce()) end

	if self:Health() <= 0 then
		self:BeginDetonate(dmg:GetAttacker())
	end
end

function ENT:ShowSelfDestruct()
	if self.Detonating or self:GetDying() then return end

	self:SetDying(true)
	self:SetAttackMode(false)
	self:SetModel(RF.SpikeModel)
	self:RefreshRadius()
	self:EmitSound("npc/roller/mine/rmine_predetonate.wav", 80, 100)
end

function ENT:BeginDetonate(attacker)
	if self.Detonating then return end
	self.Detonating = true

	self.DashAttackUntil = nil
	self:SetAttack(false)
	self:SetDying(true)

	if self:GetBuried() then
		self:SetBuried(false)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetPos(Vector(self:GetPos().x, self:GetPos().y, (self.BurrowSurface or self:GetPos().z) + self.Radius + 4))
	end

	self:SetModel(RF.SpikeModel)
	self:RefreshRadius()
	self:EmitSound("npc/roller/mine/rmine_blades_out1.wav", 80, 90)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:ApplyForceCenter(Vector(0, 0, RF.Get("DeathJumpForce")))
	end

	self:EmitSound("npc/roller/mine/rmine_predetonate.wav", 85, 100)

	timer.Simple(RF.Get("DeathDelay"), function()
		if IsValid(self) then self:Explode(attacker) end
	end)
end

function ENT:Explode(attacker)
	if self.Exploded then return end
	self.Exploded = true

	local effect = EffectData()
	effect:SetOrigin(self:GetPos())
	util.Effect("Explosion", effect)

	self:EmitSound("npc/roller/mine/rmine_explode_shock1.wav", 90, 100)

	RF.OnMineDestroyed(self, attacker, self.LastCause or "world", self:FindAssist(attacker))
	self:Remove()
end
