RF.Cam = RF.Cam or {}

local Cam = RF.Cam

Cam.Anchors = {}
Cam.From = nil
Cam.To = nil
Cam.Started = 0
Cam.Length = 12
Cam.Angle = Angle(0, 0, 0)

local function TraceFloor(pos)
	local tr = util.TraceLine({
		start = pos,
		endpos = pos - Vector(0, 0, 16384),
		mask = MASK_SOLID_BRUSHONLY
	})

	if not tr.Hit or tr.HitSky then return end
	if tr.HitNormal.z < 0.7 then return end

	local head = util.TraceLine({
		start = tr.HitPos + Vector(0, 0, 8),
		endpos = tr.HitPos + Vector(0, 0, 160),
		mask = MASK_SOLID_BRUSHONLY
	})

	if head.Fraction < 0.5 then return end

	return tr.HitPos + Vector(0, 0, RF.Get("LobbyCamHeight"))
end

function Cam.BuildAnchors()
	Cam.Anchors = {}

	for _, class in ipairs(RF.SpawnClasses or { "info_player_start" }) do
		for _, ent in ipairs(ents.FindByClass(class)) do
			local pos = TraceFloor(ent:GetPos() + Vector(0, 0, 32))
			if pos then table.insert(Cam.Anchors, pos) end
		end
	end

	local world = game.GetWorld()
	if not IsValid(world) then return end

	local mins, maxs = world:GetModelBounds()

	for _ = 1, 400 do
		if #Cam.Anchors >= 40 then break end

		local sample = Vector(
			math.Rand(mins.x, maxs.x),
			math.Rand(mins.y, maxs.y),
			math.Rand(mins.z, maxs.z)
		)

		local pos = TraceFloor(sample)
		if pos then table.insert(Cam.Anchors, pos) end
	end
end

function Cam.Focus()
	local best, bestDist

	for _, ent in ipairs(ents.FindByClass("rf_mine")) do
		local dist = ent:GetPos():DistToSqr(Cam.From or vector_origin)

		if not bestDist or dist < bestDist then
			best, bestDist = ent:GetPos(), dist
		end
	end

	return best
end

local function Clear(from, to)
	local tr = util.TraceLine({
		start = from,
		endpos = to,
		mask = MASK_SOLID_BRUSHONLY
	})

	return not tr.Hit
end

function Cam.NextShot(instant)
	if #Cam.Anchors < 2 then Cam.BuildAnchors() end
	if #Cam.Anchors < 2 then return end

	Cam.From = Cam.To or Cam.Anchors[math.random(#Cam.Anchors)]
	if instant then Cam.From = Cam.Anchors[math.random(#Cam.Anchors)] end

	local pick

	for _ = 1, 24 do
		local candidate = Cam.Anchors[math.random(#Cam.Anchors)]

		if candidate ~= Cam.From and Clear(Cam.From, candidate) then
			pick = candidate
			break
		end
	end

	Cam.To = pick or Cam.From

	Cam.Started = CurTime()
	Cam.Length = instant and RF.Get("IntermissionShot") or RF.Get("LobbyShot")
end

function Cam.View(fov)
	if not Cam.From or not Cam.To or CurTime() > Cam.Started + Cam.Length then
		Cam.NextShot(RF.GetState() == RF.STATE_INTERMISSION)
	end

	if not Cam.From or not Cam.To then return end

	local frac = math.Clamp((CurTime() - Cam.Started) / math.max(0.1, Cam.Length), 0, 1)
	local eased = frac * frac * (3 - 2 * frac)
	local pos = LerpVector(eased, Cam.From, Cam.To)
	local look = Cam.Focus() or ((Cam.From + Cam.To) * 0.5 - Vector(0, 0, 60))
	local want = (look - pos):Angle()

	Cam.Angle = LerpAngle(math.Clamp(FrameTime() * 3, 0, 1), Cam.Angle, want)
	Cam.Angle.roll = 0

	return {
		origin = pos,
		angles = Cam.Angle,
		fov = fov,
		drawviewer = false
	}
end

function Cam.Reset()
	Cam.From = nil
	Cam.To = nil
	Cam.Anchors = {}
end

net.Receive("rf_anchors", function()
	local count = net.ReadUInt(8)

	Cam.Anchors = {}

	for _ = 1, count do
		table.insert(Cam.Anchors, net.ReadVector())
	end

	Cam.From = nil
	Cam.To = nil
end)
