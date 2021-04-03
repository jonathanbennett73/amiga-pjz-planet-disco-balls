
WinUAE 4.3.0 (19.12.2019)
=========================

New features/improvements:

- GUI high DPI support rewritten.
- Lagless vsync stability improvements.
- Added Trojan light gun preset to Game ports panel.
- On the fly chipset model switching compatibility improved.
- SPTI CD/DVD access mode now internally emulates all CD audio commands. All other commands are forwarded to the drive like previously.
- PCMCIA hot swap support improved. (PCMCIA SRAM and IDE needs to be set again if previously configured)
- My CPU tester detected edge cases, bugs and undocumented CPU behavior updates implemented. (More details in separate CPU tester note later)
- More compatible partition HDF default geometry calculation if size is 1000M or larger.
- CD32 pad does not anymore disable joystick second button if both CD32 and 2-button joystick is active simultaneously.
- Host directory/archive drag and drop to WinUAE window now supports mounting multiple items simultaneously.
- Debugger disassembler fixes and few very rarely used instructions dissemble now correctly.

Bugs fixed:

- Disk index pulses were not being generated when disk was being written (Cadaver v0.1 save disk writing)
- CDTV audio CD playing state restore fixed.
- A2024 monitor didn't show full viewable area.
- 24-bit uaegfx RTG mode had random wrong color pixels in some situations.
- nrg CD images didn't load correctly in relative path mode.
- Graphics glitch in some programs that also depended on display scaling/size (for example Alien Breed 3D)
- Disk swapper path modifications did nothing while emulation was running.
- Restoring CD32 or CDTV statefile with CD audio playing: start playing immediately, do not include normal CD audio start delays.
- Fixed possible crash when PPC emulation stopped emulated sound card audio.
- Quite special kind of CD32 pad button read code was not emulated correctly.

Other changes:

- Added separate 68000-68060 CPU tester/validator project based on UAE CPU core generator.
- Removed all 68020 cycle-exact CPU mode internal idle cycles. It mainly slowed down the CPU too much and didn't match real world well enough.

New emulated hardware:

- Archos Overdrive HD (PCMCIA IDE adapter)
- ICD Trifecta (A500 IDE/SCSI controller)
- M-Tec Mastercard (SCSI expansion for M-Tec T1230 A1200 accelerator)
- Scala MM dongles


WinUAE 4.2.1 (16.05.2019)
=========================

4.2.0 bugs fixed:

Picasso IV and uaegfx YUV (video) overlay fixed. Didn't affect RGB overlays.
Reset/restart didn't reset overlay state.
Graphics corruption in some AGA programs (for example Alien Breed 3D).

Old bugs fixed:

PPC emulation + Picasso IV: some programs had incorrect colors (For example Shogo MAD).
A2386SX bridgeboard unreliable/hanging floppy access fixed.
Changing accelerator board options (jumpers etc) on the fly didn't do anything.
Fixed hang when attempting to play physical CD32 CD with video tracks.
Fixed crash when mounting UAE controller HDF with more than 30 partitions.


WinUAE 4.2.0 (08.04.2019)
=========================

New features:

uaegfx and Picasso IV Overlay window/PIP support.
All GUI listviews support column order and column width customization.
Custom ROM selection (4 slots) added.
Direct3D 9/11 shader embedded config entry support.
68030 MMU instruction disassembler support and other disassembler fixes.
68030 MMU emulation will now also create short type bus error stack frames when possible, matching real 68030 behavior.
Windowed mode keeps aspect ratio if CTRL is pressed while resizing.
Added debugger invalid access logger (memwatch l).
Reject Alt+<some key> Windows system menu key shortcuts. Invalid short cut combinations can generate annoying Windows alert sounds.
KS ROM selection supports loading and relocation of hunk and m68k elf executables.

Bug fixes:

Direct3D 11 shader support fixes.
CDTV CD drive read/play startup delays adjusted. Fixes Town without no name speech audio track stopping too early.
Accelerator board CPU fallback (to mainboard CPU mode) works again.
Many video port adapters (which includes grayscale mode and genlock) didn’t support all doubling modes.
Minor custom chipset fixes (Small graphics corruption in certain special situations)
Moving mouse outside and back to WinUAE window in Magic mouse activated WinUAE window even if some other window was already active.
AVI recording with non-standard refresh rate was reset to default if GUI was entered and exited during recording.
uae-configuration returned return code 10 even when matching config entry was found.
“Add PC drives at startup” enabled and same drive’s root directory also mounted manually: drive was mounted twice. (Introduced in 4.1.0)
Genlock transparency didn’t always activate even when genlock emulation was enabled.
A2090 compatibility fix, A2090 + tape drive does not hang anymore.
A2620/A2630 boot ROM autoconfig didn't work with some expansion devices, for example A2090.
Sprites to bitplanes and odd bitplanes to even bitplanes collisions didn't work in subpixel emulation mode.

New emulated hardware:

Pacific Peripherals Overdrive
IVS Trumpcard
IVS Trumpcard 500AT
ICD Trifecta
BSC Tandem (IDE only, Mitsumi CD is not emulated)
ACT Prelude and Prelude 1200
Harms Professional 3000


WinUAE 4.1.0 (06.12.2018)
=========================

PC Bridgeboard (A1060 Sidecar, A2088, A2088T, A2286 and A2386SX) emulation rewrite:

Emulation core replaced with PCem. Compatibility has improved greatly, for example Windows 3.x enhanced mode, DOS extenders and Windows 95 are now fully working.
Bridgeboard built-in CGA emulation graphics corruption fixed.
A2386SX VLSI chipset memory remapping, shadowing and EMS fully supported.
Cirrus Logic emulation PC compatibility improved, 2M VRAM, linear frame buffer and blitter support.
PC Speaker emulation (PCem)
Sound Blaster emulation (PCem, various models)
Serial mouse emulation (PCem)
SCSI adapter emulation (Rancho Technology RT1000B)

Other updates:

AGA hires/superhires horizontal pixel positioning and borderblank horizontal single hires pixel offset fully emulated. Optional because it requires much more CPU power and it is rarely needed. DIWHIGH H0/H1 AGA-only bits emulated.
AGA FMODE>0 undocumented features implemented (BPLxDAT, SPRxDAT CPU/copper accesses, bitplane modulos that are not integer divisible by fetch size)
Added new misc option which captures mouse immediately when windowed/full-window winuae window is activated.
68030 MMU emulation compatibility improved.
Paula disk emulation GCR MSBSYNC support added (Alternate Reality protection track).
Added quick search and quick directory select to Configurations panel. Link and autoload moved to Advanced information panel.
Added history list to config file name edit box and to statefile path string box.
Added vertical offset option to D3D scanlines.
64-bit version didn't support 64-bit unrar.dll.
68030/040/060 with data cache emulation but without enabled MMU emulation: force Chip RAM as non-data cacheable.
Magic mouse Windows cursor to Amiga mouse sync partially fixed.
Window corners now work as drag'n'drop hot spots for different floppy drives. (top/left=0, top/right=1, bottom/left=2, bottom/right=3).

Bug fixes:

68020 + memory cycle exact hung the emulator in some situations.
Reading CIA interrupt status register in a very tight loop generated spurious interrupt(s) in certain situations.
Softfloat mode with unimplemented FPU emu ticked didn't disable 68040/060 unmasked interrupts, confusing 68040/68060.library and possibly causing it to return incorrect values.
Some CHD CD images didn't mount correctly.
uaehf.device HD_SCSICMD didn't set scsi_SenseActual. Also set io_Actual=30 (=sizeof(struct SCSICmd))
If config file had KS ROM path/file that didn't exist, it was replaced with non-existing <original path>../system/rom/kick.rom path or was not correctly fixed with valid path.
NCR53F94 SCSI chip emulation DMA counter fix (affected for example Blizzard SCSI Kit)
Very large directory harddrives returned halved used/free space.
Fixed multiple problems with screenshots and video recording from hardware emulated RTG board.
Filter panel scanlines work now correctly in multimonitor mode.
Crash fixed if more than one non-Paula audio stream was active. Included emulated sound cards, also CD audio if "include" option ticked.
NE2000 PCMCIA and NE2000 bridgeboard didn't support custom MAC and network mode selection.
Fixed hardware emulated graphics board hang with Picasso96 if board supported vblank interrupts and RTG board refresh rate mode was not Chipset.
Fixed statefile crash when saving statefile while disk operation was active and disk image included bit cell timing information.

Bug fixes (Introduced in 4.0.0/4.0.1):

Display port adapters that needed genlock transparency data (FireCracker, HAM-E, OpalVision, ColorBurst) didn't work correctly since 4.0.0.
Display port adapters didn't work in multimonitor mode.
Blitter statesave with blitter active: log window opened and listed few lines of blitter debug information.
Some programs caused continuous flood of "blitter is active, forcing immediate finish" log messages.
CTRL+F11 quit ignored new "Warn when attempting to close window" option.
68020/030 more compatible/cycle-exact mode statefiles didn't always restore properly.

New emulated hardware:

CSA Twelwe Gauge (A1200 68030 accelerator + SCSI controller)
AccessX/Acetec IDE controller.


WinUAE 4.0.1 (16.07.2018)
=========================

4.0.0 bugs fixed:

- Enabled "Minimize when focus is lost" option caused crash in some situations.
- 64-bit FPU mode always changed back to 80-bit if config file was loaded.
- 80-bit native FPU mode FREM and FMOD returned wrong results.
- RTG statefile restore didn't restore screen state completely.

Other bugs fixed:

- "Minimize when focus is lost" incorrectly activated when switching modes in some situations.
- "Minimize when focus is lost" minimized main emulation window when GUI was open and main window lost focus.
- If CPU panel FPU mode select menu was active and then some other panel was opened: JIT was switched off.
- CD audio play from real/virtual CD (not from directly mounted image file) didn't restart correctly if audio settings changed.
- Only some emulated SCSI controllers flashed CD led when emulating a CD drive.
- input.keyboard_type was always read as Amiga keyboard. If PC layout was set as default, keyboard layout was read incorrectly from config file.
- Amiga reset during active RTG rendering in RTG Multithread mode could have caused a crash.
- RTG Multithread mode display refreshing was unreliable in 8-bit modes when palette changed.
- Finally fixed corrupted drag and drop graphics in Harddrives and Disk Swapper panel.
- When inserting previously connected USB input device, previous device type (Gamepad, CD32 pad etc) and autofire mode (if any) was not restored.
- Clipboard sharing could have attempted to transfer data to Amiga side after program had taken over the system, possibly overwriting memory.

New features:

- Environmental variables (%variable%) in paths are not anymore resolved immediately when config is loaded but only when needed without modifying original path, preserving original path if config file is saved again.
- Added full statefile absolute/relative path support. Loading statefile will restore correct paths even if absolute/relative path mode was changed after saving the statefile.
- D3D9 and D3D11 VSync mode (both lagless and standard) 100/120Hz support with optional black frame insertion.
- 68060 FPU was not disabled after soft reset if 68060 was configured without emulated 68060 accelerator board, causing reset loop.

New emulated expansions:

- QuikPak 4060


WinUAE 4.0.0 (20.06.2018)
=========================

New major features:

- Beam Racing Lagless VSync which reduces input latency to sub-5ms. Replaces old Low Latency VSync. (Use 1-2 slice Lagless VSync to match old Low Latency VSync behavior)
- Virtual multi monitor support. Each virtual Amiga video output connector (Video port graphics adapter, RTG boards) can be "connected" to separate WinUAE window, emulating real hardware being connected to more than one physical monitor.
- Debugger supports running Amiga executables from shell, adds symbol and gcc stab debugging data support, loads executable to special reserved address space which enables detection of any illegal accesses byte accurately and more. (Details)
- Host mode FPU emulation mode is finally full extended precision (80-bit) capable. It is also fully JIT compatible.

New other features:

- Overlay graphics led (power, floppy etc) support.
- Close confirmation option added to misc panel.
- Default WASAPI audio device automatically follows Windows default audio device.
- Directory harddrives now use uaehf.device as a fake device driver (replacing non-existing uae.device), for example programs that query extra information (like SCSI Inquiry data) now get valid data.
- Directory filesystem harddrive fake block size dynamic adjustment now starts from smaller disk size, workaround for WB free space calculation overflow when partition is larger than 16G.
- Harddrive imager now also supports native (mainboard/expansion board) IDE connected CHS-only drives.
- Disk swapper config file data is restored from statefile.
- Cirrus Logic RTG horizontal doubling support, keeps aspect ratio in doublescan modes.
- Action Replay II/III state file support improved.
- Windowed mode resize enable/disable option.
- CDTV SCSI and SRAM options moved to Expansions.

3.6.x bug fixes:

- WD33C93 based SCSI controllers hung the system if controller didn't have any connected SCSI devices.
- Direct3D11 fullscreen mode didn't open if monitor was connected to non-default GPU. (For example laptops with Intel and NVidia GPU with NV GPU connected to external monitor)
- Direct3D11 fullscreen ALT-TAB refresh problems and other D3D11 fixes.
- 68030 MMU PLOAD was broken (Caused Amiga Linux crash at boot).

Older bugs fixed:

- On the fly switching from non-cycle exact to cycle-exact mode stopped emulation in certain situations.
- Fixed E-Matrix accelerator board RAM selection.
- If CD was changed and system was reset during change delay, drive become empty and new CD was never inserted. Mainly affected CD32 and CDTV.
- Reset when uaescsi.device CD was mounted caused memory corruption/crash in certain situations.
- Code analyzer warnings fixed (uninitialized variables, buffer size checks etc..)
- Old JIT bug fixed: many CPU instructions didn't set V-flag correctly. (Aranym)
- Inserting or removing USB input device caused crash in some situations.
- Softfloat FPU edge case fixes (FABS, FNEG with infinity, logarithmic instructions with NaN)
- Decrease/increase emulation speed input events didn't do anything.
- Toccata audio was not fully closed when reset/reset and caused crash if new config was loaded and started.
- Removed forgotten, useless and obsolete "The selected screen mode can't be displayed in a window, because.." check.
- Fixed WASAPI Exclusive mode audio glitches when paused/unpaused.
- Paula audio volume GUI volume setting was ignored if audio mode was mono.

New emulated expansions:

- C-Ltd Kronos
- CSA Magnum 40
- DCE Typhoon MK2
- GVP A1230 Series II
- Hardital TQM
- MacroSystem Falcon 040
- Xetec FastTrak


WinUAE 3.6.1 (04.03.2018)
=========================

3.6.0 bugs fixed:

- Crash when running on first Windows 10 release version (build 10240) .
- D3D11 mode fullscreen to/from windowed mode change crashes/blank screens.
- D3D11 mode on screen leds on the fly on/off switching.
- D3D11 mode screenshot via GUI button didn’t work.
- Floppy sound type selection was not loaded correctly from config file.
- It was not possible to create "DOS" file names like "AUX" to directory filesystem.

Older bugs fixed:

- Floppy sound used incorrectly empty drive volume level in certain situations.
- PPC emulation interrupt handling rewrite, fixes for example hang/crash problems with NE2000 based network adapters under OS4.
- Not all Advanced chipset options reset when compatible checkbox was ticked.
- Autoscale ignored small vertical display areas in very top of display in some situations.
- Fixed random crash when at least one Input panel custom event string was set, Restart was clicked and then emulation was started again.
- Blizzard SCSI Kit IV (possibly others) SCSI phase error in certain situations.
- Added better validation to clipboard sharing IFF parsing to prevent crashes if data is truncated.
– -joyport2 -config entry incorrectly used port 3 slot.
- Game Ports panel selected Custom input mapping reverted to none in some situations.
- Restart didn't completely free configured emulated network cards.
- Other misc bugs fixed.

New features:

- OCS/ECS only BPLCON2 undocumented feature: "illegal" PF1 or PF2 value is now accurately emulated in dual playfield mode.
- If selected D3D11 fullscreen refresh rate is "default": always prefer highest supported refresh rate.
- Optional threaded emulated RTG VRAM to host OS surface color space conversion/copy.
- Added "Identity" checkbox to Add harddrive panel. If ticked and ATA identity can be read (Direct IDE connection, compatible USB adapter): real ATA identity data is used in emulated ATA device instead of generic UAE generated and drive appears exactly as it does in real hardware (identical name, geometry etc).
- CHS-only IDE drives can now be mounted in emulation and they appear with real size and geometry when using USB adapters that allow identity read but does not support CHS (for example common JMicron based adapters).

New emulated expansions:

- A.L.F.3
- Elsat Mega Ram HD
- Progressive Peripherals & Software Zeus 040


WinUAE 3.6.0 (17.01.2018)
=========================

Core emulation updates:
- 68030, 68040 and 68060 full instruction and data cache emulation, with or without MMU emulation.
- 68030, 68040 and 68060 EC model partial MMU (transparent translation registers only) emulation.
- 68030, 68040 and 68060 MMU emulation performance improved (added extra translation caches).
- STOP-instruction CPU model specific undocumented behavior emulated when parameter does not have S-bit set.
- 68020+ DIVS/DIVU CPU model specific undefined overflow condition N and Z flags emulated.
- Undocumented 68881/68882 FMOVECR values emulated.
- 68020/030 BCD instructions undocumented V flag behavior fixed (68000 was already correct)
- Optional Toshiba Gary slow (chip ram like) Z2 IO and/or ROM space access speed.

Emulated hardware expansion updates:

- Added Cubo CD32 later revision hardware support, PIC copy protection, touch screen, NVRAM and RTC emulation. (TODO: Coin and ticket dispenser support, no hardware information available)
- Cubo CD32 is now an expansion device, added DIPs, PIC game ID/language and expansion device enable options.
- A2090 Combitec and MacroSystem 3rd party ROM update/adapter supported.
- DKB 1230/1240/Cobra and Rapidfire flash rom write support added.

New emulated hardware expansions:

- Ashcom Addhard (SCSI)
- Evesham Micros Reference (SCSI)
- FastATA 4000 MK I/II (IDE)
- Gigatron Arriba (IDE)
- Kupke Golem HD3000 (OMTI)
- Profex HD3300 (OMTI)
- Reiter Software Wedge (OMTI)
- Sprit Technology InMate (SCSI)
- Music Master dongle

Direct3D 11 support implemented:

- Requires Windows 7SP1 and later. Windows 7 requires KB2670838 (Available via Windows update as an optional update), Windows 8 and later does not need any extra packages like D3D9 support required (Ancient DX9 redistributable).
- Requires hardware level 9.1 or higher, which means most Windows 7 capable GPUs are supported.
- All Direct3D9 mode features supported (overlays, masks, custom shaders)
- Variable sync (G-Sync, possibly also FreeSync) supported in windowed mode.
- Many D3D9 custom shaders are supported automatically, some require manual modifications to work in Direct3D 11 mode.

Other new features and updates:

- Simple box art/screenshot config file support.
- If Wait for Blitter is enabled and blit size makes no sense, don't wait. Fixes long delay in Vital / Mystic.
- Added "CIA 391078-01" advanced chipset checkbox. This CIA revision has a bug in IO port output mode, reading output mode port will always read output mode data state. Other models, including original DIP 8520, 391078-02 and Akiko internal CIAs read IO pin external voltage level as documented. This can affect "bad" mouse left button/joystick fire button reading code (not working or stuck button). Used in A600. A1200/A4000 can have -01 or -02 revision.
- Added ATAPI Tape drive emulation.
- CD SCSI emulator READ CD-DA and READ CD-DA MSF commands emulated.
- Expansion device GUI changes are now always activated after hard reset.
- uaehf.device hardfiles/harddrives unit number is now user configurable.
- "Include CD and FMV Audio" and/or sound mode change on the fly when CD or FMV audio is playing is now supported.
- Debugger assembler support (a) and some other misc debugger updates.
- Optional non-rawinput mouse and keyboard mode is back (-norawinput_all)
- Added Misc panel option to show WinUAE in Windows shutdown/logoff screen (Vista or newer) if emulation session is active.
- JIT Direct is allowed in CyberStorm PPC configuration but it also disables CSPPC MAP ROM hardware feature.
- Ability to image CHS-only IDE drives using USB adapters that don't support CHS-only drives. (Common side effect is drive being detected but it appears as zero size drive in Windows Disk Management)

Bugs fixed:

- It was not possible to override Z2 RAM board autoconfig data if board had built-in manufacturer/product ID defaults.
- It was not possible to change existing path with Select Directory/Select Archive or Plain File buttons.
- Fixed 64-bit version random crashes that usually happened with some shell extensions.
- Z3 RAM in manual mode was completely broken.
- UAE directory harddrive/hardfile KS 1.2 autoboot hack didn't work without extra reset if UAE autoconfig board wasn't first board in autoconfig chain.
- 68030 data cache emulation corrupted data if write was cached, write size was word or long and address was odd.
- 68040/060 without FPU: many FPU instruction F-line exceptions generated incorrect stack frames.
- ECS Denise BPLCON2 ECS-only bits (for example KILLEHB) were masked unless AGA was also selected.
- Obsolete IDE FORMAT TRACK command fixed.
- GamePorts panel custom mapping incorrectly parsed joystick autofire state from config file.
- Directory filesystem ACTION_SET_DATE failed to change date stamp if file was read-only.
- 68020 memory cycle exact CPU speed slider is again partially working, CPU speed can be reduced but not increased.
- GamePorts panel custom mapping incorrectly parsed joystick autofire state from config file.
- uae-configuration joystick port (joyportx) modification only queued but didn't apply changes.
- uaeserial.device crash fixed. DTR/RTS state now match serial.device behavior when device is opened.
- Fixed uaegfx VRAM size check, some modes that almost filled whole VRAM didn't appear in resolution list.
- uaenet.device didn't close low level ethernet handles when Amiga was reset, causing duplicate packets.
- Bitplane overrun condition triggered incorrectly in rare situation where bitplane DMA is enabled after DDFSTOP on OCS
- Tape drive emulation fixes. Fixes Amix install error if last file on tape was selected for install.

AVI recording bug fixes and updates:

