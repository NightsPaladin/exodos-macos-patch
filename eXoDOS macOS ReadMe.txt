eXoDos Collection
		v6.04 macOS Patch
		retroexo@gmail.com (community macOS port)
		=======================================================
		-------------------------------------------------------
		Contents
		-------------------------------------------------------
		Description.......................................Sec01
		Requirements......................................Sec02
		Setup.............................................Sec03
		Using the GUI.....................................Sec04
		Emulators.........................................Sec05
		MIDI / MT-32 Sound................................Sec06
		Limitations.......................................Sec07
		Troubleshooting...................................Sec08


-------------------------------------------------------
Description                                       Sec01
-------------------------------------------------------
This is the community macOS patch for eXoDOS Version 6.04.

It adds full macOS support including:
 - A native Python/PyQt6 GUI launcher (exogui-macos)
 - Launch scripts for all 7,666 DOS games via dosbox-staging or dosbox-x
 - Support for MT-32 MIDI emulation and FluidSynth Sound Canvas
 - Videos and documentation viewer for games with Extras
 - Game install directly from the GUI (extracts included ZIPs)

Both Intel (x86_64) and Apple Silicon (arm64) Macs are supported.

Supported macOS versions: 12 Monterey and later (Homebrew required).


-------------------------------------------------------
Requirements                                      Sec02
-------------------------------------------------------
1. A copy of eXoDOS v6.04 (base collection + Linux patch applied)
2. macOS 12 Monterey or later
3. Homebrew  (https://brew.sh)
4. Python 3.11+  (via mise, pyenv, or Homebrew)

The macOS dependencies installer will handle the rest.


-------------------------------------------------------
Setup                                             Sec03
-------------------------------------------------------
STEP ONE - Place the eXoDOS collection on a volume

  The collection should be on a drive formatted as exFAT or APFS.
  The collection root (containing the eXo/, xml/, Images/ folders)
  is referred to as the "eXoDOS root" throughout this document.

STEP TWO - Apply this patch

  Extract the macOS patch ZIP on top of your eXoDOS root.
  This will add/replace only the macOS-specific files; no game
  data or existing Linux patch files will be overwritten except
  for eXo/util/launch.msh (which gains macOS support).

STEP THREE - Install dependencies

  Double-click:  install_dependencies.command

  This installs via Homebrew:
    - dosbox-staging  (primary emulator for ~7,649 games)
    - dosbox-x        (for 18 games requiring DOSBox-X)
    - scummvm         (for ScummVM-based games)
    - aria2, wget, gnu-sed, python3 (utilities)

  NOTE: Wine and XQuartz are NOT needed and are NOT installed.

STEP FOUR - Launch the GUI

  Double-click:  exogui-macos.command

  On first run this installs PyQt6 automatically (requires internet).
  The GUI will load all 7,666 games from the XML metadata.


-------------------------------------------------------
Using the GUI                                     Sec04
-------------------------------------------------------
 - Search bar: type to filter games by title, genre, or developer
 - Genre / Year / Status filters in the left panel
 - Click a game to see its box art, screenshots, description,
   and any available Videos & Documents
 - Install button: extracts the game's ZIP to the data directory
 - Play button: launches the game (enabled after install)
 - Videos & Documents section: click any item to open it in the
   system default application (Preview for PDFs, QuickTime for MP4)

IMPORTANT for games with copy protection:
  Many games (e.g. Dune II) require consulting the included manual
  or reference card for in-game security questions. These are found
  in the Documents section of the game detail panel.


-------------------------------------------------------
Emulators                                         Sec05
-------------------------------------------------------
DOSBox Staging is used for the vast majority of games.
DOSBox-X is used for 18 games that require specific features.

The emulator mapping is stored in:
  eXo/util/dosbox_macos.txt      (Intel)
  eXo/util/dosbox_mac-m1.txt     (Apple Silicon)

These files are generated from the Linux patch mappings and use
dosbox-staging as the equivalent for all DOSBox-ECE games.

DOSBox is launched from the eXo/ directory with two config files:
  1. eXo/eXoDOS/!dos/<gamedir>/dosbox_linux.conf  (per-game)
  2. eXo/emulators/dosbox/options_macos.conf       (macOS overrides)


-------------------------------------------------------
MIDI / MT-32 Sound                                Sec06
-------------------------------------------------------
DOSBox Staging's built-in MT-32 emulator is enabled by default.
ROM files are located at:  eXo/mt32/

Games that support MT-32 will use it automatically.
Games that use OPL/AdLib/Sound Blaster directly are unaffected.

8 games were specifically configured for FluidSynth (Sound Canvas)
in their Linux configs; these will use MT-32 instead on macOS,
which still sounds good but may differ from the intended audio.

The SoundCanvas.sf2 soundfont is available at eXo/mt32/ for
future per-game FluidSynth configuration.


-------------------------------------------------------
Limitations                                       Sec07
-------------------------------------------------------
 - 5 games require Windows-only DOSBox variants via Wine on Linux:
     Cosmic Sheriff, Mike Gunner, Pack Regalo Gun Stick,
     Descent to Undermountain, TNM 7 Second Edition
   These are flagged with a warning in the GUI and may not run
   correctly (they fall back to dosbox-staging).

 - ScummVM game detection is not yet fully implemented.
   Games known to need ScummVM may still launch via dosbox-staging.

 - 86Box emulation (used for some Windows 3.x games) is not
   supported in this patch. See eXoWin3x for Windows 3.x support.

 - Multiplayer (IPX networking) games use a different launch path
   and have not been tested on macOS.


-------------------------------------------------------
Troubleshooting                                   Sec08
-------------------------------------------------------
Game won't launch:
  - Check that install_dependencies.command was run successfully
  - Ensure the game is installed (Install button in the GUI)
  - Check that dosbox-staging is in your PATH:
      which dosbox-staging

DOSBox window has no sound:
  - macOS may prompt for microphone/audio permissions on first run
  - Grant permissions in System Settings > Privacy & Security

MT-32 not working:
  - Verify ROM files exist: eXo/mt32/MT32_CONTROL.ROM
  - MT-32 requires in-game configuration (use the game's SETUP.EXE)

GUI won't start:
  - Re-run install_dependencies.command
  - Try manually: cd /path/to/eXoDOS && python3 exogui-macos/main.py

Copy protection / password required:
  - Open the PDF manual or reference card from the Documents section
    in the game detail panel

For support, visit the eXoDOS Discord:
  https://discord.gg/exodos
