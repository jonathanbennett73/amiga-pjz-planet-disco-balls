                        The JIT compiler for UAE

Introduction
============

UAE has always been hampered by being somewhat lacking in CPU performance.
Undoubtedly, it was amazingly fast for what it did, but it never really
was an alternative to a decked out, no expense spared Amiga.

The Just In Time compiler should help change that.

If you just want to know how to *use* it, rather than how it works,
stop right now and read the file README.umisef. Yep, that name is obscure;
I just wanted to make sure you at least look at this one once ;-)

Normal Emulation
================

In order to understand how the JIT compiler works, and especially how
it speeds up emulation, one has to first understand how the normal UAE
CPU emulation works. As an example, here is a small 68k routine that
copies a block of memory, from A1 to 0x42000000. 

         mov.l 0x42000000,A0
loop:    mov.l (A1+),(A0+)
         cmp.l 0x42010000,A0
         bne   loop

The syntax might be a bit off, but you get the idea.

The normal emulation works one instruction at a time. It maintains a 
pointer to where the next instruction can be found in the host's memory
(which means you can only execute stuff from "real" memory --- can't
execute the CIA registers, for example ;-).

As a first step, the emulation loads the 16 bit value that pointer points
to, i.e. the opcode. The opcode is then used as an index into a lookup
table that contains 65536 pointers to functions; The functions pointed to
are the respective handlers for the instructions matching the opcode.

Next comes the actual call of that routine. In order to make life easier
(and UAE a managable size), most handler routines handle more than one
opcode --- for example, our mov.l (A1+),(A0+) would be handled by the
same routine as mov.l (A7+),(A3+). In order to handle all the different
opcodes for which they can be called, most handler routines extract the
numbers of the registers used from the opcode (which gets that passed as
an argument). In order to do so, they have to shift the bits in the 
opcode around a little, and then mask out the needed bits. That then gives
indices into the array that holds the current values for the registers;
If a register is read from or written to, the indices are used to calculate
the actual address to read from or write to.

OK, almost done --- one rather small part of emulating an instruction is
actually *doing* it. The mov.l instructions up there basically just realize
that they should store their source in their destination, the cmp.l subtracts
the immediate from the register's value, and the bne looks at the flags and
decides whether or not to change the instruction pointer.

Last but not least comes the cleanup --- if the instruction is supposed to
produce flags, these need to be calculated; Also, the instruction pointer
gets moved to the next instruction. Then any changed registers, any
changed flags and changed state information is written back to the 
respective memory locations, the handler routine executes a return, and
the whole cycles starts again.

Bottlenecks
===========

This way of doing it has several big performance drawbacks. At the very
start, the instruction fetch and handler lookup look sort of like this:

    opcode=*instruction_pointer;
    handler=handlers[opcode];
    call handler;

That's two memory accesses before we even reach the "call", and it's a
straight dependency chain --- each instruction depends on the result
of the previous. Hopefully, all those memory locations are in the L1,
but even then, the latency is 3 cycles each time (on a PII), for 6 cycles 
minimum so far.
Another real biggie is the call instruction --- it is always the *same*
instruction, but the target changes around all the time. This means that
the CPU has little hope of ever predicting the target correctly, leading
to a pipeline stall. Uh-oh! Pipeline stalls are *really* expensive on the
PII, to the tune of 10 or so cycles. The total is up to 16.
Most 68k instructions read at least one register, so most handler start
out with a shift, an AND, and then an indexed memory access. Of course,
they depend on each other, so the minimum time for this is another 5
cycles before the register value can be used. Total 21, and we haven't done
a thing yet.
Then most instructions create flags. For many of the most often used
instructions, the x86 instruction that does the calculation will produce
the right flags (and for mov's, an extra TEST x86 instruction will do
the trick). UAE is clever to pick these up --- but isn't clever in the
way it does it. It uses pushf --- which translates in 16 micro-ops and
takes at least 7 cycles. There is a better way (using LAHF and TESTO),
but unless one is very careful, that way can easily lead to a so called
"partial register stall" --- which just means that we get screwed in a 
whole new and interesting way, but screwed we get, for another 7 cycles
or so. We are now up to 28, just for the overhead of a typical instruction.
[ Update: The latest versions of UAE-JIT contains patches that overcome 
some of the flag-handling problems of the normal emulation. By and large,
the above is still true, though]