- First avioutput recorded frame was sometimes partially corrupted.
- When saving state with avioutput active: last frame before state save was not recorded.
- Number of avioutput frames buffered (waiting for compression thread processing) counter was reset periodically which caused lost frames (and leaked memory) in recorded video if CPU was not fast enough.
- Delay initialization until first display frame or sound buffer recording request comes, previously "before filtering" option may have used wrong display size in some situations.
- Uncompressed video selection is not forgotten anymore.
- First frame was not rendered (and also not recorded) if statefile was restored when emulation was already running.
- If emulator state was changed (debugger breakpoint, statefile save etc..), last frame before state change was not recorded.
- File splitting (2G limit) incorrectly flushed sound buffers causing random sound glitches.
- Added -max_avi_size <bytes> -command line parameter to set split size.
- If recording was started and GUI was never opened in same session, sound recording rate become 44100Hz, causing AV syncronization issues if real rate was not same.

and more.


WinUAE 3.5.0 (15.06.2017)
========================

New emulated hardware

- Comspec SA-1000
- California Access Malibu
- DKB RapidFire
- M-Tec AT-500 Megabody

New features

- Softfloat FPU emulation mode. Bit perfect FPU emulation (except transcendental functions), including full arithmetic exception support. (Co-operation with Previous emulator author)
- Lightpen emulation absolute coordinate HID (USB light guns) and touch screen device support.
- American Laser Games second player and Actionware dual light gun adapter emulation.
- Real harddrive mount lock option. Enables full exclusive access even if drive has Windows mounted FAT partition(s).
- winlaunch.lib is now built-in feature and is also 64-bit compatible.
- Show [Paused] in windowed mode title bar when in pause mode.
- If statefile is loaded with one or more floppy images that can't be opened: keep fake disk in drive (like previously) and ask for new disk path when missing disk is accessed for the first time.

Custom chipset features emulated

- AGA FMODE>0 unaligned bitplane and sprite pointer behavior implemented, resulting display corruption is now 100% accurate.
- BPLCON4 XOR mask special case in HAM6/8 or EHB modes.
- Loading blitter B-DAT manually when B-shift was nonzero.
- Lightpen hardware is now cycle-exactly emulated.
- Sprite special case when DMA mode sprite's start X-coordinate is less than sprite's DMA slot position.
- Audio interrupts are delayed by 2 cycles.

Feature improvements

- 68020+ T0 trace mode is now fully emulated.
- 68020 cycle exact mode adjustments.
- Memory cycle exact mode mode accuracy improved
- Implemented previously unimplemented bsdsocket.library emulation sendmsg() and recvmsg().
- Recursive mode ROM scanner now skips directories starting with dot.
- MMU emulation can be now switched on/off on the fly.
- Release all currently pressed keys when emulation pauses.
- Added memory cycle-exact Quickstart step for A1200 and CD32 configurations. Less CPU heavy than full cycle-exact and usually not much more worse (or better). At least not until 68020 CE gets better.
- Escape old style directory and hardfile paths if it contains ",".
- Masoboshi MasterCard fully implemented, including DMA support.

Bug fixes

- FM801 16-bit audio corruption.
- A2090 ST-506 emulation.
- Possible crash when display was very wide with bitplane DMA overrun condition.
- Fixed crash when sound card audio play started and channel mode was mono and "Include CD and FMV audio" was ticked.
- Fixed crash when accessing accelerator board SCSI IO region without any added SCSI device(s).
- Fixed crash if Blizzard accelerator on board memory size was set to zero.
- JIT was not 512k or 1M Chip RAM compatible.
- Manual RAM configuration GUI didn't accept smaller end address than current board size.
- Manually configured but disabled (size zero) Z2/Z3 banks were added to system.
- Apollo 1240/1260 memory address space fixed
- PC bridgeboard NE2000 boot crash fix.
- Windowed mode mouse does not anymore hit hidden barriers if window is partially outside of desktop or uncaptured if window is on top of task bar.
- If Custom autoconfig board order was enabled, expansion devices custom config setting(s) was not saved correctly.
- 68000 address error stacked PC was not correct in some read-modify-write instructions
- Untrap middle mouse button option was stuck.
- GUI listview column width calculation used default font size, not selected font.
- 68030 CE/prefetch mode cache access bug fixed.
- G-REX and Cirrus Logic graphics board state was reset if RAM or HW Info GUI panels were opened after emulation was started.

And more…


WinUAE 3.4.0 (21.12.2016)
=========================

New emulated hardware:

Graphics adapters:

- ColorBurst
- Harlequin
- OpalVision (OpalPaint, King of Karate)

Accelerator boards:

- Blizzard 1230 MK II and III.
- IVS Vector 68030.

HD controllers:

- Blizzard 1230 MK II and III SCSI Kit.
- Buddha.
- Expansion Systems Dataflyer Plus.
- FileCard 2000/OSSI 500
- Mainhattan A-Team.
- Microbotics HardFrame.
- SCRAM 500/2000.

Network adapters:

- AmigaNet.
- Ariadne.
- Ariadne II.
- LAN Rover/EB920.
- NE2000 compatible PCMCIA.
- NE2000 compatible ISA (x86 bridgeboard compatible).
- X-Surf and X-Surf 100 (Partial).

American Laser Games arcade game hardware:

- LaserDisc player (video file)
- Genlock (using video file genlock mode)
- Light gun and buttons.

New features:

- RAM/RTG RAM handling updated, all size combinations are now supported.
- Autoconfig board GUI list with custom sorting support.
- RAM Z2/Z3 board full autoconfig data customization support.
- Up to 4 Z2 and Z3 RAM boards can be enabled simultaneously.
- Multiple display and sound boards can be now enabled simultaneously.
- Genlock realtime custom image, video file or capture stream overlay.
- Genlock mode screenshot/video alpha channel support.
- Accelerator board 68000 fallback mode supported.
- Game Ports panel custom mapping autofire support.
- Network access on screen led.
- Single step (emulate one frame + pause) input event.
- MIDI and Genlock video volume control.

Updates:

- Reduced input latency.
- Reduced WASAPI sound mode latency.
- WinPCap network mode now uses generated local MAC address, no more MAC conflicts between Windows and emulated Amiga.
- If some RAM board is not JIT Direct capable, only board’s access mode changes to JIT Indirect. Global JIT Direct option is not switched off.
- Most RAM size/position related JIT Direct restrictions are gone.
- Environment variables in file paths (%VAR%) are now always expanded.
- Implemented AGA only bitplane DMA overrun emulation (Moon Child).
- Host path 260 character limit removed (Windows 10 v1607+ only).

Bug fixes:

- Shortcuts with Shift key work again.
- Custom Game Port remapping does not disappear mysteriously anymore.
- Mounting file with size less than 512 bytes as a harddrive work again.
- CDTV statefiles fixed.
- On the fly directory/archive mounting only worked once under OS4.x.
- Worms DC and ACSYS (possibly others) graphics glitch fixed.
- Bad sprite collision optimization fixed (Jumpman Junior).
- Stop PPC emulation first, before freeing any emulation resources to prevent random crashes at exit.
- FPS.Adj config file handling fixed.
- ATAPI CD emulation odd data size fix (HDToolbox hang)
- default.uae with unplugged device: set to none, not layout A.

And more…


WinUAE 3.3.0 (06.06.2016)
=========================

New features:

- New optional "indirect" UAE expansion trap system, fully compatible
  with OS 4.x, virtual memory and some debugging programs.
- PC Bridgeboard disk drive raw image support. (ipf, ext adf,...)
- Monochrome video out emulation, including A1000 color/mono video
  out software control (BPLCON0 COLOR bit).
- Dark palette fix option to correct colors of badly ported Atari ST
  games (Midnight Resistance etc..)
- Official CSPPC/BPPC flash updater can be used to install full ROM
  image without having existing ROM image file.
- Custom input events can execute Amiga-side commands and scripts.
- Windows clipboard to emulated Amiga keyboard paste support.
- Variable refresh rate optimized vsync mode (G-Sync/FreeSync).
- Black frame injection is supported in variable refresh modes.
- IVS Trumpcard Pro/GrandSlam SCSI emulation.

OS4.x supported UAE expansions:

- Directory harddrives, including on the fly insertion/removal.
- CDFS CD mounting.
- Clipboard sharing.
- uaegfx RTG.
- uaehf.device hardfiles.
- Virtual mouse driver/magic mouse/tablet mode.
- uaenet.device.
- uaeserial.device.
- uaescsi.device.
- uae.resource.
- uaenative.library.

Thanks to all who donated.

