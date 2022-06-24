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

; Character I/O for the Modular CP/M 3 BIOS. Interrupt routines for PS/2 keyboard interrupts
; and driver for TMS99x8 

	KBLAYOUT equ "DE"
    vdp$pos equ 2 ;Bit in @covec etc. representing VDP

    ;public	?cinit,?ci,?co,?cist,?cost
    public @ctbl
    extrn @isrtbl 				;isrtbl.asm
	extrn ?vdpinit,?vdputc		;vdp.asm
	
    maclib syscfg
    maclib modebaud
    maclib utils

cseg
;
; Initialization routine for character IO devices. Device number in reg. C
?cinit::
	ld a,c! or a! jp z,init$dart
	cp 1! jp z,init$ps2
	cp 2! jp z,init$vdp
	ret
 init$dart: ;DART without interrupts for serial console
    ld hl,darta$cfg! ld b,dartb$cfg-darta$cfg ! ld c,p$zdartCFG$A ;Init DART A
    otir
    ld b,dart$cfg$end-dartb$cfg ! ld c,p$zdartCFG$B ;Init DART B
    otir
	ret
 init$ps2: ;PS/2 keyboard
	ld ix,(@isrtbl)
    ld hl,isr1! ld (ix+2),l! ld (ix+3),h
    ld hl,isr5! ld (ix+10),l! ld (ix+11),h

	ld a,1! out p$zdartCFG$A
	ld a,dart$ra1! or 1! out p$zdartCFG$A ;Ext interrupt DART-A
	ld a,1! out p$zdartCFG$B
	ld a,dart$rb1! or 5! out p$zdartCFG$B ;Status affects vector, Ext interrupt DART-B
    ret
 init$vdp: ;TMS99x8 VDP
	call ?vdpinit
	ret

?ci::		; character input
	ci1: call ?cist! jp z,ci1		; wait for character ready
    bit 7,a! jp nz,ps2$read
	dec c ! in a,(c)			; get data
	and 7Fh				; mask parity
	ret
    ps2$read:
    ld a,(kbinchr)! and 7Fh! ld (kbinchr),a ;reset flag
    ret

?cist::		; character input status
 	ld a,b! cp vdp$pos! jp z,ps2$stat
    jp m,dart$stat
    ld b,0 
    dart$stat:
	ld l,b ! ld h,0		; make device number 16 bits
	ld de,data$ports ! add hl,de	; make pointer to port address
	ld c,(hl) ! inc c		; get SIO status port
	in a,(c)				; read from status port
	and 1! ret nz	; new character in DART, return 1
    ret
    ps2$stat:
    ld a,(kbinchr)! and 80h! ret nz ;character in PS/2, return 80h
	xor a! ret ;(else) if no character available, return 0

?co::		; character output
 	ld a,b! cp vdp$pos! jp z,vdp$out
    jp m,dart$out
    ret ;null$device: 
 vdp$out:
    call ?vdputc
    ret 
 dart$out:
	ld a,c! push af		; save character from <C>
	push bc				; save device number
	pop hl ! ld l,h ! ld h,0	; get device number in <HL>
	ld de,data$ports ! add hl,de	; make address of port address
	ld c,(hl)				; get port address
	pop af! out (c),a		; send data
    ret    
 
?cost::
    mvi a,0ffh ; Output devices always ready
    ret


; Interrupt Service Routines for PS/2 keyboard interrupts
; This only handels the Ext. Interrupt of DART-B by resetting its interrupt flag. data is actually read in the clock ISR, isr5
isr1: ;EXT Interrupt DART B (CTSA, PS/2 data)
    ex af,af'
    ld a, 00010000b ;Reset Interrupts
    out p$zdartCFG$B   
    ex af,af'
    ei
    reti

