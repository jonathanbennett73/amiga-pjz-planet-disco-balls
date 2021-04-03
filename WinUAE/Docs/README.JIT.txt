You found it --- this tells you how to use the JIT compiler.

First things first: This is not an explanation on how to use UAE under 
linux, or how to use UAE in general. There is other documentation about
that, and if you are not familiar with it, PLEASE read it! This document
only ever mentions stuff specific to the JIT compiler versions!

More disclaimers: This stuff is still definitely in a pre-Beta stage.
It works for me, and I am trying to make sure it works for others, too,
but it is impossible to test even a significant portion of the possible
configurations.
Most of my testing is done on 8 bit screens. Other bit depths *should*
work, but have seen little to no testing.
Things might crash at any time, and in interesting ways, and while you
can curse me for it, that's the worst you can do. No liability whatsoever!

There are two executables, uae_Xwin and uae_DGA2. Normally, you will want
to use uae_Xwin, it is the much more mature and less experimental one.
Both will connect to the X display in your DISPLAY environment variable,
bring up the GTK Gui (unless you disable it in the config file), and start
the emulation. 

If you have a working configuration file for UAE/linux, then you can
use it as-is with these executables. However, be aware that the default
settings for the new configuration options are extremely conservative,
and to get best performance, you should really change them (see below).
[Update: This is no longer true. The default settings are now pretty
much optimal, and you probably won't have any reason to change them!]

If you don't have a working configuration file, each executable comes with
a sample config file. Of course, you'll have to change a lot of options,
because your setup and mine are different, but it is a start. I recommend,
however, that you first get and install pristine UAE 0.8.15, and make
sure you *do* have *that* working correctly. UAE-JIT will have no chance
whatsoever of working correctly otherwise.


There are several new options in the config file. PLease take the time
to read through this, so you know what you are dealing with!

comptrustbyte:
comptrustword:
comptrustlong:  Possible values are direct, indirect, indirectKS,
                and afterPic.
             ***** These options are obsolete now! Leave them at their *****
             ***** default value of "direct" unless you really, really *****
             ***** have a good reason for changing them!               *****
             These describe how aggressive to be when it comes to accessing
             Amiga memory. If you choose "direct", the emulation will be
             very aggressive. If you choose "indirect", the emulation will
             always use the slower but safe method. "indirectKS" will
             use the aggressive method for all code except Kickstart code,
             and "afterPic" uses the safe method until the first time
             a Picasso96 mode is switched on, and the aggressive method
             from then on.

             I usually use "afterPic" for all of them; If this fails
             (you get a core dump and UAE exits suddenly --- for me that
             happens when starting SysInfo or GeneticSpecies2), it usually
             is enough to set comptrustbyte to "indirect". Defaults are
             "indirect" for all three. 

             Unless you are not using P96 graphics (why not?), there isn't
             much point setting this to "direct". During the startup, weird
             and wonderful things happen in the Amiga, and only having faith
             in the aggressive method once that difficult time is over is
             certainly a wise thing to do.

comptrustnaddr: Same as above.
             ***** This option is obsolete now! Leave it at its        *****
             ***** default value of "direct" unless you really, really *****
             ***** have a good reason for changing it!                 *****
             I have yet to find any software that can't handle
             "afterPic", and I'd be very surprised if there is
             any. If you find something that works with "indirect",
             but not with "afterPic", please tell me!

compnf:  "yes" or "no". Whether to optimize away flag generation when
             it isn't needed. There really shouldn't be any reason why
             you'd want to set this to "no"; If you find something that
             works with "no" and doesn't with "yes", that's a bug and
             I need to know about it! The reverse is a bug, too, but
             hopefully I squashed that one before the release ;-)

cachesize:   The size (in kb) the JIT compiler uses to store pretranslated
             code. When this becomes full, or when the OS issues a
             flush icache instruction, this gets completely emptied, and
             then refilled during execution. Setting it to 0 will
             disable the JIT compiler.

comp_flushmode: *NEW* "hard" or "soft". If this is set to soft (the default), 
             an OS induced icache flush doesn't actually empty the 
             cache, but instead checksumming will be used to check whether
             blocks have to be discarded. You'll probably want to leave this
             at its default (otherwise lots of stuff, like the OS, gets
             translated over and over).

comp_constjump: *NEW* If this is "yes" (the default), unconditional branches
             will not end a block; Effectively, UAE-JIT compiles "through"
             them. Generally, that's a good idea, as it improves performance.
             However, it makes soft cache flushing impossible for some blocks,
             so if you experience lots and lots of soft cache flushes (e.g.
             when using a Mac emulator), you might try "no" and see whether it
             does any better.

compfpu:     If this is "yes" (the default), the JIT compiler will
             be used for the most commonly used FPU instructions. Setting
             it to "no" will disable JIT-compiling for the FPU.


[Note: The "unroll" option is no longer supported. You should remove it
       from your config files if it's still in there]

[Note2: Setting some of those options to sub-optimal values will cause
       UAE-JIT to exit with a message pointing at README.JIT-tuning]
================= All of the above can be set from the GTK GUI, too ===========
================= The options below are one-time, config-file only ============

avoid_cmov: "yes" or "no". If you have a processor that doesn't support
             the P6-class CMOV instructions, you have to set this to "yes".
             The JIT compiler will then not try to translate any
             instructions for which it would generate code with CMOV
             in it. Better slower than "illegal instruction", right ;-)

avoid_dga:   If you use the Xwin executable, setting this to "yes" will
             stop it from even looking for the DGA extension. Obviously,
             it won't use it, either.

avoid_vid:   If you use the Xwin executable, setting this to "yes" will
             stop it from even looking for the Vidmode extension. Obviously,
             it won't use it, either.