NOTE: Performance is not (and can't be) as fast as with m68k AmigaOS,
especially with directory harddrives, due to slower, much more
complex UAE to/from native code context switch trap system.

Updates:

- Game Ports panel input customization is finally very intuitive.
- On the fly input device insertion/removal improvements.
- Many input device handling updates and fixes.
- Faster screenshot/capture in after filtering mode.
- Continuous screenshot mode.
- CD32 Akiko chip low level emulation compatibility improved.
- Nero .nrg CD image support.

Bug fixes:

- Hardware RTG emulation rendered same frame twice in some situations
  causing slow performance.
- Amithlon partition type (0x78/0x30) support works again.
- Some storage devices failed to mount as a harddrive.
- AGA subpixel scrolling glitches.
- Miscellaneous custom chipset emulation fixes.
- AGA mode HAM6 colors were not 100% accurate.
- Some programmed custom chipset display modes crashed.
- Direct3D mode DirectX9 not installed warning corrupted memory.
- Fullscreen + paused + enter GUI: GUI was invisible.
- Display panel gamma value calculation fixed.
- CDFS automount didn't mount CDs with empty label.


WinUAE 3.2.2 (21.12.2015)
=========================

3.2.0 bugs fixed:

- JIT FPU 32-bit and 64-bit compatibility fixes.
- Interlace mode blank screen in some configurations.
- Slirp network mode high CPU usage.
- Some programs that use AGA subpixel scrolling had horizontal
  jittering.
- Per-monitor high DPI update still caused repeated GUI window
  closing/opening.

Other bug fixes:

- Game controllers suddenly stopped working. Most likely only happened
  under Windows 10 and only in some setups.
- MIDI out devices missing (x64 only).
- Serial port transmit buffer was not always flushed.
- 68020+ BFFFO undocumented offset calculation fixed.

Updates:

- AVIOutput in capture before filtering mode: width is now always divisible
  by 16 pixels and height is always even for best codec compatibility.
- Useless, very basic and invisible touch screen mouse and joystick overlay.
- Load config with joystick that is not connected, fall back to previously
  loaded (default.uae) setting instead of always falling back to keyboard
  layout A.
- Out of bounds RTG coordinates are now clipped to valid region instead of
  rejecting whole operation.
- Keyboard names (if available) are now listed in Input panel device list.
- Built-in HRTmon update v2.36.
- Phoenix Board SCSI emulation.


WinUAE 3.2.1 (19.11.2015)
=========================

3.2.0 bugs fixed:

- Loading statefile with enabled FPU crashed.
- Custom chipset display was shifted in some rare situations.
- 64-bit version didn't load DLLs without x64, _64,... extension in name.
- RTG board was not fully disabled if configured RAM config was incompatible.

Other bug fixes:

- 68040+ CPU mode statefile save buffer overflow.
- Unaligned supervisor stack was not allowed in 68020+ modes.

Updates:

- Reduce RAM size and try again if Blizzard RAM allocation fails.
- Switch off triple buffering if windowed mode with DWM active.


WinUAE 3.2.0 (11.11.2015)
=========================

Major updates:

- 64-bit compatible 680x0 JIT.
- 64-bit compatible PPC emulation.
- PCI bridgeboards.
- Commodore PC/AT bridgeboards.
- A2410 RTG Zorro II board
- DCTV video port graphics adapter (Partially)
- Genlock "emulation", including transparency and ECS genlock features.
- Directory harddrive and hardfile KS 1.2 and older full autoboot support.

New emulated expansion hardware:

Accelerator boards:
- DKB Wildfire

HD controllers:
- 3-State Apollo 500/2000
- A2090 previously missing ST-506 support
- Elaborate Bytes A.L.F.
- Kupke Golem Fast SCSI/IDE
- Mainhattan Data Paradox SCSI
- Multi Evolution 500/2000
- OMTI-Adapter
- Spirit Technology HDA-506
- Tecmar T-Card/T-Disk
- Vortex System 2000
- Xebec 9720H

Commodore x86 bridgeboards:
- A1060 (A1000 Sidecar)
- A2088
- A2088T
- A2286
- A2386SX

x86 bridgeboard expansion devices:
- AT IDE HD controller (A2286 and A2386SX)
- XTIDE Universal BIOS compatible IDE HD controller.
- ISA VGA display card (Cirrus Logic GD542x based)

PCI bridgeboards:
- G-REX
- Mediator 1200/4000
- Prometheus

PCI bridgeboard compatible PCI cards:
- FM801 sound card
- ES1370 (SB128) sound card
- RTL8029 network card

Notes:

- SSE2 capable CPU is now required.

Other Updates:

- CD and sound card emulation audio output quality improved.
- 68020/030 prefetch emulation improved.
- High DPI display support improved.
- AGA subpixel scrolling emulated.
- Support shortcut paths (.lnk) in command line.
- More undocumented chipset features supported.
- Right control = right Windows key option.
- Memory accesses only -cycle-exact mode.
- UAE devices (uaeserial etc) are compatible with KS 1.2 and older.
- Improved compatibility with very old A500 config files.

Bug fixes:

- WinPCap network mode didn't detect any devices.
- 68030 data cache emulation fixes.
- Custom to/from RTG mode switch didn't check for filter changes.
- JIT on/off on the fly change (outside of GUI) was unreliable.
- Keyboard layout changed (B/C only) during device re-enumeration.
- D3D9 non-shader mode forgot scanline texture when switching modes.
- Audio wave recording created huge broken wave files.
- It was not possible to select HDF PCMCIA SRAM and IDE options.
- Flash ROM and RTC file dialogs didn't allow creation of new files.


WinUAE 3.1.0 (07.06.2015)
=========================

New emulated expansion hardware:

SCSI controllers:
- A2090/A2090a (ST-506 not supported)
- AdSCSI Advantage 2000
- Archos ADD-500
- C-Ltd A1000/A2000
- GVP Series I (Three models)
- GVP Series II
- Expansion Systems DataFlyer 1200/4000 SCSI+
- HK-Computer Vector Falcon 8000
- J.Kommos A500
- Kupke Golem
- Masoboshi MC-702 (Incomplete)
- Microbotics StarDrive (Clock not emulated)
- Preferred Technologies Nexus
- Protar A500
- RocTec RocHard RH800C (SCSI+IDE)
- SupraDrive (All five models)

IDE controllers:
- ICD AdIDE
- AlfaPower/AT-BUS 508/2008/AlfaPower Plus
- M-Tec AT 500
- Masoboshi MC-302/MC-702 (Incomplete)
- RocTec RocHard RH800C

Accelerator boards:
- ACT Apollo 1240/1260
- DKB 1230/1240
- RCS Fusion Forty
- GVP A3001
- GVP A530
- GVP G-Force 030
- Kupke Golem 030 A500

Video port display adapters:
- Archos AVideo 12
- Archos AVideo 24 (Animation features not implemented)
- Black Belt Systems HAM-E and HAM-E Plus
- Newtronic Technologies Video DAC 18
- Impulse FireCracker 24

Miscellaneous expansions:
- Toccata Zorro II sound card
- Nordic Power v3.2 freezer cartridge
- Pro Access v2.17 freezer cartridge

New features:

- CD, CD32 FMV and Toccata audio are now optionally mixed with Paula
  audio stream. Sound sync is not lost even when emulation speed
  changes and sound is included with audio recording.
- Multiple SCSI/IDE expansion boards can be enabled at the same time.
- Floppy sound per-drive empty/disk inserted volume control.
- Added partial A1000 Velvet prototype support. Unfortunately
  currently no known Velvet boot disks exist.
- GUI Filter panel configurable overscan region blanking.
- Hardfile ATA and SCSI version configuration option.
- Fullscreen GUI option.
- If system has touch screen (Windows tablet for example), touching
  top of screen more than 2 seconds will open GUI.
- GUI Paths panel portable mode checkbox enabled.
- Configured but disconnected game controller is remembered.

Updates:

- Custom chipset display emulation partially rewritten, many
  A1000 vs OCS vs ECS chipset undocumented edge cases are now
  fully emulated.
- AMAX ROM dongle emulation improved.
- CD and disk image volume label is shown in status message bar.
- CPU Idle feature rewritten, lower CPU usage.
- More reliable simultaneous on the fly media insertions/removals.
- Action Replay 2/3 emulation improved.
- Added 1/2, 1/4 and 1/8 filter panel "integer" scaling options.
- Audio master volume is now real master volume control. Paula,
  CD and AHI are sub-volume controls.
- Optionally disk saveimages can use same directory as parent image.
- More accurate 68000 bus/address error stack frame undocumented fields.

3.0 bugs fixed:

- Some CPU halted conditions caused emulator hang.
- Chip RAM/Slow RAM size change on the fly crash.
- Multiple other crash bugs fixed.

Other bugs fixed:

- Low level SCSI emulation fixes and updates.
- RTG mode screenshots in 16-bit host color depth mode had wrong colors.
- Real CD drive as emulated ATAPI or SCSI returned wrong last block.
- Graffiti corrupted display in non-AGA modes.
- Some programs had shifted display in some configurations (For example
  Gloom AGA, Worms Directors Cut title screens)
- Picasso IV graphics corruption in OS4 16-bit modes.
- Picasso IV mode switch out of bounds memory access crash (OS41FE).
- Serial port emulation lost characters in some situations.
- Branch FPU instructions didn't work in more accurate CPU modes.
- AVI recording audio/video sync problems fixed.
- Stuck key if "Mouse captured: emulation paused" was ticked.

And much more...


WinUAE 3.0.0 (17.12.2014)
==========================

New emulated hardware:

- PPC CPU emulation. CyberStorm PPC and Blizzard PPC boards emulated
  using QEMU PPC core, on-board SCSI supported.
- Other accelerator boards emulated (Blizzards, CyberStorms, Warp
  Engine, TekMagic, A2630), including on-board SCSI if available.
- More SCSI expansion boards emulated (Fastlane, Oktagon, Blizzard Kit IV)
- CD32 Full Motion Video cartridge emulation.
- CDTV-CR emulation.
- A590 XT hard drive emulation.

New features:

- Show on screen message when disk or CD is inserted or ejected or input
  device is autoswitched.
- Added null serial port mode that connects two WinUAE instances running
  on same PC.
- Fastest possible CPU speed mode is now available with cycle-exact mode,
  CPU is fastest possibly, only chip memory and chipset is cycle-exact. 
- Immediate blitter is available in cycle-exact modes.
- 68040/060 with more compatible emulates instruction cache, MMU supported.
- 68000/68010 + 32-bit address space is supported.
- Optionally game controllers can be kept active when WinUAE does not have
  focus.
- Implemented secondary Z2 RAM board, for example 6M Z2 RAM + 2M Z2 RTG board
  combination is now possible.
- Added "history" menu to filesystem, hardfile and tape drive path selection.
- Added CDTV/CDTV-CR/CD32 turbo CD read mode.
- Multiple SCSI controllers can be active simultaneously.

Updates:

- Programmed chipset display modes accuracy improved.
- Uncompressed CHD harddrive image write support.
- Implemented previously unavailable small Z2 RAM board sizes (64k to 512k)
- Z3 board emulation supports official autoconfig space, required when using
  PPC-only operating systems.
- 68000 cycle exact mode updates.
- Improved cycle counting in 68000 more compatible mode.

Bugs fixed:

- 68060 with "Unimplemented CPU emu" checkbox ticked: 68060 only unimplemented
  instructions were not emulated normally.
- Screenshot with D3D shader filter enabled always took filtered screenshot.
- SCSI CD READ CD command only worked if audio track was first track of CD.
- Hard reset didn't reset map rom loaded KS ROM data.
- AGA sprites in borders were clipped incorrectly in some situations (2.8.0)
- Autofire always on mode crashed.
- PCMCIA IDE emulation was broken long time ago.
- uanet.device + slirp combination was unusable.
- Directory filesystem statesave support open file path handling fixed.
- AVI audio recording always used PCM mode.

And much more small updates and fixed.


WinUAE 2.8.1 (18.06.2014)
=========================

2.8.0 bugs fixed:

- JIT on/off on the fly switching was unreliable.
- A500 reading write-only/non-existing registers method introduced in 2.8.0
  was incorrectly also used in AGA modes.

Updates:

- Fast CPU mode audio DMA wait hack compatibility improved (workaround for
  programs that use CPU delay loops in audio code)
- Some chipset emulation updates, Critical Mass / Parallax finally works.
- AROS ROM updated.

New features:

- Directory filesystem MorphOS compatible >4G file size DOS packet support.
- Paths panel relative path mode now supports relative paths that point
  outside of winuae root directory.

Bug fixes:

- Filter modes in DirectDraw crashed in some situations.
- Disk insert using GUI after emulation was started inserted disk in
  write protected state.
- Quickstart disk eject button was unreliable.
- Video recording with "Capture before filtering" unticked used wrong
  video size.
- "Toggle between mouse grabbed and un-grabbed" input event fixed.


WinUAE 2.8.0 (05.05.2014)
=========================

Standard A500 compatibility is now practically as good as it can get
without knowledge of blitter's undocumented internal logic design.
(Mainly problem with some demos that accidentally modify blitter
registers while blitter is already active)

New features:

- Full A4000T and A4091 NCR53C710 SCSI emulation.
- A590/A2091 and A4091 boot ROM GUI selection.
- Separate graphics filter settings for native and RTG modes.
- 256k ROM image inserted in floppy drive emulates A1000 KICK disk.
- Super Card Pro image file support (.scp).
- SLIRP network inbound port support (default: 21, 22, 23 and 80, others
  can be added by editing configuration file)
- Input panel previously toggle-only events can be optionally set to on
  and off state, audio/video recording input event added.
- Joystick/joypad can be used to control light pen cursor.

Updates:

- Remaining 68000 cycle-exact mode timing fixes. 
- 68000 reading from write-only or non-existing custom register
  compatibility improved.
- Big chipset edge case compatibility update, for example demos with
  vertical "copper" bars work perfectly, real hardware glitches in
  horizontal scaling are now accurately emulated and much more.
- 68040/68060 without emulating unimplemented FPU instructions is now
  fully compatible with Motorola FPU emulation library, FSAVE special
  FPU exception stack frames implemented.
- Programmed modes (Super72 etc) now automatically select best fit horizontal
  resolution and is more compatible with different filter modes, also display
  positioning is improved.
- Recently dumped Arcadia arcade system ROM images supported.
- Debugger full FPU and 68020+ bitfield, and other previously missing
  68020+ only instructions supported in disassembler.
- Magic mouse + mousehack mode now always stops keyboard input when mouse
  is outside of emulation window, even if window still has focus.

2.7.0 bug fixes:

- Unformatted partition hardfiles didn't mount and had incorrect geometry.
- Resolution autoswitch was not compatible with new interlace scanline modes.
- 68020 CE mode FPU exceptions fixed, broke for example KS 1.3 FPU detection.
- Sound glitches in games that use OCS compatible "fake 60Hz" screenmodes.

Bug fixes:

- Keyboard led indicator state syncronization problems fixed.
- Fixed very rare JIT FPU bug introduced in 1.2.
- Vertical centering works again, improved horizontal centering.
- Full tablet emulation boot guru fixed.
- Graphics glitches in some borderblank and border sprite modes.
- Master floppy write protection setting was not loaded from config file.
- Some narrow AGA modes clipped some pixels from right edge of display.
- A590/A2091 didn't work in all supported CPU modes.
- CPU polled disk reading was unreliable in some situations.


WinUAE 2.7.0 (05.12.2013)
=========================

New features:

- Cirrus Logic SVGA chip based hardware graphics board emulation.
  - Use graphics board in emulated Amix, Linux, NetBSD and others.
  - Use native CyberGraphX, Picasso96 and EGS RTG software in emulation.
  - Emulates following boards: Picasso II, Picasso II+, Picasso IV (flash
    rom image required), Piccolo, Piccolo SD64 and EGS-28/24 Spectrum.
  - Text mode is also emulated (Linux/NetBSD etc.. text console support)
  - Based on QEMU Cirrus Logic emulation.
- SCSI tape drive emulation.
  - Can install Amix without hacks.
  - Both reading and writing supported.
  - Works also with most backup software that supports tape drives.
- SLIRP user mode NAT emulation.
  - A2065 and uaenet.device emulation without need for host side
    extra drivers.
- 68020 cycle-exact mode emulation rewritten to better match real hardware,
  accuracy improved, more improvements planned in future versions.
- Added GUI button that opens small disk image information window.
- GUI open log file and open error log buttons added.
- New WiX based installer.

Updates:

- Two new field based interlace options added, reduces interlace artifacts.
- Chipset emulation compatibility improved, more undocumented chipset
  corner cases emulated.
- Game Ports panel input configuration improved.
- Built-in HRTMon and AROS ROM replacement updated to latest versions.
- Do not wake up all sleeping harddrives if loaded config has mounted
  physical harddrives (or memory cards) that are not currently connected.
- SCSI HD and CD emulation compatibility improved.
- SCSI HD/CD/TAPE statefile compatibility improved.
- CIA TOD counting is now cycle-exact.
- 68020/030 cycle-exact/prefetch is fully compatible with FPU emulation.

2.6.x bugs fixed:

- Some OFS formatted hardfiles didn't mount.
- Wired XBox 360 pad (possibly others) missed input events.

Other bugs fixed:

- All Input panel events stopped working in some situations.
- RTG mode video recording display size fixed.
- Same game controller was inserted in both joystick ports if
  loaded config file had non-existing controller in second port.
- Built-in lzx decompressor didn't always decompress last byte of file.
- CD CUE file parsing fix, some images had incorrect CD audio timing.
- Output panel crashed on some systems.
- Crash when system was reset if it caused immediate PAL/NTSC mode change.


WinUAE 2.6.1 (19.06.2013)
=========================

2.6.0 bugs fixed:

- OFS formatted partition hardfile didn't mount.
- Some AGA demos had horizontally duplicated graphics.
- Direct3D hq2x shader filter did nothing.

Other bugs fixed:

- Reset didn't fully reinitialize SCSI emulation.
- A3000 SCSI emulation compatibility improved, original A3000 1.4 ROM
  driver hung during writing to the disk.

New features:

- Input panel Invert option added (press becomes release and vice versa,
  joystick and mouse movement is inverted)
- FPU unimplemented instruction emulation can be optionally disabled,
  emulates real 68040/68060 CPU behavior.
- >2M Chip RAM is now merged with original Chip RAM pool.


WinUAE 2.6.0 (16.05.2013)
=========================

New features:

- Full 68030, 68040 and 68060 MMU emulation. Amix, Linux, NetBSD, Enforcer,
  WHDLoad MMU option and more fully working.
- Game Ports panel Remap GUI rewritten, more intuitive, supports manually
  added events.
- SCSI and ATAPI (IDE) CD drive emulation.
- Built-in full CHD CD and HD image support. HD image support is read-only.
- Partial partition hardfile on the fly eject/replacement support, requires
  filesystem that has removable drive support.
- Multiple Direct3D shader filters can be enabled simultaneously, optionally
  shader can be now run after scaling and filtering.
- Directory filesystem shortcut (.lnk) and symbolic links are mapped to
  Amiga soft links.
- Added support for mountlist-like hardfile configuration files.
- 100Hz+ vsync mode black frame insertion support, reduces LCD motion blur.

Updates:

- A590/A2091/A3000 SCSI emulation compatibility improved. (Amix, NetBSD etc..)
- A2065 network adapter compatibility improved. (Early NetBSD versions)
- Multithreaded IDE and SCSI emulation, slow read or write operations won't
  temporarily pause the emulation anymore.
- When CPU double faults, emulated CPU is halted instead of forcing instant
  emulated hardware reset.
- Custom chipset emulation improved.
- Full Amiga file timestamp resolution (1/50s) support on FAT directory
  filesystems.
- Max supported resolution increased to 8192*8192 (NV Surround/AMD Eyefinity)
- CD32 CD detection works again in JIT mode.
- AROS ROM replacement updated.

Bug fixes:

- If display mode switched from RTG to native (or vice versa) and WinUAE window
  had no focus: emulation incorrectly started receiving keyboard input.
- 1.5M chip ram option didn't work.
- GamePorts panel Swap Ports button cleared custom mappings.
- 68060 CPU and More compatible checked was unreliable.
- 68040/68060 no FPU/FPU disabled exception stack frame fixed.
- A2024 and Graffiti emulation memory leak fixed.
- FPU rounding mode was reset when using filters.
- Some USB game controllers had ghost events (move axis, button event is
  triggered or vice versa)
- CD32 CDs with multiple tracks didn't boot.


WinUAE 2.5.1 (22.12.2012)
=========================

2.5.0 bugs fixed:

- 1G RTG RAM size was rejected.
- Windows mouse cursor becoming visible in windowed modes.
- 2.4.x and older versions allowed higher Z3/RTG total memory under 32-bit Windows.
- Maprom feature crashed in JIT mode.
- CDTV emulation didn't work.
- Power led state was incorrect.

Other bugs fixed:

- Inserting or ejecting USB game controller or mouse deleted all custom Game Ports panel configurations.
- Fixed DirectDraw fullscreen mode problems if using secondary monitor positioned on left side of primary monitor.
- SCSI emulation read commands returned wrong data if CD/CD image had more than one track.
- Fixed mouse cursor jumping to opposite direction if it was moved to same direction long enough.
- File comments and protection flags wasn't read correctly from _UAEFSDB.___ files. (if non-NTFS drive)
- Windowed mode status bar had gap on Windows Vista classic theme.
- Epson matrix printer emulation red and blue colors were swapped.
- lzh/lha archive MSDOS-style timestamps supported.

New features:

- Directory filesystem full Amiga 1/50s datestamp resolution support, previously resolution was only 1s. (NTFS and archives only)
- Mount drag'n'dropped archive file as a directory harddrive only if removable drive support is enabled, without harddrive
  support attempt to mount as a disk image in DF0:.


WinUAE 2.5.0 (02.12.2012)
=========================

New features and updates:

- GUI is finally fully resizeable! GUI font is configurable.
- GUI position, size and fonts saved separately for windowed, fullwindow and fullscreen modes.
- GUI CD audio volume control added.
- Syncronize clock option does full time sync when emulation is unpaused or exited from GUI.
- Memory configuration can be fully modified (on the fly, loading state file or using Restart button)
  without need to rerun the emulator.
- RTG screenshot and video recording directly from emulated VRAM if capture before filtering ticked.
- RTG monitor (if multiple monitors) selection added to GUI.
- RTG hardware sprite and hardware vblank emulation are now optional.
- Chipset "Wait for Blitter" too fast CPU workaround added, enabled by default, fixes most graphics
  glitches if program does not wait for the blitter, more compatible than immediate blitter.
- Optional fake 1G directory harddrive size limit for old programs that think drive is full or has
  negative space if drive is bigger than 2G. Can be changed on the fly.
- Added disable notification icon option.
- Added blank unused displays(s) (opens full screen topmost black window(s)) option.
- CD32 CD controller emulation improved (Missing Guardian and Universe CD32 CD audio)
- AutoVSync 100Hz/120Hz capable monitor support added.
- Low latency vsync and legacy vsync stability improved.
- Full PC hardware interlaced mode support.
- 68060 missing integer instructions are not anymore emulated if more compatible CPU checkbox is checked.
- Chipset emulation improvements. (EyeQlazer/Scoopex, Blerkenwiegel/Scoopex, No Way Demo/Academy,
  Brian the Lion AGA, SuperPlus monitor mode)
- Sometimes appearing Windows "no disk in drive" dialogs that point to missing harddrive path are gone.
- Audio emulation quality improved.
- Parallel port sampler emulation audio quality improved.
- GamePorts panel remap option allows separate axis configuration and multiple events.
- Game Ports panel Test mode can be used to test any kind of input event, not just joystick events.
- Lots of Input panel improvements. (qualifiers, custom events etc)
- Easy to use debug logging option added to Paths panel.
- Optional MIDI In to Out routing added.
- 64-bit build supports 2.5G address space, allowing up to 2G of Z3 expansion memory.

2.4.x bugs fixed:

- Add Harddrive dialog didn't list all harddrives on some Windows XP systems.
- New CDFS didn't work with DVDs (2G size limit) and Joliet CDs.
- Extended ADF write support was accidentally disabled.
- "ALT-TAB or middle mouse button untraps mouse - F12 opens settings" window title was missing.
- Directory filesystem 64-bit seek packet implementation was broken.
- USB HID game controller [-] and [+] input axis movement was broken.
- SPTI + built-in CDFS crash.
- uaescsi.device error codes fixed (MakeCD)

Older bugs fixed:

- RTG palette (if 8-bit mode) wasn't saved to statefile.
- Disable screen saver option haven't worked properly since 2.0.
- Warp mode didn't work in all vsync modes.
- CD image mounter MDS image CD audio tracks didn't play if subchannel data was not included,
  MDS image data tracks with subchannel data didn't work at all.
- CD/CD image on the fly switching was unreliable. (Again)
- Random unexplained graphics glitches when cycle-exact CPU enabled and bsdsocket emulation was in use.
- Some chipset mode on the fly configuration changes caused blank screen when returning back to RTG mode.
- Volume control in WASAPI exclusive mode didn't work.
- Windows XP blank screen after ALT-TAB back to Direct3D fullscreen mode.
- Direct3D pixel alignment errors in some modes. (Again)
- Many Input configuration fixes.
- Windows Mouse mouse mode sometimes stopped at invisible barriers.
- CD32 CD audio was delayed.


WinUAE 2.4.1 (09.05.2012)
=========================

"Traditional" x.x.0 bug fix update and some improvements.

2.4.0 bugs fixed:

- CDFS problems fixed. (crashes, wrong case if RockRidge or Joliet, truncated file comments)
- Fake 60Hz didn't work.
- Software filter major slowdown in higher resolutions.
- D3D overlay mask scaling artifacts in some resolutions.
- D3D "CRT" filters had bad geometry.
- Automatic resize resized continuously in interlaced modes.
- Some USB joysticks had multiple buttons with same name and dpad diagonal movement didn't work.
- Keyboard reset warning emulation didn't work.
- Legacy VSync works correctly again.
- Bsdsocket emulation gethostbyname("ip.address") random crash.

Other bugs fixed:

- Automatic scale/center/resize didn't work in ECS SuperPlus screen mode.
- OCS/ECS max hires overscan didn't show first 4 pixels. (ECS SuperPlus)
- 68020 cycle-exact mode statefile reliability improved. (Random "CPU trace" errors)
- 0.5M Chip RAM was detected as 1M in JIT mode.
- Mouse cursor jumping to top/left corner in some virtual machines when mouse button was clicked.

New features and updates:

- Fastest possible CPU mode (including JIT) throttle option (-10% to -90%)
- Approximate CPU mode speed adjustment (-90% to +500%). Replaces old CPU/Chipset adjustment.
- Fastest possible CPU mode timing improved.
- Low latency vsync stability improved.
- Internal display buffering system rewritten, PAL/NTSC vertical centering, even better screen
  positioning in programmed modes.
- Fullscreen (TV)/(Max) filter mode programmed mode and PAL/NTSC switching support.
- Custom Input Event autofire support.
- Switch to another monitor if multiple monitors with different resolutions and current RTG resolution
  is not supported by current monitor.
- CDFS statefile support implemented.
- Sound sync improved.
- Debugger basic math operator support (+-/*).
- Autoscaling improved (CD32 boot screen).


WinUAE 2.4.0 released (29.03.2012)
==================================

New features:

- VSync supported in fastest possible CPU and JIT modes, complete rewrite, fast, 100% jitter free.
- Built-in CD filesystem. Full Amiga CD compatibility, including audio tracks and Amiga Rock Ridge extension,
  without need for manually installed CDFS, completely replaces old CD option that mounted CD drives as
  read-only harddrives. NOTE: CD device names renamed to standard CDx: (Old was WinCD_x:)
- Commodore A2024 monitor emulation. (1024*1024 grayscale monitor)
- Individual Computers Graffiti emulation.
- PCMCIA IDE hardfile emulation.
- USB game controller low latency raw input mode is now the default. (Mouse and keyboard support was already
  implemented long time ago) Windows Vista and newer only. Custom input mappings may need resetting.
- PC keyboard mode, keys like home, end, pageup, pagedown etc are mapped to Amiga key codes.
- Input configuration qualifier key/button support. Any key or button can be configured as a qualifier
  and other key mappings can be configured to require one or more active qualifiers.

Updates:

- Programmed screen modes (DBLPAL, Multiscan etc..) display positioning and setup greatly improved.
- Performance improved in fastest possible CPU without JIT mode.
- Performance greatly improved when immediate blitter and fastest possible CPU is enabled and program
  does lots of small blits.
- Gayle IDE emulation IDE doubler mode compatibility improved.
- Sound syncronization updates, much more stable with VSync. (more updates planned in future)
- Fastest possible CPU mode audio glitch prevention hack updated. (WHDLoad IK+, Moonstone, Uridium II, etc..)
- Added pause emulation/disable sound option to active but mouse uncaptured state.
- RTG emulation optional ZorroII mode.
- UAE harddrive controller RDB harddrive "Do not mount" and "Bootable" options supported.
- Interlace mode handling and switching improved.
- Interlaced fields are matched in vsync modes if both Amiga mode and output device mode are interlaced.
- Lots more options can be modified on the fly using uae-configuration.
- Multiple display adapter/multiple monitor selection and support improved.
- GUI sound buffer range adjusted, non-linear scale, more smaller buffer sizes selectable.
- Joystick/mouse autoswitch also enabled in Input panel non-GamePorts mode.
- Native code execution disabled by default. Enable option in Miscellaneous panel.
- CPU Idle automatic limit added, no more slowdowns if it is set too low.
- Keyboard emulation improved, properly emulated handshake and lost sync state.

Bugs fixed:

- uaenet.device crash if opened without installed winpcap.
- Startup crash if more than 8 serial ports detected.
- Random hangs when switching cycle-exact mode on the fly.
- CD image/physical media change on the fly didn't always trigger notification correctly.
- Lots of bsdsocket emulation compatibility and multi-thread stability fixes (YAM hangs fixed)
- Directory filesystem reported file size was not updated until file was closed.
- Directory filesystem host-side memory leak fix.
- Some Advanced Chipset options were not correctly overridden in compatibility mode.
- Mouse input stopping working randomly after returning emulation from GUI.
- Emulated middle mouse button got stuck in rawinput mode if middle button was set to untrap mouse.
- Detect and fix bad configuration options when using uae-configuration, for example it
  was possible to enable both cycle-exact and JIT at the same time causing frozen emulation.
- Rare cycle-exact mode interrupt timing issue. (Guardian Dragon II / Kefrens random hang)
- Some minimized/inactive/active switching issues.
- Directory harddrives configured as unbootable still booted normally under KS 1.3.
- Windows dialogs (not GUI or file dialogs) were invisible in fullscreen Direct3D mode.

and more...


WinUAE 2.3.3 released (18.09.2011)
==================================

New features:

- New very low latency VSync mode, autodetects real refresh rate, no more 100% CPU usage, supports also windowed modes.
  (Not compatible with fastest possible CPU modes but planned in future)
- Experimental rawinput joystick/joypad support. (-rawhid command line parameter)
  Added because DirectInput is said to introduce some extra input lag.

Updates:

- Real cause for Max Transfer IDE problem found. IDE emulation detects and logs it now.
- CD image audio buffer increased slightly, some systems had glitches in CD audio.
- Non-configured joystick/mouse autoswitch update: short firebutton press or move left = insert into joystick port,
  longer press or move right = insert into mouse port. 
- Add Harddrive option does not require Administrator privileges anymore, most removable drives can be used without
  higher privileges, at least under Windows 7.

Bug fixes:

- IDE emulation write hang introduced in 2.3.2.
- A590/A2091 emulation crash if CPU was 68020+.
- On the fly CD switching (both images and real CDs) reliability improved.
- Direct3D blank screen problem is now 100% fixed. Really.
- win32.hardfile_path didn't work.
- On the fly resolution change didn't work correctly, resolution autoswitch improved.
- Key or joystick button mapped to mouse direction didn't work.
- Analog stick mapped to mouse had too fast and unstable speed.


WinUAE 2.3.2 released (02.06.2011)
==================================

New features:

- AROS ROM replacement development snapshot included, replaces old
  very basic ROM replacement feature, used by default if official
  KS ROM is not found.
- New autofire option. Button released = autofire. Button pressed = normal
  non-autofire firebutton.
- Stop the CPU and wait until blitter has finished if any blitter register
  is accessed while blitter is busy and CPU mode is fastest possible.
  Better workaround than immediate blitter for programs that have blitter
  wait bugs with fast CPU.
- Serial port telnet server.

Updates:

- Disk emulation accuracy improved
  (Codertrash / Mexx, El Egg Tronic Quarts / Quadlite)
- CIA timer undocumented startup delays emulated (Risky Woods sound
  glitches)
- win32.floppy_path and win32.hardfile_path really works as expected.
- Display panel refresh rate accepts non-integer values.

Bug fixes:

- Implemented workaround that should fix Direct3D blank screen problem.
- Sample ripper crash.
- 68000 exception 3 emulation fixed again. (Broke compatibility with some
  very old copy protections, for example Soldier of Light and Zoom!)
- Reset bug that broke Arcadia mode, A1000 mode and Action Replay ROMs.
- Automatic resolution switch interlace detection was unreliable.
- CD32 early boot menu is accessible again.
- Rare crash when switching from fullscreen RTG mode to native mode.
- Borderblank chipset feature didn't work in ECS Denise mode.
- Possible input configuration corruption due to uninitialized variable.
- Color change table overflow crash that can happen when emulated
  program crashes really badly.


WinUAE 2.3.1 released (26.02.2011)
==================================

New features:

- Directory filesystem ACTION_LOCK_RECORD and ACTION_FREE_RECORD.
- Gamepad joystick type for games that support 2nd fire button but
  can't read it without pullup resistor. (for example Aladdin)
- Manual filter configuration fully implemented.
- Autoresolution supported (automatically selects lowest used
  resolution on the fly)
- MIDI device names are stored in configuration file.

Updates:

- Custom chipset undocumented feature compatibility updates.
  (For example Magic Demo / Diabolics, MoreNewStuffy by PlasmaForce,
  Kefrens Party Intro by Wiz)
- M68K AROS compatible IDE and RTG emulation.
- Statefile compatiblity updates. (Initial audio glitches, mouse
  counters updated correctly, CPU exact mid-instruction state saved,
  active disk DMA state saved)
- New filter defaults, 1x (not FS) and always scale if selected
  screen/window size is very small or large enough.
- Auto resize and center filter modes 1x/2x.. modifiers now
  adjust window size.
- Attempt to load disk image and harddisk paths in state files from
  current directory, current adf/hardfile path and finally state
  file directory if original path or file is missing.
- SCSI emulation physical drive tray load/eject passthrough.
- SCSI emulation CD audio support improved.
  (for example T-Zero and The Shadow of the Third Moon)
- Clipboard sharing disable option in GUI.

2.3.0 bugs fixed:

- Audio pitch errors if audio period rate was near minimum audio
  DMA limit.
- Very heavy CPU usage if program continuously plays really short
  audio samples.
- ROM scanner again detects *.rom files in root directory.
- Sample ripper works again.

Bugs fixed:

- Directory filesystem was slow on most modern multicore systems.
- CDTV CDA playback didn't work if play ending track was set to
  last track. (Prehistorik CDTV)
- 2352 byte sector plain ISO images didn't mount correctly.
- Some drives had problems reading Mode 2 Form 1 data tracks.
- SPTI+SCSI SCAN didn't detect any non-CD devices (broke in 2.2.1)
- Automatic resize filter didn't always work correctly.
- Topmost scanline was usually not visible in autoscale modes.
- GamePorts parallel port joystick configuration crash fix.
- Random RTG color errors when switching to/from fullscreen 8-bit
  RTG modes.
- Archive mounting crashed if something prevented complete unpack
  (for example non-dos dms image file)
- Harddrive state files didn't save correctly if more than one
  harddrive was configured.
- A2065 Z2 board emulation fixes. (Lost interrupts, broadcast
  packets getting ignored, transmitter dropping big packets.)
- A500 power led fade tricks really work now.
- HRTMon didn't work in cycle-exact modes.

And more...


WinUAE 2.3.0 released (24.09.2010)
==================================

New features:

- CDTV and CD32 subchannel hardware emulation, CD+G audio CDs supported.
- CDTV statefile support.
- FLAC compressed CD audio tracks supported (cue+flac or cue+iso+flac).
- Automatic center, max fullscreen and tv-like fullscreen options added.
- uaescsi.device SCSI emulation, including full CD audio support.
- Pause uaescsi.device CD audio when emulation is paused or GUI is open.
- Support for configuration file delayed CD image insert, for example CD32 games
  F17 Challenge and Last Ninja crash if booted before CD32 boot screen appears...
- Right and bottom border, if outside of display area, is blanked instead of filling
  with current border color.
- Full "Portable"/USB key mode (-portable command line parameter) and relative path support.
- Borderless/minimal/normal windowed mode option.

Updates:

- CD/CD image handling rewrite:
  * .ccd/.img/.sub and .mds/.mdf v1 image files supported.
  * Subchannel support (CDTV/CD32 CD+G).
  * Audio tracks fully supported.
  * SCSI emulation, CD images and non-SPTI mode full uaescsi.device CD audio support,
    most common CD SCSI commands emulated. SCSI emulation enabled by default.
  * Near-instant compressed (mp3/flac) CD audio and zipped CD image startup time.
  * More reliable CD/CD image and CD image/real drive on the fly change support.
- CD32/CDTV more accurate CD audio and animation streaming.
- Rawinput keyboard handling improved.
- Cycle exact audio and disk DMA sequencer, Paula DMA request line timing fully emulated,
  (previously DMA accesses were "immediate", all other timing was already exact)
- Direct3D bezel overlays and "old" overlays separated, bezel overlays
  are in overlays-directory, old overlays should be renamed as masks.
- Direct3D bezel automatic display area detection and aspect ratio correction.
- Disk images inside archives are automatically "extracted" to Disk Swapper
  and floppy drive paths when dragged and dropped.
- 68000 and 68020 cycle exact CPU timing updates.
- 68040 MMU emulation compatibility improved, Linux and NetBSD confirmed working.
- Keyboard led handling improved.

2.2 bugs fixed:

- Triple/double/single buffer option was not saved to configuration file.
- Autovsync didn't work.
- Rawinput GUI F12 key ignored window focus.
- Gameports panel joystick/mouse type (mouse,joystick,analog joystick,..)
  was ignored when configuration file was loaded.

Other bugs fixed:

- Direct3D 2x+ shader filter bad image quality.
- CDTV CD timecode (Built-in CD player time counter).
- CD32 CD end of play notification only worked if play was last sent CD command. (Fightin Spirit)
- CD32 CD audio status reporting when attempting to play data tracks (Mission Impossible 2025)
- CD32 pad 2-button mode fixes (F17 Challenge, Quik The Thunder Rabbit, ATR)
- Audio length detection error if MP3 audio tracks had checksummed frames.
- Built-in image mounter CD audio timecode offset fixed.
- Z3/RTG RAM leak when restarting.
- Direct3D scanlines can be (finally) enabled on the fly.
- Configuration file cdimage0=<drive letter>:\ at startup didn't work.
- Dynamic hardfiles didn't work reliably with DirectSCSI filesystems.
- Dynamic hardfile data corruption if physical file size grew over 4G.
- Some demos had blank display (broke in 2.0 Denise updates).
- Transparent clipboard support crash fixes.
- Initial ROM scan didn't detect Amiga Forever rom keys correctly.
- Joystick axis bogus autofire in some situations when remapping joysticks.
- Rawinput was not enabled if only one (physical or logical) keyboard was detected.
- RTG mouse cursor problem in D3D mode with enabled filter.
- RTG 8-bit fullscreen mode color error in some situations.
- Miscellaneous custom chipset and disk emulation tweaks.
- RTS and RTD odd address check was missing, fixes also mysterious JIT crashes.
- Epson printer emulation multiple page printing fixes.
- plugin directory detection problems.
- Rar archive crash.
- ~1.5G Z3 Fast RAM works again (64-bit host OS only)

and more..


WinUAE 2.2.0 released (28.06.2010)
==================================

Major Game Ports and Input GUI update (finally!):

- Quick and easy Game Ports input event remapping support.
- Test mode, check built-in or custom key mappings quickly.
- Also includes simple autofire configuration.
- Game Ports mappings are always merged with Input panel configuration modes (*).
  For example when configuring a game pad, you can use Game Ports GUI for basic
  configuration and remap extra buttons using Input GUI.
- Input GUI also includes quick test and remap options. Press any key,
  joystick or mouse axis or button and selected input target will be
  instantly ready for remapping, no more slow and manual searching.
- "Windows mouse" not supported in test or remap modes.

*) Possible compatibility issue with old configuration files in Configuration
   #1-3 mode. Workaround: set Game Ports mouse and joystick to none.

Other new features:

- (Pointless) Max 1G Chip RAM support.
- 7zip SDK updated, XZ and PPMD decompression support added.
- Triple/Double/No buffering option added to GUI.
- NTSC checkbox added to Quickstart GUI.
- WASAPI and PortAudio volume control support.
- 68030 data cache emulated (mostly useless currently).
- Save state when emulator is quit configuration file option.
- Show information window while scanning for ROMs.
- Monitor "bezel" overlay image support (configuration file only).
- Floppy sound channel mask (configuration file only).

Bugs fixed:

- CD32 on the fly CD changes, both images and real CDs.
- Autoscale top border position was incorrect in some situations.
- Directory filesystem crash in some situations when attempting
  to open non-existing files or directories.
- INTREQR returned bit 15 set in some situations.
- GUI custom CPU frequency was read incorrectly.
- More 68020 "cycle exact" timing fixes (interrupts and blitter).
- 68000 cycle exact too slow CIA interrupt timing.
- Audio filter emulation didn't always follow power led state correctly.
- Amiga to Windows clipboard image sharing failed to convert some image types.

Updates:

- Direct3D shader mode is more compatible with Intel integrated graphics cards.
- Custom chipset compatibility updates (for example Roots 2.0 / Sanity)
- 68020 "cycle exact" mode improvements.
- Direct3D "none" filter allows again all filter setting adjustments.
- On screen Power LED fade emulation improved.

and more, check winuaechangelog.txt for (technical) details.


WinUAE 2.1.0 released (28.04.2010)
==================================

2.0.x bugs fixed:

- Super Stardust level selector sprite bug.
- Directory filesystem mount failures if ISO-8859-15 character set was
  not installed in Windows.
- 68020 CE mode duplicate interrupts.
- Command line parser heap corruption.

Other bugs fixed:

- Random Direct3D mode graphics crap is gone.
- Direct3D fullscreen ALT-TAB weird behavior.
- More than 8 CD drives crash.
- Rare dualplayfield buffer corruption. (Shadow Fighter AGA)
- CD32 pad emulation compatibility improved. (Roadkill CD32)
- Some game controller device types were ignored.
- Vista/7 file dialog multi file selection fix (Disk swapper).
- Swapped sound channels if stereo separation was enabled.
- Unreliable VSync in interlaced Direct3D mode.
- NTSC statefiles didn't restore correctly.
- Sometimes printer always reported busy, paper out or offline.
- Directory filesystem rename operation weird behavior if file name
  included non-ISO-8859-1 characters.
- Directory filesystem cyrillic character set support.
- Mouse driver (tablet) mode random mouse jitter.
- Filter presets.
- Rar unpacking crashed if unrar.dll was too old.

New features:

- CDTV/CD32 direct CD image file support, including audio tracks,
  plain iso, cue + bin, cue + bin + wav and cue + bin + mp3.
  Quickstart GUI support, cdimage0=<path> in configuration file and
  -cdimage=<path> in command line.
- Direct 3D rewrite, shader based (if shaders supported), overlays
  and RTG supported, Direct3D is now default rendering backend,
  configuration in Misc panel, all software filters are available
  in Direct3D and DirectDraw modes.
- DF3: on screen led shows internal (NV)RAM accesses (CDTV and CD32)
- Input panel Caps and Scroll Lock full remapping support.
- A1000 Agnus vblank bug emulated. (Alcatraz Megademo 2)
- Fullscreen dialogs have separate size and position settings (Vista/7),
  always center dialogs in fullscreen (XP)
- Multidisk image selection helper, right click on disk image select
  button to open quick selection menu.
- "GamePorts" "Copy From" option added to Input panel, copies Game Ports
  panel mouse/joystick settings to current input configuration.
- Parallel port sound sampler emulated, WIP, bad sound quality..
- Windowed mode status bar CD/HD/floppy "led" activity status improved.
- "Minimize when focus is lost" option.
- Expand environment variables in configuration and command line file paths.

Updates:

- Many 68000 CPU cycle-exact mode instruction cycle counting and interrupt
  timing updates, A500 emulation accuracy is near-perfect now.
- More compatible CDTV/CD32 CD audio support using direct digital audio
  extraction. Sound panel volume control adjusts CD audio volume.
- OCS Denise horizontal position counter bug fully emulated.
- Autoscale display size detection improved.
- Support DMS files that have fake complete track zero. (BBS ads)
- Epson matrix printer emulation improved, no extra libraries or fonts
  required anymore, color text and graphics supported.
- OCS chipset "fake 60Hz" refresh rate support rewritten, now handles
  non-60Hz rates.
- Raw keyboard option is now always enabled, Input panel multiple
  keyboard support.


WinUAE 2.0.1 released (23.12.2009)
==================================

Major 2.0 bugs fixed:

- Random interference in some AGA screen modes.
- Blitter onedot line drawing mode was partially broken in non cycle exact modes.

Other changes:

- Screenshot and AVI recording "capture before filtering" options.
- Tar archive support added to "archive" harddrives.
- Custom chipset emulation compatibility updates. NOTE: ECS Denise
  undocumented feature is now emulated and some demos have blank
  screen if chipset configuration is set to ECS Denise/Full ECS.
- More compatible directory filesystem character set translation.
- Mouse driver (tablet) mode didn't work without magic mouse.
- Ignore unrar.dll versions that do not support unicode.


WinUAE 2.0.0 (13.12.2009)
========================

Main new features:

- Huge A500 cycle exact mode compatibility improvement.
- Improved unexpanded A1200/CD32 emulation compatibility.
  Approximate cycle-exact 68EC020/68020 emulation implemented, includes
  emulated 68020 instruction cache, approximate prefetch emulation.
- 68040 MMU emulation (from Aranym) For example Enforcer and M68K Linux
  compatibility. Not compatible with JIT.
- A2065 Zorro II hardware ethernet card emulation.

Other updates:

- CD32 drive emulation compatibility improved, includes animation CD
  streaming.
- Old game protection dongles emulated (Leaderboard, Robocop3, etc..)
- Built-in Vista/Windows 7 WASAPI sound API support.
- Real harddrive safetycheck only complains if drive is mounted
  read-write and has mounted Windows partitions.
- Full NTSC timing implemented (long/short line toggle etc..)
- "AutoVSync" mode that change native refresh rates automatically.
- Basic CPU frequency/bus multiplier configuration option added.
- Gayle IDE emulation compatibility improved.
- Single sided PC/Atari ST disk images supported.
- AVI and wave sound recording improved.
- File paths support http, https and ftp protocols.
- Automatic split DMS support.
- File dialog file type setting is stored to registry/ini.
- Display width is not anymore restricted to values divisible by eight.
- Bsdsocket emulation MSG_WAITALL implemented, CVS compatibility fix.
- Uaescsi.device TD_REMOVE implemented.
- DMA cycle debugger implemented.
- RTG screen mode on-screen leds.
- "Add PC drives at startup" does not mount drives that are also
  configured as real harddrives.

Bugs fixed:

- Programmed refresh (non-PAL or NTSC) rate modes had bad sound.
- Right border background color error in some programs.
- On the fly USB input device insert changed unrelated keyboard layout
  settings.
- Non-DMA mode sprites work again (broke long time ago)
- 5.1 sound mode had wrong center and sub mixing ratio.
- CD32 pad default mapping green and yellow, RDW and FFW reversed.
- Uaescsi.device TD_GETGEOMETRY off by one error and no media status fixed.
- Directory filesystem ACTION_FH_FROM_LOCK notification bug fixed.
- Some types of serial ports were not detected.
- Randomly appearing single jumping black scanline finally fixed.
- Command line quote parsing was not compatible.
- Mouse didn't capture properly in mouse driver (tablet) mode.
- Directory harddrive duplication was possible in configuration file if
  path included national characters.

and much more than ever before..


Credits:
========

- Bernd Schmidt
- Toni Wilen
- Bernd "Bernie" Meyer
- Sam Jordan
- Brian King
- Bernd Roesch
- Adil Temel
- Andreas Junghans
- Mathias Ortmann
- István Fábián
- James Bagg
- Benjamin Pahlke

______________________________________________________________________________

IMPORTANT NOTICE: Picasso96 support in (Win)UAE would not be possible without
the support and generosity of Alexander Kneer and Tobias Abt. Please donate
to the Picasso96 team if you use P96 and UAE together.  NOTE: Amiga Forever
from Cloanto includes a full Picasso96 license already, which is even more
reason to support a long-time Amiga software company. Click on the Picasso96
link in the About page of the WinUAE GUI for more information.
______________________________________________________________________________


Catweasel support
-----------------

- Windows driver installed: automatically detected
- No Windows driver installed and TVicPort
  - Windows 2000/XP/Vista: automatically detected

How to use hdtoolbox with full harddisk images
----------------------------------------------

Create hardfile normally or use harddisk image from your real Amiga but clear all
hardfile parameters except block size.(sectors, surfaces and reserved)

HDToolBox must be run with "uaehf.device"-parameter ("tools/hdtoolbox uaehf.device")

Amiga formatted harddisk support
--------------------------------

Requires Windows 2000 or newer with administrator privileges.

All Amiga formatted or empty drives (=zeroed partition table) are autodetected.
WinUAE does not care about interface type, drive can IDE or SCSI or even
memory card if Windows detects the drive in device manager.

Use uaehf.device to access the drive in HDToolBox.
Note that some versions of HDToolBox don't see drives with unit number > 6.
Remove some mounted harddrives (directory or hardware) to fix the problem.

WARNING: you can force all drives to be detected if you run WinUAE with
-disableharddrivesafetycheck command line parameter but be very careful.
Don't try to select and partition/format your Windows drive(s)!

NOTE: uaescsi.device or ASPI don't have anything to do with harddisk support.

Vsync-instructions
------------------
- works in fullscreen modes only
- select 50Hz or 100Hz refresh rate (PAL) or 60Hz/120Hz (NTSC)
- WinUAE skips every other frame if refresh rate is over 85Hz
- display driver must support refresh rate selection. VSync is not selectable
  if only available option in refresh rate selection box is "default"
- you can also select other refresh rates for "interesting" results :)
- your pc must be fast because missed frames will cause huge slowdown
- display emulation refresh rate must be set to "every frame"

CD32 emulation instructions:
----------------------------

Emulated:

- CDROM except CD audio fast forward and rewind (1) (2)
- 1Kb NVRAM (works just like console emulators' memory card)
- C2P
- Joypad (keys: /=RWD *=PLAY -=FFW 7=Green 9=Yellow 1=Red 3=Blue)
  You can use input-tab to configure pad mappings.

Notes:

- CD32 configuration: 68EC020, AGA, 2MB chip, 0 floppy drives
- CD32's NVRAM (build-in 1024 byte flash RAM) file location can be specified in ROM-tab.
- CD32 ROMs come with Amiga Forever 5.0+ or you can dump then from floppy drive extended CD32.
  Don't ask me for ROMs!
- If you have CD32 CD images, you can use daemon tools (http://www.daemon-tools.cc/) to mount them.
- Make sure harddrives panel is empty and uaescsi.device is disabled!

uaescsi.device instructions
---------------------------

- Makes your IDE ATAPI/SCSI CDROM drives available on Amiga side (1)
  Use Amiga CDFS, CDA players or CD burning software etc..
  (not tested with real SCSI drives)

1:
- requires working ASPI drivers or admin privileges (SPTI)
- no configuration option for drive selection yet.
2:
- no drive selection configuration yet, just insert disc in any drive and start WinUAE.


Action Replay 1 / 2 / 3 instructions
--------------------------------

- You need AR 1, AR 2 or 3 ROM (see below for rip instructions)
- Set path to Action Replay ROM file (ROM-tab, cartridge ROM)
- Freeze button = Page Up
- Don't use AR support to save game states, use build-in state save option instead.
  (much faster and compatible)
- WARNING: Action Replay don't like fast Amigas or 68020+ CPUs
  and max supported fast ram is 4MB.

Action Replay ROM Ripping instructions:

 Find A500 with Action replay-cardridge,
 press 'freeze'-button, write following:

 AR 1:

 lord olaf<RETURN>

 AR 2 and 3:

 may<RETURN>
 the<RETURN>
 force<RETURN>
 be<RETURN>
 with<RETURN>
 you<RETURN>
 new<RETURN> (AR 3 only)
 
 insert empty floppy disk into DF0:

 AR1: "sm ar1.rom,f00000 f10000"
 AR2: "sm ar2.rom,400000 420000"
 AR3: "sm ar3.rom,400000 440000"
 transfer ROM image to your PC


Improved debugger
-----------------

 - f-command extended:
    f without parameters = break when PC not in ROM and current instruction is not
    0x4ef9 (don't break when executing library jump tables) Great for finding start
    address of bootblock.
    f i = break when PC points to RTS/RTR/RTE-instruction
    f i <opcode> = break when PC points to instruction opcode <opcode>
    f <addr> = add/remove new breakpoint (max 8)
    fd = remove all breakpoints
    f <addr1> <addr2> = break when <addr1> <= PC <= <addr2>
 - W-command's value-parameter can be decimal 12345 or hexadecimal (0x12345 or $12345)
    write size is byte if val < 256, word if 255 > val < 65536 and long if val > 65535.
    (previous version's write size was always long and was limited to chip ram)
 - memwatch break points added, w <0-7> <address> <length> <r/w/rw> [<value>]
    break when address space between address and address + length is accessed and
    if accessed value = <value> R = break only on reads, W = writes, RW = both
 - i-command: interrups and traps combined, VBR supported
 - custom register dump -command added (e), dumps the contents of all existing registers
   between 0xdff000-0xdf1ff. ea = dump AGA color register contents.
 - CIA dump-output slightly modified, added TOD stopped status-flag and more.
 - exiting debugger automatically creates "memory state" and b-command can be used
   to "rewind"
 - bl lists all stored "state recorder" states
 - search-command s <"string">/<hexvalues> [<addr]> [<length>]
 - trace (t <cnt>) can be used to step over more than one instruction
 - wd = enable illegal access logger (all read or write accesses to nonexisting memory,
   read access to write-only memory or vice versa, accesses to "unofficial" cia and custom
   register address space etc..)
 - wd x y = disable logging between addresses x to x + y
 - H = list last 50 PC addresses (HH = addresses + flags). Only available if any breakpoint
   is enabled.

Drive sound customization
-------------------------

You can use external samples if you put files called drive_click_xxx.wav,
drive_spin_xxx.wav, drive_startup_xxx.wav and drive_snatch_xxx.wav
(xxx = whatever you want, "click" is the only mandatory sample)
to directory called <winuae path>\uae_data\

Multimouse
----------

Windows 2000: no real multimouse support.
Windows XP/Vista/7: all mice are supported.

Open Input-tab. Select any manual configuration (Configuration #1 to #4)
Open device select box. You should see "Mouse *", "Windows mouse" and
2 or more "Raw Mouse" (XP-only, Vista/7 name can be also "HID compliant
mouse). Make sure "Mouse *" and "Windows mouse" are disabled, (select box
next to device select box is unchecked) enable other mice and make sure
mappings are correct.

New in 0.9.90: Multimouse can be configured in "Game & I/O-Ports"-panel,
there is no need to do complex Input-panel configuration anymore.

Windows mouse?
--------------

"Windows mouse" is mouse that gets all movement events from Windows'
desktop mouse instead of DirectInput. Enable "Windows mouse" if you
think mouse feels sluggish compared to older WinUAE before DirectInput
was implemented. (and don't forget to disable "Mouse *" first or
mouse movement will be quite erratic..) Can't be used in multimouse
configuration.

Mousehack mouse?
--------------

Needed when using Tablets. Tablets only work properly if you select
"Mousehack mouse" and run Amiga-side program "mousehack". Without
mousehack "Mousehack mouse" is equal to "Windows mouse".
(mousehack-program is needed because regular mouse sends relative
movement data but Tablets are absolute devices)

WinUAE 1.3 update: mousehack-program is now built-in.

Mouse *?
--------

"Mouse *" is DirectInput system default mouse. "Mouse *" gets all
combined events from all connected physical mice. Can't be used
in multimouse configuration.


New ROM config entries in 1.1:
------------------------------

Syntax:
 kickstart_rom=v<ver>[.<rev>] [r<subver>.<subrev>] [<model>]
Only <ver> is mandatory. Model must be specified if requested
ROM file is not a regular Kickstart ROM.
Examples:
 v1.3 (select any autodetected 1.3)
 v1.2 r33.166 (must be KS1.2 revision 33.166)
 v1.2 A500 (KS1.2 rev 33.180)
 v2.05 A600HD (KS 2.05, rev 37.350 or 37.300)
 v3.1 r40.68 A1200 (KS 3.1 rev 40.68 A1200)
 v3.1 r40.68 (KS 3.1 rev 40.68, both A1200 or A4000 version allowed)
 v3.1;v3.0 (any revision of KS 3.1 or 3.0)
 v3 A1200 (A1200 KS 3.1 or 3.0)
 v2 AR (any Action Replay v2)
Multiple matches: highest available version is selected
Extended ROM config item: kickstart_ext_rom=
Cartridge ROM config item: cart=
Arcadia ROMs:
cart=Arcadia <name>, for example cart=Arcadia Xenon

---

Older changelogs:
-----------------


WinUAE 1.6.1 released (18.06.2009)
======================================

1.6.0 bugs fixed:

- ASPI uaescsi.device emulation crash.
- Directory harddrive Windows illegal character handling fixed.
- Magic mouse fixed.
- Loading configuration file from command line with GUI enabled didn't
  override Quickstart configuration if Quickstart mode was enabled.
- Gzip decompression fixed.
- Few remaining unicode conversion issues fixed.

Other bug fixes:

- Warp mode in fullscreen mode was not much faster in some situations.
- Direct3D scanlines work correctly again.
- Bsdsocket emulation crash when closing socket in some situations.
- Vsync with "unmatched" refresh rates was not adjusted correctly.

New features:

- Added disk image and configuration file icons, file extension
  association improved.
- Added button/key toggle mode to Input panel.


WinUAE 1.6.0 (21.05.2009)
=========================

New features:

- Very popular request: automatic display scaling/window resizing!
  (not compatible with all programs) Option in Filter-panel.
- PAL/NTSC vertical size change emulated in filter modes.
- Transparent clipboard sharing between Amiga clipboard.device and
  Windows clipboard, both Amiga->Windows and Windows->Amiga supported.
  Text and images supported, HAM6/8 automatically converted to 24-bit
  image, EHB converted to 64-color image. Images with less than 256
  colors images converted to standard IFF, higher color images converted
  to 24-bit IFF. Text converted to plain text, formatting possible in
  future.
- "Interlace fixer", interlaced screens are now rock solid, all interlace
  artifacts will be gone. (this feature isn't same as scandoubler or
  flickerfixer and not compatible with most games)
- VirtualPC VHD dynamic harddisk image support (dynamic = empty hardfile
  is very small, size grows automatically when more data gets written)
- Custom chipset emulation updates, horizontally mixed lores and hires
  modes work and more (for example Disposable Hero titlescreen is
  finally perfect, Oops Up ray color issue)
- Mouse emulation rewritten (Oil Imperium pipelining minigame)
- 10 sector and 81/82 track PC/Atari ST disk images supported.
- Diskspare disk images supported.
- OCS/ECS "7-planes" mode fully implemented (4 normal bitplanes + 2
  static 16-bit patterns for planes 5 and 6) 1st Anniversary by Lazy
  Bones has 100% correct display now.
- SuperHires supprted in lores and filtered lores modes.
- 320x256, 640x512, 800x600, 1024x768 and 1280x1024 always added to RTG
  mode list (320x200 and 320x240 was already available previously)
- RTG mode vertical blanking interrupt implemented without busy
  waiting, interrupt rate added, configuration added to GUI.
- Filter multiplier select boxes now support manually entered
  multipliers, for example 2.5 = 2.5x. Aspect ratio correction added.
- Full drawing tablet support. (must be wintab compatible)
- "Magic mouse" mode improvements.
- Parallel port joystick adapter configuration added to Gameports panel
  (Much easier and quicker than using Input panel configuration)
- Input device type (mouse, digital joystick, analog joystick, lightpen
  etc..) selection added to Gameports panel. (Less need for complex
  Input panel configuration)
- WinUAE is now unicode Windows application, added full unicode support
  to configuration files. (backwards compatibility still maintained)
- PortAudio v19 audio library support. ASIO, WDM-KS (Windows XP low
  level sound API), WASAPI (Vista low level sound API), lower latency
  sound. NOTE: WDM-KS is unstable in current PortAudio version.
- Added new 64-bit seek and size dos packets to filesystem emulation.
- ICD AdIDE "scrambled" IDE disk and hardfile format supported, also
  includes automatic byteswap detection.
- Include some monitor unsupported modes in display modes list because
  some drivers lists custom modes as unsupported with current monitor
  (even if they work just fine..)
- ASCII-only and experimental Epson matrix printer emulation added, do
  not print anything if less than 10 bytes received.
- Added support for Windows Recent Documents/Windows 7 Jump Lists.

1.5.3 bug fixes:

- Random CD32 pad button events without enabled pad.
- Mid horizontal line graphics mode change fix (for example Cover Girl
  Strip Poker)
- ECS Agnus 0.5M+0.5M "1M chip" mirror works again (Move Any Mountain)
- Rainbow Islands one missing horizontal line fixed.

Other bug fixes:

- Directory filesystem bug fixes (very old bugs), ACTION MODE CHANGE
  fixed, also fixed case that caused lost file comments, show >2G files
  as 2G - 1 instead of showing "random" 32-bit truncated value.
- HAM mode graphics errors if left border was not fully visible.
- Some crashing bugs fixed.
- uaeserial.device unit 10 or larger works now.
- Early boot menu PAL/NTSC switching works properly, previously only
  worked after reset.
- CD32 CD emulation is now compatible with newer cd.device (comes
  with FMV cartridge boot ROM)
- KS loader 16-bit odd/even ROM image to 32-bit merging fixed.
- A1000 bootstrap ROM in even/odd format loading fixed.
- Another non-interlace to interlace switch graphics corruption fixed.
- Sprite graphics garbage appeared in some rare cases.
- Restoring statefile without GUI enabled emptied all floppy drives.
- lha extended datestamps fixed. 7zip updated, datestamps supported.
- Recursive archives as a harddrive support improved.
- RTG display refresh crash in some specific situations.
- Switching cycle-exact mode on the fly sometimes freezed the blitter.
- Screenshots in windowed D3D modes fixed.
- 100% stereo separation was not working properly.
- Much improved sound stability/syncronization.


WinUAE 1.5.3 (09.11.2008)
=========================

Major 1.5.x bug fixes:

- Huge memory leak when switching between RTG and native modes.
- Writing to disk images didn't work in some games.
- Configuration cache missing files in subdirectories.
- Random freeze when switching to fullscreen modes that are smaller
  than desktop resolution.
- Second and third mouse/firebutton handling fix (Aladdin, BC.Kid
  and more)

Other bugs fixed:

- "Always on top", "No taskbar button" and fullscreen color depth
  change works on the fly.
- OpenGL fullscreen fixed.
- Parallel/Serial/MIDI select menus and Input-panel bottom options
  didn't work correctly.
- System clock run slightly too fast or slow if chipset refresh rate
  was different than startup refresh rate (really old bug).
- OCS NTSC configuration defaulted to PAL refresh rate.
- Real PCMCIA SRAM card re-insert detection fixed.
- Fullscreen RTG 16-bit to 32-bit desktop windowed mode switch
  (CTRL+F12) color errors fixed.

New features:

- Basic file association settings added to GUI (.uae, .adf etc..)
- RTG vertical blank wait uses interrupts, no more busy waiting. Should
  improve performance in many fullscreen RTG games.
- Added RTG virtual refresh rate configuration to GUI.
- Added RTG refresh rate next to chipset refresh rate FPS counter.
- Undocumented OCS "scanline" feature emulated (Ode to Ramon I and II)
- Midline resolution change improvements (still far from perfect,
  Disposable Hero, Innovation Part 2)
- Only accept current latest OpenAL32.dll or newer (old versions can
  cause crashes during device enumeration)
- Improved emulation of reads from write-only custom registers
  (S.E.X. / Fantasys)
- Syncronize Clock stability improved.


WinUAE 1.5.2 (05.09.2008)
=========================

Major 1.5.1 bug fixed:

- Random crashing if USB mouse or joystick inserted.

Other bugs fixed:
 
- Only titlebar was visible if minimized window was restored.
- Bottom part of display was not updated in bigger than display RTG modes.
- uae-configuration/uaectrl didn't always work.
- Bsdsocket emulation was not initialized in some configurations.
- Catweasel MK4 joystick/mouse compatibility improved.
- uaescsi.device media change didn't update all geometry parameters.
- Sound mute on/off inputevent fixed.

New features:

- Store relative ROM paths in ini-file mode.
- OpenAL sound support (experimental).


WinUAE 1.5.1 (12.08.2008)
=========================

Major 1.5.0 bugs fixed:

- Failed to start with some display card/driver combinations.
- Regular (non-RDB) OFS formatted hardfiles didn't mount under KS 1.3.
- Memory corruption in configuration file handling causing random
  crashes when loading or saving configuration files.
- Configuration files in subdirectories didn't load if configuration
  cache was enabled.
- RTG hardware mouse cursor may have been invisible (or had
  wrong graphics) in some cases after resolution change.
- Switching between non-interlaced and interlaced modes caused random
  "scanline" graphics corruption.

Other bug fixes:

- Built-in HRTMon crashed in JIT modes.
- Interlace modes fixed in "normal" (non-doubled/scanline) modes.
- Fixed borderblank graphics corruption in interlaced modes.
- Fixed possible crashes when switching Windows desktop resolution or
  when using quick user switching.
- "Kickstart Replacement" fixed.
- PCMCIA SRAM emulation didn't work in memory expansion mode.
- Emulation paused if "stop sound while inactive/minimzed" was enabled.
- Improved directory filesystem statefile support.
- AVI recording crash if only audio recording was enabled.
- Native DLL support fixed.
- Forced fullscreen refresh rates didn't work in some cases.
- Multiple identical (same serial number) USB game controllers do not
  confuse input system anymore.
- Major blitter slowdown in some AGA modes.
- ADF was not updated if disk write was aborted (Cadaver save disk)
- Crash when USB mouse/joystick was removed or inserted before
  emulation was started.

New and improved features:

- Added support for Direct3D pixel shader filters (very fast compared
  to software filters, pixel shader 2.0+ compatible display card
  required), plain Direct3D filter performance improved.
  Latest (August 2008 or later) DirectX required.
- In windowed mode all resolution or chipset/RTG mode switches
  resize the window instead of window closing and opening.
- Aspect ratio setting added to RTG and filter panels.
- Window resize enabled in windowed mode (chipset mode).
- Added Picasso96 option "Always scale in windowed mode" which enables
  window resizing and disables automatic resize. Keeps aspect ratio
  automatically.
- Only reset fullscreen mode when resolution or depth changes.
- On the fly USB mouse/joystick insert/removal does not modify
  currently selected input device(s) in Ports-panel.
- Enable ini-mode (registry replacement) if <name of winuae.exe>.ini
  (without .exe) is found. Previously always used winuae.ini.

And more. Originally 1.5.1 was planned to be "1.5.0 bug fix" update only..


WinUAE 1.5.0 (19.06.2008)
=========================

Requires Windows 2000 or newer. Does not run on Windows 9x/ME.

New features/improvements:

- Picasso96 emulation rewrite.
  * Major speed increase.
  * Optimized blitter operations.
  * Hardware (flicker free) mouse cursor emulated.
  * Picasso96 <> native switch without screen/window reopening if
    old and new size matches (instant mode switching).
  * Fullscreen to fullscreen switch without desktop flashing.
  * Color space conversion, all RTG color depths supported in windowed
    mode as long as Windows desktop has same or higher color depth.
  * Simple scaling support added, fill to whole screen instead of
    switching resolution. (Useful with low resolution games and demos in
    windowed mode or if host resolutions like 320x200 are not supported).
  * Configurable 15/16/24/32 bit color space formats.
  * Important notes if slowdown is noticed:
    - Select "NonLocalVRAM" in Misc-panel (if major slowdown)
    - Make sure display panel depth setting is same as Picasso96 depth
      setting (or tick "Match host and RTG color depth if possible")
      Color space conversion is always slower than direct match.
- Filter update.
  * Scaling and centering are now more intuitive (NOTE: old settings
    are not compatible).
  * "FS" scale multiplier added (fill whole screen).
  * "1/2" scale multipler added.
  * Hq3x and hq4x filters added.
  * Onscreen leds are not filtered anymore.
  * Keep aspect ratio option added.
  * Direct3D/OpenGL filters not yet updated.
- PCMCIA SRAM card emulation, includes real PCMCIA SRAM card support.
- ROM scanner byteswapped and even/odd ROM image support.
- Multithreaded AVI recording, huge speed increase with 2+ core CPUs
- Right mouse button over image selection buttons opens favorites menu
  (can add/remove/edit shortcut paths to disk/rom/harddrive images).
- Sprite emulation updates, sprite doublescan support improved
  (for example Fantastic Dizzy CD32 background), yet another missing
  undocumented feature implemented.
- More compatible with timing changes caused by power saving features.
- Missing uaescsi.device CMD_GETGEOMETRY added.
- Debugger, GUI debugger improvements.
- A600/A1200/A4000 IDE emulation LBA48 (>128G) support.
- Input handling is more Windows-like, only release mouse/joystick/keyboard
  when WinUAE loses focus (previously when mouse was not captured)
- Added 1.5M Chip RAM (A600 + 0.5M trap door expansion) and 384M/768/1.5G
  Z3 RAM (configures two emulated RAM boards) configurations.
- Configuration file cache implemented, increases initial configuration
  list loading speed.
- 5.1 sound settings include center and LFE channel (all 4 channels mixed)

Bug fixes:

- uaenet.device random deadlock fix, NSCMD_DEVICEQUERY works correctly.
- Gayle interrupt handling update.
- CPU emulation fixes, EXTB.L and CHK.L was 68000 (should be 68020+).
- Sprite emulation fix, Super Skid Marks hires mode cars and Marvin's
  Marvellous Adventure score/cloud interference.
- "HAM4" and "HAM5" is displayed properly.
- Sound emulation fix, fixes Weird Dreams hospital scene sound problem.
- More compatible CD32 state restore support.
- AGA mode sprite garbage may have appeared in some cases. (1.4.5+)
- DOS formatted HD floppy image crash.
- Rare real harddrive detection crash.
- CD32 compatibility improved (Liberation CD32)
- Display emulation fix, mixed interlaced and non-interlaced modes don't
  cause random display errors anymore, same with doublescanned interlaced
  modes. (for example hires-mode Pinball Illusions)
- Autoconfig emulation update, Action Replay 3 does not detect
  non-existing fast RAM board anymore.
- Many lha/lzh archives mounted as a harddrive crashed.
- Mousehack (tablet) mode works again.
- On the fly mouse/joystick switching crash fix.
- A3000 1.3 SuperKickstart works again.
- Many "non-standard" resolutions were missing in Picasso96 mode.

and more..


WinUAE 1.4.6 (02.02.2008)
=========================

1.4.6 will be the last version that runs on Windows 98/ME. Following
versions will require Windows 2000 or newer.

1.4.5 problems fixed:

- Mouse never capturing. (Windows 98/ME, rarely on W2K/XP)
- Some games crashing.
- Broken sprite outside playfields-feature and SWIV score information.
- Fullscreen mode with non-default refresh rate fallback problem.

Other bugs fixed:

- A600/A1200/A4000 IDE emulation freeze if >2G drive/HDF.
- CDTV E.S.S. Mega "semi-hidden" track now loads properly on W2K/XP.
- Crash when switching between <=2MB Chip + Fast and >2MB Chip setting.
- Sound emulation tweak. (Dungeon Master II, perhaps some others)
- Unstable NMI (IRQ7) option in cycle-exact and more-compatible modes.
- "Full-window" mode didn't always allow Windows desktop RTG resolution.

New features:

- Inverted mouse and analog joystick input sources.
- Input device (USB joystick, mouse etc..) on the fly insertions and
  removals supported. Device names saved to configuration file.
- Automatic joystick switching, firebutton 'inserts' any non-selected
  joystick to Amiga joystick port, mouse port selected if second button
  pressed or there is already other joystick in joystick port with
  firebutton pressed.
- Dynamic JIT direct memory allocation. Increased Z3 and RTG maximum
  sizes to 1G and 512M. (If at least 2G physical RAM)
- A3000 confirmed 2.04 ROM added to ROM scanner.
- CD32 FMV cartridge ROM added to ROM scanner. ROM and autoconfig
  emulated. Overlay and video/audio decoder chips not emulated.
- Directory filesystem ACTION_EXAMINE_ALL implementation is now more
  compatible with buggy programs.
- CIA/Gayle overlay emulation setting added to advanced chipset.
- Original early A1000 non-EHB Denise added to advanced chipset.
- Original A1000 (and early A2000) Agnus blitter busy bug added.
- Keyboard reset warning emulated and added to advanced chipset.
- Debugger improvements, hex/dec/bin converter, all commands that accept
  numeric parameters also accept register names (RAx,RDx,PC,USP,VBR,..),
  number prefixes supported, hex = 0x or $, bin = %, dec = !.
- 1M (both 0xe0/0xf8 and 0xf0/0xf8) and 2M (0xa8/0xb0/0xe0/0xf8) ROM
  image support.
- Implemented "stretch to fullscreen" filtering option.


WinUAE 1.4.5 (20.12.2007)
=========================

New features:

- Sana2 compatible net device (uaenet.device) emulation. WinPCap required.
- Full doublescan mode emulation (DBLPAL, DBLNTSC, MultiScan etc..),
  sprite doublescan support.
- Full SuperHires emulation, bitplanes and sprites, including ECS
  Denise "scrambled palette" superhires mode. Also does not downscale
  hires sprites to lores anymore when bitplane resolution is lores.
- SuperHires resolution added to display panel, replaces old GUI lores
  setting with lores, hires and superhires select box.
- .dsq (DiskSqueeze) and .wrp (Warp) disk decompression support.
- "Automount" and "Do not boot" harddrive options added.
- Axis movements can be mapped to buttons in input panel
  (left/right and up/down)
- Picasso96 resolutions 320x200, 320x240, 640x400 and 640x480 added to
  resolution list, even if no native Windows support.
- optional ini-file registry replacement. (winuae.ini or -ini <file>) 
- Autocomplete added to most path text boxes.
- Added information text to hardfile panel (shows type, size,.. of HDF)
- Nordic Power 3.0 freezer cartridge support.

Bugs fixed:

- lzx decompression stability and compatibility improved.
- Debugger C-command word and long word support fixed.
- Heavy CD32 Akiko C2P usage caused huge performance loss.
- AGA statefile restore crash fix.
- Analog joystick mouse emulation fix.
- A500 cycle-exact mode freeze in some cases.
- Picasso96 display preferences resolution list corruption.
- A590/A2091 SCSI emulation buffer overflow crash fix.
- Some types of HDF didn't mount properly.
- Some automount issues fixed.
- CDTV and CDTV SCSI emulation compatibility improved.
- Some ECS Denise-only features fixed.
- Miscellaneous fixes here and there.
- Blank screen in windowed mode fixed (RGB overlay incompatibility)


WinUAE 1.4.4 (22.09.2007)
=========================

New features:

- major directory filesystem emulation update:
  * removable drive automounting on the fly (USB memory, USB HD, memory
    cards, any removable drive that mounts as a drive letter in Windows)
  * drag'n'drop directory/archive automount
  * more missing filesystem packets supported (including ACTION_EXAMINE_ALL)
- major "Add Harddrive" uaehf.device update:
  * removable drives (real harddrives, x-in-one memory card readers, zip drives,
    etc..) supported on the fly
  * configured drive but no media or [USB] drive not connected when emulation
    was started: automounted when inserted (no RDB automount yet)
  * empty drives listed in "Add Harddrive" dialog.
- X-Power Professional v1.3 and Nordic Power v1.5 support
- Pro-Wizard module ripper updated to v1.62
- hq2x filter added.
- Added two basic A4000 quickstart configurations.
- More accurate CD32/CDTV end of audio track detection.
- Current configuration name added to window title.

Bugs fixed:

- Windows 2000: "Add Harddrive" was always disabled.
- "Add Harddrive" HD controller selection was missing.
- Better compatibility with OS 3.1 and older HDToolbox versions.
- CD32 statefile support works again.
- Paths handling updates (yet again..)
- Disappearing mouse pointer in fullscreen modes when GUI was active.
- bsdsocket emulation crashing or freezing when emulation was reset.
- directory filesystem file/directory deletion failing and Windows
  recycle bin support enabled returned wrong error codes.


WinUAE 1.4.3 (29.07.2007)
=========================

New features:

- Built-in lha/lzh and lzx support.
- Mount archives as a harddrive with transparent, recursive
  (archives inside archive) decompression. Supported: zip, 7zip,
  rar (unrar.dll or archiveaccess.dll required), lha/lzh, lzx.
- A3000 Kickstart ROM and SuperKickstart disk support.
- A590/A2091 SCSI, A3000 SCSI and CDTV SCSI expansion harddrive (HDF)
  emulation (WD33C93 + (Super)DMAC based SCSI hardware).
- Action Cartridge Super IV Professional freezer cartridge emulation.
- X-Power Professional 500 (v1.2) freezer cartridge emulation.
- Nordic Power (v2.0) freezer cartridge emulation.
- Debugger improvements (improved deep trainer, copper memwatch points,
  CPU-model specific registers can be modified, illegal access logger
  improved, process breakpoints etc..)
- Paths-panel default paths selection improved.
- Separate native and Picasso96 vsync setting.
- GUI will "autoscroll" if fullscreen mode is smaller than GUI.
- Improved rtg.library, speeds up Picasso96 in high resolution modes
  (obsoletes picasso96fix)

Bugs fixed:

- CDTV emulation improved (DOTC2, Xenon2, ChaosInAndromeda CD player)
- CD32 CD emulation improved (Fightin' Spirit, Base Jumpers etc..)
- Ghostscript printing fixed (again).
- Floppy drive sound selection if fdrawcmd.sys was not installed.
- Video recording sound pitch issue.
- -datapath command line parameter fixed (again..)
- uae-configuration JIT on/off switching fixed.
- Sprite attachment fix, fixes "Great Demo" by "The Tremendous Trio" :)
- Some FPU fixes from Aranym.
- Directory filesystem locked files (most commonly s:startup-sequence)
  after software reset
- Filesystem emulation not initializing if JIT was enabled and no other
  expansions enabled (fast RAM, Z3 fast, etc..)

WinUAE 1.4.2a (13.05.2007)
==========================

- Paths not working bug fixed.
- Windows 98SE/ME compatibility fixed.

WinUAE 1.4.2 (12.05.2007)
=========================

New features:

- "Windowed fullscreen" for users with multiple monitors, fullscreen
  Amiga on secondary monitor, Windows on primary monitor, no more lost
  fullscreen when focus changes to Windows program.
- A600/A1200 and A4000 IDE harddrive (HDF) hardware emulation, includes
  also "4-Way IDE" / "IDE splitter" emulation.
- Directory, HDF, IDE and Picasso96 statefile support. WARNING: data loss
  possible if data in HDF has changed between saving and restoring!
  Picasso96 statefile support not 100% compatible yet.
- 68030 and 68060 (with FPU. 68060.library required) emulation. (no MMU)
- 68881/68882 FPU type selectable.
- Global brightness, contrast and gamma adjustment.
- "PAL" TV-like filter, with brightness, contrast, gamma, scanline level,
  blur and noise adjustment.
- GUI debugger, debugger improvements. (xx switches debugger modes)
- New GUI font if running under Windows 2000/XP/Vista.
- Interpolation and filters supported in 4/6 channel sound modes.
- Log and debugger console position stored in registry.

Bugs fixed:

- Improved CDTV emulation compatibility.
- 1.4.0 FPU clamping fix.
- Missing channels in 4 channel sound mode. (Emu10K based cards)
- 10x+ performance increase during "decrunching" color effects when
  no filters enabled and only background color was visible.
- Crash when loading config and specific chipset extra model was selected.
- Direct HD support improved, SyQuest removable drives detected properly.
- Minor custom chipset emulation updates.
- Rare emulator crash when running Amiga program crashed badly.
- Filter centering improved.


WinUAE 1.4.1 (18.03.2007)
=========================

Major bug fixed:

- Start-up crash introduced in 1.4.0.

Bugs fixed:

- Yet another bsdsocket crash fix.
- ASPI detection ignored NeroASPI, also ASPI detection was improved.
- Some interlaced programs had color stripes or wrong colors in right border.
- Picasso96 RTG RAM mapping error in non-JIT mode

New features:

- New input targets added. (disk swapper, input configuration 1-4)
- Quickstart-mode automatically selects best available CD access mode.
- Master (Windows main volume) volume control added to input targets.
- map "POV Hat"-type joypad control to joystick horizontal and vertical.


WinUAE 1.4.0 (03.03.2007)
=========================

New features:

- CDTV emulation, including CD controller, internal SRAM and 64KB SRAM
  expansion memory card support.
- More compatible SPTI CD32/CDTV CD support.
- Advanced Chipset configuration. Miscellaneous model specific
  hardware configuration entries like real time clock chip type, CIA-A
  TOD clock source, RAMSEY, FAT GARY register emulation..
- Rewritten harddisk configuration system. No more lost hardfile or
  virtual directory configuration entries if path was missing..
- A3000/A4000 motherboard RAM bank support.
- Added Arcadia bios rom type selection.
- New Windows Vista -style application icon added :)
- Small CIA and custom chip emulation updates.

Bugs fixed:

- FPU emulation floating point to integer conversion fixed
  (proper clamping instead of truncating)
- uaeserial.device compatibility improved
- New serial port detection didn't detect all types of serial ports
- Random sound errors after adjusting sound GUI setting on the fly
- Directory filesystem memory leaks fixed and compatibility improved
- It was not possible to disable keyboard layout C after enabling it.
- Sound panel settings were not always enabled correctly.
- -datapath command line parameter didn't work.
- Disk image drag and drop didn't work.
- Quickstart panel disk swapping is properly delayed again.
- Some Picasso96 display modes were not available.
- bsdsocket freeze fix (Aminetradio)
- Windows driver Catweasel support works again.
- "Faster RTG"-mode lockups fixed.
- External drive sound selection GUI didn't work if fdrawcmd.sys
  was not installed.

WinUAE 1.3.4 (30.12.2006)
=========================

Bugs fixed:

- Improved bsdsocket emulation stability
- Winuaeclipboard crash fix
- Windows Vista compatibility problems fixed
- Filesystem flag handling on FAT volumes
- Page Down-key Input panel remapping works properly
- Sound system improved
- ECS Denise/AGA borderblank feature works properly
- Dualcore/SMP random freezes properly fixed

and more minor fixes..

Bugs introduced in 1.3.3 fixed:
  
- AVIOutput out of sync fix
- CPU emulation condition code fix
- Fixed handle leak in bsdsocket and AHI
- Sound pitch shifting in VSync-mode and more..
- Catweasel MK4 mouse support

New features:

- Improved emulation of AGA sprites outside display window
- uaeserial.device introduced. Multi-port serial device, unit numbers
  are directly mapped to PC serial ports (unit 0 = COM0, 1 = COM1 etc..)
- Improved serial port detection, virtual devices also supported
- Improved Catweasel MK3/4 support without Windows driver installed
  (requires TVicPort, http://www.entechtaiwan.com/dev/port/index.shtm)
- Improved debugger features
- Sound system is not anymore reinitialized when losing/gaining focus
- 1M (1024KB) ROM image support
- Sound volume configuration setting also sets AHI audio volume
  (previously was Paula audio only)
- Custom chipset interrupt timing improved

And more..


WinUAE 1.3.3
============

- big E-UAE merge, cleanups, optimizations etc..

Bug fixed:

- Reboot loop if RTG RAM without Z3 RAM enabled (1.3.2 bug)
- Hardfile TD_GETGEOMETRY buffer overflow fix
- RDB emulation failed to mount partition(s) if RDB had one or more
  not needed filesystems and required FS was in ROM.
- Selecting "Mousehack mouse" crashed if HD emulation was not enabled.
- "Genlock connected" GUI checkbox fixed (1.3.2 bug)
- Clicking eject in GUI and immediately selecting another floppy image
  enables delayed insert instead of immediately inserting the image.
- Input panel key mapped to <none> reverted back to its default
  mapping after saving and loading the configuration.
- Directory filesystem Windows flag-AmigaOS flag handling fixes.
- Bsdsocket.library Remote Desktop compatibility fix.
- Dual core directory filesystem freeze workaround
- Some minor blitter timing and CIA emulation fixes.
- Stereo sound channel swap setting stored in configuration.

Major new features:

- Lightpen/lightgun emulation.
- Built-in 7zip decompression support.
- Unrar.dll rar archive decompression support.
- Sound emulation partially rewritten, better latency, possible
  fix for scratchy sound on some systems. Sound emulation will be
  automatically disabled when emulated audio subsystem is idle. Audio
  status led implemented.
- Better DMS error handling, encrypted DMS files are transparently
  decrypted.
- bsdsocket.library ReleaseCopyOfSocket() implemented (AmiVNC fixed)
- Improved AF rom.key support.
- ProWizard module ripper updated to latest version.
- 100% accurate sound emulation mode does not cause huge CPU usage
  anymore with specific games, for example Paradroid 90 and Rambo 3.
- Automatic direct IO Catweasel MK4 support if no Windows driver
  installed, CWMK4 can now be used under 64-bit Windows XP.
  TVicPort direct io driver required.


WinUAE 1.3.2
============

WinUAE 1.3.x bugs fixed:

- Debug window won't open automatically anymore
- HRTMon keyboard layout and WHDLoad commands fixed

New features:

- Mouse Up/Down and Left/Right input destinations supported
  simultaneously
- CD32 state save support (work in progress)
- A1000 Kickstart disk images can be used as a ROM image


WinUAE 1.3.1
============

WinUAE 1.3 bugs fixed

- Uaescsi.device freeze problem fixed.
- Boot freeze if A4000 ROM was used without AGA.
- Original extended ADF read bug.
- Larger than 1280 wide fullscreen modes work.
- Sound "led" filter configuration data was read incorrectly.
- AVIOutput does not split the AVI anymore when focus was lost.
- D3D filter fullscreen/windowed switching freeze fixed.
- Integrated mousehack access fault fixed.

New and improved features:

- AVIOutput codec settings stored in registry and other small tweaks.
- HRTMon updated to 2.30, WHDLoad-commands supported.
- Some custom chipset timing tweaks.


WinUAE 1.3
==========

New and improved features:

- Input event recording and playback (WIP)
- PC floppy drive drive sound emulation :)
- Mousehack-"driver" build-in.
- PC DD and HD floppy image support.
- Added improved audio filter and interpolation code from uade
  and other sound setting updates.
- Added build-in HRTMon debugger/monitor. (WIP)
- Action Replay for Amiga 1200 ROM image support.
- Arcadia emulation updates.
- Directory filesystem compatibility updates. (illegal characters in
  directory names work better now, some protection flag tweaks,
  more compatible disk capacity check if disk is very big,
  compatibility issues with \\server\share-directories fixed)
- Debugger updates. (improved trainer search command, fa-command,
  like in Action Replay, AGA color register dump etc..)

Bug fixes:

- Fix for random state restore freeze.
- AVIOutput crash, incorrect window size.
- Random Picasso96 screen mode switch crash.
- "Create hard disk imagefile"-option in harddisk settings fixed,
  previously it usually created corrupt hardfiles..
- Fixed garbage lines when program mixed interlace and
  non-interlace modes.
- D3D filter fullscreen freeze fixed.
- Priority-panel "pause emulation/disable sound output"-checkboxes
  were not initialized correctly.

And more smaller (and maybe bigger) changes..

WinUAE 1.2
==========

New features:

- New "lores filter" in GUI, fixes incorrect colors in programs that
  use superhires trick (eg. Virtual Karting, demo Rest-2).
- Logitech G15 keyboard LCD support.
- FPU emulation updates and fixes.
- Ability to create 1:1 HDF from Amiga formatted harddisk.
- ProWizard module ripper updated to latest version.
- Display Filter panel updates, added 1x,2x,4x,6x,8x multipliers.
  (not implemented in OGL/D3D filters yet)
- PNG screenshots.
- Light pen hardware emulated. (but no trigger or cursor emulation yet)
- Manual language selection.

Bug fixes:

- Right border color problems finally fixed.
  (Leander, T-Racer, Unreal etc..)
- Misc custom chipset emulation updates.
  (Bubba'n'Stix second level, Cover Girl Strip Poker title screen,
  Detonator, Thai Boxing, Wicked etc..)
- CIA TOD counter fix. (demo Harmony by Haujobb)
- Display was shifted by one pixel in lores-mode and horiz centering enabled.
- Overlay windowed mode one pixel position error.
- Swapped parallel port joystick adapter firebuttons.
- Toggling disk image's read-write status don't leave locked files anymore.
- Amiga Forever 2005 path detection should really work 100% now.
- Corrupted wav-files in 4-channel audio mode.


WinUAE 1.1.1
============

Bugs fixed:

- Incorrect AF 2005 path defaults.
- Blitter freeze in CE-mode if D-channel was not enabled.
- Misc/Priority panel crash when running under Windows 9x/ME.
- Parallel port emulation. (Gauntlet III)
- Two disk emulation bugs. (Xybots, Disposable Hero and others)
- Incorrect .uae extension path if -datapath -command line
  parameter was used.

New features:

- Old versions of AdaptecASPI and NeroASPI are now automatically
  rejected. No more crashes or bluescreens under Windows 9x/ME if
  Windows build-in ASPI is used.
- Full SCSI device support in SPTI-mode.
- Display panel resolution and depth moved to separate select boxes
- Disk history format changed. File name is now visible even if
  path is very long.
  

WinUAE 1.1
==========

Major bugs introduced in 1.0 fixed:

- Picasso96 graphics corruption after ALT-TAB
- Zipped Amiga Forever Kickstart ROM image decryption problem
- JIT FPU ACOS bug (incorrect result if argument was negative)

Older bugs fixed:

- More stable on the fly configuration loading
- In windowed mode Amiga window height was sometimes slightly
  larger than requested size
- "the desktop is too small for the specified window size"-check
  was not completely correct
- AHI recording mode memory leak
- Some Amiga monitor drivers work now properly (for example Euro36)
- Incorrect paths if WinUAE was run from networked drive
- Some custom chipset emulation bugs (Obliterator intro, Elfmania
  scoreboard, Warp and others)
- Directory filesystem directory modification date bug if comment
  or protection flags were modified
- Improved directory filesystem compatibility
- Rare disk emulation bug introduced in 0.9.90
- Action Replay statefile restore bug introduced in 0.9.90
- OCS/ECS color translation to native colors fixed. (this was bug
  since the beginning of UAE..) Colors are now slightly brighter.
  No effect on AGA-mode colors.

New features:

- Configurable Catweasel joystick support, MK4 mouse support added
  (NOTE: Right and middle mouse button may not work with all mice,
  requires Catweasel driver/firmware update)
- MMKeyboard support added
- Transparent "drive led status bar"
- SPTI (Windows 2K/XP) SCSI emulation includes non-CDROM SCSI devices
- Improved uaescsi.device SCSI interface selection
- Custom emulation updates (Death Trap, Loons Docs, Spanish Rose by
  Creed, Filled Perspective by Zero Defects, Himalaya by Avalanche..)
- Improved default path setting, Amiga Forever 2005 paths supported
- More missing keycodes added to input-panel
- Copper debugger: tracing, single step and breakpoint
- Disk swapper: right button doubleclick in "Disk image"-column:
  removes disk in disk swapper panel. right button singleclick in
  "Drive"-column: remove disk in drive
- New-style ROM config entries (see below)
- Compressed hardfiles supported (limitations: max 100MB, all written
  data will be lost after reset or exit, hardfile file name extension
  must be either hdz, zip, rar or 7z)
- Hardfile drag&drop to harddisk-panel

WinUAE 1.0
==========

Bug fixes:

- Fullscreen resolution reset if selected display mode's
  height was larger than width
- Sprite emulation improvements (Battle Squadron missing high
  score character and Bubba'n'Stix background mountains)
- Directory filesystem file/directory datestamp modification
  if file/directory's protection flags or comment was modified
  (broke in 0.9.92)
- Picasso96 RAM autoconfig area memory size error (16M or
  larger was always marked as 8M)
- proper AmigaForever ROM path autodetection
- AMOS filesystem freeze (workaround only, proper fix unknown)
- Kickstart 1.2 was not autodetected (wrong CRC32)
- improved JIT direct access memory area allocation (fixes JIT
  direct mode problems with some Pentium 4 or NForce 3/4 boards)
- In some cases all priority-levels were changed to "Above Normal"
- bsdsocket crash fix
- Fixed swapped audio channels
- Picasso96 compatibility problem with Directory Opus 4.12
- Random crash fixed while using external drive sounds or while
  loading new configuration on the fly
- Emulation fixes (Shinobi, Double Dragon 2.., broke in 0.9.91)

New features:

- Catweasel Windows driver support, MK1/MK3/MK4 supported
  (MK4 direct floppy support and Amiga mouse support coming later)
- Nero Burning ROM ASPI is automatically used if Nero is installed
  (better compatibility than Adaptec ASPI)
- Arcadia (Amiga 500 based Arcade system) game support
- Disk swapper-panel improved (path edit box and history added)
- bsdsocket emulation does not ask for internet connection if
  requested address is localhost
- Emulation improvements (some Digital's demos, demo Tenebra partially
  fixed, 3v Demo by Cave, New Year Demo by Phoenix, game Sci-fi
  graphics corruption, Battle Squadron highscores, Bubba'n'Stix
  background etc...)
- Sound sample ripper
- Improved debugger

--

WinUAE 0.9.92 "WinUAE 1.0 public beta #3"
======================================================

Final beta before 1.0 (?)

Bug fixes:

- Regular HDF TD_GEOMETRY returned incorrect data. (caused some
  larger HDF's fail to mount, 0.9.91 only)
- Filesystem bug fix (0.9.90-91), files with Windows
  System or Hidden -flag set didn't open properly in all cases.
- Stardust starwars-scroller in cycle-exact mode.
- SuperStardust AGA tunnel-section and Superfrog intro bee flashing
  plus other sprite emulation fixes.
- Random disk formatting verify errors when using non-turbo mode
  (was broken couple of releases ago)
- Display corruption/crashes if display width was larger than 1024
  and display depth was 32bit (only native display mode, Picasso96
  was unaffected)
- Windowed mode window close button didn't work if "Use CTRL+F11
  to quit" was enabled
- input-panel autofire yes/no-selection
- AVIOutput video recording bug in interlaced modes

New features:

- Filesystem emulation now uses NTFS named streams to store Amiga
  FS protection flags and comment instead of __UAEFSDB.__-files.
  (non-NTFS drives still use old method)
- Postscript printer emulation using Ghostscript. All Windows
  supported printers work. Amiga-side only needs standard Amiga
  Postscript printer driver.
- Automatic print job flush after user configurable timeout.
- Improved hardfile creation, filesystem selection (OFS/FFS/SFS) etc..
- Disk swapper key shortcuts. (both GUI and in emulation)
- GUI drag'n'drop. (no more ugly up/down arrows)
- screenshots are now named <name of disk image>_xxx.bmp
- user configurable emulation speed adjustment from 5 to 100 fps
- rar and 7zip -archive support (using archiveaccess.dll)
- some custom chipset emulation improvements here and there.
- improved drive click sound emulation (requires separately downloadable
  sample package)
- X-Arcade build-in key mappings
- onscreen disk and HD leds flash red while writing
- "Always on top"-windowed mode setting

--

WinUAE 0.9.91 "WinUAE 1.0 public beta #2"
=========================================

Bugs in 0.9.90 fixed:

- Multiple directory filesystem emulation bugs (files getting truncated
  to zero if opened in rw-mode, read-only files failing to open and some
  operations returning incorrect AmigaDOS error codes)
- AGA horizontal scrolling bug in some games.
- Stereo separation setting was not always set properly.
- Another task-switching Direct3D/OpenGL-mode problem.

Other fixes and updates:

- Picasso96 black screen after CTRL-ALT-DEL.
- bsdsocket update, fixes ~2 second pause on some systems and
  added internet connection off-line check (Stephen Riedelbeck)
- CPU idle calculation update. CPU Idle-setting may need re-adjusting.
- PP Hammer and Spindizzy Worlds graphics flicker fixed in non-cycle
  exact mode (again..)

New features:

- "uae-configuration" Amiga side program that can list current configuration,
  change all configuration parameters and send any inputevent on the fly.
- Both right alt and ctrl are mapped to firebutton in keyboard layout B
  (some laptops don't have right ctrl key).
- disable quickstart-mode if using -f or -config= -command
  line parameters

--

WinUAE 0.9.90 "WinUAE 1.0 public beta #1"

New features:

- New Quickstart-panel. Easy and fast way to run disk-based games or
  demos. Simply select Amiga model, compatibility level, disk image
  and click start!
- Hardware and host configuration separated. Create and use your own
  custom host configurations instead of build-in host configuration.
  data from standard configuration files.
- Kickstart ROM scanner and autodetection. (only official ROMs supported)
  Old-style ROM selection is still supported.
- User configurable graphics filter presets.
- Scaling support in all software filters.
- Paths-panel added. User configurable ROM, statefile, screenshot etc.. paths.
- Automatically return back to GUI if Kickstart ROM fails to load.
- Added help-tooltips here and there.
- More compatible paraport direct parallel port support.
- Mapped filesystem P-flag to Windows System-flag, H-flag to Hidden
  and fixed inverted archive-flag.
- Replaced "PC Joystick 0", "PC Joystick 1" and "PC Mouse" with select box
  listing all available input devices.
- Configurable stereo separation and stereo mixing delay.
- uaehf.device TD_GETGEOMETRY support.
- USB keyboard led support.
- Fullscreen mousehack (Tablet) support.
- Directory filesystem emulation Windows Recycle Bin support.

Bugs fixed:

- Ages old right border horizontal centering graphics bug.
- ECS Agnus was always reported as an OCS Agnus (0.8.26)
- 68000 cycle-exact mode compatibility (0.8.26)
- Floppy emulation writing bug (0.8.26, fixes SWOS disk error when saving).
- Dialogs in fullscreen mode.
- On the fly switching between A1000/CDTV/CD32 modes.
- Swapping disk image sometimes changed another drive's disk image.
- German keyboard #-key.
- Windowed mode DFx,Power,etc.. "leds" are now non-96DPI compatible.
- Minimized WinUAE jumping back to fullscreen by clicking on other program's
  taskbar buttons and other ALT-TAB handling updates.
- CD32 pad emulation.
- AIBB crash in 68020-mode.
- Debugger keyboard freeze on some Windows 2000 systems.


WinUAE 0.8.27
=============

Bugs in 0.8.26 fixed:

- JIT-only crash when loading state file or loading new
  config on the fly
- crash when loading config and directory or no config
  file was selected
- ports-page uninitialized joystick/mouse radio buttons
- ignore files not having .uae-extension when scanning
  configuration file directory
- GUI works now with non-96DPI fonts
- possible crash when starting emulator or inserting/ejecting
  disks
- JIT compatibility problems with some games (for example
  Alien Breed 3D II)
- debugger am-command
- "Priority=2!"-debug dialog
- disk image path/name text input

Older bugs fixed:

- centering improved
- hardfile error "tried to seek out of bounds"-message when
  hardfile was too small or blocksize was set to zero
- fullscreen D3D/OpenGL-mode ALT-TAB
- fixed forever repeating "...because desktop is too small for
  the specified window size.."
- saving config: always add (if missing) ".uae"-extension to
  config file name
- "exter_int_helper: unknown native action xxx"

New features:

- new rtg.library, 20-30 times faster Picasso96 pixel read
- don't add contents of zip file to disk history if zip only
  contains one supported disk image file
- compatibility fix for buggy programs that access non-existing
  memory in CIA address space
- MIDI can be selected without serial port
- full collision level implemented correctly (game "Rotor")
- AVIOutput tweaks
- improved compatibility (Back in Bizness, Total Triple Trouble)


WinUAE 0.8.26
=============

Bugs fixed:

- custom chipset emulation updates (Aunt Arctic Adventure
  collision detection, Warhead music and sound effects etc..)
- very old FPU emulation bug
- bsdsocket emulation (AmiTradeCenter, CTRL-C signal check)
- interrupt level 7 freeze
- uaescsi.device MODE SENSE/SELECT translation
- Picasso96 WaitForVSync fix (Fake Electronic Lightshow" by
  Ephidrena)
- Picasso96 8-bit mode palette problem (black Workbench
  background color after returning from Windows desktop)
- MIDI-IN random freeze

New features:

- new GUI!
- improved GUI pages
- systray icon and shortcut menu
- improved drop and drop support
- faster END+PAUSE warp-mode
- 68020+/JIT crash prevention
- debugger improvements
- floppy drive disk image history list
- disk swapper page for swapping quickly multi-disk games
- integrated Pro Wizard module ripper (http://asle.free.fr/prowiz/) 
- improved IPF (CAPS) and FDI support


WinUAE 0.8.25
=============

Bugs fixed:

- DirectDraw error when starting WinUAE 0.8.24 if display card supports multiple
  heads and one or more head is disabled (also depends on display driver)
- crash when starting emulation if more than 2 mouse-like devices are detected
- floppy drive sound emulation volume level was not saved to config file
- floppy drive sample rate conversion was broken, sound quality was
  very bad if selected sample rate was not 44100Hz.
- multimouse support under Windows XP
- bsdsocket emulation update, fixes CNet's SMTPd
- uaescsi.device IDE ATAPI CDROM translation support, fixes PlayCD

New features:

- right border is not clipped anymore if program uses overscan
  (Settlers, Pinball Illusions etc..)
- fixed display corruption in some older programs
  (Mystic Tunes by Vertical, Bierkrug-tro by TEK, Forgotten Realms
  Slideshow '90 by Fraxion etc..)
- AVIOutput improved, much faster recording if any software filter
  (null filter recommended) is enabled
- readme.txt updated. (custom drive sounds, how to use multimouse etc..)


WinUAE 0.8.24
=============

Bugs fixed:

- Windows 9x/ME duplicate keypresses when using USB-keyboard
- bsdsocket emulation updates (TCP:<port>, Apache)
- saving compressed state file without zlib1.dll created broken state file
- crash after saving four or more state files

New features:

- improved multimonitor compatibility
- sound volume slider and keyboard shortcuts
  (END+numpad -, END+numpad + and END+numpad *, also multimedia keys Volume +- and Mute)
- configurable floppy drive sound emulation :)
- improved debugger (new breakpoints, memwatch points etc.. see below)
- Windows XP-compatible multimouse support, improved input-support
- FDI 2.0 disk image format

and some smaller updates..


WinUAE 0.8.23
=============

Bugs fixed:

- mousebutton getting stuck randomly when WinUAE lost focus
- floppy drives' state was not restored fully
- fixed crash when switching from 68000 to JIT-mode
- bsdsocket browser freezes/slowdowns
- SPTI CDROM media change detection
- parallel port joystick adapter works properly again
- saving state in ce-mode with blitter active created broken state files
- serial port/MIDI randomly lost received characters

New features:

- maprom emulation (BlizKick support)
- first CDROM is always uaescsi.device unit zero, second is zero etc.. and then
  other non-CDROM SCSI devices.
- improved priority settings
- improved filter options
- compatibility improvements
- bsdsocket emulation improved (Jabberwocky)
- faster Picasso96 solid window moves
- improved AHI emulation
- IRQ level 7 shortcut in input-tab
- percentage of CPU in use -meter added next to FPS-counter
- immediate state save (no need to exit the GUI anymore)
- dropped release numbers :)


WinUAE 0.8.22 Release 9
==============================================================================

Bugs fixed

- compiler misoptimization of some rare instructions
  (affected 0.8.22R8 only, usually caused GURUs)
- bsdsocket emulation (connection freeze, IRCD, AmyGate etc..)
- NTSC vsync sound
- Windows 2K/XP CD detection problems in non-ASPI mode
- more compatible audio emulation
  (TBL's Tint, some demos playing only noise)
- ticking/unticking 68000 "more compatible" checkbox on the fly
  does not crash the emulated Amiga anymore
- AVI capture sound sync

New features:

- software 2x filters (Scale2x, SuperEagle, 2xSaI and Super2xSaI) and
  manual screen position adjustment.
- separate windowed and fullscreen mode width and height
- 100% exact blitter block mode cycle diagram (cycle-exact mode only)
- replaced "run at higher priority" with priority selection select box
- added CAPS support to mini-version
- automatic AVI splitting


WinUAE 0.8.22 Release 8
==============================================================================

Bugs fixed:

- stuck joypad POV directional controller
- joystick keyboard layout B and C second firebutton
- workaround for buggy sound driver (ISA SB16, maybe others)
  that report zero as minimum and maximum supported sample rate
- possible crash when copying to virtual filesystem's root
- CD32 media change detection
- extended ADF write protection check
- extended ADF HD floppy support
- fast copper works again + config file support
- JIT FPU fix (Descent Freespace -demo)
- 57600 serial bit rate was incorrectly rounded to 56000
- ~2.8GHz+ CPU clock rate calculation overflow

New features:

- all configuration file loading restrictions removed,
  load new configuration file at any time!
- display width, height, depth, lores, doubling, correct aspect
  can be changed on the fly
- bsdsocket.library updates
- Picasso96 emulation optimizations
- improved audio emulation
  (Mortville Manor, Maupiti Island speech and Fighting Soccer)
- AHI driver update
- improved and more compatible CD32 pad emulation
- improved CD32 CD autodetection
- sound capture to wav-file
- Direct3D hardware filtering and scaling
- more configurable source tree, added very simple way
  to disable features like AGA, JIT, bsdsocket, Picasso96,
  harddisk, 68020+ etc..
- separate basic A500-only WinUAE executable included (winuae_mini.exe)
- quick state save (SHIFT/CTRL + END + numpad 0-9) and restore support (END + numpad 0-9)


WinUAE 0.8.22 Release 7
==============================================================================

Bugs fixed:

- printer didn't work if serial port emulation was enabled
- palette wasn't updated properly when entering and exiting the GUI
  in fullscreen 8-bit Picasso96 mode
- button or key mapped to mouse horizontal or vertical axis
- random crash when horizontal centering was enabled
- bsdsocket emulation, ping, traceroute, AmTelnet SSH connection freeze
- config save crash and non working keyboard
- ShapeShifter-support improved, all Kickstart 2.x/3.x versions supported
- lores-mode support for "sprites outside display window"-feature
- and more..

New features:

- emulation compatibility improvements
  Elfmania, Rainbow Island (broke accidentally in R6),
  Mission Elevator (properly fixed this time...), SWIV,
  Old Timer, Inferior, Sub Rally, Sargon History, TBL demos,
  Sound of Silents, Cardamom, Cardamon etc..
- analog joystick (paddle) ports emulated
- improved hard/ZIP disk RDB detection
- Action Replay 2/3 state file support
- sound "power led" filter emulation
- freely selectable sound sample rate (8000 - 48000)
- "direct" serial port support, fixes PC to PC Lotus 2 serial link
  problems. (two player only, 3 or 4 players require lower serial
  latency that is not possible under Windows)
- zipped CAPS-image support
- updated AHI driver included

WinUAE 0.8.22 Release 6
==============================================================================

Bugs fixed:

- increased compatibility
- display emulation graphics corruption in some programs
  (NOTE: some very old games, for example Eliminator, require OCS Agnus)
- sprites outside display window emulated partially
  (Banshee AGA, Alien Breed 3D)
- audio emulation fixes (noise and random popping)
- input configuration fixes
- crash when creating new CD32 NVRAM-file
- compressed disk images can be write-enabled
- more compatible with newer CDTV extended ROMs
  (still no CDROM controller emulation)
- disk emulation fixes (writing freeze, drive type, disk eject/insert,
  more compatible disk change detection, writing to multiple drives simultaneously)
- stuck middle button when "Middle Mouse-Button -> ALT-TAB" was enabled
- don't crash if zlib.dll is missing
- lost mouse input events when using high refresh rate mouse

New features:

- compressed state files
- rewritten and more compatible serial port emulation,
  serial link game support
- more compatible blitter speed in non cycle-exact mode
  (Spindizzy Worlds, PP Hammer..)
- turbo-floppy speed enables fast writing
- disable screensaver when WinUAE is active
- improved configurable CPU idle-function
- screenshots saved to ScreenShots-directory
- input configuration joystick port swap and device
  disable-button implemented.

WinUAE 0.8.22 Release 5
==============================================================================

Bugs fixed:

- CD32-mode media change detection
- SlowRAM detection fixes (Commando and more)
- more compatible CIA keyboard emulation (Back to the Future 2 and more)
- bsdsocket.library emulation updates (Stephen Riedelbeck)
- state restore fixes
- fixed mouse problems in Space Crusade, Billy the Kid etc..
- writing to custom floppy images was unstable
- primary sound buffer-checkbox removed and disabled. It is useless and usually
  only caused huge slowdown problems.
- PC Competitor interface's second joystick works properly
- improved compatibility (fixes USGold Murder, Crack Down, Liverpool,
  Pinball Hazard, future CAPS-images etc..)
- SuperHires sprite fix (SkidMarks AGA)
- another Pentium 4 JIT-crash workaround
- improved Action Replay support (Mark Cox)

New features:

- configurable boot priority and device name for regular (non-RDB) hardfiles
  and virtual directory filesystems
- configurable filesystem for regular hardfiles. (Automount/boot for example
  SmartFileSystem formatted regular hardfiles)
- FPU state file support
- configurable keyboard leds (DF0,DF1,DF2,DF3,POWER,HD,CD)
- floppy write-protect state added to floppies-tab
- implemented write-support for images that don't support writing
  natively (compressed images, CAPS-images)
- Amiga program p96refresh for selecting mousepointer refreshrates in
  Picasso96 mode (Bernd Roesch)
- "Middle-Mouse-Button -> ALT-TAB" works now in fullscreen mode
- improved input-tab GUI, increased number of input mappings from 1 to 4
- CD32 pads are now enabled in non-cd32 mode if configured in input-tab
- state files are saved to SaveStates-directory (was Configurations..)

WinUAE 0.8.22 Release 4
==============================================================================

Bugs fixed:

- changing joystick options in ports-tab caused joystick to not respond in some cases
- bad performance on laptops with power saving enabled
- mouse handling updates
- RDB SmartFileSystem 1.58 (and older?) crash fixed
- more filesystem bug fixes
- uaescsi.device reset crash on Win9x
- some games had problems detecting slow ram (for example Lotus 3), fixed
- MIDI SYSEX buffer overflows fixed
- sound timing always defaulted back to PAL when WinUAE lost or gained focus, fixed
- more ALT-TAB switching problems fixed (I hope so..)

New features:

- improved FPS counter
- filesystem notification (ACTION_ADD_NOTIFY, ACTION_REMOVE_NOTIFY) support added and more..
- CD-led is lit when CD32 audio track is playing
- new keyboard shortcuts: PAUSE-pause emulation, PAUSE+END-turbo speed
- CAPS-image support
- Catweasel MK3 support (joystick ports, keyboard and Zorro2-board emulation for multidisk.device)
- 1.5MB slow RAM support

WinUAE 0.8.22 Release 3
==============================================================================

Bugs fixed:

- Ports-tab crash fixed
- joystick handling fixes
- hard drive configuration save fixed
  (trailing spaces are now removed from HD ID-string)
- fixed stuck keys when switching between WinUAE and Windows
- sprite fix (some games had flashing sprite garbage)
- thread priority tweaks
- setupapi.dll error when running under Windows 95
- emulation slowdown and sound stuttering in 68000 mode (finally?)
- Amithlon partition detection fixed (detection failed if drive's
  partition table contained more than 6 partitions)
- jumpy mouse fixed
- hardfile not found -bug fixed
- "The selected screen mode can't be displayed in a window, because.." now correctly
  forces fullscreen mode instead of repeating the message forever..

New feature:

- implemented harddisk and CD-leds that flash during HD/CD access

WinUAE 0.8.22 Release 2
==============================================================================

New features:

- Kickstart 1.3 RDB and regular hardfile autoboot/automount support
  KS 1.3 regular (non-RDB) HDF autoboot requires FastFileSystem from WB1.3:L in KS roms-directory
- keyboard/mouse/joystick handling rewritten for DirectInput
  Windows keys are now 100% usable as an Amiga keys and SHIFT-keys don't get stuck anymore
- mouse speed configuration
- all keyboard keys (even special "multimedia keys") are available in input-tab configuration window
- configurable floppy drive type (3.5"DD/3.5"HD/A1010 5.25"SD)
- screenshot button moved from F11 to PrintScreen. PrintScreen = copy to clipboard,
  END + PrintScreen = write to ScreenShots-directory.

Following features require Windows 2000 or Windows XP

- "unlimited" hardfile size (2G limit removed),
  uaehf.device now supports TD64 and NSD -style 64-bit addressing
  NTFS filesystem required for >4G hardfiles (FAT32 max file size is about 4G) 
  WARNING: Make sure installed AmigaOS is new enough (OS 3.9 recommended)
- ability to mount real harddisks with full RDB automount/autoboot support
- Amithlon partition support

Bugs fixed:

- Slow harddisk, CDROM, etc.. performance in non-CPU idle mode
- CPU idle tweaks, defaults to off, config file support
- disk emulation improvements
- added missing configuration file entries
- better compatibility with old config files
- 68000 "more compatible"-checkbox works again
- fixed uaehf.device crash with older HDToolBox versions
- custom chipset fixes (Chaos Engine AGA/CD32, Obliterator, Terrorpods etc..)
- GUI's screenshot-button was always disabled
- state file restore fixes (CPU type is automatically restored correctly and more)
- switch from fullscreen/no-vsync to vsync-mode crash fixed
- filesystem "ghost"-file bug fixed (but filesystem emulation still have some bugs left..)
- bsdsocket emulation compatibility fixes
- fixed serial and printer port defaults

WinUAE 0.8.22 Release 1
==============================================================================

fixes/updates:

- UAE 0.8.22 merge, bumped version number (but most changes were already included in R4)
- 68000 CHK-instruction fix (Days of Thunder) and exception 3 handling update
- real 68000 prefetch emulation ("100 most remembered C64 games" and more)
- some custom chipset fixes (sprite-playfield collisions, graphics corruption)
- keyboard fix (some key presses were missed when pressing multiple keys)
- A1000 emulation fixes
- AVIOutput update (Sane)
- input-tab updates
- vsync works properly in interlaced screen modes
- sound updates/changes (DirectSound, uses UAE timing in non-JIT/vsync modes and more...)
- filesystem bug fixes
- CD32 pad numeric keypad emulation works again
- fixed joystick bugs in compatibility mode
- fast RAM state save fix
- bsdsocket fix (Stephan Riedelbeck)
- disk emulation fixes

new features:

- full harddisk image support (hdtoolbox, RDB, custom filesystems, SFS and PFS3 confirmed working)
- uaescsi.device improvements, confirmed compatible with CacheCDFS, AmiCDFS and AsimCDFS
  (disk change support added and use of direct scsi-mode is not needed anymore)
- Action Replay 1 support (but breakpoints don't work)
- CPU idle (tries to detect use of STOP-instruction, may not be complatible with all Amiga software..)
- floppy speed slider is back
- new AHI code and driver (Bernd Roesch)
- Amiga <> Windows clipboard support (Bernd Roesch)
- on the fly switching between OpenGL and DirectDraw mode
- on the fly switching between vsync and non-vsync mode
- compressed Kickstart ROM image support
- build-in screenshot function, shortcut key: F11 (Sane)
- experimental (and much slower) cycle-exact cpu and blitter emulation mode
  WARNING: requires at least 50%+ more cpu power than "regular" mode.
  Athlon XP/Pentium IV + DDR/RAMBUS RAM highly recommended!
  WARNING2: Frameskip must be set to 1
  WARNING3: very experimental, timing is quite far from perfection
- wkeykill.dll support (disables Windows-keys)
- OpenGL scanline brightness slider added

and more..

WinUAE 0.8.21 Release 4
==============================================================================
- EXPERIMENTAL: added configurable input device (mouse, joystick, keyboard) support
- EXPERIMENTAL: added OpenGL mode (for best results set lores and disable line-doubling)
- printer support fixed (Bernd Roesch)
- MIDI updates (Bernd Roesch, Alfred J. Faust)
- custom chipset updates (Superfrog,Exile,Apocalypse,Rainbow Islands,Torvak the Warrior...)
- disk emulation fixes (Typhoon Thompson,SuperDuper,S.T.A.G...)
- CPU idle patch (no more 100% CPU usage)
- HOME + F5 opens state restore dialog and SHIFT + HOME + F5 opens state save dialog
- vsync updates
- AVIoutput improvements (can be started later, stops when re-entering GUI)
- Picasso96 updates. Mouse trails are now 100% fixed (Bernd Roesch)
- refresh rate selection only affects Amiga display modes, Picasso96 always use default refresh rate
- "16-bit mode detect" crash fixed
- removed useless 8/16-bit sound selection. Sound output is now always 16-bit
- sound lag compensation slider reimplemented. (if you have bad sound, move slider left until sound gets better)
- build-in gzip and zip support (autoselects first adf-image or Amiga executable if zip contains multiple files)
- executable to adf support, just "insert" Amiga executable in to floppy drive
- improved external decompression support (xdms.exe)
- configuration save option is now available even after emulation has been started
- HD floppy image support in disk-tab

WinUAE 0.8.21 Release 3
==============================================================================
- experimental vsync support, refresh rate selection and triple buffering implemented. (me)
  See below for instructions.
- extended CDTV ROM supported. (me)
  Note that CDROM hardware isn't emulated yet.
- joystick emulation fixes. (me)
- Picasso96 fixes. (Bernd Roesch)
- DirectX 7 or newer required. (was DX 5 or newer)
- custom chipset emulation compatibility updates. (me, Bernd Schmidt)
- Shapeshifter-checkbox fixed. (patch from WinUAE 0.8.17)
- hardfile fix, Reorg works again. (patch from WinUAE 0.8.17)
- serial port update. (Bernd Roesch)
- JIT CPU emulator update (from BasiliskII-JIT)
______________________________________________________________________________

WinUAE 0.8.21 Release 2
==============================================================================
- FIXED:   custom chipset emulation fixes (me, Bernd Schmidt)
- FIXED:   JIT FPU (Bernd Roesch)
- FIXED:   filesystem emulation (Bernd Schmidt, Stephan Riedelbeck)
           (read-only files are handled correctly, programs in WBStartup
           aren't run multiple times anymore, A-flag handling fixed)
- FIXED:   PC joystick 2 (me)
- FIXED:   mouse 2 emulation (me)
- FIXED:   multiple CD32 CDROM and uaescsi.device updates (me)
- FIXED:   bsdsocket (Bernd Roesch, Stephan Riedelbeck)
- FIXED:   configuration GUI memory leak fixed (Stephan Riedelbeck)
- FIXED:   keyboard problems (me)
           (problems with SHIFT key and Action Replay activating when exiting GUI)
- FIXED:   CD32 pad button emulation
           (some games had problems with red button)
- FIXED:   serial port updates (Bernd Roesch, me)
- CHANGED: sound emulation (me, Bernd Schmidt)
- ADDED:   CD32 media eject/insert support (me)
- ADDED:   CTRL-AMIGA-AMIGA-ALT resets and clears chipmemory (me)
           (use to remove reset proof programs)
- ADDED:   "pause emulation while minimized"-option to misc-page (me)
- ADDED:   FDI-support is back (me)
______________________________________________________________________________

WinUAE 0.8.21 Release 1
==============================================================================
- Maintainer change, new WinUAE maintainer is Toni Wilen
- CHANGED: Many custom chipset fixes and updates (Bernd Schmidt, me)
- CHANGED: Audio code replaced with SDL audio (Bernd Schmidt)
           Remember to re-adjust sound buffer size
- FIXED:   CPU emulation fixes (Bernd Schmidt, me)
- FIXED:   Filesys seek fix (Bernd Roesch)
- FIXED:   JIT compatibility fixes (Bernd Schmidt)
- FIXED:   State save fixes (Bernd Schmidt, me)
- FIXED:   Prevent notebook CPU throttling when calculating CPU speed (Bernd Roesch)
- ADDED:   New input device code (me)
- ADDED:   Full CD32 support (me)
- ADDED:   Action Replay 2 and 3 support (me)
- ADDED:   CDROM scsi.device emulation (Win32 port by me)
- ADDED:   Sane's AviOutput patch
_____________________________________________________________________________
WinUAE 0.8.17 Release 3
==============================================================================
- FIXED:   Mouse trails are gone gone gone.
- FIXED:   No longer crashes in windowed-mode on XP Themed-view.
- FIXED:   68020+ bitfield instruction fix (stuck doors in Dungeon Master AGA)
- FIXED:   Fix garbage display on Venus the Flytrap and Nightbreed Interactive
           Movie. (Toni Wilen)
- FIXED:   Trying to delete a non-empty directory will now properly return
           ERROR_DIRECTORY_NOT_EMPTY. (Bernd Roesch)
- FIXED:   Renaming a directory which was opened then closed will no longer
           crash. (Bernd Roesch)
- FIXED:   Increased the range of addresses checked for memory-mapping, in
           order to make JIT "direct" mode work on more systems. (Bernd
           Roesch)
- FIXED:   Selecting a Picasso96 8-bit mode in windowed-mode would complain
           about not matching your desktop's depth, and switch to full-screen.
- FIXED:   CD-ROM Mounting should work again.
- FIXED:   Installer won't install when WinUAE is already running.
- FIXED:   Right-click and "Editting" a .UAE config-file will now result in
           the correct config-name and config-description in the GUI.
- FIXED:   MIDI-Out won't crash external MIDI drivers like "hubies loopback".
           (Bernd Roesch)
- ADDED:   Jose's modifications to the sound routines and GUI. (Jose Gil)
           NOTE: Read doc called "SoundSyncro Readme.rtf"
- ADDED:   AHI driver support. (Bernd Roesch)
- ADDED:   Option to disable use of overlays completely.
- CHANGED: Floppy-disk emulation, including .FDI support. (Toni Wilen)
- CHANGED: Picasso96 licensing/support notice (above).
- CHANGED: Removed references to "Amiga" in the GUI.
______________________________________________________________________________
WinUAE 0.8.17 Release 2
==============================================================================
- FIXED:   Fixed the center_image() routine which was causing crashes with
           centering inside of screens less than 800x600.
- FIXED:   Remove hard dependency on RegisterDeviceNotification API so that
           WinUAE still works on Win95.
- FIXED:   Event timing works better now, and shouldn't hang any demos or
           games. (Bernd Schmidt)
- FIXED:   Max out at 512-Megs of ZorroIII RAM, since 1-Gig won't work.
- FIXED:   Merged in some CIA-related save-state changes. (Bernd Schmidt)
- FIXED:   Banshee AGA and Lemmings3 AGA are now mostly working, thanks to
           new delay-offset code.  See the "KNOWN BUGS" section above for
           further details. (Toni Wilen)
- FIXED:   Sound-syncro settings can be changed on-the-fly. (Jose Gil)
- ADDED:   New version of "uaediskchange" utility.  Put this inside your
           "Amiga" installation, and call it in your startup-sequence like
           "run >nil: c:uaediskchange cd0:" to watch cd0: for disk-changes.
           You can watch more than one drive. (Bernd Roesch)
- CHANGED: Tweaked the sound-syncro code again. (Jose Gil)
- CHANGED: Creating an AmigaDOS .adf file from the GUI will now create a
           formatted disk. (Toni Wilen)
- REMOVED: No restriction on only being able to run one instance of WinUAE.
           NOTE: USE THIS WITH CAUTION.
______________________________________________________________________________
WinUAE 0.8.17 Release 1
==============================================================================
- FIXED:   Various AGA and chipset-related fixes. (Bernd#1, Toni Wilen)
- FIXED:   .GZ support in floppy dialog doesn't cause corruption. (Timothy)
- FIXED:   Updated sprite-collision logic which fixes Leander, Archon 1 and 2,
           Menace, etc. (Toni)
- FIXED:   Updated disk-emulation code, for higher compatability.  Also now
           supports .fdi and high-density .adf images. (Toni, Adil Temel)
- FIXED:   60Hz support in Dynablaster and BC Kid (Toni Wilen)
- FIXED:   BSD-Socket emulation is mostly working, although bugs still exist.
           (Bernd#3)
- FIXED:   Picasso96 screens smaller than their display-mode would have crap
           in their left-hand-border if you grabbed the screen's title-bar and
           moved the screen to the right.
- FIXED:   Updated copy of rtg.library, including more patches. (Bernd#3)
- FIXED:   You can set the WinUAE resolution in full-screen to whatever you
           desire.  Especially useful so that you set your full-screen size to
           match your desktop size, and it will prevent all your desktop icons
           from moving around after exitting WinUAE. (me, Georg)
- FIXED:   Stupid sound_channels=0 stuff in config-files works properly.
- FIXED:   Stupid gfx_center_xxx=yes/no stuff in config-files works properly.
- FIXED:   Selecting an item in the Hard Drives page of the GUI and then
           moving its position in the list now leaves the item highlighted.
- FIXED:   Detect OS version early, and inform the user appropriately instead
           of crashing.  Windows NT is no longer a supported OS for WinUAE.
- FIXED:   Various little off-by-one pixel errors in the GUI.
- FIXED:   MIDI in/out lists in the Ports page of GUI were behaving strangely.
- FIXED:   Floppy-disc emulation change to allow Shadow of the Beast Trainer
           to work. (Toni Wilen)
- FIXED:   Small change in MIDI support so that closing MIDI and then
           reopening it will work properly. (Bernd Roesch)
- FIXED:   Call ahi_install in main.c.  No Amiga-side AHI driver yet.
- FIXED:   MIDI-input doesn't have the concept of a "default device", unlike
           MIDI-output.  Changed the GUI and programming accordingly.
- FIXED:   MIDI-output now does the right things with the serial-port after
           each written byte, which allows some other programs to finally
           work (MusicX, Deluxe Music, etc.)
- ADDED:   New hook function in uaelib for checking on removable drive state.
- ADDED:   Disk-change status is now tracked via WM_DEVICECHANGE notifications
           which allows "run >nil: uaediskchange cd0:" in the startup-sequence
           to work properly.  Eject a CD-ROM, and the Amiga knows about it.
           Insert a new CD-ROM, and the Amiga knows about it.  Woo-hoo!
           NOTE: Probably really buggy.
- ADDED:   New collision-modes, fast-copper mode (not save-able with config).
- ADDED:   State-save support. (Toni Wilen)
- ADDED:   Option in Sound page of GUI to enable/disable synchronized sound.
- ADDED:   Printing of DDCAPS info for display-driver, to help diagnostics.
- ADDED:   FDI disk-image support (Toni Wilen)
- CHANGED: Tweaked the sound-code yet again, hopefully will get less out of
           sync.  (Jose Gil, myself)
- CHANGED: Add PC Drives no longer adds the floppy-drives.  If you want access
           to A:, then you'll have to add it manually in the GUI.
- CHANGED: Added ability to allocate larger amount of ZorroIII memory. 
           (Bernd#3)
- CHANGED: Added ability to allocate larger amount of RTG (Picasso96) memory.
           (Bernd#3)
- CHANGED: Removed Vertical Blank Synchronization (VSync) support in Flip
           calls.  This should increase synchronization and performance in
           full-screen mode, but may introduce some tearing/artifacting.
- CHANGED: Use the system "hand" cursor when pointing at web-links in the
           About page (if available). (Oscar Sillani)
- CHANGED: Use Tahoma font in About page of GUI.
- CHANGED: Use up/down icons in the HardDisk page of GUI. (Oscar Sillani)
______________________________________________________________________________
WinUAE 0.8.16 Release 4
==============================================================================
- FIXED: 50Hz/60Hz switching (B.C. Kid) works again. (Toni Wilen)
- FIXED: Various Picasso96 issues. (Bernd Roesch)
- FIXED: F11 should be '\' again.
- ADDED: .GZ support in floppy dialog. (Timothy Roughton, aka Inner) 
- CHANGED: Tweaked the sound-code yet again, hopefully will be less choppy.
- CHANGED: Tweaked the exception-handling code for JIT. (Bernie Meyer)
- REMOVED: icon1.ico from the source-code archive.
______________________________________________________________________________
WinUAE 0.8.16 Release 3
==============================================================================
- FIXED: GUI DLL loader is no longer fixated on Deutsch.
- FIXED: Selecting 68000 CPU from a JIT config doesn't result in error message.
- ADDED: Sprite-collisions can be enabled/disabled during emulation, not just
         at startup.
- ADDED: Patched rtg.library added to package, which should fix the mouse trails.
         (Thanks to Tobias Abt and Alexander Kneer of P96, and Bernd Roesch).
		 This file (rtg.library) will end up in the "Amiga Programs/" directory
		 under the "WinUAE/" directory where you install to.
- ADDED: German keymap (UAE_German)
- ADDED: uaediskchange utility
- ADDED: French and German DLLs updated, Italian DLL added.  (Thanks Georg V,
         FagEmul, and Daniele G)
- CHANGED: Tweaked the sound code again, memory-leak should be gone, performance
           should be better - expect a speed decrease when using JIT and sound.
- CHANGED: Graphics glitches caused by NOVSYNC flipping should be gone in full-
           screen mode.
- REMOVED: Turkish DLL, as it was out-of-date
______________________________________________________________________________
WinUAE 0.8.16 Release 2
==============================================================================
- FIXED: Stupid shift-key issue (me)
- FIXED: Should be back to 50Hz at A500 speed emulation, so audio latency should
         be reduced or non-existant. (me)
- FIXED: Graphics-updates may work now on Voodoo cards (Toni, me)
- FIXED: Updated file-version info in WinUAE.exe resource. (Georg)
- FIXED: Bug with version-number checking and GUI DLLs (Georg)
______________________________________________________________________________
WinUAE 0.8.16 Release 1
==============================================================================
- FIXED: Better 040 compatibility (Toni, Bernd#3, Gwenole)
- FIXED: Even more 040 and debugger compatibility (Toni, Bernd#3, Gwenole)
- FIXED: Fixed the cleanup_sound() routine to not crash on some systems (Andreas)
- FIXED: AGA support (Toni)
- FIXED: Don't die on CPUs (Cyrix) which don't have rdtsc instruction
- FIXED: Printing from within FinalWriter (Bernd#3)
- FIXED: Graphics printing should work now. (Bernd#3)
- FIXED: Translated GUI libraries are only loaded if their version number is
         0.8.16.1 now, so that the GUI is consistent across languages for a
         given WinUAE version.
- FIXED: Horizontal/vertical lines are 2x faster in Picasso96 (Bernd#3)
- FIXED: Floppy disk emulation tweaks (Toni Wilen)
- FIXED: Auto-activation of WinUAE window is smarter now.
- FIXED: Bug with flipping surfaces in DirectDraw.  If the flipping-pair was
         not properly created (say the primary was in video-ram, but the
         secondary was in system-ram) and cannot be flipped, we tried to
         flip anyways.  This would fill up the log with flip-failure reports.
- FIXED: Infinite loops when GetBytesPerPixel fails.  Still looking into why
         GetBytesPerPixel fails in some weird circumstances.
- FIXED: "more compatible" string in CPU page of GUI is no longer too long.
- FIXED: Mouse-pointer reappears when message-boxes pop up.
- FIXED: Mouse-button state isn't kept across screen-mode changes (Bernd#3)
- FIXED: Clear the write-protect bit when copying files from read-only media.
         This fixes the icon overwrite problem when installing OS 3.5 and 3.9.
         (Bernd#3)
- FIXED: Added a hack for volume-names of "AmigaOS3.5" and "AmigaOS3.9" to be
         used even though Windows shows "AmigaOS35" and "AmigaOS39". (Bernd#3)
- FIXED: Make sure that the Windows mouse-pointer is not active on an Amiga
         screen-mode switch. (Bernd#3)
- FIXED: Fixed timing problems on SpeedStep mobile processors, due to their
         strange RDTSC implementation being variable.  Instead, use the OS
         provided QueryPerformanceCounter(), which actually works but
         has much lower resolution.
- FIXED: Framerate reporting. (Toni)
- FIXED: Maximum number of Picasso96 screen-modes is increased.
- FIXED: Screen refresh bug when minimizing/maximizing full-screen Amiga gfx.
- FIXED: Now use gzip.dll for .adz/.roz handling.
- FIXED: Floppy disks can be written/formatted again.
- FIXED: Disk-select logic for certain demos (Toni)
- FIXED: Bogus printer loading when printer is "none" in GUI.
- FIXED: Incorrect block-size reporting for HardDiskFiles (.hdf) in GUI
- FIXED: Keyboard stickiness during screen-switches, and/or F12 GUI. (Bernd#3)
- ADDED: JIT support for massive speed increase (Bernd#2)
- ADDED: "mixed stereo" setting in the Sound page of the GUI.
- ADDED: "CTRL-F11 to quit" setting in Misc page of the GUI.  ALT-F4 can then
         be used by the Amiga properly, and CTRL-F11 will quit WinUAE.
- ADDED: Virtual screens in Picasso96 (Bernd Roesch)
- ADDED: MIDI-In support (Bernd Roesch)
- CHANGED: Slightly different compile flags, resulting code may be faster (?)
- CHANGED: Moved the Immediate Blit option from Misc to Display page of GUI
- CHANGED: Use some of WinFellow's fsdb code in WinUAE.
- CHANGED: Picasso96 rendering/display engine (Larry, Curly, me)
- CHANGED: AIAB web-link in About page of GUI.
- REMOVED: 32-bit Blitter option is gone now (no longer applies)
- REMOVED: 24-bit display-mode support.
- REMOVED: Enforcer-logging option in Misc page of GUI
- REMOVED: DirectDraw6 option in Misc page of GUI (now the default)
- REMOVED: NT4 support.
______________________________________________________________________________
WinUAE 0.8.14 Release 3
==============================================================================
- FIXED: Stupid frames-per-second bug whenever the GUI has been displayed.
- FIXED: Graphics garbage at bottom of Amiga screens whenever the GUI is
         displayed and moved around (in windowed-mode).
- FIXED: Enabling "Show LEDs in full-screen" once running didn't actually work.
- FIXED: Speed of emulation is no longer "crazy" when sound is disabled.
- FIXED: Crashing with certain .uae config-files, including default.uae.
- FIXED: Minimizing WinUAE and then restoring it wasn't restoring sound.
- FIXED: Screen refresh bug when minimizing/maximizing full-screen Amiga gfx.
- FIXED: Now use gzip.dll (included) for .adz/.roz handling.
- ADDED: Can now adjust sound preferences while the emulation is running.
- ADDED: Turkish GUI DLL to installer
- CHANGED: Printing support in the GUI is now based on a printer-name, not a
           physical printer-port.  You MUST have a printer-driver on the Amiga
           side that matches your actual printer.
- REMOVED: Ability to adjust the floppy-disk speed.  This "feature" doesn't
           exist in the core UAE version, and can also cause incompatabilities.
______________________________________________________________________________
WinUAE 0.8.14 Release 3 (the Stupid release)
==============================================================================
- FIXED: Stupid bug with GUI (F12) when in full-screen mode.
- FIXED: Stupid Picasso96 slow-down in Release 2
- FIXED: Stupid Picasso96 bug with menu painting from Release 2
- ADDED: French GUI DLL to installer
______________________________________________________________________________
WinUAE 0.8.14 Release 2
==============================================================================
- FIXED: Picasso96 screen-modes weren't being drawn/updated correctly.
- FIXED: Sound-buffer slider gets disabled when no audio output is selected.
- FIXED: German GUI DLL is accurate now. (Thanks Georg)
- ADDED: Flicker-free Amiga screen updates when full-screen.  Doesn't affect
         Picasso96 screens, though.
- CHANGED: Sound output tweaked again, should be "slightly" better.
______________________________________________________________________________
WinUAE 0.8.14 Release 1
==============================================================================
- FIXED: When WinUAE is full-screen, the Message dialog-box no longer "hides"
         and locks up WinUAE.  Instead, WinUAE will automatically minimize
         itself and display the dialog-box on the Windows Desktop.
- FIXED: log-file no longer fills up with blit failure reports.
- FIXED: Some resources (critical-sections, threads) weren't being cleaned-up.
- FIXED: [Load From...] button now works properly.
- FIXED: .uae config-files with spaces in them are now supported when double-
         clicked.
- FIXED: Increased compatability (Bernd, Sam, Toni)
- FIXED: Copper emulation state machine (Sam)
- FIXED: Floppy emulation and DMA (Sam, Toni)
- FIXED: CPU+FPU emulation bugs (Sam, Christian Bauer, Toni, me)
- FIXED: Only allow a single instance of WinUAE to be running.
- FIXED: Joystick support under Win2K.
- FIXED: Scroll-Lock to pause screen-refreshes works.
- FIXED: About-page URL link handling.
- FIXED: File-system code, including preservation of mode-bits on a rename
         (Brian Gontowski, David Varley, me)
- FIXED: File-system code can handle more than 500-files per directory now.
- ADDED: File-system now supports and persists file-notes (comments), and
         the Script, Pure, and Delete bits.
- ADDED: Floppy disk DMA slider for control of disk DMA speed (Toni)
- ADDED: Ability to disable specific floppy disk drives (Bernd)
- ADDED: "Custom" floppy creation, for use in game-saves (Toni)
- ADDED: DirectInput support for USB and other joystick devices.
- ADDED: Sound interpolation support code (Bernd), and relevent GUI changes.
- ADDED: [Info] section on Configurations page of GUI, for linking external
         text, html, or screen-shots to a particular configuration.
- ADDED: German localization of the GUI. (Georg Veichtlbauer)
- ADDED: "Back To The Roots" link in About page of GUI. (Bobic)
- CHANGED: All audio goes through WaveOut octal-buffering now.
- CHANGED: Hard-disk to local filesystem translation-layer.  MAY BE BUGGY NOW!
- CHANGED: Native CD-ROM drives are mounted as CDx: instead of DHx:
- CHANGED: Frames-per-second are only displayed in Amiga screen-modes now.
- CHANGED: Blitter, copper, and floppy emulation (from Bernd, Sam and Toni)
------------------------------------------------------------------------------

For general information about the core UAE platform, refer to:

http://www.freiburg.linux.de/~uae/

This readme file does _not_ cover the features of UAE that are common to
all versions. If you're not familiar with UAE yet, consulting the generic
distribution before attempting to use this port might actually not be a
bad idea.

The generic UAE documentation can be found in the docs directory of this
archive. Take these docs with a grain of salt, though: Not every detail of the
Linux documentation pertains to WinUAE, and vice versa.

The latest release of UAE for Win32 is available from:
http://www.winuae.net/

Also, excellent English *and* German help-files in Compiled HTML Manual (.chm)
format can be found at http://www.winuae.net/download.htm.  Many thanks
to Georg Viechtlbauer for his help with this!

If you are using Windows 95 (shame on you!) and don't have DirectX
installed yet, you need to grab and install a copy first. UAE works
with older versions of DirectX, so chances are that you won't have
any problems if you had installed a DirectX game on your machine at
least once.

There are no problems running WinUAE under Windows 2000 and XP - in fact,
Win2K or XP is the best platform to run WinUAE on - providing the best
graphics and network performance, as well as core emulation duties.

Windows NT 4.0 is not supported

| BUG REPORTS VIA EMAIL: Please make sure that the following conditions are
| met before you report any kind of problem:
|
| (1) You are using the latest version of WinUAE
| (2) You have read the documentation (90% of all potential questions are
|     answered thoroughly in the this readme file)
| (3) You have used your brain
| (4) The graphics drivers of your systems are up-to-date 
|
| If you do write me, _always_ state what version of UAE your feedback is
| pertaining to. Include all the necessary information, e.g. the command
| line options you are using.
|
| Do _not_ send me warez of any kind, no matter how non-working they are.
| Do _NOT_ ask me for ROM-files, warez, etc.

1. Command Line Parameters
==========================
UAE's command line options are now quite hidden, since we're a true
Windows application now (and not a console-application).

The most important one is:
  -config=configfile.uae
or this will also work:
  -f configfile.uae

which will cause WinUAE to load the saved config-file (which is just
ASCII format anyways).

2. File-System Specifics
========================
UAE will try its best to bridge the gap between Microsoft and Tripos file
system semantics, but there are some inherent limitations:

1. The Windows "read only" flag controls the w and d bits on the Amiga side
2. r and e are always set
3. h, s and p cannot be set
4. The a flag is preserved
5. File comments are not supported
6. Not all file names that are "forbidden" under the lame Windows fs are
   being handled correctly yet. The most common ones, however, are.

Beware: UAE does _not_ live in a chroot-like environment! There is no
checking for accesses to directories above the mount point. Do not
assume that your data is absolutely safe from rogue Amiga programs!

3. Keyboard Emulation
=====================
Most of your keyboard retains its regular functionality under UAE, but
there are a few notable exceptions:

- if you don't have a Win95 keyboard, you'll have to use Ins/Home as a
  replacement for Left Amiga/Right Amiga (this is different from other
  versions of UAE).
- HELP has been remapped to Page-Down
- F12 brings up the GUI
- Shift+F12 brings up the GUI-based debugger
- Scroll Lock toggles screen refresh, speeding up the emulation
- Pause toggles sound, speeding up the emulation (note that you can't
  enable sound this way if you haven't configured UAE to run with sound
  from the beginning).
- End+F1, F2, F3 or F4 allows you to change disks in one of the four
  Amiga disk drives. Shift+End+F1...F4 ejects the disk.

The keyboard replacements for an Amiga joystick are as follows:

                 a              b            c
Up            Keypad 8      Cursor Up        T
Down          Keypad 2     Cursor Down       B
Left          Keypad 4     Cursor Left       F
Right         Keypad 6     Cursor Right      H
Fire          Keypad 0      Right Ctrl    Left Alt

WinUAE supports gzip-compressed disk images if you have zlib.dll.

Windows 2000/XP users: Using the compression feature of NTFS instead
of gzip is a good idea if you wish to save space and be able to write
to the ADF files at the same time.

3. Performance Issues
=====================
On a sufficiently powerful PC, UAE will give you quite an authentic
flashback into a (better?) past.

Thanks to DirectX, the raw drawing throughput of this version will be
among the highest of all Intel ports. 800x600 is only about 20% slower
than 320x200 on my Pentium 100, although it requires more than seven
times as many bytes per second to be pumped across the PCI bus. UAE's
native display depth is 16 bpp. This table shows how the net drawing
speed is affected by your display type:

16 bpp full screen - 100%
16 bpp desktop     -  98% 
24 bpp desktop     -  72%
32 bpp desktop     -  60%

Sound is a luxury. Because sound output is strictly synchronized with
video DMA, you _won't_ get clean sound _unless_ your machine is capable
of running at 50 fps at least internally.

Rule of thumb: Get a PPro or Pentium II if you want full graphics and
full sound at the same time (reportedly, the Pentium MMX 200 MHz,
overclocked to 250 MHz [83.3 MHz bus speed], is a powerful platform
for running UAE. I have no definite reports about the K6 and the M2 yet,
but these should do pretty good as well.).

On a Pentium 100 equipped with a Matrox Millennium, UAE-Win32/DirectX
is slightly faster than the Linux version under AcceleratedX for programs
that perform a _lot_ of screen updates, i.e. action games and demos.
All other things should run at roughly the same speed.

4. Compatibility
================
The number of programs that don't run properly under UAE decreases with
every new release. If you find a piece of software to require special
treatment, please let me know. I have received copies of pirated software
in my email in the past. Never ever do this to me.

Consult compatibility.txt for tips on how to get software running and a
growing collection of user-submitted parameters.

A few broken programs require instruction prefetch and/or exception 3
to be emulated (e.g.  Shadow of the Beast I, Katakis and Denaris). These
can be forced to run by playing with the "compatible-mode" CPU-flag in
the CPU-settings section of the GUI.

5. Acknowledgements
===================
to Bernd Schmidt for creating this comprehensive emulation of the most
complex home computer ever

to Mathias Ortmann, for all his pioneering WinUAE efforts, and the meat of this
document

to Microsoft for contributing an excellent IDE and an operating system that
hasn't crashed a single time during the development of this project,
although I've done some pretty nonstandard things to it repeatedly :->

to the Free Software Foundation for providing an invaluable set of tools

to Cygnus Software for porting them over to the Win32 environment

to Thomas Kessler for mercilessly tracking down and reporting even the
most subtle bug

to Andreas Schildbach for providing several hundred MIPS of raw CPU power and
demonstrating that this program will actually make sense on the entry-level
PC generation of 1998. :-)

to Cloanto for their Amiga Forever work

to JayBee for his AIAB work

to Christian Buchner (flower-power) for his work on a uaescsi.device

to all the mirror-sites and their owners

to those who have contributed to my Internet funding


6. Known Bugs/Issues:
=====================
Please see the WinUAE home-page at http://www.winuae.net/

Please use the following type of template with all bug reports:
1. Amiga OS versions (kickstart and workbench)
2. Extensions running (MagicWB, NewIcons, DirOPUS, ToolManager, etc.)
3. Settings of Amiga that caused the problem
4. HostOS (Win95, Win95-OSR2, Win2K, etc.)
5. DirectX version
6. PC Graphics card and its driver's version
7. Sound card and its driver's version
