	title	'Boot loader module for CP/M 3.0'

true equ -1
false equ not true

banked	equ false

	public	?init,?ldccp,?rlccp,?time
	extrn	?pmsg,?conin
	extrn	@civec,@covec,@aivec,@aovec,@lovec
	extrn 	@cbnk,?bnksl

	maclib ports
	maclib z80
	maclib debug
	debug equ true

bdos	equ 5

	if banked
tpa$bank	equ 1
	else
tpa$bank	equ 0
	endif

	dseg	; init done from banked memory

?init:
	lxi h,08000h ! shld @civec ! shld @covec	; assign console to CRT:
	lxi h,04000h ! shld @lovec 			; assign printer to LPT:
	lxi h,02000h ! shld @aivec ! shld @aovec	; assign AUX to CRT1:
	lxi h,init$table ! call out$blocks	; set up misc hardware
	lxi h,signon$msg ! call ?pmsg		; print signon message
	ret	

out$blocks:
	mov a,m ! ora a ! rz ! mov b,a
	inx h ! mov c,m ! inx h
	outir
	jmp out$blocks


	cseg	; boot loading most be done from resident memory
	
    ;	This version of the boot loader loads the CCP from a file
    ;	called CCP.COM on the system drive (A:).


?ldccp:
	; First time, load the A:CCP.COM file into TPA
	xra a ! sta ccp$fcb+15		; zero extent
	lxi h,0 ! shld fcb$nr		; start at beginning of file
	lxi d,ccp$fcb ! call open	; open file containing CCP
	inr a ! jz no$CCP		; error if no file...
	lxi d,0100h ! call setdma	; start of TPA
	lxi d,128 ! call setmulti	; allow up to 16k bytes
	lxi d,ccp$fcb ! call read	; load the thing

if banked
					; now,
					;   copy CCP to bank 0 for reloading
	lxi h,0100h ! lxi b,0C80h	; clone 3K, just in case
	lda @cbnk ! push psw		; save current bank
ld$1:
	mvi a,tpa$bank ! call ?bnksl	; select TPA
	mov a,m ! push psw		; get a byte
	mvi a,2 ! call ?bnksl		; select extra bank
	pop psw ! mov m,a		; save the byte
	inx h ! dcx b			; bump pointer, drop count
	mov a,b ! ora c			; test for done
	jnz ld$1
	pop psw ! call ?bnksl		; restore original bank
endif
	ret

no$CCP:			; here if we couldn't find the file
	lxi h,ccp$msg ! call ?pmsg	; report this...
	call ?conin			; get a response
	jmp ?ldccp			; and try again

?rlccp:
	jmp ?ldccp
	ret

    ; No external clock.
?time:
	ret

	; CP/M BDOS Function Interfaces

open:
	mvi c,15 ! jmp bdos		; open file control block

setdma:
	mvi c,26 ! jmp bdos		; set data transfer address

setmulti:
	mvi c,44 ! jmp bdos		; set record count

read:
	mvi c,20 ! jmp bdos		; read records


signon$msg	db	27,'[2J',27,'[H','ZX 2020 CP/M 3.0 ready. Type "type intro" for advice',13,10,0

ccp$msg		db	13,10,'BIOS Err on A: No CCP.COM file',0


ccp$fcb		db	1,'CCP     ','COM',0,0,0,0
		ds	16
fcb$nr		db	0,0,0

init$table	db	3,p$zpio$3a,0CFh,0FFh,07h	; set up config port
		db	3,p$zpio$3b,0CFh,000h,07h	; set up bank port
		db	1,p$bank$select,0	; select bank 0
		db	0			; end of init$table

	end
