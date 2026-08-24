@echo off
setlocal EnableDelayedExpansion
title RollerFight Installer

set "REPO=HexagonUBI/GMod-RollerFight"
set "BRANCH=main"
set "SOURCE_URL=https://github.com/%REPO%/archive/refs/heads/%BRANCH%.zip"
set "MODULE_NAME=gmcl_drpc_win64.dll"
set "MODULE_DIR=https://github.com/%REPO%/raw/%BRANCH%/binaries"
set "UPSTREAM_REPO=shockpast/gmcl_drpc"
set "UPSTREAM_TAG=v1.0.0"
set "UPSTREAM_SIZE=135680"
set "UPSTREAM_URL=https://github.com/%UPSTREAM_REPO%/releases/download/%UPSTREAM_TAG%/%MODULE_NAME%"

for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "CURL=%SystemRoot%\System32\curl.exe"
set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%CURL%" set "CURL=curl.exe"
if not exist "%TAR%" set "TAR=tar.exe"

set "GMODDIR="
set "ASSUMEYES="
set "ACTION=install"
set "INTERACTIVE=1"
set "SKIPRPC="
set "RPCSTATUS=SKIPPED"

:parseargs
if "%~1"=="" goto parsed
if /i "%~1"=="/y"         set "ASSUMEYES=1" & set "INTERACTIVE=" & shift & goto parseargs
if /i "%~1"=="/norpc"     set "SKIPRPC=1" & shift & goto parseargs
if /i "%~1"=="/uninstall" set "ACTION=uninstall" & shift & goto parseargs
if /i "%~1"=="/pack"      set "ACTION=pack" & shift & goto parseargs
if /i "%~1"=="/gmod"      set "GMODDIR=%~2" & shift & shift & goto parseargs
if /i "%~1"=="/help"      goto usage
if /i "%~1"=="-h"         goto usage
echo Unknown option: %~1
goto usage
:parsed

echo.
echo   ==========================================
echo    R O L L E R F I G H T    I N S T A L L E R
echo   ==========================================
echo.

call :findgmod
if errorlevel 1 goto finish

set "GAMEDIR=!GMODDIR!\garrysmod"
set "ADDON=!GAMEDIR!\addons\rollerfight"
set "BINDIR=!GAMEDIR!\lua\bin"

set "HAVELOCAL="
if exist "!ROOT!\gamemodes\rollerfight\rollerfight.txt" set "HAVELOCAL=1"

set "MODE=INSTALL"
set "LINKED="
if exist "!ADDON!" (
    fsutil reparsepoint query "!ADDON!" >nul 2>&1
    if not errorlevel 1 set "LINKED=1"
    if exist "!ADDON!\gamemodes\rollerfight\rollerfight.txt" set "MODE=UPDATE"
)

echo    GarrysMod   : !GMODDIR!
if defined HAVELOCAL echo    Source      : this folder
if not defined HAVELOCAL echo    Source      : github.com/%REPO%
echo    Action      : !MODE!
if defined LINKED echo    Current     : linked to a local folder
echo.

if /i "%ACTION%"=="pack" goto dopack
if /i "%ACTION%"=="uninstall" goto douninstall

call :checktools
if errorlevel 1 goto finish

echo    This will:
if defined HAVELOCAL echo      - link this folder into GarrysMod addons
if not defined HAVELOCAL echo      - download RollerFight into GarrysMod addons
if not defined SKIPRPC echo      - install the Discord Rich Presence module
echo      - verify everything landed correctly
echo.

call :ask "Go ahead"
if errorlevel 1 (
    echo    Cancelled, nothing was changed.
    goto finish
)

echo.
if defined HAVELOCAL (
    call :dojunction
) else (
    call :dodownload
)

if not exist "!BINDIR!\" mkdir "!BINDIR!" >nul 2>&1

if not defined SKIPRPC (
    call :scanmodules
    if defined FOUND (
        echo    Discord module already present.
        set "RPCSTATUS=OK"
    ) else (
        call :domodule
    )
)

echo.
echo   ------------------------------------------
echo    CHECKING
echo   ------------------------------------------

set "PROBLEM="

call :expect "!ADDON!\gamemodes\rollerfight\rollerfight.txt" "gamemode definition"
call :expect "!ADDON!\gamemodes\rollerfight\gamemode\init.lua" "server code"
call :expect "!ADDON!\gamemodes\rollerfight\gamemode\cl_init.lua" "client code"
call :expect "!ADDON!\gamemodes\rollerfight\entities\entities\rf_mine\init.lua" "rollermine entity"
call :expect "!ADDON!\gamemodes\rollerfight\logo.png" "menu logo"
call :expect "!ADDON!\gamemodes\rollerfight\backgrounds\rollerfight01.jpg" "menu backgrounds"
call :expect "!ADDON!\materials\rollerfight\logo.png" "interface art"

