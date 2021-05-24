; Copyright (C) 2020  Doctor Volt

 ; This program is free software: you can redistribute it and/or modify
 ; it under the terms of the GNU General Public License as published by
 ; the Free Software Foundation, either version 3 of the License, or
 ; (at your option) any later version.

 ; This program is distributed in the hope that it will be useful,
 ; but WITHOUT ANY WARRANTY; without even the implied warranty of
 ; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ; GNU General Public License for more details.

 ; You should have received a copy of the GNU General Public License
 ; along with this program.  If not, see <https://www.gnu.org/licenses/>.


title 'PATA disk driver'

public pa$init,pa$read,pa$write

;Includes
maclib cpm3
maclib z80
maclib utils
maclib ports
;Command block registers
dev$addr  equ 100000b ; Base address A5
reg$data    equ dev$addr+000b ;Data register
reg$err     equ dev$addr+001b ;Read: Error
reg$fr      equ dev$addr+001b ;Write: Features
reg$sc      equ dev$addr+010b ;Sector Count
reg$sn      equ dev$addr+011b ;Sector Number
reg$lba7    equ dev$addr+011b ;LBA Bits 0-7
reg$cylo    equ dev$addr+100b ;Cylinder Low
reg$lba15   equ dev$addr+100b ;LBA Bits 8-15
reg$cyhi    equ dev$addr+101b ;Cylinder High
reg$lba23   equ dev$addr+101b ;LBA Bits 16-23
reg$dh      equ dev$addr+110b ;Drive/Head
reg$lba27   equ dev$addr+110b ;LBA Bits 24-27
reg$status  equ dev$addr+111b ;Read: Status
reg$cmd     equ dev$addr+111b ;Write: Command

;Status flags
BSY     equ 80h ;Drive busy
DRDY    equ 40h ;Drive ready for command
DSC     equ 10h ;Drive head settled over sector
DRQ     equ 08h ;Drive ready for r/w
ERR     equ 1 ;Drive error

;Drive commands
cmd$initpar equ 091h ;Init drive parameters
cmd$read    equ 020h ;Read sector w. retry
cmd$write   equ 030h ;Write sector w. retry
cmd$setfr   equ 0EFh ;Set Features
cmd$diag	equ 090h ;Drive diagnosis

; General constants
cr	equ 13
lf	equ 10
ldn equ 2 ; Lowest drive number in @adrv for drives 2: drive c

; Disk drive dispatching tables for linked BIOS
public	pata0

; Variables containing parameters passed by BDOS
extrn	@adrv,@rdrv,@dma,@trk,@sect,@dbnk

; System Control Block variables
extrn	@ermde		; BDOS error mode

; Utility routines in standard BIOS
extrn	?wboot	; warm boot vector
extrn	?pmsg	; print message @<HL> up to 00, saves <BC> & <DE>
extrn	?pdec	; print binary number in <A> from 0 to 99.
extrn	?pderr	; print BIOS disk error header
extrn	?conin,?cono	; con in and out
extrn	?const		; get console status

;Macro to compute offset for selected drive: c:0, d:64, e:128, f:192
OFFSET macro
 	lda @adrv ;selected drive number
	sui ldn ;for lowest selected drive number (C:) a shall be 0
	rept 6 ;shift left 6 bytes
		add a
	endm
	endm
	
; Error messages
err$init: db cr,lf,'Error: HD not available',0
err$dsk:  db cr,lf,'Drive error',0
err$lba:  db cr,lf,'Error: LBA not available',0
err$rd:   db cr,lf,'Error: HD cannot be read',0
err$wr:   db cr,lf,'Error: HD cannot be written',0
err$8bit: db cr,lf,'Error: 8 Bit mode could not be set',0
err$diag: db cr,lf,'Error: Drive diagnosis failed',0
err$para: db cr,lf,'Error: LBA Mode cannot be set', 0

dpb$pata ;Disk Parameter Block 
	dw 	128 ;(sect$len*?pspt)/128	; spt number of logical 128 - byte records per track
	db	7,127 ;bsh,blm for 16384 bytes blocks - block shift and mask
	db	7 ;exm - extent mask
	dw	03ffh ;dsm - highest block number, number of blocks - 1
	dw	511  ;drm - maximum directory entry number
	db	080h,0  ;al0,al1 - alloc vector for directory
	dw	08000h ;cks - checksum size 08000h permanently mounted
	dw	0 ;off - offset for system tracks
	db	1,1  ;psh,phm - physical sector size shift (Sector len=256 bytes)

; Extended Disk Parameter Headers (XDPHs)
xdph:
	dw	pa$write
	dw	pa$read
	dw	pa$login
	dw	pa$init2
	db	0,0		; unit, type
pata0:	;Disk Parameter Header (DPH)
	DPH  0, dpb$pata, 0

;cseg

