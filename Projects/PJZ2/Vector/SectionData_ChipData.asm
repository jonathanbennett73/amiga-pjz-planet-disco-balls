*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipBss,bss_c

*****************************************************************************

*****************************************************************************

;CUR_CHIP_BUF set FW_Chip_Buffer_1

;BPL_Phys	equ	CUR_CHIP_BUF	;3bpl 320x256 = 30720
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log1	equ	CUR_CHIP_BUF	;3bpl = 30720
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Scratch	equ	CUR_CHIP_BUF	;1bpl
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_SCRATCH_TOTALSIZE

;P0_CL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+P0_CL_SIZE

