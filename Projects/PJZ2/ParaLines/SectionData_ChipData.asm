*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipBss,bss_c

*****************************************************************************

CUR_CHIP_BUF set FW_Chip_Buffer_1

;BPL_Phys:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Phys	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log1:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log2:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log2	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log3:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log3	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log4:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log4	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;P0_CL_Log1:	ds.b	P0_CL_SIZE
;P0_CL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+P0_CL_SIZE