; Init routine called by bootloader.
; returns a=0 on success, a=1 otherwise
pa$init:
	;PRINT 'Init PATA drive'
	in reg$status
	ani DRDY
	jnz init$wait
	mvi a,1! ret
 init$wait:
	PRINT 'Waiting for hard drive (can take up to 30s...)'
	mvi b,100

 bsy$wait
	DLY 0ffffh
	in reg$status
	;call ?hex8
	BIT 0,a ;Error Flag
	jnz drive$error
	BIT 7,a ;BSY flag
	jz disk$ready
	DJNZ bsy$wait
	PRINT 'Drive timeout'
	ora a! rnz ; If this went wrong

 drive$error:
	PRINT 'Hard drive error'
	mvi a,cmd$diag! out reg$cmd
	mvi c, DRDY! lxi h, err$diag! call wait$sr
	ora a! rnz ; If this went wrong
	PRINT 'Drive diagnosis passed'
	ret
	mov a,1! ret ; If this went wrong
	
 ;disk$ready:
	mvi a,cmd$diag! out reg$cmd
	mvi c, DRDY! lxi h, err$diag! call wait$sr
	ora a! rnz ; If this went wrong
	PRINT 'Drive diagnosis passed'
 disk$ready:
 	;PRINT 'Drive found'
	mvi a,ldn! sta @adrv
 	mvi a,0e0h! out reg$lba27
	mvi a, cmd$initpar! out reg$cmd
	mvi c, DRDY! lxi h, err$para! call wait$sr
	ora a! rnz ; If this went wrong
	;PRINT 'Drive ready'
	;Set 16 Bit data transfer to fill up 512 byte sectors
	mvi a,0! out reg$fr 
  	mvi a,cmd$setfr! out reg$cmd
	mvi c, DRDY! lxi h, err$8bit! call wait$sr
	xra a! ret


; Disk I/O routines for standardized BIOS interface
; Initialization entry points.
pa$init2:
	; Just do nothing, because drive has already been initialized
	; by pa$init, invoked by bootloder
	ret

pa$login:
	;PRINT 'Pata drive selected: '
	ret	

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


; Bios read function
pa$read:
	rept 100 ;Waiting a bit here makes the thing work. 
	nop
	endm

	OFFSET
	lhld @sect
	add l ;offset for selected drive
	out reg$lba7
	;PRINT 'Read HD Sector: '
	;call ?hex8
	lda @trk! out reg$lba15 
  	lda @trk+1! out reg$lba23
	lhld @trk! 
	;PRINT 'Track: '
	;call ?hex16
	;Issue read command
  	;mvi c,DRDY! ;lxi h,err$rd! ;call wait$sr
  	mvi a,cmd$read! out reg$cmd 
  	mvi c,DSC! lxi h,err$rd! call wait$sr
	ora a! rnz
  	lhld @dma ;DMA addr to <HL>
	;PRINT 'DMA: '
	;call ?hex16
  	mvi b,0 
  	mvi c,reg$data 
	INIR
	mvi a,0
	ret

; write function
pa$write
	OFFSET
	lhld @sect
	add l ;offset for selected drive
	out reg$lba7
	;PRINT 'write Sector: '
	;call ?hex8
	lda @trk! out reg$lba15 
  	lda @trk+1! out reg$lba23
	lhld @trk! 
	;PRINT 'Track: '
	;call ?hex16
	;Issue read command
  	mvi a,cmd$write! out reg$cmd 
  	mvi c,DSC! lxi h,err$wr! call wait$sr
	ora a! rnz
  	lhld @dma ;DMA addr to <HL>
 	;PRINT 'DMA: '
	;call ?hex16
  	mvi b,0 
  	mvi c,reg$data
	OUTIR
	mvi a,0! ret

;wait until BSY falg in PATA status register is cleared
;and at least the flags specified in c are set
;input: reg: c bitmask
;return: d=status reg, e=error reg. or 0 if no error occurred
;<a> = 0 if no error, <a> = 1 on error
wait$sr: 
	mvi b, 255 ;number of retries
 wait$sr$loop:
  	in reg$status ;card status
	mov d,a! mvi e,0
  	BIT 0,a ;ERR flag
  	jnz err
  	BIT 7,a ;BSY flag
	jnz wait$sr$bsy
	ana c! cmp c ;are the required bits in reg b set in a?
	mvi a,0
	rz ;then return here
	;PRINT 'WAIT'
  	jmp wait$sr$wt
 wait$sr$bsy: 
	;PRINT 'BUSY'
  	jmp wait$sr$wt
 wait$sr$err:
	;PRINT 'ERROR'
	in reg$err
	mov e,a
  	jmp wait$sr$wt
 wait$sr$wt: 
  	DLY 0fffh 
	DJNZ wait$sr$loop ;retry
	call ?pmsg ;print error message
	PRINT 'Drive status: '
	mvi h,0! mov l,d! push d! call ?hex16! pop d
	PRINT 'Drive error: '
	mvi h,0! mov l,e! push d! call ?hex16! pop d
	mvi a,1 ;Something went wrong
	ret


end

