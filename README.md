# Atari7800 for MiSTer.

## Features
- Runs complete retail library.
- Supports NTSC and PAL regions.
- Supports High Score Cart saving.
- Has support for YM and Pokey audio.
- Partial support for XM and XBoard modules (limited expansion ram).
- Supports Activision, Absolute, Souper, and Supergame mappers up to 1mb.
- Choice of Cool, Warm, or Hot system temperature color output.

## Setup
Not much setup is required, but you may optionally put a 4kb NTSC system bios as `boot0.rom` in your Atari7800 ROMs folder to use before loading a game. It may increase compatibility in some cases if used. This core does rely on properly configured Atari7800 headers as detailed [here](http://7800.8bitdev.org/index.php/A78_Header_Specification). Using Trebors 7800 ROM PROPack is recommended as this is a reliable source of correctly headered ROMs.

## Additional Notes
Some games use the [difficulty switches](https://atariage.com/forums/topic/235913-atari-7800-difficulty-switches-guide/) to control their behavior, most notably Tower Toppler, which will continue to skip levels if the switches are in the "low" position. Tower Toppler also relies on composite blending artifacts to look correct, so it may be worthwhile to enable that for this game. The 7800 had issues with color consistency depending on the temperature of the system. Not all games may look idea with the warm palette, so you may have to experiment per game to find the ideal colors.

## Known Bugs
- POKEY audio has some issues with 16 bit frequencies and certain tones.

## Special Thanks
- Mark Saarna for his enormous knowledge of the system.
- Osman Celimli for his DMA timing traces and experience.
- Robert Tuccitto for the extensive palette information.
- Remowilliams for testing a zillion games for me on real hardware.
