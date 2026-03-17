# eXoDOS macOS Compatibility Notes

This document lists games that have reduced functionality or cannot be played on macOS
due to Windows-only helper tools or DOSBox variants (DAUM, ECE, GunStick) that are not
available on macOS.

The macOS patch uses **DOSBox Staging** for the vast majority of games and **DOSBox-X**
for 18 games that require it. The tools below have no macOS equivalent:

| Tool | Used for |
|------|---------|
| **Wine** | Running Windows `.exe` helpers or the game itself |
| **DOSBox ECE** (Enhanced Community Edition) | Sound/MIDI/save-state extras |
| **DOSBox DAUM** | Old WIP fork, incompatible with modern macOS |
| **GunStick DOSBox** | Special build for light-gun game hardware |

---

## Category 1 — Not Playable on macOS

These games require Wine to run the game itself, or use a DOSBox variant that has no
macOS equivalent. On macOS, launching these games will start DOSBox Staging with the
standard `dosbox_linux.conf`, but the game will likely fail to run or be unplayable.

| Game | Year | Folder | Reason |
|------|------|--------|--------|
| Cosmic Sheriff | 1989 | `cosmicsh` | Requires GunStick DOSBox (Wine) — light-gun hardware variant |
| Mike Gunner | 1988 | `MikGunner` | Requires GunStick DOSBox (Wine) — light-gun hardware variant |
| Pack Regalo Gun Stick | 1989 | `PackGun` | Requires GunStick DOSBox (Wine) — light-gun hardware variant |
| Descent to Undermountain | 1998 | `DescUnd` | Requires DOSBox DAUM via Wine |
| TNM 7: The Wrestling Simulator - Second Edition | 2018 | `TNM7SE` | Native Windows EXE (`TNMGS.EXE`) run via Wine — not a DOS game |

---

## Category 2 — Playable, but Multiplayer/Network Mode Unavailable

These games launch and play in DOSBox Staging, but a Windows helper process that enables
the network or online component cannot run on macOS.

| Game | Year | Folder | What's Missing |
|------|------|--------|----------------|
| The Sierra Network | 1991 | `INNBarn` | `InnProxy.exe` (Win32 network proxy) — the online Sierra Network simulation won't connect; single-player/offline content still launches |

---

## Category 3 — Fully Playable, Enhanced Features Unavailable

These games run correctly on macOS via DOSBox Staging. On Linux, a companion Windows
utility runs alongside DOSBox to provide extras (auto-save, map overlay, or mouse
capture fix). Those extras require Wine and are unavailable on macOS, but the core game
is complete and playable without them.

### Gold Box Companion (GBC) — map/tracker overlay

`GBC.exe` is a Windows tool that displays an automap and party tracker alongside the
DOSBox window. The D&D Gold Box games below are fully playable without it.

| Game | Year | Folder |
|------|------|--------|
| Pool of Radiance | 1988 | `poolrad` |
| Curse of the Azure Bonds | 1989 | `curse` |
| Secret of The Silver Blades | 1990 | `secsilbl` |
| Champions of Krynn | 1990 | `ckrynn` |
| Gateway to the Savage Frontier | 1991 | `gatesf` |
| Pools of Darkness | 1991 | `pooldark` |
| Death Knights of Krynn | 1991 | `dkkrynn` |
| The Dark Queen of Krynn | 1992 | `drkqueen` |
| Treasures of the Savage Frontier | 1992 | `TreasSav` |
| Unlimited Adventures | 1993 | `unlimadv` |
| Buck Rogers: Countdown to Doomsday | 1990 | `BRcdoom` |
| Buck Rogers: Matrix Cubed | 1992 | `BRmatrix` |

### Auto Save Engine (ASE) — automatic save states

`ASE.exe` adds automatic save states to the Eye of the Beholder series. The games are
fully playable using the in-game save system instead.

| Game | Year | Folder |
|------|------|--------|
| Eye of the Beholder | 1991 | `eob1` |
| Eye of the Beholder II: The Legend of Darkmoon | 1991 | `eob2` |
| Eye of the Beholder III: Assault on Myth Drannor | 1993 | `eob3` |

### Mouse helper utilities — improved mouse capture

On Linux, a Windows `.exe` runs in the background to improve mouse capture and
sensitivity in DOSBox. The games are fully playable on macOS; mouse control may feel
slightly different than the Linux experience.

| Game | Year | Folder | Helper |
|------|------|--------|--------|
| Dune II: The Building of a Dynasty | 1992 | `dune2` | `Dune2MouseHelper.exe` |
| SkyNET | 1996 | `SkyNET` | `SkyNETMouseHelper.exe` |
| The Terminator: Future Shock | 1995 | `TermFS` | `SkyNETMouseHelper.exe` |
| Warcraft: Orcs & Humans | 1994 | `WarCraft` | `WarcraftMouseHelper.exe` |

### Partially enhanced games

These games have one mode that works fully and another mode that requires Wine.

| Game | Year | Folder | What works | What's missing |
|------|------|--------|-----------|----------------|
| System Shock | 1994 | `SystemSh` | Original version (DOSBox) | SSP Configurator (`SSP.exe` via Wine); SSP itself still launches via DOSBox |
| Robot Warfare 1 | 1999 | `RoboWar1` | Play game (DOSBox) | Windows robot editor (`RW1_EDIT.EXE` via Wine) |
| Girlfriend Terri | 1994 | `gfterri` | Play game (DOSBox) | User info editor (`GFUpdate.exe` via Wine) |
| Girlfriend Tracy | 1995 | `gftracy` | Play game (DOSBox) | User info editor (`GFUpdate.exe` via Wine) |

---

## Summary

| Category | Count |
|----------|------:|
| Not playable on macOS | 5 |
| Network mode unavailable | 1 |
| Missing GBC map overlay | 12 |
| Missing ASE auto-save | 3 |
| Missing mouse helper | 4 |
| Partially playable (one mode requires Wine) | 4 |
| **Total affected games** | **29** |

Out of 7,666 DOS games in the collection, **7,637 play identically on macOS and Linux**.
