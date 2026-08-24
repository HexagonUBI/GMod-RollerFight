@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set "ROOT=%%~fI"

set "GMODDIR="
set "MODULE="
set "ACTION=install"

:parseargs
if "%~1"=="" goto parsed
if /i "%~1"=="/uninstall" set "ACTION=uninstall" & shift & goto parseargs
if /i "%~1"=="/pack"      set "ACTION=pack"      & shift & goto parseargs
if /i "%~1"=="/gmod"      set "GMODDIR=%~2"      & shift & shift & goto parseargs
if /i "%~1"=="/module"    set "MODULE=%~2"       & shift & shift & goto parseargs
if /i "%~1"=="/help"      goto usage
if /i "%~1"=="-h"         goto usage
echo Unknown option: %~1
goto usage

:parsed

echo RollerFight installer
echo Repo: %ROOT%
echo.

if not "%GMODDIR%"=="" goto checkgmod

set "VDF=C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
if not exist "%VDF%" goto trydefault

for /f "usebackq delims=" %%A in (`findstr /c:"\"path\"" "%VDF%" 2^>nul`) do (
    set "LINE=%%A"
    set "LINE=!LINE:*"path"=!"
    set "LINE=!LINE:"=!"
    set "LINE=!LINE:\\=\!"
    for /f "tokens=*" %%B in ("!LINE!") do set "LIB=%%B"
    if exist "!LIB!\steamapps\common\GarrysMod\garrysmod\" set "GMODDIR=!LIB!\steamapps\common\GarrysMod"
)

:trydefault
if "%GMODDIR%"=="" (
    set "GMODDIR=C:\Program Files (x86)\Steam\steamapps\common\GarrysMod"
)

:checkgmod
if not exist "%GMODDIR%\garrysmod\" (
    echo ERROR: no GarrysMod at "%GMODDIR%"
    echo Pass the path yourself:  install.bat /gmod "D:\Steam\steamapps\common\GarrysMod"
    exit /b 1
)

set "GAMEDIR=%GMODDIR%\garrysmod"
set "ADDON=%GAMEDIR%\addons\rollerfight"
set "BINDIR=%GAMEDIR%\lua\bin"

echo GarrysMod: %GMODDIR%
echo.

if /i "%ACTION%"=="pack" goto dopack
if /i "%ACTION%"=="uninstall" goto douninstall

if exist "%ADDON%" (
    fsutil reparsepoint query "%ADDON%" >nul 2>&1
    if errorlevel 1 (
        echo WARNING: "%ADDON%" is a real folder, not a junction. Leaving it alone.
    ) else (
        echo Addon junction already present.
    )
) else (
    if not exist "%GAMEDIR%\addons\" mkdir "%GAMEDIR%\addons"
    mklink /J "%ADDON%" "%ROOT%" >nul
    if errorlevel 1 (
        echo ERROR: could not create the junction.
        echo Right click install.bat and pick "Run as administrator", then try again.
        exit /b 1
    )
    echo Created addon junction -^> %ROOT%
)

if not exist "%BINDIR%\" (
    mkdir "%BINDIR%"
    echo Created lua\bin
)

if "%MODULE%"=="" goto scanmodules

if not exist "%MODULE%" (
    echo ERROR: no file at "%MODULE%"
    exit /b 1
)

for %%F in ("%MODULE%") do set "LEAF=%%~nxF"

set "VALID="
if /i "!LEAF:~0,5!"=="gmcl_" (
    if /i "!LEAF:~-4!"==".dll" (
        for %%P in (win64 win32 linux64 linux osx64 osx) do (
            set "STRIPPED=!LEAF:_%%P.dll=!"
            if not "!STRIPPED!"=="!LEAF!" set "VALID=1"
        )
    )
)

if not defined VALID (
    echo ERROR: "!LEAF!" is not a GMod client module name.
    echo Expected something like gmcl_drpc_win64.dll
    exit /b 1
)

copy /y "%MODULE%" "%BINDIR%\%LEAF%" >nul
echo Installed %LEAF% into lua\bin

:scanmodules
echo.
set "FOUND="
for %%N in (drpc discordrpc gdiscord) do (
    for %%P in (win64 win32 linux64 linux osx64 osx) do (
        if exist "%BINDIR%\gmcl_%%N_%%P.dll" set "FOUND=!FOUND! gmcl_%%N_%%P.dll"
    )
)

if not "%FOUND%"=="" (
    echo Discord RPC module present:%FOUND%
) else (
    echo No Discord RPC module in lua\bin.
    echo RollerFight adapts to any of: drpc, discordrpc, gdiscord
    echo Download one yourself, then run:
    echo     install.bat /module "C:\path\to\gmcl_drpc_win64.dll"
    echo This installer will not download binaries for you on purpose.
)

echo.
echo Done. In game:  gamemode rollerfight ; map phys_dmm_house_r
exit /b 0

:douninstall
if not exist "%ADDON%" (
    echo No junction to remove.
    goto uninstalldone
)

fsutil reparsepoint query "%ADDON%" >nul 2>&1
if errorlevel 1 (
    echo SKIPPED: "%ADDON%" is a real folder, not a junction. Delete it yourself if you mean to.
) else (
    rmdir "%ADDON%"
    echo Removed the addon junction. The repo itself is untouched.
)

:uninstalldone
echo Left lua\bin alone. Remove any RPC module by hand if you want it gone.
exit /b 0

:dopack
set "GMAD=%GMODDIR%\bin\gmad.exe"
if not exist "%GMAD%" (
    echo ERROR: gmad.exe not found at "%GMAD%"
    exit /b 1
)
"%GMAD%" create -folder "%ROOT%" -out "%ROOT%\rollerfight.gma"
echo.
echo Built "%ROOT%\rollerfight.gma"
exit /b 0

:usage
echo.
echo Usage:
echo   install.bat                       install the addon junction and lua\bin
echo   install.bat /module "<dll path>"  also install a Discord RPC module
echo   install.bat /gmod "<path>"        point at a GarrysMod install by hand
echo   install.bat /pack                 build rollerfight.gma with gmad
echo   install.bat /uninstall            remove the addon junction
exit /b 0
