* Startup.asm  - A working tested version of startup from Howtocode7
*
* Written by CJ of SAE... Freeware. Share and Enjoy!
*
* This code sets up one of two copperlists (one for PAL and one for NTSC)
* machines. It shows something to celebrate 3(?) years since the Berlin
* wall came down :-) Press left mouse button to return to normality.
* Tested on Amiga 3000 (ECS/V39 Kickstart) and Amiga 1200 (AGA/V39)
*
* $VER: startup.asm V7.tested (17.4.92)
* Valid on day of purchase only. No re-admission. No rain-checks.
* Now less bugs and more likely to work.
*
* Tested with Hisoft Devpac V3 and Argasm V1.09d
*
* Now added OS legal code to switch sprite resolutions. Ok, big deal
* this 'demo' doesn't use any sprites. But that's the sort of effort I
* go to on your behalf!   - CJ

        opt     l-,CHKIMM                   ; auto link, optimise on

        section mycode,code             ; need not be in chipram

        incdir  "include:"
        include "exec/types.i"
        include "exec/funcdef.i"        ; keep code simple and
        include "exec/exec.i"           ; the includes!
        include "libraries/dosextens.i"
        include "graphics/gfxbase.i"
        include "intuition/screens.i"
        include "graphics/videocontrol.i"

        include "howtocode:source/include/graphics_lib.i"    ; Well done CBM!
        include "howtocode:source/include/exec_lib.i"        ; They keep on
        include "howtocode:source/include/intuition_lib.i"   ; forgetting these!

        include "howtocode:source/include/iconstartup.i"     ; Allows startup from icon


        move.l  4.w,a6
        sub.l   a1,a1                   ; Zero - Find current task
        jsr     _LVOFindTask(a6)

        move.l  d0,a1
        moveq   #127,d0                 ; task priority to very high...
        jsr     _LVOSetTaskPri(a6)

        move.l  4.w,a6                  ; get ExecBase
        lea     intname(pc),a1          ;
        moveq   #39,d0                  ; Kickstart 3.0 or higher
        jsr     _LVOOpenLibrary(a6)
        move.l  d0,_IntuitionBase       ; store intuitionbase
;       Note! if this fails then kickstart is <V39.


        move.l  4.w,a6                  ; get ExecBase
        lea     gfxname(pc),a1          ; graphics name
        moveq   #33,d0                  ; Kickstart 1.2 or higher
        jsr     _LVOOpenLibrary(a6)
        tst.l   d0
        beq     End                     ; failed to open? Then quit

        move.l  d0,_GfxBase
        move.l  d0,a6
        move.l  gb_ActiView(a6),wbview  ; store current view address

        tst.l   _IntuitionBase          ; Intuition open? (V39 or higher)
        beq.s   .skip

        bsr     FixSpritesSetup         ; fix V39 sprite bug...

        move.l  _GfxBase,a6
.skip   sub.l   a1,a1                   ; clear a1
        jsr     _LVOLoadView(a6)        ; Flush View to nothing
        jsr     _LVOWaitTOF(a6)         ; Wait once
        jsr     _LVOWaitTOF(a6)         ; Wait again.

; Note: Something could come along inbetween the LoadView and
; your copper setup. But only if you decide to run something
; else after you start loading the demo. That's far to stupid
; to bother testing for in my opininon!!!  If you want
; to stop this, then a Forbid() won't work (WaitTOF() disables
; Forbid state) so you'll have to do Forbid() *and* write your
; own WaitTOF() replacement. No thanks... I'll stick to running
; one demo at a time :-)

        move.l  4.w,a6
        cmp.w   #36,LIB_VERSION(a6)     ; check for Kickstart 2
        blt.s   .oldks                  ; nope...

; kickstart 2 or higher.. We can check for NTSC properly...

        move.l  _GfxBase,a6
        btst    #2,gb_DisplayFlags(a6)  ; Check for PAL
        bne.s   .pal
        bra.s   .ntsc

.oldks  ; you really should upgrade!  Check for V1.x kickstart


        move.l  4.w,a6                  ; execbase
        cmp.b   #50,VBlankFrequency(a6) ; Am I *running* PAL?
        bne.s   .ntsc

.pal
        move.l  #mycopper,$dff080.L       ; bang it straight in.
        bra.s   .lp

.ntsc
        move.l  #mycopperntsc,$dff080.L


.lp     btst    #6,$bfe001              ; ok.. I'll do an input
        bne.s   .lp                     ; handler next time.

CloseDown:

        tst.l   _IntuitionBase          ; Intuiton open?
        beq.s   .sk                     ; if not, skip...

        bsr     ReturnSpritesToNormal

