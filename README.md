# Planet Jazz - Planet Disco Balls (Amiga A500 Intro Source)

## What is it?

This is the 68000 assembler source code for the Planet Jazz ["Planet Disco Balls"](https://www.pouet.net/prod.php?which=88532) intro.

It consists of a very cut down Windows build environment based on the [Lemon toolchain](https://www.pouet.net/prod.php?which=65625) by Hannibal.

## License

The original source code (Under the Projects folder) is under the MIT license. This does not refer to any other tools and utilties that are included such as WinUAE/VASM, etc (Toolchain and WinUAE folders). Those files are covered by their own licenses.

## How to Use

1. Go into the Projects\PJZ2 folder
2. Open "_DevCmdPrompt.cmd" to bring up a command prompt with paths set for the toolchain
3. Run "make clean gendemo run" to run the intro an AROS environment (I use the A500 KS1.3 rom but don't want to include it here for obvious reasons)

Each demo "part" is in its own folder under Projects\\PJZ2\\\<part>

You can assemble and run just he individual parts as follows:
* make clean genstretchvert run
* make clean genparalines run
* make clean genvector run
* make clean gengreetz run
* make clean genibobs run
* make clean genbackdrop1 run
* make clean gencredits run

The "Framework" folder is probably the most generic and useful as it contains all the helper functions, libraries, startup code, etc.

Any problems [email me](mailto:jon@autoitscript.com) or contact Antiriad_UK on [English Amiga Board](http://eab.abime.net/index.php).

## Thanks

Thanks to these people for the tools and scripts used in this demo. It wouldn't have been possible without
you!

* Virgill - Amigaklang and convincing me to enter Revision 2021
* Hannibal/Lemon. - KingCon
* Blueberry/Loonies - Shrinkler
* Soundy/The Deadliners - Gradient Master
* Axis/Oxyron - Planet Rocklobster source
* Frank Wille - VASM 68k
* prb28 - [ASM extension for VSCode](https://github.com/prb28/vscode-amiga-assembly)
* Toni Wilen - WinUAE
