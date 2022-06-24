	title	'Boot loader module for CP/M 3.0'

true equ -1
false equ not true

	extrn	?pmsg,?conin,?sldsk
	extrn	@civec,@covec,@aivec,@aovec,@lovec,@scbbase,@dtbl

	extrn ?cinit			; (re)initialize device in <C>
	extrn ?irqinit			; Init interrupts
	maclib syscfg
	maclib utils

	bdos	equ 5
	@bootdev:: equ 08000h ;Mem addr with device from which we booted from. 0,1: Serial disk 3: Pata drive

;dseg	
?init::
	ld hl,0A000h ! ld (@civec),hl ! ld (@covec),hl	; assign console to CRT:
	ld hl,00000h ! ld (@lovec),hl 			;
	ld hl,08000h ! ld (@aivec),hl ! ld (@aovec),hl	; assign AUX to CRT1:

	call ?irqinit
	ld c,0! call ?cinit
	ld c,1! call ?cinit ;PS/2 Keyboard
	ld c,2! call ?cinit ;Init VDP if p$vdp in syscfg.lib is not 0
	PRINTLN 'ZX 2020 CP/M 3.0. Have fun.'		; print signon message

	;Set drive to load CCP from
	ld a,(@bootdev) ;0: No HD, 1:HD, NO CP/M, 3: HD with CP/M
	;PRINT 'Boot device: '
	;call ?hex8
	cp 0! jp nz,ld$1
		;PRINT 'No HD'
		;Erase drive entries for drives C-F in @dtbl
		ld b,8! ld hl,@dtbl+4 ;Starting at word 2/drive C:
	 owdrv:
		ld (hl),0! inc hl
		djnz owdrv
		jp ld$end
 	ld$1:
	cp 1! jp nz,ld$3
		PRINT 'Hard drive found. Call mkdsk to init' 
		jp ld$end
 	ld$3:
		cp 3! jp nz,ld$end
		ld (ccp$fcb),a! ld (ldr$fcb),a! dec a! ld (@scbbase+013h),a ;Load CCP from hd:
 	ld$end:
	 	CRLF
	
	;call ?rlldr
	;Switch from boot bank to CPM bank
	ld a,5! out p$zdartCFG$A 
	ld a,dart$ra5! or 080h! out p$zdartCFG$A
	ret

 ;Restore bootloader
?rlldr:
	PRINTLN 'Restoring Bootloader'
	xor a! ld (ldr$fcb+15),a! ld (ldr$fcb+32),a		; zero ex and cr
	OPEN ldr$fcb			; open file containing bootldr
	inc a! jp z,no$LDR		; error if no file...
	STDMA 0				; All to the very beginning of RAM 
	SETMULTI 32	; 
	READSEQ ldr$fcb	; load the thing
	CLOSE ldr$fcb
	PRINTLN 'Bootloader restored'
	ret
 no$LDR:			; here if we couldn't find the file
	PRINT 'Warning: Bootloader could not be restored'
	ret

;Load ccp from active drive
?ldccp::
 	;PRINTLN '?ldccp '
 	RESETD 
	xor a! ld (ccp$fcb+15),a! ld (ccp$fcb+32),a		; zero ex and cr
	OPEN ccp$fcb			; open file containing CCP
	inc a! jp z,no$CCP		; error if no file...
	STDMA 100h		;start of TPA
	SETMULTI 64		;allow up to 16k bytes
	READSEQ ccp$fcb	;load the thing
	CLOSE ccp$fcb
	;ld a,5! out p$zdartCFG$A 
	;ld a,dart$ra5! or 82h! out p$zdartCFG$A
	ret

 no$CCP:			; here if we couldn't find the file
	PRINTLN 'BIOS Error: No CCP.COM file.'
	PRINTLN 'Press any key to load from drive A:'
	call ?conin			; get a response
	ld a,0! ld (ccp$fcb),a! ld (@scbbase+013h),a
	jp ?rlccp			; and try again
	
    ; No external clock.

?rlccp:: 
	;PRINT 'rlccp'
	jp ?ldccp

?time::
	ret
	; CP/M BDOS Function Interfaces


;Data
dseg
ccp$fcb		db	0,'CCP     ','COM' 
			ds	32
ldr$fcb		db	0,'BOOTLDR ','COM'
			ds	32

end