isr5: ;EXT Interrupt DART A (CSTA, PS/2 clock)
    ex af,af'
    exx
    in p$zdartCFG$A
    and 00100000b ;CTSA (Clock status )
    jp z, eisr5 ; if CTSA not active:skip (Ignore rising edge)

    ld hl,cntr! inc(hl) ;Count up clock counter (count bits)
    ld a,(cntr)
    cp 1! jp z,eisr5 ;Skip start bit
    cp 10! jp p,scn$rdy ;Parity bit: Character fully received 
    ;cntr = 2..9; Data bits, fall through
    in p$zdartCFG$B
    and 00100000b ;mask CTSB (data) bit
    jp z, ones
    srl b ; clock in "0"
    jp eisr5
    ones:
    sra b! set 7,b ; clock in "1"

 eisr5:  
    ld a, 00010000b ;Reset Interrupts
    out p$zdartCFG$A   
    exx  
    ex af,af'
    ei
    reti
 scn$rdy: ;All data bits received (skipped stop and parity)
	ld a,255! delay: dec a! jp nz,delay ;Hang around for a while, so the stop and parity bit cannot trigger an Interrupt
    ld hl,status
    ld a,(hl)! and 1! jp nz, rlsd1  ;if status == 1 goto rlsd1
    ld a,b
    ;HEX8 a! jp scn$rdy$end
    cp 12h! jp z,shft ;Shift key (left)
    cp 59h! jp z,shft ;Shift key (right)
    cp 14h! jp z,ctrl ;control key
    cp 11h! jp z,alt ;alt key
    cp 0E0h! jp z,e$0 ;Special key like Ins, DEL, PgUp etc.
    cp 0f0h! jp z,rlsd0 ;Key released 

    ;Now look up the character we typed in the character table
    ld c,a! ld b,0 ;make 16 bit value in BC
    ld hl,keymap2
    ld a,(status)! and 0C0h! jp nz, pick
    ld hl,keymap1
    pick:
    add hl,bc ; (hl) points to character in keymap
    ld a,(status)! bit 6,a! jnz on$ctrl ;CTRL pressed?
    ld a,(hl)! jp pick$rdy
    on$ctrl: ;If CTRL pressed, 
    ld a,(status)! bit 5,a! jnz on$ctrlalt  ;CTRL-ALT pressed
    ld a,(hl)! sub 64 ;Subtract 64 ('@') to get CTRL A-Z 
    jp pick$rdy
    on$ctrlalt:  ;If ALT pressed

    pick$rdy:
    or a! jz scn$rdy$end ;On unknown key, it picks 0: Do nothing and return
    or 80h ;Set pending flag
    ld (kbinchr),a
    ;call ?hex8
    jp scn$rdy$end
    shft:
    set 7,(hl)! jp scn$rdy$end
    ctrl:
    set 6,(hl)! jp scn$rdy$end
    alt:
    set 5,(hl)! jp scn$rdy$end
    e$0:
    set 4,(hl)! jp scn$rdy$end
    rlsd0: ;set status bit 0, if key released
    set 0,(hl)! jp scn$rdy$end

    rlsd1: ;Goes here if scancode before was f0h (key released, status = 1)
    res 0,(hl) ;reset "key released" bit
    res 4,(hl) ;reset E0 Bit
    ld a,b
    ;ld a,(shiftreg) ;b ; Scancode we just received
    cp 12h! jp z,shft$rel ;Shift key (left)
    cp 59h! jp z,shft$rel ;Shift key (right)
    cp 14h! jp z,ctrl$rel ;control key
    cp 11h! jp z, alt$rel ;alt key
    jp scn$rdy$end
    shft$rel:
    res 7,(hl)! jp scn$rdy$end ;reset Shift
    ctrl$rel:
    res 6,(hl)! jp scn$rdy$end ;rest CTRL
    alt$rel:
    res 5,(hl)! jp scn$rdy$end ;reset ALT
    
    scn$rdy$end:
    xor a! ld(cntr),a ;Reset clock counter
    jp eisr5 

dseg
cntr:       db 0 ;Clock counter
;shiftreg:   db 0 ;"Shift register" where the scancode goes in
status:     db 0 ;Bit 7: Shift Bit 6: Ctrl, Bit 5: Alt, Bit 4: E0, Bit 1: a key was released
kbinchr:    db 0  ;ASCII value of last key pressed. Bit 7 indicates new pending character 

if KBLAYOUT = "DE" 
keymap1:
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0, '^', 0
    db  0,  0,  0,  0,  0, 'q','1', 0,    0,  0, 'y','s','a','w','2', 0
    db  0, 'c','x','d','e','4','3', 0,    0, ' ','v','f','t','r','5', 0
    db  0, 'n','b','h','g','z','6', 0,    0,  0, 'm','j','u','7','8', 0
    db  0, ',','k','i','o','0','9', 0,    0, '.','-','l','\','p','\', 0
    db  0,  0 ,'@', 0, '|','=', 0,  0,    0,  0, 13, '+', 0, '#', 0,  0
    db  0, '<', 0,  0,  0,  0,  8,  0,    0, '1','v','4','7', 0,  0,  0
    db '0','.','2','5','6','8',1Bh, 0,    0,  0, '3', 0,  0, '9', 0,  0
    db  0,  0,  0,  0 
