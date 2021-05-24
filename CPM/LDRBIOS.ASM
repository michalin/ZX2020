;--------------------------------------------------------
;
;	PROGRAM ID:	GBIOS3.ASM
;			GENERIC LOADER AND BIOS FOR CP/M PLUS
;			FOR CP/M-80 V2.2 SYSTEMS
;			UNBANKED
;			NO HASHING
;			BIOS PERFORMS BLOCKING/DEBLOCKING
;
;--------------------------------------------------------
;
;	ORGANIZATIONAL COMMENTARY
;
;--------------------------------------------------------
;	This BIOS is designed to be the user's first step
;in making an upgrade from CP/M-80 v2.2 to CP/M Plus v3.0.
;This BIOS will function properly in most CP/M-2 systems,
;even those with the BIOS in PROM.
;
;FUNCTION:
;	This PROGRAM implements an UNBANKED, NON-HASHED,
;UNBUFFERED BIOS for CP/M Plus version 3.0.
;
;METHOD:
;	CP/M Plus allows many levels of sophistocation in
;the implementation of the BIOS.  At the highest levels,
;the BIOS allows CP/M Plus to manage a potentially large
;memory pool which acts like an instant access disk drive;
;a substantial performence enhancement.  At the lowest level,
;the performance of CP/M Plus is the same as that of CP/M-80
;version 2.2.  This interface program is a simple implementation
;of a CP/M Plus BIOS which operates as a parasite to the user's
;existing BIOS for CP/M-80 version 2.2.
;
;PURPOSE:
;	This BIOS allows the CP/M-80 v2.2 user to easily
;upgrade to CP/M Plus v3.0 and enjoy its logical enhancements
;at the same level of performance he has enjoyed with v2.2.
;This BIOS can be an end-point since system performance
;will be satisfactory.  For users who own the hardware
;required to implement hashing and buffering, this BIOS
;will serve as a welcome starting point for further enhancement.
;
;ORGANIZATION:
;	This BIOS is organized as follows:
;
;	CONSTANTS
;	CONFIGURATION CONSTANTS AND CONDITIONS  ***
;	EXTERNAL REFERENCES
;	PUBLIC DECLARATIONS	(NULL)
;	RAM DEFINITIONS
;	CP/M 2.2 LINKAGE EQUATES
;
;	CP/M PLUS JUMP TABLE
;	INITIALIZATION PROCESSES
;	LOCAL AND NULL PROCESSES
;	SIMPLE INDEXED PROCESSES
;	COMPLEX INDEXED PROCESSES
;	LOCAL SUBROUTINES
;	INITIALIZED STORAGE
;	UNINITIALIZED STORAGE
;	END
;
;	***	edit these
;--------------------------------------------------------
;
;	OPERATIONAL COMMENTARY
;
;--------------------------------------------------------
;
;	Digital Research owes much of its success to the
;foresight of its operating system designers who have seen
;fit to make their products upward compatible with one
;another.  CP/M Plus is no exception, and so it is no
;surprise that the CP/M Plus BIOS shares many constructs
;with the earlier CP/M-80 v2.2.
;
;	The CP/M Plus BIOS implements 32 entry points in
;its jump table.  Of these, the first 17 correspond to the
;17 entries in the CP/M-80 v2.2 jump table.  14 of these
;are treated as identical to those in 2.2.  These index
;directly into the 2.2 jump table.  The remaining three in the
;2.2 set are BOOT, which is null, WBOOT, which loads CCP.COM,
;and SELDSK which creates all of the necessary disk data
;structures required by CP/M Plus based on those in the 2.2 BIOS.
;The remaining 15 entries in the CP/M Plus BIOS, with the
;single exception of MOVE, are implemented in one of
;the following ways:
;
;	1.)	null, simply return.
;	2.)	nearly null, do something really simple.
;	3.)	tell a white lie.
;
;--------------------------------------------------------
;
;	constants
;
;--------------------------------------------------------
true	equ	-1
false	equ	not true
jmpop	equ	0c3h
getch	equ	1
print	equ	9
open	equ	15
readseq	equ	20
dma	equ	26
;--------------------------------------------------------
;
;	configuration constants and conditions
;
;--------------------------------------------------------
drives	equ	2		;number of drives supported
bios	equ	0e900h		;address of your bios
ldrbios	equ	true
;ldrbios	equ	false
;--------------------------------------------------------
;
;	external references
;
;--------------------------------------------------------
	extrn	@civec, @covec, @aovec, @lovec, @bnkbf
	extrn	@crdma
	extrn	@crdsk,	@fx, @resel, @vinfo, @usrcd, @ermde
	extrn	@date, @hour, @min, @sec, @mxtpa
