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

;Bootloader remains in RAM

;Includes
    maclib utils

    extrn sd$read ;serdisk.asm
    extrn ?painit,?paread ;pata.asa
    extrn ?cinit,?irqinit
    public @covec
    public @trk,@sect,@dma

bootdev equ 08000h ;Byte in memory shared with bios boot routine. Contains drive to boot from
                    ;0: Serial disk (A:), no HD
                    ;1: Serial disk (A:), init HD 
                    ;3: Hard disk (C:)
; 
; Main program
;
    db 0,0 ;reserved, must be zero
    jp start
tmpbdos:
    db 0 ;jmp
    dw 0 ;Reserved space for temporary bdos jump vector used by BOOT.ASM/?rlldr
start:
    ld sp,stack$end
    ld c,0! call ?cinit ;Init DART A and B without interrupt
    PRINT <27,'[2J',27,'[H'> ;Clear terminal screen, Cursor to home position
    ld c,2! call ?cinit ;Init VDP

;Init vars
    ld hl,0! ld (@sect),hl! ld(@trk),hl
    ld hl,dma$data! ld (@dma),hl

    PRINTLN 'ZX 2020 Bootloader V2.0 (c) Doctor Volt'
    ;PRINTLN 'Init memory from 0x8000-0xffff'
    ld hl, 08000h
init$mem:  
    ld (hl),0
    inc l! jp nz,init$mem
    inc h! jp nz,init$mem

;Init disk drive
    call ?painit
    or a! jp nz,sdboot1 ;HD not available
; If a hard disk is available, check if it has a kernel file 
    PRINTLN 'Hard drive found'
    
    call ?paread

   ; jp sdboot2 ; Uncomment to always boot from serial

    call find$rec
    or a! jp nz,sdboot2
    jp hdboot
sdboot1:
    PRINTLN 'No hard drive found'
    ld a,0! ld (bootdev),a
    jp sdboot
sdboot2:
    PRINTLN 'No CP/M system found on hard drive'
    ld a,1! ld (bootdev),a
sdboot: 
    PRINTLN 'Boot from Serial disk'
    call sd$read! or a! jp nz,sdboot$err
    ld hl,0! ld (@sect),hl ;Sector with the memory maps
    ld hl,1! ld (@trk),hl ;Track with cpm3.sys
    call find$rec
    or a! jp z,boot
 sdboot$err:
    PRINTLN 'Serial disk not connected or CPM3.SYS missing'
    hlt

hdboot:
    PRINTLN 'Boot from hard drive'
    ld hl,0! ld (@sect),hl
    ld hl,1! ld (@trk),hl ; Read the first sector on Track 1 with the memory maps
    ld a,3! ld (bootdev),a
boot:
    call dev$read
;    ld hl,dma$data+80h! call ?print! halt
    PRINTLN 'CP/M Load addresses:'
    CRLF
    PRINTLN '*************************'
    ;Get load adresses of Kernel
    ld de,biosbase! ld hl,dma$data+091h ;Base addr of BIOS
    call ?str2hex
    ld hl,(biosbase)
    PRINT '* BIOS START: 0x'! HEX16 h! CRLF
    ld de,bdosbase! ld hl,dma$data+0ach ;Base addr of BDOS
    call ?str2hex
    ld hl,(bdosbase)
    push hl
    PRINT '* BDOS START: 0x'! HEX16 h! CRLF
    pop hl
    ld a,0C3h! ld (tmpbdos),a ;JP **
    ld bc,6! add hl,bc! ld (tmpbdos+1),hl ;temporary BDOS jump vector

    ld de,biossize! ld hl,dma$data+097h ;BIOS size
    call ?str2hex ;Size of BIOS in DE
    ld hl,(biosbase)
    ld bc,(biossize)
    add hl,bc ;add BIOS base and BIOS size
    ld (biostop),hl ;store result in bistop
    PRINT '* TOP: 0x'! HEX16 h! CRLF

    ld hl,(biostop)
    ld bc,(bdosbase)
    adi 0; this resets the carry flag
    sbc hl,bc ;BIOS Top - BDOS Base 
    ld (krnlsize),hl
    PRINT '* KERNEL SIZE: 0x'! HEX16 h! CRLF
    ;Now read 256 byte sectors and copy 128-byte records in reverse order to biostop and below
    PRINTLN '*************************'
    ld a,(krnlsize+1) ;High byte of Kernelsize is the number of 256 byte sectors
    ld b,a ; b contains number of sectors
    ld de,(biostop) ;destination address for Kernel
copy$loop:
    push bc
    ;Read next sector from disk
    ld a,(@sect)! inc a! ld (@sect),a
    jp nz,copy$loop$rd
    ld hl,(@trk)! inc hl! ld (@trk),hl
 copy$loop$rd: 
    push de! call dev$read! pop de
    dec d ;Next target addr
    ld hl,(@dma)! ld bc,080h! add hl,bc ;Upper 128 byte record of DMA buffer
    ldir
    ld bc,080h! ld hl,(@dma) ;Lower 128 byte record of DMA buffer
    ldir
    dec d
    pop bc
    djnz copy$loop

;biosstart:
    ld hl,(biosbase)
    jp (hl)
;
; Auxiliary and debug functions
;
;find the string "CPM3   SYS" at the beginning of the dma buffer?
;returns a=0: if found. a=1 otherwise
find$rec:
    ld b,11
    ld hl,krnl$rec
    ld de,(@dma)! inc de!
 fr$loop:
    ld a,(de)! and 07fh! cp (hl) 
    jp nz,fr$notfound
    inc de! inc hl ;next two characters to compare
    djnz fr$loop
    xor a! ret
 fr$notfound:
    ld a,1! ret ;//todo
    ;ld a,0! ret

 krnl$rec: db 'CPM3    SYS' ;Name of kernel file

;
;Branch to the appropriate read function
dev$read
    lda bootdev
 read$dev0:
    cp 0! ;Read from A> (No HD)
    jp z,sd$read
 read$dev1:
    cp 1! ;Read from A> (HD Avail.)
    jp z,sd$read
 read$dev2:
    cp 2! ;Read from B>
    ret z
 read$dev3:
    cp 3! ;Read from C>
    jp z,?paread

;Convert a byte string into a hex number
;Input: <hl> Start addr of string, <de> Start addr of result (16 bit word)
;After execution, the address pointed to by DE contains a hex number
?str2hex::
    ld b,2
    inc de
 s2h$lp:
    ld a,(hl)! inc hl
    call ?c2hex
    add a! add a! add a! add a! ;Shift left 4 bytes
    ld c,a ;Upper 4 bits
    ld a,(hl)! inc hl
    call ?c2hex
    add c
    ld (de),a 
    dec de
    djnz s2h$lp
    ret
?c2hex: ;Convert Single character in <a> to hex value
    cp 65 ;'character A'
    jp m,deci
    sbc 55 ;A-F
    ret
 deci: 
    sbc 47 ;1-9
    ret


dseg

bdosbase ds 2
biosbase ds 2
biossize ds 2
biostop ds 2
krnlsize ds 2
dma$data ds 256
@trk: ds 2
@sect: ds 2
@dma: ds 2

@covec: dw 0a000h

stack ds 32
 db 'ende'
stack$end equ $


end


