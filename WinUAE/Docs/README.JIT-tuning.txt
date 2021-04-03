                How to get maximum performance out of UAE-JIT
                =============================================

A) How to disable the configuration checks in UAE-JIT
-----------------------------------------------------
If you are reading this, chances are that UAE-JIT told you that your
configuration is suboptimal, and quit. First of all --- if, for whatever
reason (benchmarking?), you want to use such a configuration, you can
disable the check by adding

       compforcesettings=yes

to your UAE config file. However, please read the rest of this README,
because otherwise you might experience stability problems in addition to
the non-optimal performance!


B) Most direct memory access
----------------------------
Part of what makes UAE-JIT fast is that, for most memory accesses, it
replaces UAE's traditional, function call based routines with x86 instructions
that directly access the host memory. In order for this to work, UAE-JIT
performs some slightly convoluted mapping magic, using Linux' SYSV shared
memory segments.
It is possible for that magic to fail. That has two consequences:

  * Emulated Memory access will be slower than it could be.
  * More importantly, you might experience occasional crashes.

The crashes result from UAE-JIT trying to access Amiga "memory" that in 
reality is an area of memory mapped I/O. UAE-JIT tries to guess which
instructions access I/O and which access real memory, but it can and does
occasionally get it wrong.
Usually (when the magic succeeds), there is a safety net that catches those
mis-guessed accesses, simulates their effect on the emulation, and causes
UAE-JIT to "guess again". THIS SAFETY NET IS UNAVAILABLE WHEN NOT USING THE
MOST DIRECT MEMORY ACCESS, and thus things might crash.

Here is a list of reasons why you might experience such problems, sorted
by likelyhood (i.e. most probably, the first one is the reason):

  * You are using a large amount of memory for z3mem (like 64MB), and
    your linux kernel has a smaller limit on the maximum size of a 
    SYSV shared memory segment (see "cat /proc/sys/kernel/shmmax").
    Solutions:
      - decrease the amount of Z3 memory
      - increase the maximum size of shared memory segments by issuing
              echo 67108864 >/proc/sys/kernel/shmmax
        while logged in as root. 67108864 is 64MB, i.e. 64*1024*1024.
        Of course, you can set it to other values, if you want to, it
        just has to be at least as large as your Z3 mem
 
  * Your system is generally short on memory
    Solution:
      - Add RAM
      - Add extra swap space
      - Reduce memory sizes in UAE config file

  * You are running too old a kernel, which doesn't support some of 
    the needed functionality and/or uses a memory mapping not suitable.
    I am not aware of any such kernels, but I am sure there are some
    Solution:
      - upgrade your kernel ;-)
    
  * Something else
    Solution:
      - add the following lines to your UAE config file:
            comptrustbyte=indirect
            comptrustword=indirect
            comptrustlong=indirect
            compforcesettings=yes
        Performance will be *much* worse than optimal, and crashes are
        still at least possible, though not likely. This should only be
        a last resort, if nothing else helps. If you need to do this,
        please tell me (bmeyer@csse.monash.edu.au) about it (because I
        intend to remove those options eventually if nobody is using them)!

In summary, you *really* want to have the most direct memory access
happening!


C) comptrustxxxx Settings
-------------------------
UAE-JIT "guesses" which emulated 68k instructions access real memory,
and which access memory mapped I/O. Depending on those guesses, it compiles
them into native code differently.
The comptrust* configuration parameters allow you to override those guesses.
If, for example, you put  

       comptrustbyte=indirect

into your config file, then UAE-JIT will treat *all* byte sized memory accesses
as accessing memory mapped I/O. Of course, this will impact performance.

As explained in the previous section, there is now a safety net that 
correctly handles the cases where UAE-JIT guessed "real memory", but reality
was "memory mapped I/O" (such cases would crash earlier versions of UAE-JIT).
Thus, these configuration options are obsolete, and should be left at their
default values of "direct". 
These Options will probably go away sometime in the future, so making sure
you use the default settings will not only give you best performance, but
will also ensure that you won't be unpleasantly surprised when the default
settings become hardcoded behaviour in future versions of UAE-JIT.

If you find a reproducable crash while using the most direct memory
access which can be avoided through comptrust* settings, that is a BUG
which I need to know about! In that case, please email a detailed 
description to bmeyer@csse.monash.edu.au.


D) The compnf Option
--------------------
UAE-JIT tries to avoid generating 68k flags that are never used. Flag
generation (and storage) takes time, so avoiding it when it isn't needed
speeds things up.
However, it is possible that I screwed up, and that it might be over-aggressive
about this --- which might mean that some needed flags are not generated.

That's what the compnf ("nf" for "noflags") Option is for. Putting 

    compnf=no

into your config file (and also "compforcesettings=yes" to make UAE-JIT
accept it) will disable this feature. Of course, it will also reduce 
performance.

This option is like the comptrust* options; It will eventually go away,
and the default ('yes') will become hardcoded behaviour. If you find
any software that behaves differently with this set to 'no', it's a bug
and I need to know about it (so that I can fix it).


E) The cache flush mode
-----------------------
UAE-JIT now tries very hard to avoid recompiling code that doesn't need
a recompile. If you have

   comp_flushmode=hard

in your config file, all compiled code will get discarded each time the
68k processor issues an icache flush. That's normally not much of a problem,
but if you are running a Mac emulator inside your Amiga emulator, there
will be lots and lots of cache flushes, and you really really need to use
"soft" rather than "hard".


F) FPU Emulation
----------------
JIT FPU emulation is still very new and not very mature. It's almost certain
to be even fuller of bugs than the non-JIT FPU emulation. So if you suspect
that the JIT-FPU emu is causing you problems, put

    compfpu=no

into your UAE config file. Note that eventually (when things have
matured a bit), UAE-JIT will require the "compforcesettings=yes" to
work without the JIT-FPU, and ultimately the option is likely to
disappear.


G) Console output
-----------------
Due to its pre-Beta status, UAE-JIT still outputs a lot of info useful
for debugging to the console it was started from. In most cases, that
shouldn't have any significant effects on overall speed, but there
are exceptions.

If you suspect that console output is slowing you down, try running
like this:

    uae -f config_file  2>/dev/null >/dev/null

However, that way you won't get *any* output. In particular, if things
go wrong, and you experience a crash, you won't have any info to mail me,
so it will be much harder for me to fix what caused your crash. So please
only do this if it really helps your performance!

