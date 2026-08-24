@echo off
setlocal EnableDelayedExpansion
title RollerFight Installer

set "REPO=HexagonUBI/GMod-RollerFight"
set "BRANCH=main"
set "SOURCE_URL=https://github.com/%REPO%/archive/refs/heads/%BRANCH%.zip"
set "MODULE_DIR=https://github.com/%REPO%/raw/%BRANCH%/binaries"
set "MODULES=gmcl_drpc_win64.dll gmcl_drpc_win32.dll"

for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "GMODDIR="
set "ASSUMEYES="
set "ACTION=install"
set "INTERACTIVE=1"

:parseargs
if "%~1"=="" goto parsed
if /i "%~1"=="/y"         set "ASSUMEYES=1" & set "INTERACTIVE=" & shift & goto parseargs
if /i "%~1"=="/uninstall" set "ACTION=uninstall" & shift & goto parseargs
if /i "%~1"=="/pack"      set "ACTION=pack" & shift & goto parseargs
if /i "%~1"=="/gmod"      set "GMODDIR=%~2" & shift & shift & goto parseargs
if /i "%~1"=="/help"      goto usage
if /i "%~1"=="-h"         goto usage
echo Unknown option: %~1
goto usage
:parsed

echo.
echo  ==============================
echo   RollerFight Installer
echo  ==============================
echo.

call :findgmod
if errorlevel 1 goto finish

set "GAMEDIR=!GMODDIR!\garrysmod"
set "ADDON=!GAMEDIR!\addons\rollerfight"
set "BINDIR=!GAMEDIR!\lua\bin"
set "HAVELOCAL="
if exist "!ROOT!\gamemodes\rollerfight\rollerfight.txt" set "HAVELOCAL=1"

echo  GarrysMod : !GMODDIR!
if defined HAVELOCAL echo  Source    : this folder ^(!ROOT!^)
if not defined HAVELOCAL echo  Source    : github.com/%REPO%
echo.

if /i "%ACTION%"=="pack" goto dopack
if /i "%ACTION%"=="uninstall" goto douninstall

call :checktools
if errorlevel 1 goto finish

if defined HAVELOCAL (
    call :ask "Link this folder into GarrysMod so edits are live"
    if not errorlevel 1 call :dojunction
    if errorlevel 1 (
        call :ask "Download a fresh copy from GitHub instead"
        if not errorlevel 1 call :dodownload
    )
) else (
    call :ask "Download RollerFight from GitHub and install it"
    if not errorlevel 1 call :dodownload
)

if not exist "!BINDIR!\" mkdir "!BINDIR!" >nul 2>&1

call :scanmodules
if defined FOUND (
    echo.
    echo  Discord RPC module already installed:%FOUND%
) else (
    echo.
    call :ask "Install the Discord Rich Presence module"
    if not errorlevel 1 call :domodule
)

echo.
echo  ------------------------------
echo   Done.
echo   In game:  gamemode rollerfight
echo             map phys_dmm_house_r
echo  ------------------------------
goto finish


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
    echo  ERROR: no GarrysMod found at "!GMODDIR!"
    echo  Run again like:  install.bat /gmod "D:\Steam\steamapps\common\GarrysMod"
    exit /b 1
)
exit /b 0


:checktools
where curl.exe >nul 2>&1
if errorlevel 1 (
    echo  ERROR: curl.exe not found. Windows 10 1803 or newer is required.
    exit /b 1
)
where tar.exe >nul 2>&1
if errorlevel 1 (
    echo  ERROR: tar.exe not found. Windows 10 17063 or newer is required.
    exit /b 1
)
exit /b 0


:ask
if defined ASSUMEYES exit /b 0
set "ANSWER="
set /p "ANSWER=  %~1? [Y/N] "
if /i "!ANSWER!"=="y" exit /b 0
if /i "!ANSWER!"=="yes" exit /b 0
exit /b 1


:dojunction
if exist "!ADDON!" (
    fsutil reparsepoint query "!ADDON!" >nul 2>&1
    if errorlevel 1 (
        echo  WARNING: "!ADDON!" is a real folder, not a link. Leaving it alone.
        exit /b 0
    )
    echo  Link already present.
    exit /b 0
)
if not exist "!GAMEDIR!\addons\" mkdir "!GAMEDIR!\addons" >nul 2>&1
mklink /J "!ADDON!" "!ROOT!" >nul
if errorlevel 1 (
    echo  ERROR: could not create the link.
    echo  Right click install.bat, pick "Run as administrator", try again.
    exit /b 1
)
echo  Linked into GarrysMod.
exit /b 0


