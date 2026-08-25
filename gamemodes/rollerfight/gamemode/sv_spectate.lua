function RF.SpectateList()
	local list = {}

	for _, ply in ipairs(player.GetAll()) do
		local mine = ply.RFMine

		if IsValid(mine) and not ply:GetNWBool("rf_spectating", false) then
			table.insert(list, ply)
		end
	end

	table.sort(list, function(a, b) return a:EntIndex() < b:EntIndex() end)

	return list
end

function RF.WatchTarget(ply, target)
	if not IsValid(target) or not IsValid(target.RFMine) then return end

	ply:SetNWEntity("rf_watch", target)
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(target.RFMine)
end

function RF.CycleWatch(ply, step)
	local list = RF.SpectateList()

	if #list == 0 then
		ply:SetNWEntity("rf_watch", NULL)
		ply:Spectate(OBS_MODE_ROAMING)
		ply:SpectateEntity(NULL)

		return
	end

	local current = ply:GetNWEntity("rf_watch")
	local index = 1

	for i, other in ipairs(list) do
		if other == current then
			index = i
			break
		end
	end

	index = ((index - 1 + step) % #list) + 1

	RF.WatchTarget(ply, list[index])
end

function RF.RefreshWatch(ply)
	local current = ply:GetNWEntity("rf_watch")

	if IsValid(current) and IsValid(current.RFMine) then
		if ply:GetObserverTarget() ~= current.RFMine then RF.WatchTarget(ply, current) end

		return
	end

	RF.CycleWatch(ply, 1)
end

function RF.StopWatching(ply)
	ply:SetNWEntity("rf_watch", NULL)
end

hook.Add("StartCommand", "RF.SpectateInput", function(ply, cmd)
	if ply:IsBot() then return end
	if IsValid(ply.RFMine) then
		if IsValid(ply:GetNWEntity("rf_watch")) then RF.StopWatching(ply) end

		return
	end

	if not RF.InRound() then return end
	if ply:GetNWBool("rf_spectating", false) then return end

	local buttons = cmd:GetButtons()
	local pressed = bit.band(buttons, bit.bnot(ply.RFWatchButtons or 0))

	ply.RFWatchButtons = buttons

	if bit.band(pressed, IN_ATTACK) ~= 0 then RF.CycleWatch(ply, 1) end
	if bit.band(pressed, IN_ATTACK2) ~= 0 then RF.CycleWatch(ply, -1) end
end)

timer.Create("RF.SpectateKeep", 0.5, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply.RFMine) then
			RF.HideBody(ply)

			if RF.InRound() and not ply:IsBot() and not ply:GetNWBool("rf_spectating", false) then
				RF.RefreshWatch(ply)
			end
		end
	end
end)

hook.Add("PlayerDisconnected", "RF.SpectateDrop", function(gone)
	timer.Simple(0.1, function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetNWEntity("rf_watch") == gone then RF.CycleWatch(ply, 1) end
		end
	end)
end)
