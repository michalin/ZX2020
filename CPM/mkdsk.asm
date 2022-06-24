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

    title 'ZX-2020 disk formatter'

    maclib utils

    PRINTLN 'ZX-2020 Disk formatter V2.0'
    RETDSK ; From which disk started?
    or a! jp z,check
    PRINTLN 'This program must be started from drive A>'
    jp 0
; Hard drive available?
check:
    SETERMDE 0 ;Default Error mode: Shows error message and returns to the calling program
    ld a,3! ld (cpm$fcb),a ;drive C>
    SEARCH cpm$fcb ;Search for CPM3.sys on C>
    push af! ld a,h 
    cp 4! jp nz, check$1 ;Drive valid
    PRINTLN 'No hard drive found'
    jp 0

 check$1: ; Kernel file?
    PRINTLN 'Hard drive found. What do you want to do?'
    PRINTLN 'i: Init disk'
    PRINTLN 'f: Format disk: Init disk and write system files'
    pop af! inc a! jp z,start
    PRINTLN 'u: Update kernel files'

; Main menu
start:
    PRINTLN 'Press any other key to quit'
    READKEY '>'
    cp 'i'! jz initd
    cp 'f'! jz format
    cp 'u'! jz update
    jp 0

initd:
    PRINT 'Initialize disk. All data will be lost. Sure? (y/n) '
    READKEY '>'
    cp 'y'! jp nz,0! call initb
    jp 0

format: 
    PRINT 'Format disk. All data will be lost. Sure? (y/n) '
    READKEY '>'
    cp 'y'! jp nz,0
    call initb
    call cpykrnl
    call cpysys
    CRLF
    PRINTLN 'Ready. To copy the CP/M files to drive C> enter "pip c:=*.*"'
    jp 0

update: 
    PRINT 'Update kernel file. Sure? (y/n) '
    READKEY '>'
    cp 'y'! jp nz, 0
    call cpykrnl
    jp 0

    ld a,3! ld (cpm$fcb),a
    lxi d,cpm$fcb! ;call searchf
    ora a! ;jz cpycpm ; Just replace the files, do not format

initb:
    PRINTLN 'writing directory block, please wait.'
    ;Select drive C:
    ld c,2! call ?sldsk
    call ?home

 ;fill DMA buffer with 0xE5
    ld b,0! ld hl,DMA
    ft$fill$dma:   
    ld (hl), 0E5h! inc hl
    djnz ft$fill$dma

 ;Fill sectors of track 0 
    lxi b,DMA! call ?stdma
    ld b,0! ld hl,0 
    ft$writeall:
        push bc! push hl
        ld b,h! ld c,l! call ?stsec
        call ?write
        pop hl! inc hl! pop bc
        djnz ft$writeall

    ld c,0! call ?sldsk
    ret

cpykrnl:
    ld bc,36! ld hl,cpm$fcb! ld de,cur$fcb
    ldir
    PRINTLN 'Copying Kernel to C>'
    ld b,1! call copy$file ; only first drive (C>)
    ret
cpysys:
    lxi b,36! lxi h,ccp$fcb! lxi d,cur$fcb
    LDIR
    PRINTLN 'Copying ccp to C-F>'
    ld b,4! call copy$file ; CCP.COM to all drives
    lxi b,36! lxi h,ldr$fcb! lxi d,cur$fcb
    LDIR
    PRINTLN 'Copying bootloader to C>'
    ld b,1! call copy$file ; BOOTLDR.COM to drive C>
    ret

;copy system files from A: to C:
copy$file:  
    push bc
    ld a,1! ld (cur$fcb),a ;Source drive a:
    OPEN cur$fcb
    STDMA DMA
    SETMULTI 128
	READSEQ cur$fcb	; load the thing
    CLOSE cur$fcb
    ld a,3! ld (cur$fcb),a ;set target drive
    pop bc! ld c,a ; b: number of runs; c: initial drive
 cf$wrloop:
    DIRIO '.'
    inc c  
    push bc
    xor a! ld (cur$fcb+32),a ;Reset cr flag before writing
    ld a,(cur$fcb+9)! and 07fh! ld (cur$fcb+9),a ;Reset Read-only Attribute, so we can overwrite
    SETATTR cur$fcb
    OPEN cur$fcb
    cp 0ffh! jp nz, cp$write ;If file exists
    MAKE cur$fcb ;If file does not exist, create it
 
 cp$write:
    WRITESEQ cur$fcb
    CLOSE cur$fcb
    ;Set attributes
    ld a,(cur$fcb+9)! ori 080h! ld (cur$fcb+9),a ;Set Read-only Attribute
    ld a,(cur$fcb+10)! ori 080h! ld (cur$fcb+10),a ;Set System Attribute
    SETATTR cur$fcb
    pop bc
    djnz cf$wrloop
    CRLF
    ret

; Redirection functions to BIOS calls
?home:
    ld a,8! ld (bp$func),a
    ld c,50! lxi d,biospb
    jp bdos

?sldsk:
    ld a,9! ld (bp$func),a
    ld a,c! ld (bp$bcreg),a
    ld a,0! ld (bp$bcreg+1),a
    ld c,50! lxi d,biospb
    jp bdos

?stsec:
    ld a,11! ld (bp$func),a
    ld a,c! ld (bp$bcreg),a
    ld a,b! ld (bp$bcreg+1),a
    ld c,50! lxi d,biospb
    jp bdos

?stdma:
    ld a,12! ld (bp$func),a
    ld a,c! ld (bp$bcreg),a
    ld a,b! ld (bp$bcreg+1),a
    ld c,50! lxi d,biospb
    jp bdos

?write:
    ld a,14! ld (bp$func),a
    ld c,50! lxi d,biospb
    jp bdos

DSEG

;Parameters to be passed to BIOS functions
biospb:
    bp$func ds 1
    bp$areg ds 1
    bp$bcreg ds 2
    bp$hlreg ds 2

cpm$fcb:
    db 0,'CPM3    ','SYS'
    dw 0,0,0,0,0,0,0,0,0,0,0,0
ccp$fcb:
    db 0,'CCP     ','COM'
    dw 0,0,0,0,0,0,0,0,0,0,0,0
ldr$fcb:
    db 0,'BOOTLDR ','COM'
    dw 0,0,0,0,0,0,0,0,0,0,0,0

cur$fcb ds 36

;@covec:: dw 0a000h

DMA db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;DMA equ $+100 ;use TPA after program for file exchange
end    

