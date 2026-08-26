util.AddNetworkString("rf_achievement")

net.Receive("rf_achievement", function(len, ply)
	if not IsValid(ply) then return end
	if CurTime() < (ply.RFNextBrag or 0) then return end

	local entry = RF.AchievementByID[net.ReadString()]
	if not entry then return end

	ply.RFBragged = ply.RFBragged or {}

	if ply.RFBragged[entry.id] then return end

	ply.RFBragged[entry.id] = true
	ply.RFNextBrag = CurTime() + 3

	MsgN("[RollerFight] " .. ply:Nick() .. " unlocked " .. entry.name)

	net.Start("rf_achievement")
	net.WriteEntity(ply)
	net.WriteString(entry.id)
	net.Broadcast()
end)
