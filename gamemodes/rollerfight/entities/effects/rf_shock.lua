local BeamMaterial = Material("sprites/laserbeam")
local FlashMaterial = Material("sprites/light_glow02_add")

EFFECT.Life = 0.26

local function Perpendicular(dir)
	local guide = math.abs(dir.z) > 0.9 and Vector(1, 0, 0) or Vector(0, 0, 1)
	local right = dir:Cross(guide):GetNormalized()

	return right, dir:Cross(right):GetNormalized()
end

function EFFECT:Init(data)
	self.Origin = data:GetOrigin()
	self.StartPos = data:GetStart()
	self.Source = data:GetEntity()
	self.Width = math.max(2, data:GetScale())
	self.BranchReach = math.max(0, data:GetMagnitude())
	self.BranchCount = math.floor(data:GetRadius())
	self.Born = CurTime()
	self.Color = Color(140, 200, 255)

	if IsValid(self.Source) and self.Source.GetTeamColor then
		self.Color = self.Source:GetTeamColor()
	end

	local a, b = self.StartPos, self.Origin
	local pad = self.BranchReach + 96

	local mins = Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z)) - Vector(pad, pad, pad)
	local maxs = Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z)) + Vector(pad, pad, pad)

	self:SetRenderBoundsWS(mins, maxs)
end

function EFFECT:Think()
	return CurTime() < self.Born + self.Life
end

function EFFECT:BuildPath(from, to, jitter, segments, anchored)
	local delta = to - from
	local right, up = Perpendicular(delta:GetNormalized())
	local points = { from }

	for i = 1, segments - 1 do
		local t = i / segments
		local amp = anchored and jitter * math.sin(t * math.pi) or jitter * t

		points[#points + 1] = from + delta * t
			+ right * math.Rand(-amp, amp)
			+ up * math.Rand(-amp, amp)
	end

	points[#points + 1] = to

	return points
end

function EFFECT:DrawRibbon(points, width, color)
	local length = 0

	for i = 1, #points - 1 do
		length = length + (points[i + 1] - points[i]):Length()
	end

	if length <= 0 then return end

	render.StartBeam(#points)

	local travelled = 0

	for i = 1, #points do
		if i > 1 then
			travelled = travelled + (points[i] - points[i - 1]):Length()
		end

		render.AddBeam(points[i], width, travelled / length, color)
	end

	render.EndBeam()
end

function EFFECT:Render()
	local frac = 1 - math.Clamp((CurTime() - self.Born) / self.Life, 0, 1)
	if frac <= 0 then return end

	local col = self.Color
	local alpha = 255 * frac
	local shade = Color(col.r, col.g, col.b, alpha)
	local span = (self.Origin - self.StartPos):Length()

	render.SetMaterial(BeamMaterial)

	local main = self:BuildPath(self.StartPos, self.Origin, math.Clamp(span * 0.07, 2, 14), 12, true)
	self:DrawRibbon(main, self.Width * frac, shade)

	for i = 1, self.BranchCount do
		local index = math.random(2, math.max(2, #main - 1))
		local node = main[index]
		local along = (main[math.min(index + 1, #main)] - main[math.max(index - 1, 1)]):GetNormalized()
		local right, up = Perpendicular(along)
		local dir = (right * math.Rand(-1, 1) + up * math.Rand(-1, 1) + along * math.Rand(0.2, 0.8)):GetNormalized()
		local reach = self.BranchReach * math.Rand(0.5, 1)

		self:DrawRibbon(self:BuildPath(node, node + dir * reach, reach * 0.18, 5, false), self.Width * 0.4 * frac, shade)
	end

	local flash = self.Width * 4 * frac

	render.SetMaterial(FlashMaterial)
	render.DrawSprite(self.Origin, flash, flash, shade)
	render.DrawSprite(self.StartPos, flash * 0.6, flash * 0.6, Color(col.r, col.g, col.b, alpha * 0.8))
end