echo.
if defined PROBLEM (
    echo   ==========================================
    echo    SOMETHING IS MISSING, see the list above
    echo    Run this again, or use /gmod to point at
    echo    the right GarrysMod folder.
    echo   ==========================================
    goto finish
)

echo   ==========================================
echo    YOU ARE GOOD TO GO
echo   ==========================================
echo.
echo    1. Launch Garry's Mod
echo    2. Start New Game
echo    3. Gamemode : RollerFight
echo    4. Map      : phys_dmm_house_r
echo.
if not defined SKIPRPC (
    if "!RPCSTATUS!"=="OK" (
        echo    Discord presence ready. Needs the GarrysMod
        echo    x86-64 branch, set it in Steam under Betas.
    ) else (
        echo    Discord presence not installed. Optional,
        echo    everything else works without it.
    )
)
goto finish


:expect
if exist "%~1" (
    echo      [  OK   ]  %~2
    exit /b 0
)
echo      [MISSING]  %~2
set "PROBLEM=1"
exit /b 0


:findgmod
if not "!GMODDIR!"=="" goto verifygmod

set "VDF=C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
if not exist "!VDF!" goto defaultgmod

for /f "usebackq delims=" %%A in (`findstr /c:"\"path\"" "!VDF!" 2^>nul`) do (
    set "LINE=%%A"
    set "LINE=!LINE:*"path"=!"
    set "LINE=!LINE:"=!"
    set "LINE=!LINE:\\=\!"
    for /f "tokens=*" %%B in ("!LINE!") do set "LIB=%%B"
    if exist "!LIB!\steamapps\common\GarrysMod\garrysmod\" set "GMODDIR=!LIB!\steamapps\common\GarrysMod"
)

:defaultgmod
if "!GMODDIR!"=="" set "GMODDIR=C:\Program Files (x86)\Steam\steamapps\common\GarrysMod"

:verifygmod
if not exist "!GMODDIR!\garrysmod\" (
    echo    Could not find Garry's Mod.
    echo    Run this again like:
    echo        install.bat /gmod "D:\Steam\steamapps\common\GarrysMod"
    exit /b 1
)
exit /b 0


:checktools
if not exist "%SystemRoot%\System32\curl.exe" (
    where curl.exe >nul 2>&1
    if errorlevel 1 (
        echo    curl.exe is missing, Windows 10 1803 or newer is needed.
        exit /b 1
    )
)
if not exist "%SystemRoot%\System32\tar.exe" (
    where tar.exe >nul 2>&1
    if errorlevel 1 (
        echo    tar.exe is missing, Windows 10 17063 or newer is needed.
        exit /b 1
    )
)
exit /b 0


:ask
if defined ASSUMEYES exit /b 0
set "ANSWER="
set /p "ANSWER=   %~1? [Y/N] "
if /i "!ANSWER!"=="y" exit /b 0
if /i "!ANSWER!"=="yes" exit /b 0
exit /b 1


:dojunction
if defined LINKED (
    echo    Already linked, your edits are live. Nothing to copy.
    exit /b 0
)
if exist "!ADDON!" (
    echo    Replacing the downloaded copy with a live link.
    rmdir /s /q "!ADDON!" >nul 2>&1
)
if not exist "!GAMEDIR!\addons\" mkdir "!GAMEDIR!\addons" >nul 2>&1
mklink /J "!ADDON!" "!ROOT!" >nul
if errorlevel 1 (
    echo    Could not create the link.
    echo    Right click install.bat and choose Run as administrator.
    exit /b 1
)
echo    Linked into GarrysMod.
exit /b 0


:dodownload
set "WORK=!TEMP!\rollerfight_install"
set "ZIP=!WORK!\source.zip"
if exist "!WORK!" rmdir /s /q "!WORK!" >nul 2>&1
mkdir "!WORK!" >nul 2>&1

echo    Downloading RollerFight...
"!CURL!" -fL --retry 2 --progress-bar -o "!ZIP!" "%SOURCE_URL%"
if errorlevel 1 (
    echo    Download failed, check your connection.
    exit /b 1
)

pushd "!WORK!"
"!TAR!" -xf source.zip
set "TARFAIL=!errorlevel!"
popd

if not "!TARFAIL!"=="0" (
    echo    Could not unpack the download.
    exit /b 1
)

set "SRC=!WORK!\GMod-RollerFight-%BRANCH%"
if not exist "!SRC!\gamemodes\" (
    echo    The download did not contain a gamemodes folder.
    exit /b 1
)

if defined LINKED (
    echo    Removing the old link.
    rmdir "!ADDON!" >nul 2>&1
)

