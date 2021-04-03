*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipBss,bss_c

*****************************************************************************

;CUR_CHIP_BUF set FW_Chip_Buffer_1

;BPL_Phys:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Phys	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log1:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;P0_CL_Log1:	ds.b	P0_CL_SIZE
;P0_CL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+P0_CL_SIZE

;We need these lines to be in the same 64KB area so that we can skip 
;writing bplxpth each line
;BPL_Line_Phys:	ds.b	BPL_LINE_BUF_TOTALSIZE
;Space for 4 lines (line1 and line2, double buffered)
;BPL_Line1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+(BPL_LINE_BUF_SIZE*4)+65536

