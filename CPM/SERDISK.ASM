	title 'Serial disk handler'

;    CP/M-80 Version 3     --  Modular BIOS

;	Disk I/O Module for wd1797 based diskette systems

	;	Initial version 0.01,
	;		Ramdisks only.	- jrp, 20 May 2020

	true equ -1
	false equ not true
	
    ; Disk drive dispatching tables for linked BIOS

	public	sersd0

    ; Variables containing parameters passed by BDOS

	extrn	@adrv,@rdrv
	extrn	@dma,@trk,@sect
	extrn	@dbnk

    ; System Control Block variables

	extrn	@ermde		; BDOS error mode

    ; Utility routines in standard BIOS

	extrn	?wboot	; warm boot vector
	extrn	?pmsg	; print message @<HL> up to 00, saves <BC> & <DE>
	extrn	?pdec	; print binary number in <A> from 0 to 99.
	extrn	?pderr	; print BIOS disk error header
	extrn	?conin,?cono	; con in and out
	extrn	?const		; get console status


	maclib ports
	maclib cpm3
	maclib z80
	maclib debug
    ; common control characters

cr	equ 13
lf	equ 10
bell	equ 7

; Extended Disk Parameter Headers (XDPHs)
	dw	fd$write
	dw	fd$read
	dw	fd$login
	dw	fd$init
	db	0,0		; relative drive zero
sersd0	;Disk Parameter Header (DPH)
	dph     0, dpbsd, 64;, 254


;?psize is the physical sector size in bytes; (128)
;?pspt is the number of physical sectors per track; (16)
;?trks is the number of tracks on the drive; (16)
;?bls is the allocation unit size in bytes; (1024)
;?ndirs is the number of directory entries; (64)
;?off is the number of tracks to reserve; (2)
;?ncks is the number of checked directory entries.

dpbsd	dpb 128,64,256,8192,256,0 ;Disk Parameter Block 

;cseg

; Disk I/O routines for standardized BIOS interface
; Initialization entry point.
; called for first time initialization.
fd$init:	; all initialization done by drive 0
	;DBGOUT 'init disk'
	mvi a,0
	ret

fd$login:
	;DBGOUT '-->login'
	mvi a,0
	ret	; we have nothing to do in


; disk READ and WRITE entry points.

		; these entries are called with the following arguments:

			; relative drive number in @rdrv (8 bits)
			; absolute drive number in @adrv (8 bits)
			; disk transfer address in @dma (16 bits)
			; disk transfer bank	in @dbnk (8 bits)
			; disk track address	in @trk (16 bits)
			; disk sector address	in @sect (16 bits)
			; pointer to XDPH in <DE>

		; they transfer the appropriate data, perform retries
		; if necessary, then return an error code in <A>


reqest db '@@@'
db '@trk:' 
trk db 0
db '@sct:' 
sect db 0
db '@cnk:' 
cnk db 0
req$len equ 21
;input value in reg- a: 
;Chunk nr: bit 0,1
;write: bit 3
;reserved: bit 3
request$chunk:
; set drive: Bit 7-4
	push h
	push psw
	sta cnk
	lda @adrv
	add a! add a! add a! add a ;shift left 4 bits
	mov b, a
	lda cnk! add b ;add chunk nr
	sta cnk
	lda @trk! sta trk
	lda @sect! sta sect
; Send request
	lxi hl, reqest
	mvi b, req$len
	mvi c, dta$reg ;Port of DART-B
	OUTIR
	pop psw
	pop h
	ret

dta$reg equ p$zdart + 2
cfg$reg equ p$zdart + 3
chunk$nr db 0
chunksize equ 32
; Bios read function
fd$read:
	lhld @dma

req$chunks: ;request chunk
	lda chunk$nr 
	call request$chunk ;if chunk$nr < 4
	inr a
	sta chunk$nr

; receive chunk
mvi b, chunksize
mvi c, dta$reg

receive:
poll: 	
	in cfg$reg 
	ani 1! jz poll		;Wait for data in rx buffer
	INI
	jnz receive
	
	lda chunk$nr
	cpi 4 ;128 / chunksize
	jnz req$chunks ; next chunk

	mvi a, 0
	sta chunk$nr
	ret

; Send chunks
fd$write
	lhld @dma

req$wchunks: ;request chunk
	lda chunk$nr 
	SETB 3, a  ;write request
	call request$chunk
	RES 3, a	;now a contains only chunk nr.
	inr a
	sta chunk$nr
	;DBGINT8 chunk$nr
 wt:
 	in cfg$reg ; Wait until Arduino/PC are ready for next chunk
	ani 1! jz wt
	in dta$reg 
	cpi '&'! jnz wt
	
	;send chunk
	mvi b, chunksize
	mvi c, dta$reg
	OUTIR

	lda chunk$nr
	cpi 4 ;128 / chunksize
	jnz req$wchunks ; next chunk

	mvi a, 0
	sta chunk$nr
	ret
end