;--------------------------------------------------------
;
;	public declarations
;
;--------------------------------------------------------
;
;currently null
;
;--------------------------------------------------------
;
;	ram definitions
;
;--------------------------------------------------------
iobyte	equ	3
tpa	equ	100h
dffcb	equ	5ch
stack80	equ	100h
bootram	equ	0
bdos	equ	5
ccp	equ	tpa
;--------------------------------------------------------
;
;	cp/m v2.2 linkage equates
;
;--------------------------------------------------------
boot80	equ	0
warm80	equ	3
cnst80	equ	6
cnin80	equ	9
cnot80	equ	12
list80	equ	15
punc80	equ	18
redr80	equ	21
home80	equ	24
slds80	equ	27
strk80	equ	30
ssec80	equ	33
sdma80	equ	36
read80	equ	39
writ80	equ	42
lsta80	equ	45
sctr80	equ	48
;--------------------------------------------------------
;
;	cp/m plus version 3.0 jump table
;
;--------------------------------------------------------
	cseg
;	org	(bios-(200h+64*drives)) and 0ff00h
;
	jmp	boot	;arrive here from cold start load
warmpt:
	jmp	wboot	;arrive here for warm start
	jmp	const	;return console input status
	jmp	conin	;read console character
	jmp	conout	;write conlole character
	jmp	list	;write list character
	jmp	auxout	;write aux character
	jmp	auxin	;read aux character
	jmp	home	;move to track zero on selected drive
	jmp	seldsk	;select disk drive
	jmp	settrk	;set track number
	jmp	setsec	;set sector number
	jmp	setdma	;set DMA address
	jmp	read	;read selected sector
	jmp	write	;write selected sector
	jmp	listst	;return list device status
	jmp	sectrn	;translate logical to physical sector number
	jmp	conost	;return console output status
	jmp	auxist	;return aux device input status
	jmp	auxost	;return aux device output status
	jmp	devtbl	;return address of character i/o table
	jmp	devini	;init character i/o devices
	jmp	drvtbl	;return address of disk drive table
	jmp	multio	;set number of consec. sec. to read/write
	jmp	flush	;flush user [de]blocking buffers
	jmp	move	;copy memory to memory
	jmp	xmove	;set banks for next move
	jmp	selmem	;select memory bank
	jmp	setbnk	;set bank for next DMA
	jmp	userf	;reserved for me.
	jmp	wboot
	jmp	wboot	;reserved for DRI
;
;
;--------------------------------------------------------
;
;	initialization processes
;
;--------------------------------------------------------
boot:
	if	ldrbios
	ret
	endif
	;boot is null, falls thru to wboot
wboot:
	lxi	sp,stack80
;
;	initialize low memory jumps
;
	lxi	h,warmpt
	shld	bootram+1
	lhld	@mxtpa
	shld	bdos+1
	mvi	a,jmpop
	sta	bootram
	sta	bdos