Considering the need to increment the instruction pointer, write back
the registers and flags to memory, and the "ret", and also considering
that the handlers are allowed to clobber any flags they like, and that
thus there is an extra memory read at the very start of the whole thing
(rereading the instruction pointer from memory), the total overhead is
something lik 35 cycles. That easily dwarfs the time it actually takes
to *do* whatever the instrutions are supposed to do (and 35 is assuming
the ideal case, where all the memory accesses are satisfied from L1).

There is one more performance killer --- 68k instructions that access memory
(and let's face it, that's most of them ;-). Unfortunately, the 68k uses
memory mapped I/O, so an innocent mov.l (A1+),(A0+) could access just
about *anything*, depending on the values of A1 and A0. This means that
each memory access has to go through several steps --- first, the address
gets shifted 16 bits to the right and the result taken as an index into a
lookup table. That yields a pointer to a structure; In that structure,
the addresses of handler routines for reading and writing bytes, words or
longwords can be found. So one more memory access gets the address of an
appropriate handler, which then gets called (yep, a calculated subroutine
call for every single memory access!). The handlers for "real" memory
then mask the address, add it to the base address for their memory segment,
and perform the requested operation. This takes a *lot* of time. It also
(potentially) clobbers many registers, so that the instruction handler 
routine often has to temporarily store stuff on the stack to keep it
past the memory access.

Take all that together, and you get to a pretty constant average of 70 or 
so x86 cycles per emulated m68k instruction. If it wasn't for great fast
x86 chips, this would be really bad. As it stands, it's just annoying.


Solving the Bottlenecks
=======================

Right! Time to solve some of these problems. Let's start at the top:
The 2 memory lookups and the calculated call at the start of emulating
each instruction will always give the exact same results for any given
instruction. So the obvious thing to do is to do it all once, and then
keep the state around.
At this point, the concept of a "block" needs to be introduced. A "block"
is a bunch of consecutive instructions that will *always* execute all
together, one after the other, as long as the first one is executed.
In the example, there are two interesting blocks. Here is the example
again:

            mov.l 0x42000000,A0
   loop:    mov.l (A1+),(A0+)
            cmp.l 0x42010000,A0
            bne   loop

The first interesting block consists of all 4 instructions. The second
interesting block starts at "loop" and consists of three instructions.
The important thing here is that the "bne loop" instruction definitely
ends a block --- what instruction comes after it depends on the state
of the flags, and thus any "find out once and keep the info" scheme
cannot work it out.
One of the ideas behind the x86 compiler is that it operates on blocks.
So whenever a block ends, we *then* check whether there is some pretranslated
stuff for the block starting with the next instruction. If yes, that
pretranslated stuff (a whole block) is executed. If not, the normal
emulation is done in the normal way until it hits an end-of-block
instruction. This means that for each block, the cache of pretranslated
stuff is only checked once, reducing the extra overhead introduced by
those checks. However, while doing the normal emulation, we also keep
track of what locations the opcodes in the block were fetched from.

A simple compiler can do something rather ingenious --- whenever the
normal emulation finishes a block, it "compiles" it into a series of
native x86 instructions along the lines of

       mov $opcode1,%eax
       call $handler1
       mov $opcode2,%eax
       call $handler2
       mov $opcode3,%eax
       call $handler3
       
and so on (the opcodes get loaded into %eax so that the handler routines
can shift and mask them like they expect to). This has several advantages:

  * The whole get-instruction-pointer-then-fetch-opcode-and-look-up-handler 
    stuff is done once, during compile time, and then is encoded directly 
    in the x86 instruction stream. Saves about 9 cycles per instruction.
  * The calls are no longer calculated, but rather constant, and each
    68k instruction has a call of its own --- which will give the host CPU
    ample opportunity to correctly predict the targets, thus saving another
    10 or so cycles per instruction.

"Compiling" blocks in this way (and recognizing blocks in the first place)
creates another opportunity to save a few cycles. In the example code,
the mov.l (A1+),(A0+) is *always* followed by the comparison instruction.
The comparison doesn't use any flags, and overwrites any flags the mov.l
might have set or cleared. In other words, the flags generated by the mov.l
can never make any difference. Because this can be determined during
compilation time, and because the particular mov.l gets compiled into
a particular call, we can call a different handler for it --- one which
does the same thing, but just doesn't bother generating any flags. Of course,
those handlers need to be generated somehow, but that's trivial. And
every time generating the flags can be avoided by this, it save another 
7 or more cycles.