:dodownload
set "WORK=!TEMP!\rollerfight_install"
set "ZIP=!WORK!\source.zip"
if exist "!WORK!" rmdir /s /q "!WORK!" >nul 2>&1
mkdir "!WORK!" >nul 2>&1

echo  Downloading %SOURCE_URL%
curl.exe -fL --retry 2 --progress-bar -o "!ZIP!" "%SOURCE_URL%"
if errorlevel 1 (
    echo  ERROR: download failed.
    exit /b 1
)

call :showhash "!ZIP!"

tar.exe -xf "!ZIP!" -C "!WORK!"
if errorlevel 1 (
    echo  ERROR: could not extract the archive.
    exit /b 1
)

set "SRC=!WORK!\GMod-RollerFight-%BRANCH%"
if not exist "!SRC!\gamemodes\" (
    echo  ERROR: the archive did not contain a gamemodes folder.
    exit /b 1
)

if exist "!ADDON!" (
    fsutil reparsepoint query "!ADDON!" >nul 2>&1
    if not errorlevel 1 (
        echo  Removing the old link first.
        rmdir "!ADDON!" >nul 2>&1
    )
)

if not exist "!ADDON!\" mkdir "!ADDON!" >nul 2>&1
xcopy "!SRC!\gamemodes" "!ADDON!\gamemodes\" /E /I /Y /Q >nul
if exist "!SRC!\addon.json" copy /y "!SRC!\addon.json" "!ADDON!\addon.json" >nul
echo  Installed into !ADDON!

rmdir /s /q "!WORK!" >nul 2>&1
exit /b 0


:domodule
set "WORK=!TEMP!\rollerfight_install"
if not exist "!WORK!" mkdir "!WORK!" >nul 2>&1

set "GOTMODULE="
for %%M in (%MODULES%) do (
    if not defined GOTMODULE (
        echo  Trying %MODULE_DIR%/%%M
        curl.exe -fL --retry 1 -s -o "!WORK!\%%M" "%MODULE_DIR%/%%M"
        if not errorlevel 1 (
            call :showhash "!WORK!\%%M"
            copy /y "!WORK!\%%M" "!BINDIR!\%%M" >nul
            echo  Installed %%M into lua\bin
            set "GOTMODULE=1"
        )
    )
)

if not defined GOTMODULE (
    echo.
    echo  No module published at %MODULE_DIR%
    echo.
    echo  Discord presence needs a client binary module, there is no pure Lua route.
    echo  Put one of these in a "binaries" folder in the repo and this will pick it up:
    for %%M in (%MODULES%) do echo      binaries/%%M
    echo.
    echo  Or install one you already have:
    echo      install.bat /gmod "!GMODDIR!"   then copy the dll into
    echo      !BINDIR!
)

rmdir /s /q "!WORK!" >nul 2>&1
exit /b 0


:scanmodules
set "FOUND="
for %%N in (drpc discordrpc gdiscord) do (
    for %%P in (win64 win32 linux64 linux osx64 osx) do (
        if exist "!BINDIR!\gmcl_%%N_%%P.dll" set "FOUND=!FOUND! gmcl_%%N_%%P.dll"
    )
)
exit /b 0


:showhash
for /f "skip=1 tokens=*" %%H in ('certutil -hashfile "%~1" SHA256 2^>nul') do (
    if not defined HASHLINE set "HASHLINE=%%H"
)
if defined HASHLINE echo  SHA256: !HASHLINE!
set "HASHLINE="
exit /b 0


:douninstall
if not exist "!ADDON!" (
    echo  Nothing installed at !ADDON!
    goto finish
)
fsutil reparsepoint query "!ADDON!" >nul 2>&1
if errorlevel 1 (
    call :ask "Delete the installed copy at !ADDON!"
    if errorlevel 1 goto finish
    rmdir /s /q "!ADDON!"
    echo  Deleted the installed copy.
) else (
    rmdir "!ADDON!"
    echo  Removed the link. Your repo folder is untouched.
)
echo  Left lua\bin alone. Remove any RPC module by hand if you want it gone.
goto finish


:dopack
set "GMAD=!GMODDIR!\bin\gmad.exe"
if not exist "!GMAD!" (
    echo  ERROR: gmad.exe not found at "!GMAD!"
    goto finish
)
"!GMAD!" create -folder "!ROOT!" -out "!ROOT!\rollerfight.gma"
echo.
echo  Built "!ROOT!\rollerfight.gma"
goto finish


:usage
echo.
echo  install.bat                    interactive install
echo  install.bat /y                 accept everything, no prompts
echo  install.bat /gmod "PATH"       point at a GarrysMod install
echo  install.bat /pack              build rollerfight.gma
echo  install.bat /uninstall         remove the addon
echo.
goto finish


:finish
echo.
if defined INTERACTIVE pause
endlocal
exit /b 0
