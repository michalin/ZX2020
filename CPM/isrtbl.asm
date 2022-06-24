; Copyright (C) 2022  Doctor Volt

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

; Initialize Interrupt table

    maclib syscfg
    ;maclib cpmtools
    extrn ?pmsg,@SCBBASE

cseg
@isrtbl:: 
    dw 0ff00h

?irqinit:: 
    ;Build default Interrupt table
    ld b,127! ld de,isr! ld hl,(@isrtbl)
    init$loop:
    ld (hl),e 
    inc hl 
    ld (hl),d
    inc hl
    djnz init$loop
    im 2 ;Enable Mode 2 Interrupt
    ld hl,(@isrtbl)
    ld a,h! ld i,a ;High byte of Interrupt Table address
    ei
    ret

isr: ;Default interrupt routine
    ex af,af'
    exx
    ld hl,msg! call ?pmsg
    ld a, 00010000b ;Reset Interrupts
    out p$zdartCFG$A   
    out p$zdartCFG$B 
    exx
    ex af,af'
    ei
    reti

msg:
    db "Warning: unknown interrupt",10,13,0