One more problem --- what happens when the 68k overwrites some memory we
have pretranslated? Well, Motorola did the right thing, and didn't fudge
some silly logic into their processors that transparently detects this
situation. Instead, if you want the CPU to acknowledge new code, you need
to explicitly flush the icache. And every time the emulated 68020 does
that, we simply throw away all translations and restart with a blank slate.

Implementing these rather simple compilation options will result in 30-100%
speedup, depending on the task.


Getting more aggressive
=======================

Once we have taken that first step, however, and have all the infrastructure
for detecting and handling blocks in place, it becomes soooo much easier
to get a little bit more aggressive, step by step.

First, instead of outputting the 

      mov $opcode_x,%eax
      call $handler_x

sequence, we can directly output code to just do what the instruction is
supposed to do. And we can do this step by step, because if we can't handle
a particular instruction, there is always the simple mov/call pair to fall
back on. Of course, the best choices for opcodes to do this for first are
the opcodes that get executed the most. And because at compile time, we
already know the exact opcode, we can work out what registers get used
*then*, and can simply address them directly (rather than doing the 
shift-mask-and-address_indexed routine of the normal handler routine).
And of course it also saves the call/return overhead, not to mention that
some of the hand-designed x86 code tends to be a fair bit more efficient
than what gcc creates from the portable C code.

A word about how to do the translating --- UAE has a wonderful framework
in place to generate the handler routines for the normal emulation. Simply
copying that framework allows us to create translation routines in much
the same way. Of course, instead of actually *doing* stuff, those routines
must themselves *generate code* that will eventually do stuff, and this
extra level of indirection (writing a program which outputs routines which
generate routines which emulate 68k instructions) can be a bit mind-twisting
at times, but it definitely beats the alternatives.

