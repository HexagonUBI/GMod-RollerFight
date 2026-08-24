local Panel

local Actions = {
	{ id = "respawn", label = "Respawn Mine" },
	{ id = "refill", label = "Refill Health / Energy" },
	{ id = "god", label = "Toggle Godmode" },
	{ id = "teleport", label = "Teleport To Aim" },
	{ id = "dummy", label = "Spawn Target Dummy" },
	{ id = "clear", label = "Remove All Dummies" },
	{ id = "team_combine", label = "Join Combine" },
	{ id = "team_rebel", label = "Join Rebels" },
	{ id = "team_free", label = "Join Free For All" },
	{ id = "reset", label = "Reset Server Settings" },
	{ id = "conflicts", label = "Report Addon Conflicts", local_only = true }
}

local function SendAction(id)
	net.Start("rf_admin_action")
	net.WriteString(id)
	net.SendToServer()
end

local function BuildSlider(parent, v)
	local slider = parent:Add("DNumSlider")
	slider:Dock(TOP)
	slider:DockMargin(6, 2, 12, 2)
	slider:SetText(v.label)
	slider:SetMin(v.min)
	slider:SetMax(v.max)
	slider:SetDecimals(v.default % 1 == 0 and 0 or 2)
	slider:SetValue(RF.Get(v.key))

	if v.respawn then
		slider:SetTooltip("Applies on next respawn")
	end

	if v.realm == "client" then
		slider:SetConVar(v.name)
		return
	end

	local id = "rf_setvar_" .. v.key

	slider.OnValueChanged = function(_, value)
		timer.Create(id, 0.15, 1, function()
			net.Start("rf_admin_setvar")
			net.WriteString(v.key)
			net.WriteFloat(value)
			net.SendToServer()
		end)
	end
end

local function BuildActions(parent)
	for _, action in ipairs(Actions) do
		local button = parent:Add("DButton")
		button:Dock(TOP)
		button:DockMargin(6, 3, 12, 3)
		button:SetTall(30)
		button:SetText(action.label)
		button.DoClick = function()
			if action.local_only then
				RF.ReportConflicts(false)
				chat.AddText(Color(120, 200, 255), "[RollerFight] ", color_white, "Client conflicts printed to console. Server list is in the server console.")

				return
			end

			SendAction(action.id)
		end
	end
end

function RF.OpenMenu()
	if not RF.IsAdmin(LocalPlayer()) then
		chat.AddText(Color(255, 120, 100), "[RollerFight] Test panel is host and superadmin only")
		return
	end

	if IsValid(Panel) then
		Panel:Remove()
		return
	end

	Panel = vgui.Create("DFrame")
	Panel:SetSize(560, 540)
	Panel:Center()
	Panel:SetTitle("RollerFight Test Panel")
	Panel:SetDeleteOnClose(true)
	Panel:MakePopup()

	local sheet = Panel:Add("DPropertySheet")
	sheet:Dock(FILL)
	sheet:DockMargin(4, 4, 4, 4)

	local actions = vgui.Create("DScrollPanel", sheet)
	BuildActions(actions)
	sheet:AddSheet("Actions", actions, "icon16/wrench.png")

	for _, group in ipairs(RF.VarGroups) do
		local page = vgui.Create("DScrollPanel", sheet)

		for _, v in ipairs(RF.VarList) do
			if v.group == group then BuildSlider(page, v) end
		end

		sheet:AddSheet(group, page, "icon16/cog.png")
	end
end

concommand.Add("rf_menu", RF.OpenMenu)

function GM:OnSpawnMenuOpen()
	RF.OpenMenu()
end

net.Receive("rf_admin_notify", function()
	chat.AddText(Color(120, 200, 255), "[RollerFight] ", color_white, net.ReadString())
end)
