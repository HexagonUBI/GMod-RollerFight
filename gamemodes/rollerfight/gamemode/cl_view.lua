local smoothPos

local hiddenElements = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
	CHudCrosshair = true,
	CHudDamageIndicator = true,
	CHudSuitPower = true
}

function GM:CalcView(ply, pos, angles, fov)
	local mine = ply:GetNWEntity("rf_mine")

	if not IsValid(mine) then
		smoothPos = nil
		return
	end

	local focus = mine:GetPos() + Vector(0, 0, RF.Get("CameraHeight"))

	if smoothPos then
		local flat = math.Clamp(FrameTime() * RF.Get("CameraSmooth"), 0, 1)
		local vertical = math.Clamp(FrameTime() * RF.Get("CameraSmoothVertical"), 0, 1)

		smoothPos = Vector(
			Lerp(flat, smoothPos.x, focus.x),
			Lerp(flat, smoothPos.y, focus.y),
			Lerp(vertical, smoothPos.z, focus.z)
		)
	else
		smoothPos = focus
	end

	local hull = 8
	local tr = util.TraceHull({
		start = smoothPos,
		endpos = smoothPos - angles:Forward() * RF.Get("CameraDistance"),
		mins = Vector(-hull, -hull, -hull),
		maxs = Vector(hull, hull, hull),
		filter = { ply, mine },
		mask = MASK_SOLID
	})

	return {
		origin = tr.HitPos,
		angles = angles,
		fov = fov,
		drawviewer = false
	}
end

function GM:ShouldDrawLocalPlayer()
	return false
end

function GM:HUDShouldDraw(name)
	return not hiddenElements[name]
end
