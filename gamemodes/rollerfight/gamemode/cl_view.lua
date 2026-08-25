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
	if ply:GetNWBool("rf_spectating", false) then
		smoothPos = nil

		return
	end

	local mine = ply:GetNWEntity("rf_mine")

	if not IsValid(mine) then
		local watch = ply:GetNWEntity("rf_watch")

		if IsValid(watch) then
			mine = watch:GetNWEntity("rf_mine")
		end

		if not IsValid(mine) then
			smoothPos = nil

			return RF.Cam and RF.Cam.View(fov)
		end
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
		angles = Angle(math.Clamp(angles.p, -89, 89), angles.y, 0),
		fov = fov,
		drawviewer = false
	}
end

function GM:ShouldDrawLocalPlayer()
	return false
end

function GM:PreDrawViewModel()
	return true
end

function GM:PostDrawViewModel()
	return true
end

function GM:CalcViewModelView(weapon, vm, oldPos, oldAng, pos, ang)
	if IsValid(vm) then vm:SetNoDraw(true) end

	return pos, ang
end

function RF.BlankModel(ent)
	if not IsValid(ent) then return end

	ent:SetNoDraw(true)
	ent:DrawShadow(false)
end

function RF.HideHands()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	RF.BlankModel(ply:GetHands())
	RF.BlankModel(ply:GetViewModel())

	for _, ent in ipairs(ents.FindByClass("gmod_hands")) do
		RF.BlankModel(ent)
	end
end

hook.Add("NetworkEntityCreated", "RF.HideHands", function(ent)
	if not IsValid(ent) then return end

	local class = ent:GetClass()

	if class == "gmod_hands" or class == "predicted_viewmodel" then RF.BlankModel(ent) end
end)

timer.Create("RF.HideHands", 0.5, 0, RF.HideHands)

function GM:HUDShouldDraw(name)
	return not hiddenElements[name]
end