And here is another word of hard earned wisdom (aka "Tried it, and after
a few days, had myself thoroughly backed into a corner, so had to scrap
it" ;-): Keep it simple. Don't try to cram too much into one layer,
rather introduce more layers, just as long as you can keep each one
simple and manageable.
In the UAE JIT compiler, the translation routines generated don't actually
contain code to emit x86 code. Instead, they contain lots of calls along the
lines of

      mov_l_rr(src,dst);
      cmp_l_ri(dst,1889);

and so on. Here is an almost-actual example (I removed some stuff that
we haven't dealt with yet, and formatted more nicely):

{
	uae_s32 srcreg = imm8_table[((opcode >> 1) & 7)];
	uae_s32 dstreg = (opcode >> 8) & 7;
        uae_u8 scratchie=S1;
	int src = scratchie++;
	mov_l_ri(src,srcreg);
        {
		int dst=dstreg+8;
		int tmp=scratchie++;
		sign_extend_16_rr(tmp,src);
		add_l(dst,tmp);
		mov_l_rr(dstreg+8,dst);
	}
}

That's the code that would get called for  "mov.w 3,a0". The way it works
is like this --- the routine targets an x86-like processor, but one with
32 registers. The first 16 of these are mapped to D0-D7 and A0-A7; The
next three hold flags and the instruction pointer, and then there are 13
scratch registers, S1 to S13. First, the routine works out what register
and immediate to use. It then calls mov_l_ri(), which will generate code
to move the immediate into a register (in this case, a scratch register).
That value then gets sign extended (pointless in this case, but that's 
what you get for generating these routines with a program...) into yet
another scratch register, then adds the immediate to the register, and
moves the result back into the register. But all the translation routine does
is to call other routines which will (eventually) generate the code.

Writing this sort of code is manageable. In the next layer down, the 32
register x86 gets mapped onto the real, 7 register PII, i.e. register
allocation takes place. Also, some optimization takes place here ---
in the example above, the last mov_l_rr() gets ignored, because its source
and destination are the same. Also, if an immediate is moved into a 
register (and that register thus has a known value, like "src" in the
example), more optimization is possible, and is indeed done. As a result
of that optimization, the superfluous sign extension never actually makes
it into x86 code for this example.
Last but not least, this layer keeps track of what 68k registers need
to be written back to memory to complete the emulated instruction.

On the lowest layer, actual bits and bytes are written to memory to encode
raw x86 instructions. If you happen to have an x86-like processor that just
happens to use different instruction encodings, this layer is all you'd need
to change. To actually port to a different target processor, such as a PPC
or StrongArm, you'd have to take care of some more details related to the
way x86 instructions do and don't set flags, but you should still benefit
greatly from the clear separation of layers (hint, hint !-).

Each of those layers is fairly complex (and the ^%&$$#$%&*& x86 certainly
doesn't make it any easier; Orthogonality, what's that?), but I can wrap
my mind around each one individually. Trying to do it all in one go would
be far beyond me.


Using these techniques, it is fairly simple to cover 90+ percent of all
the instructions that get executed in a typical Amiga application, and
the resulting speedup is rather nice.


Beyond Individual Instructions
==============================

When 90+ percent of instructions are covered, it's fairly likely that
a real translated instruction is followed by another. In that case,
there really isn't much point in writing back all the 68k registers at
the end of the first, only to reload them at the start of the second.
So instead of writing back between any two instructions, the whole
state of the middle layer (which handles register allocation) is simply
kept alive. Of course, we still need to write it all back each time
we fall back on the mov/call method, because those handlers expect
the 68k registers/flags/other state to live in certain places in
memory. That's why it can pay off to generate translation routines for
rarely used instructions --- the average lifetime of a middle-layer
state might increase dramatically. Oh, and of course at the end of a
block everything needs to be written back.


Memory Access
=============

If you do all that, you run up against the last remaining performance killer:
Memory access. Nothing will screw up your performance like the occasional
call to a C function that will not only take several cycles for itself, but
will also potentially clobber all your registers --- meaning you have to 
store it all back before the call, and start from scratch afterwards.

The *vast* majority of memory accesses are to "real" memory. The JIT
compiler has two methods for speeding these up.
The first method is simple, safe and a good bit faster than the default
memory access (see above). For this method, instead of having a lookup
table with 65536 pointers to structures that tell us how to get to memory,
we have another table with 65536 values. For memory areas which are 
*not* real memory, this table holds the same info as the other one,
except that the LSB is set. However, for memory areas which *are* 
real memory, this table holds the difference between the address the
x86 sees and the address the emulated Amiga sees. 
So a memory access looks up the content of the appropriate slot in the
table. If the LSB is set, the usual song and dance has to be done. But
if the LSB is clear, we simply add the Amiga address to what we got
from the table, and voila, there is the x86 address of real memory,
from which we can load (or to which we can write) our value, without
calling any C routines, and without clobbering registers. 

The other method is much more radical. The Amiga, while it has an address
space of 4GB, only seems to use less than 1.5G of that (From 0x00000000
to 0x60000000). Linux, at least in the 2.4 flavour, allows user programs
pretty much full control over 3GB; But it, too, tends to leave 0x50000000
to 0xbfff0000 unused.
In order to make things fast, we simply map all the real memory from the
Amiga into Linux's address space, with a constant offset. In particular,
the Amiga address X ends up at Linux address 0x50000000+X; So when a 
translation routine wants to generate a memory access at address Y
*and* knows that this access goes to real memory, then it can simply
access the memory at 0x50000000+Y. The magic behind the scenes that is
needed to keep those mappings accurate is a bit complicated, mainly
because the Amiga tends to overmap some areas over and over, but none
of that is really worrysome.
The much bigger problem is "How the heck do we know whether a particular
instruction accesses real mem or I/O?". And here comes the major
hand-waving: We guess! We are making the assumption that any given
instruction will either always access real memory, or always access
I/O. In other words, we expect this to be consistent.
Based on those assumptions, during the normal emulation (i.e. the
data-gathering phase for the compiler), we simply set a flag to 0 
before emulating each instruction; All the I/O memory handlers contain
code that set this flag to non-zero, so if the instruction completes and
the flag is still 0, then that instruction didn't access any I/O. During
the data gathering, the value of this flag is saved after each instruction,
and thus when it comes to compiling, the translation routines know whether
or not the instruction they are translating can use the aggressive method
for memory access.

Alas, these assumptions don't always hold. That's why there are many
options for forcing memory access to the slower but safer method. 
If the assumptions don't hold, you will notice --- because there is
no safety net, you *will* get a lovely core dump. (Theoretically,
it would be possible to write a SIGSEGV handler that works out what
the instruction that failed tried to do, and calls the appropriate 
I/O handler; I have done that in the past for the Alpha, but the idea
of trying to decode x86 instructions fills me with dread and fear.
Any takers? ;-). [Update: Hey, that was easier than I imagined --- such
a SIGSEGV handler is now in place, and apparently working just fine. Of
course, it isn't completely general, but instead only handles the
instructions I use for direct memory access....]



Conclusion
==========

UAE can now emulate the CPU at considerably more than 060 speeds. That
should do for a while --- although I am sure that further speedups are
still possible. Patches welcome ;-)

