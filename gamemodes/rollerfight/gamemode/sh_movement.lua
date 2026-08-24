RF.MoveModes = {}
RF.MoveOrder = {}

function RF.RegisterMove(name, tbl)
	RF.MoveModes[name] = tbl
	table.insert(RF.MoveOrder, name)
end

function RF.GetMoveMode()
	local index = math.Clamp(math.floor(RF.Get("MoveMode")) + 1, 1, #RF.MoveOrder)

	return RF.MoveModes[RF.MoveOrder[index]]
end

RF.RegisterMove("physics", {
	Drive = function(mine, phys, wish)
		local sprinting = mine.Sprinting and not mine:GetExhausted()
		local cap = sprinting and RF.Get("SprintRotCap") or RF.Get("RotCap")
		local av = phys:GetAngleVelocity()

		if math.abs(av.x) + math.abs(av.y) + math.abs(av.z) > cap then return end

		local power = sprinting and RF.Get("SprintPower") or RF.Get("RollPower")
		local center = mine:LocalToWorld(phys:GetMassCenter())

		phys:ApplyForceOffset(wish * power, center + Vector(0, 0, 1))
		phys:ApplyForceOffset(wish * -power, center - Vector(0, 0, 1))
	end,

	Jump = function(mine, phys)
		phys:ApplyForceCenter(Vector(0, 0, RF.Get("JumpForce")))
	end
})

RF.RegisterMove("arcade", {
	Drive = function(mine, phys, wish)
		local sprinting = mine.Sprinting and not mine:GetExhausted()
		local top = sprinting and RF.Get("ArcadeSprintSpeed") or RF.Get("ArcadeSpeed")
		local accel = mine.Grounded and RF.Get("ArcadeAccel") or RF.Get("ArcadeAirAccel")
		local dt = math.max(FrameTime(), engine.TickInterval())

		local vel = phys:GetVelocity()
		local flat = Vector(vel.x, vel.y, 0)
		local diff = wish * top - flat
		local step = math.min(diff:Length(), accel * dt)

		if step > 0.01 then
			phys:ApplyForceCenter(diff:GetNormalized() * step * phys:GetMass())
		end

		local spin = RF.Get("ArcadeSpin")

		if spin > 0 then
			local center = mine:LocalToWorld(phys:GetMassCenter())

			phys:ApplyForceOffset(wish * spin, center + Vector(0, 0, 1))
			phys:ApplyForceOffset(wish * -spin, center - Vector(0, 0, 1))
		end
	end,

	Jump = function(mine, phys)
		local vel = phys:GetVelocity()

		phys:SetVelocity(Vector(vel.x, vel.y, math.max(vel.z, 0) + RF.Get("ArcadeJumpSpeed")))
	end
})

function RF.ApplyTraction(mine, phys, wish)
	if not mine.Grounded then return end

	local traction = RF.Get("Traction")
	if traction <= 0 then return end

	local vel = phys:GetVelocity()
	local flat = Vector(vel.x, vel.y, 0)
	local av = phys:GetAngleVelocity()
	local spin = math.rad(av:Length()) * mine.PhysRadius
	local slip = math.min(spin - flat:Length(), 400)

	if slip < RF.Get("TractionSlip") then return end

	local dt = math.max(FrameTime(), engine.TickInterval())

	phys:ApplyForceCenter(wish * slip * traction * phys:GetMass() * dt)
end

function RF.ApplyBrake(mine, phys)
	if not mine.Grounded then return end

	local brake = RF.Get("GroundBrake")
	if brake <= 0 then return end

	local vel = phys:GetVelocity()
	local flat = Vector(vel.x, vel.y, 0)

	if flat:Length() < 2 then return end

	local dt = math.max(FrameTime(), engine.TickInterval())

	phys:ApplyForceCenter(-flat * math.min(brake * dt, 1) * phys:GetMass())
end
