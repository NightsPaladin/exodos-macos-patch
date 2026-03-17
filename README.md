# eXoDOS v6.04 — macOS Patch

> **Unofficial** — This is a community project and is not affiliated with, endorsed by,
> or supported by the eXoDOS project or the retro-exo.com team.

A community macOS patch for [eXoDOS](https://www.retro-exo.com), a curated collection
of 7,666 pre-configured DOS games. This patch adds a native macOS launcher and working
launch scripts for every game, with no dependency on the Linux patch.

Supports **Intel (x86_64)** and **Apple Silicon (arm64)** Macs running **macOS 12 Monterey or later**.

---

## Requirements

- **eXoDOS v6.04** base collection
- **macOS 12 Monterey** or later
- **[Homebrew](https://brew.sh)** — used to install emulators and utilities
- **Python 3.11+** — via Homebrew (`brew install python3`), pyenv, or mise

---

## Setup

### 1. Place the collection on a drive

The collection works from any location — internal drive, external drive, or network share.
The folder containing `eXo/`, `xml/`, `Images/`, and `Data/` is the **collection root**.

An external drive formatted as **exFAT** is recommended if you also want to access the
collection from Windows or Linux.

### 2. Apply this patch

Extract the macOS patch ZIP directly into your collection root so that `eXo/`,
`exogui-pyqt/`, and the `.command` files sit at the top level alongside each other.

This patch supplements the official **eXoDOS Linux patch** — apply the Linux patch
first, then extract this patch on top.  No game data or ZIP archives are modified.

### 3. Unify scripts

Run the unification script once after extracting the patch.  It converts all per-game
`.bsh` scripts into unified cross-platform `.sh` wrappers and folds macOS support into
the shared library:

```bash
python3 unify_scripts.py
```

Once you've verified that games launch correctly, clean up the backup files it left:

```bash
python3 unify_scripts.py --purge-backups
```

### 4. Install dependencies

Double-click **`install_dependencies.command`**.

This installs the following via Homebrew:

| Package | Purpose |
|---------|---------|
| `dosbox-staging` | Primary emulator — used for ~7,648 games |
| `dosbox-x` | Used for 18 games requiring specific DOSBox-X features |
| `scummvm` | ScummVM-supported adventure games |
| `aria2` | Multi-connection download manager |
| `wget` | Fallback downloader |
| `gnu-sed` | GNU sed (required by launch scripts) |
| `python3` | Python runtime |

On **Apple Silicon**, Rosetta 2 is installed automatically if not already present.

> Wine and XQuartz are **not** required and are not installed.

### 5. Launch the GUI

Double-click **`exogui.command`** to open eXoGUI.

See the [eXoGUI repository](https://github.com/NightsPaladin/exogui-pyqt) for full
setup and usage documentation.

---

## Emulators

| Emulator | Games | Notes |
|----------|------:|-------|
| DOSBox Staging | ~7,648 | Primary emulator; also covers all DOSBox ECE games |
| DOSBox-X | 18 | Games requiring EGA/CGA composite, PC-98, or similar |
| 86Box | 4 | Optional alternative for Dungeon Keeper, Falcon Gold, Privateer 2 SE, Wing Commander — presented as a menu choice at launch |

Each game is launched from the `eXo/` directory using two config files:

1. `eXo/eXoDOS/!dos/<gamedir>/dosbox_linux.conf` — per-game configuration
2. `eXo/emulators/dosbox/options_macos.conf` — macOS-specific overrides

The emulator assigned to each game is listed in `eXo/util/dosbox_macos.txt`.

---

## MIDI / MT-32 Sound

DOSBox Staging includes a built-in MT-32 emulator (Munt), enabled by default.
MT-32 ROM files are included in the collection at:

```
eXo/mt32/MT32_CONTROL.ROM
eXo/mt32/MT32_PCM.ROM
```

Games that support MT-32 use it automatically when configured in their
`dosbox_linux.conf`. Games using OPL2/OPL3 (AdLib/Sound Blaster) are unaffected.

A small number of games were configured for FluidSynth (Sound Canvas MIDI) on Linux.
On macOS these use MT-32 instead, which is an excellent substitute.

---

## macOS Compatibility Notes

The vast majority of the collection — **7,637 of 7,666 games** — play identically on
macOS and Linux. The remaining 29 games fall into the categories below.

### Not playable on macOS (5 games)

These games require a Windows-only DOSBox variant or run as a native Windows executable
via Wine. Neither is available on macOS. On macOS these titles fall back to DOSBox
Staging and will not run correctly.

| Game | Year | Reason |
|------|------|--------|
| Cosmic Sheriff | 1989 | Requires GunStick DOSBox (Wine) |
| Mike Gunner | 1988 | Requires GunStick DOSBox (Wine) |
| Pack Regalo Gun Stick | 1989 | Requires GunStick DOSBox (Wine) |
| Descent to Undermountain | 1998 | Requires DOSBox DAUM (Wine) |
| TNM 7: The Wrestling Simulator - Second Edition | 2018 | Native Windows EXE (Wine) |

### Network mode unavailable (1 game)

| Game | Year | Notes |
|------|------|-------|
| The Sierra Network | 1991 | The online network simulation requires InnProxy.exe (Windows); the DOSBox portion of the game still launches |

### Playable — companion tool unavailable (23 games)

These games run correctly on macOS. On Linux, a Windows companion utility runs
alongside DOSBox to provide extras. The games are fully playable without these tools;
only the optional enhancement is absent.

**Gold Box Companion (GBC)** — displays an automap and party tracker alongside DOSBox.
The D&D Gold Box RPGs below are complete without it.

| Game | Year |
|------|------|
| Pool of Radiance | 1988 |
| Curse of the Azure Bonds | 1989 |
| Secret of The Silver Blades | 1990 |
| Champions of Krynn | 1990 |
| Gateway to the Savage Frontier | 1991 |
| Pools of Darkness | 1991 |
| Death Knights of Krynn | 1991 |
| The Dark Queen of Krynn | 1992 |
| Treasures of the Savage Frontier | 1992 |
| Unlimited Adventures | 1993 |
| Buck Rogers: Countdown to Doomsday | 1990 |
| Buck Rogers: Matrix Cubed | 1992 |

**Auto Save Engine (ASE)** — provides automatic save states. The in-game save system
works normally without it.

| Game | Year |
|------|------|
| Eye of the Beholder | 1991 |
| Eye of the Beholder II: The Legend of Darkmoon | 1991 |
| Eye of The Beholder III: Assault on Myth Drannor | 1993 |

**Mouse helper utilities** — improve mouse capture and sensitivity in DOSBox. The games
are fully playable; mouse behavior may differ slightly from the Linux experience.

| Game | Year |
|------|------|
| Dune II: The Building of a Dynasty | 1992 |
| Warcraft: Orcs & Humans | 1994 |
| SkyNET | 1996 |
| The Terminator: Future Shock | 1995 |

**Partially enhanced games** — one gameplay mode is fully available; a secondary option
(configurator or editor) requires a Windows executable.

| Game | Year | Available | Requires Windows |
|------|------|-----------|-----------------|
| System Shock | 1994 | Original DOSBox version | SSP Configurator |
| Robot Warfare 1 | 1999 | Play the game | Windows robot editor |
| Girlfriend Terri | 1994 | Play the game | User info editor |
| Girlfriend Tracy | 1995 | Play the game | User info editor |

---

## Community & Support

- **Discord:** https://discord.gg/37FYaUZ
- **Website:** https://www.retro-exo.com/community.html
- **Wiki:** https://wiki.retro-exo.com

This macOS patch is a community contribution to the eXoDOS project.
