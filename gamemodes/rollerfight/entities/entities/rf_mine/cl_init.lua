include("shared.lua")

local Built = {}

local function ColorVector(col, boost, bias)
	return string.format("[%f %f %f]",
		col.r / 255 / bias.x * boost,
		col.g / 255 / bias.y * boost,
		col.b / 255 / bias.z * boost)
end

local function BodyMaterial(col, boost)
	local key = string.format("rf_body_%d_%d_%d_%d", col.r, col.g, col.b, math.floor(boost * 100))

	if not Built[key] then
		CreateMaterial(key, "VertexLitGeneric", {
			["$basetexture"] = RF.BodyTexture,
			["$bumpmap"] = RF.BodyNormal,
			["$selfillum"] = "1",
			["$selfillumtint"] = ColorVector(col, boost, RF.BodyBias),
			["$color2"] = "[1 1 1]"
		})

		Built[key] = true
	end

	return key
end

local function GlowMaterial(col, boost)
	local key = string.format("rf_glow_%d_%d_%d_%d", col.r, col.g, col.b, math.floor(boost * 100))

	if not Built[key] then
		CreateMaterial(key, "UnlitGeneric", {
			["$basetexture"] = RF.GlowTexture,
			["$additive"] = "1",
			["$translucent"] = "1",
			["$model"] = "1",
			["$color2"] = ColorVector(col, boost, RF.GlowBias)
		})

		Built[key] = true
	end

	return key
end

function ENT:Initialize()
	self.GlowSprite = Material("sprites/light_glow02_add")
	self.MoveLoop = CreateSound(self, "npc/roller/mine/rmine_moveslow_loop1.wav")
	self:SetNextClientThink(CurTime())
end

function ENT:Think()
	local speed = self:GetVelocity():Length()

	if speed > 40 and not self:GetBuried() then
		self.MoveLoop:PlayEx(math.Clamp(speed / 600, 0.15, 0.7), math.Clamp(speed / 2, 100, 150))
	else
		self.MoveLoop:Stop()
	end

	self:SetNextClientThink(CurTime() + 0.1)

	return true
end

function ENT:OnRemove()
	if self.MoveLoop then self.MoveLoop:Stop() end
end

function ENT:PaintColor()
	if self:GetDying() then return RF.DeathColor end

	return self:GetTeamColor()
end

function ENT:ApplySkin(col)
	local model = self:GetModel()
	local boost = RF.Get("TeamTint")
	local stamp = model .. col.r .. "_" .. col.g .. "_" .. col.b .. "_" .. boost

	if self.SkinStamp == stamp then return end
	self.SkinStamp = stamp

	self:SetSubMaterial()
	self:SetSubMaterial(0, "!" .. BodyMaterial(col, boost))

	if model == RF.SpikeModel then
		self:SetSubMaterial(1, "!" .. GlowMaterial(col, boost))
	end
end

function ENT:Draw()
	self:ApplySkin(self:PaintColor())
	self:DrawModel()
end

function ENT:DrawTranslucent()
	local col = self:PaintColor()
	local base = RF.Get("GlowSize")
	local size = self:GetAttackMode() and base * 1.7 or base
	local alpha = 190

	if self:GetBuried() then
		size = base * 0.65
		alpha = 70
	elseif self:GetExhausted() then
		alpha = 60
	end

	if self:GetDying() then
		size = base * 1.9
		alpha = 120 + 120 * math.abs(math.sin(CurTime() * 16))
	end

	if size <= 0 then return end

	render.SetMaterial(self.GlowSprite)
	render.DrawSprite(self:GetPos(), size, size, Color(col.r, col.g, col.b, math.Clamp(alpha, 0, 255)))
end
