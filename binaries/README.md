# binaries

Discord Rich Presence needs a compiled client module in `garrysmod/lua/bin`. Discord removed the
HTTP route in 2018, so there is no pure Lua way to do it, and a binary module cannot ship inside a
workshop addon either. RollerFight does not build one.

`tools/install.bat` resolves it in this order:

1. `binaries/gmcl_drpc_win64.dll` in this repo, if you publish one
2. otherwise `github.com/shockpast/gmcl_drpc` release `v1.0.0`

The upstream fetch is pinned to that exact tag, never to `latest`, so the file cannot change under
you. The installer refuses to install if the download is not exactly 135680 bytes.

## The sha256 pin

`gmcl_drpc_win64.dll.sha256` holds the expected hash. The installer compares every download against
it and refuses on mismatch, verified working. The current value is:

	a7e331ffd140104d98024dd1e443237e0abf8e0345ab978c3e55b413b6571b49

This came from the upstream v1.0.0 asset. It is worth confirming that independently once, since
everything downstream trusts it. Delete the file to disable the check, or replace the hash if you
ever move to a different release or host your own build.

## Hosting your own instead

Drop a file named `gmcl_drpc_win64.dll` in this folder, update the sha256 file to match, and the
installer takes yours and never touches upstream. That is the option to pick if you would rather
not have players pulling a binary from a repo you do not control.

## Branch

The upstream build is 64 bit only. It loads on the GarrysMod x86-64 branch. On the default 32 bit
branch GMod looks for `gmcl_drpc_win32.dll`, which upstream does not publish, so presence stays off
and nothing breaks.

This folder is excluded from the gma. gmad rejects dll files anyway.
