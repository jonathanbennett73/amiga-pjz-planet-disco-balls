	IFND _CUSTOMEXTRA_I
_CUSTOMEXTRA_I SET 1

**********************************************
* Custom Hardware File (c)1990-2021 Antiriad *
* Jonathan Bennett <jon@autoitscript.com>    *
**********************************************

;Additonal hardware related values not present in CBM includes
	IFND _custom
_custom equ $dff000
_ciaa	equ $bfe001
_ciab	equ $bfd000
	ENDC

_ExecBase	equ 4
_Kickstart_Version equ $f8000c

;Hardware registers, OCS
potgor	equ $16

dskpth	equ $20
dskptl	equ $22

bltcpth	equ $48
bltcptl	equ $4a
bltbpth	equ $4c
bltbptl	equ $4e
bltapth	equ $50
bltaptl	equ $52
bltdpth	equ $54
bltdptl	equ $56

cop1lch	equ $80
cop1lcl	equ $82
cop2lch	equ $84
cop2lcl	equ $86

aud0lch	equ $a0
aud0lcl	equ $a2
aud0len	equ $a4
aud0per	equ $a6
aud0vol	equ $a8
aud0dat	equ $aa
aud1lch	equ $b0
aud1lcl	equ $b2
aud1len	equ $b4
aud1per	equ $b6
aud1vol	equ $b8
aud1dat	equ $ba
aud2lch	equ $c0
aud2lcl	equ $c2
aud2len	equ $c4
aud2per	equ $c6
aud2vol	equ $c8
aud2dat	equ $ca
aud3lch	equ $d0
aud3lcl	equ $d2
aud3len	equ $d4
aud3per	equ $d6
aud3vol	equ $d8
aud3dat	equ $da

bpl1pth	equ $e0
bpl1ptl	equ $e2
bpl2pth	equ $e4
bpl2ptl	equ $e6
bpl3pth	equ $e8
bpl3ptl	equ $ea
bpl4pth	equ $ec
bpl4ptl	equ $ee
bpl5pth	equ $f0
bpl5ptl	equ $f2
bpl6pth	equ $f4
bpl6ptl	equ $f6
bpl7pth	equ $f8
bpl7ptl	equ $fa
bpl8pth	equ $fc
bpl8ptl	equ $fe

spr0pth	equ $120
spr0ptl	equ $122
spr1pth	equ $124
spr1ptl	equ $126
spr2pth	equ $128
spr2ptl	equ $12a
spr3pth	equ $12c
spr3ptl	equ $12e
spr4pth	equ $130
spr4ptl	equ $132
spr5pth	equ $134
spr5ptl	equ $136
spr6pth	equ $138
spr6ptl	equ $13a
spr7pth	equ $13c
spr7ptl	equ $13e

spr0pos	equ $140
spr0ctl	equ $142
spr0data	equ $144
spr0datb	equ $146
spr1pos	equ $148
spr1ctl	equ $14a
spr1data	equ $14c
spr1datb	equ $14e
spr2pos	equ $150
spr2ctl	equ $152
spr2data	equ $154
spr2datb	equ $156
spr3pos	equ $158
spr3ctl	equ $15a
spr3data	equ $15c
spr3datb	equ $15e
spr4pos	equ $160
spr4ctl	equ $162
spr4data	equ $164
spr4datb	equ $166
spr5pos	equ $168
spr5ctl	equ $16a
spr5data	equ $16c
spr5datb	equ $16e
spr6pos	equ $170
spr6ctl	equ $172
spr6data	equ $174
spr6datb	equ $176
spr7pos	equ $178
spr7ctl	equ $17a
spr7data	equ $17c
spr7datb	equ $17e


;ecs and aa regs
sprhdat	equ $078
bplhdat	equ $07a
lisaid	equ $07c
bplhmod	equ $1e6
sprhpth	equ $1e8
sprhptl	equ $1ea
bplhpth	equ $1ec
bplhptl	equ $1ee


;colors
color00	equ $180
color01	equ $182
color02	equ $184
color03	equ $186
color04	equ $188
color05	equ $18a
color06	equ $18c
color07	equ $18e
color08	equ $190
color09	equ $192
color10	equ $194
color11	equ $196
color12	equ $198
color13	equ $19a
color14	equ $19c
color15	equ $19e
color16	equ $1a0
color17	equ $1a2
color18	equ $1a4
color19	equ $1a6
color20	equ $1a8
color21	equ $1aa
color22	equ $1ac
color23	equ $1ae
color24	equ $1b0
color25	equ $1b2
color26	equ $1b4
color27	equ $1b6
color28	equ $1b8
color29	equ $1ba
color30	equ $1bc
color31	equ $1be

;Blitter logic (not)
;move.w	#BLTEN_ACD+(BLT_A|BLT_C),bltcon0
;vasm operators:
;& (bitwise and) 
;^ (bitwise exclusive-or) 
;| (bitwise inclusive-or) 
;~ (bitwise not)

;BLT_SRC_AD+BLT_A					;$df0
;BLT_SRC_ABD+(BLT_A|BLT_B)				;$dfc - A or B
;BLT_SRC_ABD+(BLT_A|BLT_C)				;$bfa - A or C
;BLT_SRC_ABCD+((BLT_A&BLT_B)|(BLT_C&(~BLT_A))),d3	;$fca - cookie cut

