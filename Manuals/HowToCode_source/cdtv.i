; CDTV.i       Information for programming CDTV/A570
;
; By Comrade J
;
; Read cdtv.txt


CDTV_RESET		equ	 1
CDTV_READ		equ	 2
CDTV_WRITE		equ	 3     (!!!!!)
CDTV_UPDATE		equ	 4
CDTV_CLEAR		equ	 5
CDTV_STOP		equ	 6
CDTV_START		equ	 7
CDTV_FLUSH		equ	 8
CDTV_MOTOR		equ	 9
CDTV_SEEK		equ	10
CDTV_FORMAT		equ	11
CDTV_REMOVE		equ	12
CDTV_CHANGENUM		equ	13
CDTV_CHANGESTATE 	equ	14
CDTV_PROTSTATUS		equ	15
CDTV_GETDRIVETYPE 	equ	18
CDTV_GETNUMTRACKS 	equ	19
CDTV_ADDCHANGEINT 	equ	20
CDTV_REMCHANGEINT 	equ	21
CDTV_GETGEOMETRY 	equ	22
CDTV_EJECT		equ	23
CDTV_DIRECT		equ	32
CDTV_STATUS		equ	33
CDTV_QUICKSTATUS 	equ	34
CDTV_INFO		equ	35
CDTV_ERRORINFO		equ	36
CDTV_ISROM		equ	37
CDTV_OPTIONS		equ	38
CDTV_FRONTPANEL		equ	39
CDTV_FRAMECALL		equ	40
CDTV_FRAMECOUNT		equ	41
CDTV_READXL		equ	42
CDTV_PLAYTRACK		equ	43
CDTV_PLAYLSN		equ	44
CDTV_PLAYMSF		equ	45
CDTV_PLAYSEGSLSN 	equ	46
CDTV_PLAYSEGSMSF 	equ	47
CDTV_TOCLSN		equ	48
CDTV_TOCMSF		equ	49
CDTV_SUBQLSN		equ	50
CDTV_SUBQMSF		equ	51
CDTV_PAUSE		equ	52
CDTV_STOPPLAY		equ	53
CDTV_POKESEGLSN		equ	54
CDTV_POKESEGMSF		equ	55
CDTV_MUTE		equ	56
CDTV_FADE		equ	57
CDTV_POKEPLAYLSN 	equ	58
CDTV_POKEPLAYMSF 	equ	59
CDTV_GENLOCK		equ	60


;  Quick-Status Bits
;  Bits returned in IO_ACTUAL of the CDTV_QUICKSTATUS.

QSB_READY   equ	0
QSB_AUDIO   equ	2
QSB_DONE    equ	3
QSB_ERROR   equ	4
QSB_SPIN    equ	5
QSB_DISK    equ	6
QSB_INFERR  equ	7

QSF_READY   equ	$01
QSF_AUDIO   equ	$04
QSF_DONE    equ	$08
QSF_ERROR   equ	$10
QSF_SPIN    equ	$20
QSF_DISK    equ	$40
QSF_INFERR  equ	$80

; CDTV_GENLOCK values (io_Offset)
CDTV_GENLOCK_REMOTE 	equ	0	; Remote control
CDTV_GENLOCK_AMIGA  	equ	1	; Amiga video out
CDTV_GENLOCK_EXTERNAL 	equ	2	; External video out
CDTV_GENLOCK_MIXED  	equ	3	; Amiga over external video


; CDTV_INFO Command values (io_Offset)

CDTV_INFO_BLOCK_SIZE 	equ	2	; CD-ROM block size
CDTV_INFO_FRAME_RATE 	equ	3	; CD-ROM frame rate

