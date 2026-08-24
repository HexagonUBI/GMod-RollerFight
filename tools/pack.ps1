param(
	[string]$GMod = "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod"
)

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "rollerfight.gma"
$gmad = Join-Path $GMod "bin\gmad.exe"

if (-not (Test-Path $gmad)) { throw "gmad.exe not found at $gmad" }

& $gmad create -folder $root -out $out
Write-Host "Built $out"
