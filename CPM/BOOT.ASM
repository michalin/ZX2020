	title	'Boot loader module for CP/M 3.0'

true equ -1
false equ not true

	public	?init,?ldccp,?rlccp,?time,@bootdev
	extrn	?pmsg,?conin,?sldsk
	extrn	@civec,@covec,@aivec,@aovec,@lovec,@scbbase,@dtbl
	extrn 	?setup
	maclib ports
	maclib z80
	maclib utils

	bdos	equ 5
	@bootdev equ 08000h ;Mem addr with device from which we booted from. 0,1: Serial disk 3: Pata drive

;dseg	
?init:
	lxi h,08000h ! shld @civec ! shld @covec	; assign console to CRT:
	lxi h,04000h ! shld @lovec 			; assign printer to LPT:
	lxi h,02000h ! shld @aivec ! shld @aovec	; assign AUX to CRT1:
	lxi h,init$table ! call out$blocks	; set up misc hardware
	lxi h,signon$msg ! call ?pmsg		; print signon message

	;Set drive to load CCP from
	lda @bootdev ;0: No HD, 1:HD, NO CP/M, 3: HD with CP/M
	;PRINT 'Boot device: '
	;call ?hex8
	cpi 0! jnz ld$1
		;PRINT 'No HD'
		;Erase drive entries for drives C-F in @dtbl
		mvi b,8! lxi h,@dtbl+4 ;Starting at word 2/drive C:
	 owdrv:
		mvi m,0! inx h
		DJNZ owdrv
		jmp ld$end
 	ld$1:
	cpi 1! jnz ld$3
		PRINT 'Hard drive found. Call mkdsk to initialize' 
		jmp ld$end
 	ld$3:
		cpi 3! jnz ld$end
		sta ccp$fcb! sta ldr$fcb! dcr a! sta @scbbase+013h ;Load CCP from hd:
 	ld$end:
	 	PRINT ''

	call rl$ldr ; Restore bootloader in boot bank
	
	;Switch from boot bank to CPM bank
	mvi a,5! out p$zdart+1 
	lda drr5+1! ori 080h! out p$zdart+1
	ret

 out$blocks:
	mov a,m ! ora a ! rz ;First byte: Length of entry. If zero, return
	mov b,a
	inx h ! mov c,m ! inx h ;Second byte: Addr. of device
	outir
	jmp out$blocks

;Restore bootloader
rl$ldr: 
	xra a! sta ldr$fcb+32		; zero cr
	lxi d,ldr$fcb! call open	; open file containing bootldr
	inr a! jz no$LDR		; error if no file...
	lxi d,0h! call setdma	; start 
	lxi d,32! call setmulti	; 
	lxi d,ldr$fcb! call read	; load the thing
	;PRINT 'Bootloader restored'
	;PRINT ''
	ret

 no$LDR:			; here if we couldn't find the file
	lxi h,ldr$msg ! call ?pmsg	; report this...
	ret

;Load ccp from active drive
?ldccp:
 	;PRINT '?ldccp '
 	mvi c,13! call bdos ;reset disk
	xra a! sta ccp$fcb+15! sta ccp$fcb+32		; zero ex and cr
	lxi d,ccp$fcb! call open	; open file containing CCP
	inr a! jz no$CCP		; error if no file...
	lxi d,0100h! call setdma	; start of TPA
	lxi d,64! call setmulti	; allow up to 16k bytes
	lxi d,ccp$fcb! call read	; load the thing
	ret

 no$CCP:			; here if we couldn't find the file
	lxi h,ccp$msg ! call ?pmsg	; report this...
	call ?conin			; get a response
	mvi a,0! sta ccp$fcb! sta @scbbase+013h
	jmp ?rlccp			; and try again
    ; No external clock.

?rlccp: 
	;PRINT 'rlccp'
	jmp ?ldccp

?time:
	ret
	; CP/M BDOS Function Interfaces

seldsk:
	mvi c,14 ! jmp bdos		; change directory

open:
	mvi c,15 ! jmp bdos		; open file control block

close:
    mvi c,16 ! jmp bdos

setdma:
	mvi c,26 ! jmp bdos		; set data transfer address

setmulti:
	mvi c,44 ! jmp bdos		; set record count

read:
	mvi c,20 ! jmp bdos		; read records


;Data
signon$msg	db	13,10,'ZX 2020 CP/M 3.0 Bios start',13,10,0

ldr$msg		db	13,10,'Warning: Bootloader could not be restored',13,10,0
ccp$msg		db	13,10,'BIOS Error: No CCP.COM file.'
			db	13,10,'Press any key to load from drive A:',13,10,0
ccp$fcb		db	0,'CCP     ','COM' 
			ds	32
ldr$fcb		db	0,'BOOTLDR ','COM'
			ds	32

init$table:
dart$a:
	db dart$b-dart$a-2 ;Number of bytes
	db p$crt$stat ;Config register Channel A
	;db 0, 00011000b     ;wr0, channel reset
	db 1, 10000000b    ;wr1, halt CPU until character sent
	db 3, 11000001b     ;wr3, Rx 8 Bit, receive enable
	db 4, 10000100b     ;wr4, X32 Clock, No Parity, one stop bit
drr5:
	db 5, 01101000b     ;wr5, Tx 8 Bit, transmit enable
dart$b:
	db init$end-dart$b-2 ;Number of bytes
	db p$lpt$stat ;Config register Channel B
	;db 0, 00011000b     ;wr0, channel reset
	db 1, 10000000b    ;wr1, halt CPU until character sent
	db 3, 11000001b     ;wr3, Rx 8 Bit, receive enable
	db 4, 10000100b     ;wr4, X32 Clock, No Parity, one stop bit
	db 5, 01101000b     ;wr5, Tx 8 Bit, transmit enable
init$end: db	0			; end of init$table

	end