[Note: the following options are not available in the "sanitized" versions
       of UAE-JIT. The executables made available on byron@csse.monash.edu.au
       are not sanitized, but if you compile your own from the patches,
       you need to include the "extra options" patch to get these. And don't
       take my use of the plural in this paragraph to mean anything --- it
       is generic ;-) ]

override_dga_address: If you use the DGA2 executable, this will allow you
             to override the linear frame buffer address DGA2 detects.
             Try it first without this, but if you just get a blank grey
             screen (and F12-S gets you a window with the right content),
             your XServer might get it wrong (seems fairly common, in fact).
             Find out the linear frame buffer address (preferably by looking
             at /proc/nnnnn/maps, with nnnnn the pid of the X server --- look
             for a mapping of /dev/mem with the right size; The offset of that
             mapping is the value you are looking for).
             In this option, you provide the *upper 16 bits* of that address.
             So if your linear frame buffer is at 0xd5000000, you set
             override_dga_address to 0xd500. Yes, the config file will take
             hex numbers.

============================ End of Options =============================

Many of these options can be changed through the GTK UI. However, as many
of them influence code *generation*, changes will only take effect when
code is newly translated; The already translated code in the cache is
uneffected.
In order to make your changes take effect, you need to force a hard cache
flush. The easiest way to do so is to change the cache size by some small
amount. Remember this step if you try to benchmark the result of various
option settings on performance, otherwise results will be rather 
inconclusive ;-)


How to get the maximum performance:
-----------------------------------

Here are a few tips on how to get the best possible performance, and to
avoid common pitfalls.

* Use a 2.3.*, or even better a 2.4test* kernel. Without it, you might 
  not be able to do aggressive memory modes (see README.JIT-tuning)
* The really aggressive memory modes use sysv_shm. By default, the
  largest sysv_shm block you can allocate at one time is 32M, so
  if you have a larger Z3Mem, allocation will fail and the aggressive
  modes get disabled.
  You can change the max size through /proc/sys/kernel/shmmax, the first
  parameter is the max size.
* Use Picasso96 modes!
* Use DGA for your actual display! (If you don't, you CANNOT make any
  comments about sluggish gfx performance. Understood?)
* Alternatively, use CGX3 with direct access to an S3 Virge PCI card
  (see README.pci)
* Set as many of the comptrust* options as possible as aggressively as
  you can without creating a crash [*** obsolete ***]
* For the adventurous: If you use the DGA2 executable with an XFree86 4.0x
  server, AND select a Picasso video mode that has the same width as your
  X virtual screen[1], AND haven't done anything else to prevent you from
  using aggressive memory access (like setting comptrust* to indirect),
  you *should* end up with vastly faster gfxmem access. This is still
  buggy, occasional display corruption when using blits occurs. But 
  for seeing how fast Doom can go on an "Amiga", this is the ticket ;-)
* If your app comes in versions for different CPUs, try all of them.
  I have had good experiences with using 040 versions, particularly
  of RC5 (use "-c 2" to select the 040 core). Of course, this only
  works if the 040 apps don't use 040-specific features, or if you
  have enabled 040 support for UAE

Feedback:
=========

I need to know about remarkable experiences you have, but I really
don't need to know about unremarkable things. Here is a little guide
as to what is what:

Remarkable:

  * Something that works with the compiler disabled, but fails with
    it enabled
  * Any occurrence of "illegal instruction" (from Linux) on a P6 class
    machine, or a P5 class machine with avoid_cmov=yes
  * Any failure to boot with a config file that does boot "normal" 
    UAE/linux
  * Anything else that you can clearly identify as an emulation bug,
    rather than as a configuration, hardware or user problem
  * Any patches you can come up with
  * Any offers of sponsorship for further work on it ;-)

Unremarkable:

  * Any failures attributable to memory shortage
  * Any problems you might have with linux, UAE or the Amiga in general,
    not specific to the JIT compiler version
  * Any statements to the effect that I am a traitor, a lamer, a wannabe,
    a loser, a demigod, a guru, a procrastinator, or anything else along
    those lines
  * Any non-constructive criticism of my coding style. Remember: The only
    valid form of criticism is a patch! (Of course, certain people
    are excepted from this, notably everyone who would be involved
    with integrating this code into other UAE versions ;-)

If you think you found something remarkable, PLEASE let me know. And
please describe the circumstances as precisely as possible --- only if
I can recreate the fault can I have a real shot at figuring out what
went wrong.


Good luck, and looking forward to your feedback,

     Bernie  (bmeyer@csse.monash.edu.au)


P.S.: There is some output to stdout/stderr while running (and some
      directly to the tty). The lines that pop up every second have
      a number of fields. Here are short explanations of each:

        * compiled: The total number of bytes the compiled code (and
                    the related bookkepping information) takes up
        * soft: Number of soft cache flushes done in the last second
        * hard: Number of hard cache flushes done in the last second
        * trans: Number of 68k blocks translated in the last second
        * check: Number of 68k blocks that had their checksums check in
                    the last second as a result of a soft cache flush
        * lost: Time "lost" during the last second of emulation time.
                This should be 0, but if the emulation can't keep up for
                some reason (like file I/O happening), it can be larger.
                The output is in seconds; Keep an eye on this if you
                do self-timed benchmarks!
        * debug/2/3/4: Internal counters I use for debugging. If you have
                software that can make debug3 and/or debug4 reach more
                than 100,000, please tell me about it --- these are counting
                non-compiled FPU instructions executed.

[1] In reality, things are even more complex --- what you need to match
    is the pitch of the mode. Normally, that matches the virtualwidth,
    but my Trident 3DImage975 uses a pitch of 1024 for a 640 wide mode....