;
;	load ccp.com into tpa
;
	mvi	b,36
	lxi	h,dffcb
	call	clear		;clear fcb area in low ram
	lxi	h,dffcb
	mvi	m,1		;drive a:
	inx	h
	lxi	d,ccpstg	;'ccp     com'
	lxi	b,11		;length of a file name
	call	move		;move filename to fcb
	lxi	d,dffcb
	mvi	c,open
	call	bdos		;open ccp.com
	ora	a
	jnz	operr		;if no error (
	lxi	d,tpa		;load into tpa
;
;	the load loop
;
ldloop:
	push	d		;the current dma address
	mvi	c,dma
	call	bdos		;set dma for next 128 byte read
	lxi	d,dffcb
	mvi	c,readseq
	call	bdos		;read file data to tpa ram
	ora	a		;test for complete
	pop	d		;restore dma address
	jnz	gocpm		;exit when past file end
	lxi	h,128		;advance dma address 128 bytes
	dad	d
	xchg
	jmp	ldloop		;loop
;
;
gocpm:
	cpi	1		;only legal exit = past end of file
	jnz	rderr
	jmp	ccp		;now turn it loose
;
;
operr:
	lxi	d,opnmsg	;"BIOS can't open CCP.COM"
	jmp	errs
rderr:
	lxi	d,errmsg	;"BIOS has bad sector in CCP.COM"
errs:
	mvi	c,print
	call	bdos		;print the complaint
	mvi	c,getch
	call	bdos		;wait for any key
	jmp	wboot		;try again and again
;--------------------------------------------------------
;
;	local and null processes
;
;--------------------------------------------------------
conost:
auxist:
auxost:
	mvi	a,true		;the white lies
devini:
multio:
xmove:
selmem:
setbnk:
userf:
	ret			;the null routines
flush:
	xra	a		;not implemented
	ret
devtbl:
	lxi	h,-1		;not implemented
	ret
drvtbl:
	lxi	h,-2		;no table, no hashing
	ret
move:
;	z80 users may code as:
;	xchg
;	db	0edh,0b0h	;ldir
;	xchg
;	ret
;
	ldax	d
	mov	m,a
	inx	h
	inx	d
	dcx	b
	mov	a,b
	ora	c
	jnz	move
	ret
;--------------------------------------------------------
;
;	simple indexed processes
;
;--------------------------------------------------------
const	equ	bios+cnst80
conin	equ	bios+cnin80
conout	equ	bios+cnot80
list	equ	bios+list80
auxout	equ	bios+punc80
auxin	equ	bios+redr80
home	equ	bios+home80
settrk	equ	bios+strk80
setsec	equ	bios+ssec80
setdma	equ	bios+sdma80
read	equ	bios+read80
write	equ	bios+writ80
listst	equ	bios+lsta80
sectrn	equ	bios+sctr80
;--------------------------------------------------------
;
;	complex indexed functions
;
;--------------------------------------------------------
;this routine functions as follows:
;	1.)	the requested drive is saved for use as index later
;	2.)	seldsk in bios 2.2 is called to set-up disk tables
;	3.)	the returned bios 2.2 dph address is saved
;	4.)	the saved drive number is used to index into a block
;		of length (drives * 64-bytes).  The 64-byte area
;		reserved for this drive is initially cleared (zeros).
;	5.)	using data taken from dph 2.2 returned by seldsk 2.2,
;		a new dph for 3.0 is constructed, with dpb and dirbcb.
;
;	like this:
;
;		dph:	25 bytes
;		null	7 bytes
;		dpb:	17 bytes
;		dirbcb:	15 bytes
;
;		the dph references dpb and dirbcb.  dirbcb references
;		the dirbuf from dph 2.2.  xlt, csv, alv are from dph2
;		dpb3 is copied directly from the dpb in your bios
;
seldsk:
	lxi	h,0		;bad drive
	mov	a,c		;drive request
	cpi	drives
	rnc			;exit if no space alloc for drive
	mov	b,e		;prev. selected bit
	push	b		;save drive request
	call	bios+slds80	;run seldsk 2.2
	pop	b		;restore drive request
	mov	a,l
	ora	h		;test for illegal drive
	rz			;if legal_drive (
	shld	dph2		;save address of dph 2.2
	mov	l,c		;drive number
	mvi	h,0
	dad	h		;*2
	dad	h		;*4
	dad	h		;*8
	dad	h		;*16
	dad	h		;*32
	dad	h		;*64...64 bytes per entry
	lxi	d,tables	;base of table space
	dad	d		;address of base block this drive
	mov	a,b		;selected bit
	ani	1		;lsb = 1 if previously selected
	rnz			;don't reinit if prev. sel.
	shld	dph3		;save address of new dph 3.0
	mvi	b,64		;bytes to clear
	call	clear		;initialize space
	lhld	dph2
	xchg
	lhld	dph3
	lxi	b,2
	call	move		;dph3.xlt
	lxi	b,12		;offset to dph3.csv
	dad	b
	xchg
	lxi	b,10		;offset to dph2.csv
	dad	b
	xchg
	lxi	b,4		;2 words
	call	move		;dph3.csv, alv
	xchg			;saving pointer to dph3.dirbcb
	lxi	b,32+17		;offset to bcb area
	lhld	dph3		;base
	dad	b
	push	h		;saving pointer to dirbcb
	xchg			;restore pointer to dph3.dirbcb
	mvi	a,-1		;dirbcb is unused
	stax	d		;set dirbcb.drv to unused status
	mov	m,e		;
	inx	h
	mov	m,d		;dph3.dirbcb <- dirbcb
	inx	h
	mvi	m,-1		;
	inx	h
	mvi	m,-1		;dph3.dtabcb <- empty
	lhld	dph2
	lxi	b,8		;offset to dirbuf entry
	dad	b
	xchg			;[de] is source
	pop	h		;restore pointer to dirbcb
	lxi	b,10		;offset to bufadr entry
	dad	b
	lxi	b,2		;1 word
	call	move		;dirbcb.bufadr <- dirbuf2.2
	xchg			;[hl] points to dph2.dpb
	mov	e,m		;
	inx	h
	mov	d,m		;read address of dpb2
	lhld	dph3
	lxi	b,12		;offset to dpb within dph3
	dad	b
	push	h		;points to dpb within dph3
	lhld	dph3
	lxi	b,32		;offset to dpb3
	dad	b
	pop	b		;restore pointer to dph3.dpb
	mov	a,l
	stax	b		;
	inx	b
	mov	a,h
	stax	b		;dph3.dpb <- dpb3
	lxi	b,15		;bytes in dpb2
	call	move		;fill-in dpb3 from dpb2
	if	ldrbios
	lxi	h,tables+64	;empty space in dph3 for drive b:
	mvi	b,15		;length of bcb
	call	clear
	lxi	h,tables+64+15	;empty space past dtabcb
	shld	tables+64+10	;dtabcb.bufadr
	lxi	h,tables+64	;dtabcb address
	shld	tables+20	;dph3.dtabcb
	mvi	m,-1		;set dtabcb.drv to unused
	endif
	lhld	dph3		;the big lie
	ret			; )

;--------------------------------------------------------
;
;	local subroutines
;
;--------------------------------------------------------
clear:
	mvi	m,0
	inx	h
	dcr	b
	jnz	clear
	ret
;--------------------------------------------------------
;
;	initialized storage
;
;--------------------------------------------------------
ccpstg:
	db	'CCP     COM'
opnmsg:
	db	0dh,0ah,'BIOS can''t open CCP.COM $'
errmsg:
	db	0dh,0ah,'BIOS has bad sector in CCP.COM $'
;--------------------------------------------------------
;
;	uninitialized storage
;
;--------------------------------------------------------
	dseg
dph2	ds	2
dph3	ds	2
tables	ds	64*drives
	end
;--------------------------------------------------------
;cp/m is a registered trademark of digital research, inc.
;you already knew that, but they wanted us to remind you.
;--------------------------------------------------------
