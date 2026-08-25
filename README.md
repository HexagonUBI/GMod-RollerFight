<div align="center">

<img src="https://raw.githubusercontent.com/HexagonUBI/GMod-RollerFight/main/docs/hero.png" alt="RollerFight" width="100%">

<br>

**Drive a Half-Life 2 rollermine in third person and fight by ramming the other mines.**<br>
They are not NPCs. Every rollermine on the map is a player.

<br>

<img src="https://img.shields.io/badge/Garry's%20Mod-gamemode-EE8220?style=for-the-badge" alt="Garry's Mod gamemode">
<img src="https://img.shields.io/badge/Lua-5.1-2C2D72?style=for-the-badge&logo=lua&logoColor=white" alt="Lua">
<img src="https://img.shields.io/badge/licence-all%20rights%20reserved-C1272D?style=for-the-badge" alt="All rights reserved">
<a href="https://discord.gg/BBsh8KCEhY"><img src="https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>

</div>

<br>

## Screenshots

<table>
<tr>
<td width="50%"><img src="https://raw.githubusercontent.com/HexagonUBI/GMod-RollerFight/main/docs/shot-1.jpg" alt="Two mines trading hits"></td>
<td width="50%"><img src="https://raw.githubusercontent.com/HexagonUBI/GMod-RollerFight/main/docs/shot-2.jpg" alt="Shock arc across a room"></td>
</tr>
<tr>
<td width="50%"><img src="https://raw.githubusercontent.com/HexagonUBI/GMod-RollerFight/main/docs/shot-3.jpg" alt="Mine in attack mode"></td>
<td width="50%"><img src="https://raw.githubusercontent.com/HexagonUBI/GMod-RollerFight/main/docs/shot-4.jpg" alt="Fighting through the wreckage"></td>
</tr>
</table>

## How it plays

The shell drives on real physics. You roll, you build speed, and contact is the whole weapon.

| Key | Does |
| --- | --- |
| `WASD` | Roll |
| `Shift` | Sprint, burns energy on the ground |
| `Space` | Jump, and pop back out when buried |
| `Left click` | Attack mode, spikes out, contact starts doing damage |
| `Right click` | Dash forward, hits harder for a moment then locks attack mode out |
| `Ctrl` | Burrow into soil, sand, grass or snow |
| `F` | Lamp |
| `Tab` | Scoreboard |

Sprint, dash and attack mode all draw on one energy pool. Run it dry and you are locked out until it
recovers. Coast around passive for a few seconds and the shell slowly repairs itself, so backing off
is a real option. Deep water kills you outright, and so does anything explosive.

## Gametypes

| Mode | Rules |
| --- | --- |
| **Deathmatch** | Everyone for themselves, every mine gets its own colour |
| **Team Deathmatch** | Combine against Rebels, with a team pick screen before the match starts |
| **Last One To Stand** | One life, no respawns, spectate whoever is left |

## What is in it

- Ready up lobby with a flyby camera over the map, and a training mode to roll around in while you wait
- Round timer, score limit, countdown and a round over screen
- Killfeed with a per cause icon and assist credit
- Scoreboard with a full host settings panel, every tunable is an `rf_` convar
- Spectate the other players once your mine is destroyed
- Bots that seek, ram, sprint, dash and jump, so a solo lobby still plays
- Music director pulling from Half-Life 2, Episode One and Episode Two
- Optional Discord Rich Presence

## Install

Subscribe to the Steam Workshop item, then pick RollerFight from the gamemode list in the main menu
and load a `gm_` or `phys_` map. Half-Life 2 has to be mounted. The episodes are optional and only
widen the music rotation.

<!-- workshop item: https://steamcommunity.com/sharedfiles/filedetails/?id= -->

Built and tested on
[Destructible House (REMASTERED)](https://steamcommunity.com/sharedfiles/filedetails/?id=3048598528).

To install straight from this repository instead:

```
tools\install.bat
```

It finds Garry's Mod through `libraryfolders.vdf`, links the addon, and reports what it did.

## Working on it

```
python tools/verify.py      static checks, must pass before anything is done
python tools/build.py       writes dist/, the folder to publish from
python tools/docs_art.py    rebuilds the images this page uses
tools\install.bat /pack     builds rollerfight.gma
```

| Path | Holds |
| --- | --- |
| `gamemodes/rollerfight/` | The gamemode |
| `materials/rollerfight/` | Interface art |
| `tools/` | Installer and build scripts |
| `docs/` | Images for this page, not shipped |
| `dist/` | Generated publish folder, not tracked |

Repo root is the addon root, so it works as a live dev folder and as a workshop upload.

## Contact

Bug reports and feature requests go through [issues](https://github.com/HexagonUBI/GMod-RollerFight/issues).
Everything else, including questions and permission requests, goes to
[Discord](https://discord.gg/BBsh8KCEhY).

## Licence

All rights reserved. See [LICENSE](LICENSE).

You may play it and run it unmodified on your own server. You may not reupload it, modify it, or
reuse any part of it in another project without written permission. Reports are welcome, the code is
not open for reuse.