keymap2:
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0, '~', 0
    db  0,  0,  0,  0,  0, 'Q','!', 0,    0,  0, 'Y','S','A','W','"', 0
    db  0, 'C','X','D','E','$',0a7h,0,    0, ' ','V','F','T','R','%', 0
    db  0, 'N','B','H','G','Z','&', 0,    0,  0, 'M','J','U','/','(', 0
    db  0, ';','K','I','O','=',')', 0,    0, ':','_','L',';','p','?', 0
    db  0,  0, 27h, 0, '[','=', 0,  0,    0,  0, 13, '*', 0, 27h, 0,  0
    db  0, '>', 0,  0,  0,  0,  0,  0,    0,  0, 'V', 0,  0,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0 
else
; US keymap
keymap1:
    db  0,  0,  0,  0,  0,  0,  0,  0,     0,  0,  0,  0,  0,  0, '`', 0
    db  0,  0,  0,  0,  0, 'q','1', 0,     0,  0, 'z','s','a','w','2', 0
    db  0, 'c','x','d','e','4','3', 0,     0,' ', 'v','f','t','r','5', 0
    db  0, 'n','b','h','g','y','6', 0,     0,  0, 'm','j','u','7','8', 0
    db  0, ',','k','i','o','0','9', 0,     0, '.','/','l',';','p','-', 0
    db  0,  0, 27h, 0, '[','+', 0,  0,     0,  0, 13, ']', 0, '|', 0,  0
    db  0,  0,  0,  0,  0,  0,  8,  0,     0, '1', 0, '4','7', 0,  0,  0
    db '0','.','2','5','6','8',1Bh, 0,     0,  0, '3', 0,  0, '9', 0,  0
    db  0,  0,  0,  0 
keymap2:
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0, '~', 0
    db  0,  0 , 0,  0,  0, 'Q','!', 0,    0,  0, 'Z','S','A','W','@', 0
    db  0, 'C','X','D','E','$','#', 0,    0, ' ','V','F','T','R','%', 0
    db  0, 'N','B','H','G','Y','&', 0,    0,  0, 'M','J','U','&','*', 0
    db  0, '<','K','I','O',')','(', 0,    0, '>','?','L',':','P','_', 0
    db  0,  0, '"', 0, '{','=', 0,  0,    0,  0, 13, '}', 0, '\', 0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0,  0,  0,  0,  0,    0,  0,  0,  0,  0,  0,  0,  0
    db  0,  0,  0,  0 
.endif

darta$cfg:
    db 0, 00011000b     ;wr0, channel reset
    db 1, dart$ra1     ;wr1, halt CPU until character sent
    db 3, dart$ra3     ;wr3, Rx 8 Bit, receive enable
    db 4, dart$ra4     ;wr4, X32 Clock, No Parity, one stop bit
    db 5, dart$ra5     ;wr5, Tx 8 Bit, transmit enable
dartb$cfg:
    db 0, 00011000b     ;wr0, channel reset
    db 1, dart$rb1     ;wr1, halt CPU until character sent, EXT. int enabled, Status affects vector
    db 2, dart$rb2     ;wr2. Interrupt vector
    db 3, dart$rb3     ;wr3, Rx 8 Bit, receive enable
    db 4, dart$rb4     ;wr4, X32 Clock, No Parity, one stop bit
    db 5, dart$rb5     ;wr5, Tx 8 Bit, transmit enable
dart$cfg$end equ $


data$ports:		; serial base ports by physical device number
	db	p$zdart$A,p$zdart$A

@ctbl	db 'CRT   '	; device 0, CRT port 0
	db mb$in$out+mb$serial+mb$softbaud
	db baud$9600
	db 'LPT   '	; device 1, LPT port 0
	db mb$in$out+mb$serial+mb$softbaud+mb$xonxoff
	db baud$9600
	db 'CRT1  '	; device 2, CRT port 1
	db mb$in$out+mb$serial+mb$softbaud
	db baud$9600
	db 'CRT2  '	; device 3, CRT port 2
	db mb$in$out+mb$serial+mb$softbaud
	db baud$9600
	db 'CRT3  '	; device 4, CRT port 3
	db mb$in$out+mb$serial+mb$softbaud
	db baud$9600
	db 'VAX   '	; device 5, LPT port 1 used for VAX interface
	db mb$in$out+mb$serial+mb$softbaud
	db baud$9600
	db 'CEN   '	; device 6, Centronics parallel printer
	db mb$output
	db baud$none
	db 0			; table terminator

end