;BLTCON0
BLT_SRC_A	equ  $0800
BLT_SRC_B	equ  $0400
BLT_SRC_C	equ  $0200
BLT_SRC_D	equ  $0100
BLT_SRC_AD	equ  (BLT_SRC_A|BLT_SRC_D)
BLT_SRC_ABD	equ  (BLT_SRC_A|BLT_SRC_B|BLT_SRC_D)
BLT_SRC_ACD	equ  (BLT_SRC_A|BLT_SRC_C|BLT_SRC_D)
BLT_SRC_ABCD	equ  (BLT_SRC_A|BLT_SRC_B|BLT_SRC_C|BLT_SRC_D)

BLT_A		equ  %11110000
BLT_B		equ  %11001100
BLT_C		equ  %10101010

;BLTCON1
BLT_LINEMODE	equ $1
BLT_FILL_OR	equ $8
BLT_FILL_XOR	equ $10
BLT_FILL_CARRYIN	equ $4
BLT_ONEDOT	equ $2
BLT_OVFLAG	equ $20
BLT_SIGNFLAG	equ $40
BLT_BLITREVERSE	equ $2


;Flags

; dmacon
;15	SET/CLR	Set/Clear control bit. Determines if bits written with a 1 get set or cleared Bits written with a zero are unchanged
;14	BBUSY	Blitter busy status bit (read only)
;13	BZERO	Blitter logic zero status bit (read only)
;12	X	

;11	X	
;10	BLTPRI	Blitter DMA priority (over CPU micro) (also called "blitter nasty") (disables /BLS pin, preventing micro from stealing any bus cycles while blitter DMA is running)
;09	DMAEN	Enable all DMA below (also UHRES DMA)
;08	BPLEN	Bit plane DMA enable

;07	COPEN	Coprocessor DMA enable
;06	BLTEN	Blitter DMA enable
;05	SPREN	Sprite DMA enable
;04	DSKEN	Disk DMA enable

;03	AUD3EN	Audio channel 3 DMA enable
;02	AUD2EN	Audio channel 2 DMA enable
;01	AUD1EN	Audio channel 1 DMA enable
;00	AUD0EN	Audio channel 0 DMA enable
;DMAF_SETCLR	equ  $8000
;DMAF_BLTPRI	equ  $0400
;DMAF_DMAEN	equ  $0200
;DMAF_BPLEN	equ  $0100
;DMAF_COPEN	equ  $0080
;DMAF_BLTEN	equ  $0040
;DMAF_SPREN	equ  $0020
;DMAF_DSKEN	equ  $0010
;DMAF_AUDEN	equ  $000f


; INTENA
;15	SET/CLR		Set/clear control bit. Determines if bits written with a 1 get set or cleared. Bits written with a zero are always unchanged.
;14	INTEN		Master interrupt (enable only, no request)
;13	EXTER	6	External interrupt (CiaB interrupts)
;12	DSKSYN	5	Disk sync register (DSKSYNC) matches disk

;11	RBF	5	Serial port receive buffer full
;10	AUD3	4	Audio channel 3 block finished
;09	AUD2	4	Audio channel 2 block finished
;08	AUD1	4	Audio channel 1 block finished

;07	AUD0	4	Audio channel 0 block finished
;06	BLIT	3	Blitter has finished
;05	VERTB	3	Start of vertical blank
;04	COPER	3	Coprocessor

;03	PORTS	2	I/O Ports and timers (CiaA interrupts)
;02	SOFT	1	Reserved for software initiated interrupt.
;01	DSKBLK	1	Disk block finished
;00	TBE	1	Serial port transmit buffer empty
;INTF_SETCLR 	equ  $8000
;INTF_INTEN	equ  $4000
;INTF_EXTER	equ  $2000
;INTF_BLIT	equ  $0040
;INTF_VERTB	equ  $0020
;INTF_COPER	equ  $0010
;INTF_PORTS	equ  $0008
;INTF_SOFT	equ  $0004
		

;Traps and vectors
VEC_BUSERR	equ	$08
VEC_ADDRERR	equ	$0c
VEC_ILLEGAL	equ	$10
VEC_ZERODIV	equ	$14
VEC_CHKINS	equ	$18
VEC_TRAPV	equ	$1c
VEC_PRIVILEGE	equ	$20
VEC_TRACE	equ	$24
VEC_LINEA	equ	$28
VEC_LINEF	equ	$2c
VEC_SPURIOUS	equ	$60
VEC_LEVEL1	equ	$64
VEC_LEVEL2	equ	$68
VEC_LEVEL3	equ	$6c
VEC_LEVEL4	equ	$70
VEC_LEVEL5	equ	$74
VEC_LEVEL6	equ	$78
VEC_LEVEL7	equ	$7c
VEC_TRAP0	equ	$80
VEC_TRAP1	equ	$80

	
; Cache Control Register ( CACR )
;
; 	BIT#	FUNCTION
;	0	Inst Cache Enable
;	1	Freeze Inst Cache
;	2	Clear Entry in Inst Cache
;	3	Clear Inst Cache
;	4	Inst Burst Enable
;	5	0
;	6	0	
;	7	0
;	8	Data Cache Enable
;	9	Freeze Data Cache
;	10	Clear Entry in Data Cache
;	11	Clear Data Cache
;	12	Data Burst Enable
;	13	Write Allocate (always set - I think...)
;
;	movec.l	dn,CACR


	ENDC	;EXTRA_I