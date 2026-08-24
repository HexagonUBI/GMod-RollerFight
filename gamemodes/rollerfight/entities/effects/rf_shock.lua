local BeamMaterial = Material("sprites/laserbeam")
local FlashMaterial = Material("sprites/light_glow02_add")

EFFECT.Life = 0.3

function EFFECT:Init(data)
	self.Origin = data:GetOrigin()
	self.StartPos = data:GetStart()
	self.Source = data:GetEntity()
	self.Width = math.max(2, data:GetScale())
	self.Reach = math.max(0, data:GetMagnitude())
	self.Born = CurTime()
	self.Color = Color(140, 200, 255)

	if IsValid(self.Source) and self.Source.GetTeamColor then
		self.Color = self.Source:GetTeamColor()
	end

	self.Arcs = {}

	for i = 1, math.floor(data:GetRadius()) do
		local dir = VectorRand()
		dir.z = math.abs(dir.z) * 0.6 + 0.15
		dir:Normalize()

		self.Arcs[i] = { dir = dir, scale = math.Rand(0.55, 1) }
	end

	local mins, maxs = OrderVectors(self.StartPos, self.Origin)
	local pad = Vector(1, 1, 1) * (self.Reach + 64)

	self:SetRenderBoundsWS(mins - pad, maxs + pad)
end

function EFFECT:Think()
	return CurTime() < self.Born + self.Life
end

function EFFECT:Bolt(from, to, width, alpha, segments, jitter)
	local col = self.Color
	local dir = to - from
	local prev = from

	for i = 1, segments do
		local point = from + dir * (i / segments)

		if i < segments then
			point = point + VectorRand() * jitter
		end

		render.DrawBeam(prev, point, width, 0, 1, Color(col.r, col.g, col.b, alpha))
		render.DrawBeam(prev, point, width * 0.3, 0, 1, Color(255, 255, 255, alpha))

		prev = point
	end
end

function EFFECT:Render()
	local frac = 1 - math.Clamp((CurTime() - self.Born) / self.Life, 0, 1)
	if frac <= 0 then return end

	local alpha = 255 * frac
	local col = self.Color

	render.SetMaterial(BeamMaterial)

	local link = self.Origin - self.StartPos
	self:Bolt(self.StartPos, self.Origin, self.Width * frac, alpha, 10, math.Clamp(link:Length() * 0.12, 3, 26))

	for _, arc in ipairs(self.Arcs) do
		local reach = self.Reach * arc.scale * frac
		local tip = self.Origin + arc.dir * reach

		self:Bolt(self.Origin, tip, self.Width * 0.55 * frac, alpha * 0.85, 9, reach * 0.16)
	end

	local flash = self.Width * 6 * frac

	render.SetMaterial(FlashMaterial)
	render.DrawSprite(self.Origin, flash, flash, Color(col.r, col.g, col.b, alpha))
end