if not exist "!ADDON!\" mkdir "!ADDON!" >nul 2>&1
xcopy "!SRC!\gamemodes" "!ADDON!\gamemodes\" /E /I /Y /Q >nul
if exist "!SRC!\materials" xcopy "!SRC!\materials" "!ADDON!\materials\" /E /I /Y /Q >nul
if exist "!SRC!\addon.json" copy /y "!SRC!\addon.json" "!ADDON!\addon.json" >nul

echo    Files copied into GarrysMod.
rmdir /s /q "!WORK!" >nul 2>&1
exit /b 0


:domodule
set "WORK=!TEMP!\rollerfight_install"
if not exist "!WORK!" mkdir "!WORK!" >nul 2>&1
set "DLL=!WORK!\%MODULE_NAME%"
set "GOTMODULE="
set "ORIGIN="

"!CURL!" -fL --retry 1 -s -o "!DLL!" "%MODULE_DIR%/%MODULE_NAME%"
if not errorlevel 1 (
    set "ORIGIN=your own repo"
    set "GOTMODULE=1"
)

if not defined GOTMODULE (
    echo    Fetching the Discord module from %UPSTREAM_REPO% %UPSTREAM_TAG%
    "!CURL!" -fL --retry 2 --progress-bar -o "!DLL!" "%UPSTREAM_URL%"
    if not errorlevel 1 (
        set "ORIGIN=%UPSTREAM_REPO% %UPSTREAM_TAG%"
        set "GOTMODULE=1"
    )
)

if not defined GOTMODULE (
    echo    Could not download it. Optional, carrying on.
    set "RPCSTATUS=SKIPPED"
    rmdir /s /q "!WORK!" >nul 2>&1
    exit /b 0
)

for %%A in ("!DLL!") do set "DLLSIZE=%%~zA"
call :showhash "!DLL!"

if "!ORIGIN!"=="%UPSTREAM_REPO% %UPSTREAM_TAG%" (
    if not "!DLLSIZE!"=="%UPSTREAM_SIZE%" (
        echo    REFUSED, expected %UPSTREAM_SIZE% bytes but got !DLLSIZE!
        set "RPCSTATUS=REFUSED"
        rmdir /s /q "!WORK!" >nul 2>&1
        exit /b 0
    )
)

if exist "!ROOT!\binaries\%MODULE_NAME%.sha256" (
    set /p PINNED=<"!ROOT!\binaries\%MODULE_NAME%.sha256"
    if /i not "!PINNED!"=="!LASTHASH!" (
        echo    REFUSED, sha256 does not match the pinned value.
        set "RPCSTATUS=REFUSED"
        rmdir /s /q "!WORK!" >nul 2>&1
        exit /b 0
    )
)

copy /y "!DLL!" "!BINDIR!\%MODULE_NAME%" >nul
echo    Discord module installed from !ORIGIN!
set "RPCSTATUS=OK"

rmdir /s /q "!WORK!" >nul 2>&1
exit /b 0


:scanmodules
set "FOUND="
for %%N in (drpc discordrpc gdiscord) do (
    for %%P in (win64 win32 linux64 linux osx64 osx) do (
        if exist "!BINDIR!\gmcl_%%N_%%P.dll" set "FOUND=1"
    )
)
exit /b 0


:showhash
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%~1" SHA256 2^>nul') do (
    if not defined HASHLINE set "HASHLINE=%%H"
)
if defined HASHLINE echo    SHA256: !HASHLINE!
set "LASTHASH=!HASHLINE!"
set "HASHLINE="
exit /b 0


:douninstall
if not exist "!ADDON!" (
    echo    Nothing installed.
    goto finish
)
fsutil reparsepoint query "!ADDON!" >nul 2>&1
if errorlevel 1 (
    call :ask "Delete the installed copy"
    if errorlevel 1 goto finish
    rmdir /s /q "!ADDON!"
    echo    Deleted.
) else (
    rmdir "!ADDON!"
    echo    Link removed, your repo folder is untouched.
)
echo    lua\bin was left alone.
goto finish


:dopack
set "GMAD=!GMODDIR!\bin\gmad.exe"
if not exist "!GMAD!" (
    echo    gmad.exe not found at "!GMAD!"
    goto finish
)
"!GMAD!" create -folder "!ROOT!" -out "!ROOT!\rollerfight.gma"
echo.
echo    Built "!ROOT!\rollerfight.gma"
goto finish


:usage
echo.
echo    install.bat                 install or update everything
echo    install.bat /y              no prompts
echo    install.bat /norpc          skip the Discord module
echo    install.bat /gmod "PATH"    point at a GarrysMod install
echo    install.bat /pack           build rollerfight.gma
echo    install.bat /uninstall      remove the addon
echo.
goto finish


:finish
echo.
if defined INTERACTIVE pause
endlocal
exit /b 0
