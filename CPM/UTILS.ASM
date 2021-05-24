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


   title 'Utility functions that make assembly programming easier'

   maclib z80
   maclib ports

   public ?str2hex,?c2hex,?hex8,?hex16,?showfcb

;Convert a byte string into a hex number
;Input: <hl> Start addr of string
;Output: <de> Start addr of result (16 bit word)
?str2hex:
    mvi b,2
    inx d
 s2h$lp:
    mov a,m! inx h
    call ?c2hex
    add a! add a! add a! add a! ;Shift left 4 bytes
    mov c,a ;Upper 4 bits
    mov a,m! inx h
    call ?c2hex
    add c
    stax d 
    dcx d
    DJNZ s2h$lp
    ret
?c2hex: ;Convert Single character in <a> to hex value
    cpi 65 ;'character A'
    jm dec
    sbi 55 ;A-F
    ret
 dec: 
    sbi 47 ;1-9
    ret

; Print out a 16-Bit HEX value
; Input value in <hl>
?hex16:
    push psw
    mov a,h
    call ?hex8
    mov a,l
    call ?hex8
    pop psw
    ret
    
; Input value in <a>
?hex8:
    sta inval
    ;mvi a,0bah
    rar! rar! rar! rar  
    call hex4
    lda inval
    call hex4
    lda inval
    ret
    inval: ds 1

hex4:
    ani 0fh! cpi 10 ; >=10
    jp a2f 
    adi 48 ;output 0-9
    jmp ot
 a2f: 
    adi 55 ;output a-h
 ot:
    out p$zdart
   ret

; Dump an FCB
; Start addr of fcb in hl
?showfcb:
	mov a,m! call ?hex8 ;Drive
	mvi b,11! mvi c,p$zdart! inx h 
	outir ; Print Filename
	mvi b,24
 sf$loop:
	mov a,m! call ?hex8
	mvi a,' '! out p$zdart
    inx h
 	DJNZ sf$loop
    ret
