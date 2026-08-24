# binaries

Client side binary modules that tools/install.bat downloads and drops into
`garrysmod/lua/bin`.

Discord Rich Presence needs one of these. Discord removed the HTTP route in 2018, so there is no
pure Lua way to do it, and a module cannot live inside a workshop addon either. The installer
fetches whatever is published here.

Put the file in with its exact GMod module name:

	binaries/gmcl_drpc_win64.dll
	binaries/gmcl_drpc_win32.dll

The gamemode also accepts `discordrpc` and `gdiscord` builds, see RF.Discord in
gamemodes/rollerfight/gamemode/cl_discord.lua. Add the matching name to MODULES in
tools/install.bat if you publish one of those instead.

The installer prints the SHA256 of anything it downloads so it can be checked against what you
uploaded.

This folder is excluded from the gma. gmad rejects dll files anyway.