.sk     move.l  wbview(pc),a1
        move.l  _GfxBase,a6
        jsr     _LVOLoadView(a6)        ; Fix view
        jsr     _LVOWaitTOF(a6)
        jsr     _LVOWaitTOF(a6)         ; wait for LoadView()

        move.l  gb_copinit(a6),$dff080.L  ; Kick it into life

        move.l   _IntuitionBase,a6
        jsr      _LVORethinkDisplay(a6)     ; and rethink....

        move.l  _GfxBase,a1
        move.l  4.w,a6
        jsr     _LVOCloseLibrary(a6)    ; close graphics.library

        move.l  _IntuitionBase,d0
        beq.s   End                     ; if not open, don't close!
        move.l  d0,a1
        jsr     _LVOCloseLibrary(a6)

End:    moveq   #0,d0                   ; clear d0 for exit
        rts                             ; back to workbench/cli


;
; This bit fixes problems with sprites in V39 kickstart
; it is only called if intuition.library opens, which in this
; case is only if V39 or higher kickstart is installed. If you
; require intuition.library you will need to change the
; openlibrary code to open V33+ Intuition and add a V39 test before
; calling this code (which is only required for V39+ Kickstart)
;

FixSpritesSetup:
        move.l   _IntuitionBase,a6          ; open intuition.library first!
        lea      wbname,a0
        jsr      _LVOLockPubScreen(a6)

        tst.l    d0                         ; Could I lock Workbench?
        beq.s    .error                     ; if not, error
        move.l   d0,wbscreen
        move.l   d0,a0

        move.l   sc_ViewPort+vp_ColorMap(a0),a0
        lea      taglist,a1
        move.l   _GfxBase,a6                ; open graphics.library first!
        jsr      _LVOVideoControl(a6)       ;

        move.l   resolution,oldres          ; store old resolution

        move.l   #SPRITERESN_140NS,resolution
        move.l   #VTAG_SPRITERESN_SET,taglist

        move.l   wbscreen,a0
        move.l   sc_ViewPort+vp_ColorMap(a0),a0
        lea      taglist,a1
        jsr      _LVOVideoControl(a6)       ; set sprites to lores

        move.l   wbscreen,a0
        move.l   _IntuitionBase,a6
        jsr      _LVOMakeScreen(a6)
        jsr      _LVORethinkDisplay(a6)     ; and rebuild system copperlists

; Sprites are now set back to 140ns in a system friendly manner!

.error
        rts

ReturnSpritesToNormal:
; If you mess with sprite resolution you must return resolution
; back to workbench standard on return! This code will do that...

        move.l   wbscreen,d0
        beq.s    .error
        move.l   d0,a0

        move.l   oldres,resolution          ; change taglist
        lea      taglist,a1
        move.l   sc_ViewPort+vp_ColorMap(a0),a0
        move.l   _GfxBase,a6
        jsr      _LVOVideoControl(a6)       ; return sprites to normal.

        move.l   _IntuitionBase,a6
        move.l   wbscreen,a0
        jsr      _LVOMakeScreen(a6)         ; and rebuild screen

        move.l   wbscreen,a1
        sub.l    a0,a0
        jsr      _LVOUnlockPubScreen(a6)

.error
        rts


wbview          dc.l  0
_GfxBase        dc.l  0
_IntuitionBase  dc.l  0
oldres          dc.l  0
wbscreen        dc.l  0

taglist         dc.l  VTAG_SPRITERESN_GET
resolution      dc.l  SPRITERESN_ECS
                dc.l  TAG_DONE,0

wbname          dc.b  "Workbench",0
gfxname         dc.b  "graphics.library",0
intname         dc.b  "intuition.library",0



        section mydata,data_c           ;  keep data & code seperate!

mycopper        dc.w    $100,$0200      ; otherwise no display!
                dc.w    $180,$00
                dc.w    $8107,$fffe     ; wait for $8107,$fffe
                dc.w    $180
co              dc.w    $f0f            ; background red
                dc.w    $d607,$fffe     ; wait for $d607,$fffe
                dc.w    $180,$ff0       ; background yellow
                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe

mycopperntsc
                dc.w    $100,$0200      ; otherwise no display!
                dc.w    $180,$00
                dc.w    $6e07,$fffe     ; wait for $6e07,$fffe
                dc.w    $180,$f00       ; background red
                dc.w    $b007,$fffe     ; wait for $b007,$fffe
                dc.w    $180,$ff0       ; background yellow
                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe

         end
