# Atari7800 for MiSTer.

## Features
- Runs complete Atari 7800 retail library.
- Supports NTSC and PAL regions.
- Supports High Score Cart saving.
- Supports Light Guns, Trakballs, Mice, Quadtari, and Paddles.
- XEGS Keyboard support via POKEY at $450 or $4000.
- Dual Pokey audio.
- YM2151 Audio using Jotego's JT51.
- Supports Covox.
- Support for XM and XBoard modules.
- Supports Activision, Absolute, Souper, and Supergame mappers up to 1mb.
- Choice of Cool, Warm, or Hot system temperature color output.

## Setup
Not much setup is required, but you may optionally put a system bios as `boot0.rom` in your Atari7800 ROMs folder to use before loading a game. It may increase compatibility in some rare cases if used. This core does rely on properly configured Atari7800 headers as detailed [here](http://7800.8bitdev.org/index.php/A78_Header_Specification). Using Trebors 7800 ROM PROPack is recommended as this is a reliable source of correctly headered ROMs.

## Additional Notes
Some games use the [difficulty switches](https://atariage.com/forums/topic/235913-atari-7800-difficulty-switches-guide/) to control their behavior, most notably Tower Toppler, which will continue to skip levels if the switches are in the "low" position. Tower Toppler also relies on composite blending artifacts to look correct, so it may be worthwhile to enable that for this game. The 7800 had issues with color consistency depending on the temperature of the system. Not all games may look idea with the warm palette, so you may have to experiment per game to find the ideal colors.

## Known Bugs
- Expansion ram of XM module is not fully implemented because I couldnt find anything that used it.
- YM Auto detection appears to fail because of an edge-case detection routine.
- BupChip music chip is not implemented because it runs on a modern microcontroller.

## Special Thanks
- Mark Saarna for his enormous knowledge of the system and patient help.
- Osman Celimli for his DMA timing traces and experience.
- Robert Tuccitto for the extensive palette information.
- Remowilliams for testing a zillion games for me on real hardware.
- Alan Steremberg for getting access to valuable documentation.
