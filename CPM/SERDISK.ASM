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


	title 'Serial disk driver'

	public	sersd0,sd$init,sd$read,sd$write

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

	maclib syscfg
	maclib cpm3
	maclib z80
	;maclib utils
    ; common control characters

cr	equ 13
lf	equ 10
bell	equ 7

sect$len equ 256
?pspt  equ 256

dpb$sd:
	dw 	128 ;(sect$len*?pspt)/128	; spt number of logical 128 - byte records per track
	db	7,127 ;bsh,blm for 16384 bytes blocks - block shift and mask
	db	7 ;exm - extent mask
	dw	07ffh ;dsm - highest block number, number of blocks - 1
	dw	511  ;drm - maximum directory entry number
	db	080h,0  ;al0,al1 - alloc vector for directory
	dw	080h ;cks - checksum size 0h+(drm+1)/4: Removable
	dw	0 ;off - offset for system tracks
	db	1,1  ;psh,phm - physical sector size shift (256 bytes)

; Extended Disk Parameter Headers (XDPHs)
	dw	sd$write
	dw	sd$read
	dw	sd$login
	dw	sd$init
	db	0,0		; relative drive zero
sersd0	;Disk Parameter Header (DPH)
	dph     0, dpb$sd, 128 ;(drm+1)/4: if Removable

; Disk I/O routines for standardized BIOS interface
; Initialization entry point.
; called for first time initialization.
sd$init:	; all initialization done by drive 0
	;PRINT 'Init Serial disk'
	ret
sd$login:
	;PRINT 'Serial disk selected: '
	;lda @adrv! ;call ?hex8
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
req$start:
reqest db '<$>'
req$cmd db '0:' ;$R:.. Read $W:.. Write
req$trk dw 0
req$sect db 0
req$cnk db 0
req$len equ $-req$start
req$end db '</$>'

; Send request header to PC. called with request type (R or W) in reg. <a>
snd$req$hdr: ;send request header 
  	sta req$cmd
	lda @trk! sta req$trk
	lda @trk+1! sta req$trk+1
	lda @sect! sta req$sect
; Send request to PC
	lxi hl, reqest
	mvi b, req$len
	mvi c, dta$reg ;Port of DART-B
	OUTIR
	ret

;terminate request and send to PC
snd$req$end: 
	lxi hl, req$end
	mvi b, 4! mvi c, dta$reg ;Port of DART-B
	OUTIR
	ret

dta$reg equ p$zdart$B ;DART data register Port B
cfg$reg equ p$zdartCFG$B ;DART config register Port B

; Bios read function
sd$read:
	di
	mvi a, 'R'
    call snd$req$hdr    ; Send request to PC
    call snd$req$end    ; Send request to PC
    ; receive data
  	lhld @dma! mvi b,0! mvi c,dta$reg
 sd$read$poll1:
	lxi d, 0 ;Timeout: 2^16 decrements
 sd$read$poll2: 	
	dcx d! mov a,d! ora e! jz sd$read$error ;Break loop when timeout occurs
	in cfg$reg!	ani 1! jz sd$read$poll2		;Wait for data in rx buffer
	INI
	jnz sd$read$poll1 ; next byte, reset timeout
	call reset$irq
    mvi a, 0! ret
 sd$read$error:
	call reset$irq
	mvi a,1! ret

; Write sectors
sd$write
	di
	mvi a, 'W'
    call snd$req$hdr    ; Send request to PC
	lhld @dma! mvi c, dta$reg! mvi b, 0
	OUTIR ; send data
	call snd$req$end

	;Wait for @ack@ from PC
	mvi b,5 ;Length of @ack@
	lxi d,0 ;Timeout: 2^16 decrements
ack$wait: 	
	dcx d! mov a,d! ora e! jz sd$write$error ;Break loop when timeout occurs
	in cfg$reg 
	ani 1! jz ack$wait		;Wait for data in rx buffer
	in dta$reg ;read to reset flag 
	dcr b
	jnz ack$wait
	call reset$irq
	xra a! ret
 sd$write$error:
	call reset$irq
	mvi a,1! ret

;Fuction that resets interrupts
reset$irq: 
	mvi a,00010000b! out p$zdartCFG$A! out p$zdartCFG$B
	ei 
	ret
end
	