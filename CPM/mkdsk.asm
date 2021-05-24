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

    bdos equ 5

    maclib ports
    maclib z80
    maclib utils

; From which disk started?
    call retdskf
    ora a! jz check
    PRINT 'This program must be started from drive A>'
    jmp 0

; Hard drive available?
check:
    mvi e,0ffh! call setermdef
    mvi a,3! sta cpm$fcb
    lxi d,cpm$fcb! call searchf
    push psw! mov a,h 
    cpi 4! jnz check$1 
    print 'No hard drive found'
    jmp 0

 check$1: ; Kernel file?
    lxi d,welcome1! call printf
    pop psw! inr a! jz start
    lxi d,welcome2! call printf

; Main menu
start:
    call readkey
    cpi 'i'! jz initd
    cpi 'f'! jz format
    cpi 'u'! jz update
    jmp 0

initd:
    PRINT 'Initialize disk. All data will be lost. Sure? (y/n) '
    call readkey
    cpi 'y'! jnz 0
    call initb
    jmp 0

format: 
    PRINT 'Format disk. All data will be lost. Sure? (y/n) '
    call readkey
    cpi 'y'! jnz 0
    call initb
    call cpykrnl
    call cpysys
    lxi d,readymsg! call printf
    jmp 0

update: 
    PRINT 'Update kernel file. Sure? (y/n) '
    call readkey
    cpi 'y'! jnz 0
    call cpykrnl
    jmp 0

    mvi a,3! sta cpm$fcb
    lxi d,cpm$fcb! ;call searchf
    ora a! ;jz cpycpm ; Just replace the files, do not format

initb:
    PRINT 'writing directory block, please wait.'
    ;Select drive C:
    mvi c,2! call ?sldsk
    call ?home

 ;fill DMA buffer with 0xE5
    mvi b,0! lxi h, DMA
    ft$fill$dma:   
    mvi m, 0E5h! inx h
    DJNZ ft$fill$dma

 ;Fill sectors of track 0 
    lxi b,DMA! call ?stdma
    mvi b,0! lxi h,0 
    ft$writeall:
        push b! push h
        mov b,h! mov c,l! call ?stsec
        call ?write
        pop h! inx h! pop b
        DJNZ ft$writeall

    mvi c,0! call ?sldsk
    ret

cpykrnl:
    lxi b,36! lxi h,cpm$fcb! lxi d,cur$fcb
    LDIR
    PRINT 'Copying Kernel to C>'
    mvi b,1! call copy$file ; only first drive (C>)
    ret
cpysys:
    lxi b,36! lxi h,ccp$fcb! lxi d,cur$fcb
    LDIR
    PRINT 'Copying ccp to C-F>'
    mvi b, 4! call copy$file ; CCP.COM to all drives

    lxi b,36! lxi h,ldr$fcb! lxi d,cur$fcb
    LDIR
    PRINT 'Copying bootloader to C>'
    mvi b, 1! call copy$file ; BOOTLDR.COM to drive C>
    ret

;copy system files from A: to C:
copy$file:  
    push b
    mvi a,1! sta cur$fcb ;Source drive a:
    lxi d,cur$fcb! call openf
    lxi d,DMA! call setdmaf
  	mvi e,128! call setmultf	; allow up to 16k bytes
	lxi d,cur$fcb! call readf	; load the thing
    lxi d,cur$fcb! call closef
    ;lxi h,DMA! ;mvi b,0! ;mvi c,p$zdart
    ;outir
    mvi a,3 ;Drive to start with
    sta cur$fcb ;set target drive

    pop b! mov c,a ; b: number of runs c: initial drive
 cf$wrloop:
    push b! push d
    mvi e,'.'! call coniof
    pop d! pop b
    ;PRINT 'Writing: '
    ;mov a,c! ;call ?hex8
    inr c  
    push b
    ;mvi a,3! ;sta cur$fcb ;Target drive C:
    xra a! sta cur$fcb+32 ;Reset cr flag before writing
    lda cur$fcb+9! ani 07fh! sta cur$fcb+9 ;Reset Read-only Attribute, so we can overwrite
    lxi d,cur$fcb! call setattf
    lxi d,cur$fcb! call openf
    cpi 0ffh! jnz cp$write ;If file exists
    lxi d,cur$fcb! call makef ;If file does not exist, create it
 
 cp$write:
    lxi d,cur$fcb! call writef
    lxi d,cur$fcb! call closef
    ;Set attributes
    lda cur$fcb+9! ori 080h! sta cur$fcb+9 ;Set Read-only Attribute
    lda cur$fcb+10! ori 080h! sta cur$fcb+10 ;Set System Attribute
    lxi d,cur$fcb! call setattf
    pop b
    DJNZ cf$wrloop
    ret

;Waits for key pressed and returns value in <a>.
readkey:
    mvi c,6! mvi e,'>'! call bdos
    mvi c,6! mvi e,0fdh! call bdos
    push psw
    mvi c,6! mov e,a! call bdos
    pop psw
    ret

welcome1:
    db 'ZX-2020 disk formatter. What do you want to do?',10,13
    db 'i: Init disk',10,13
    db 'f: Format disk: Init disk and write system files',10,13,'$'
welcome2:
    db 'u: Update kernel files',10,13,'$'

readymsg:
    db 10,13,'Ready',10,13
    db 'To copy the CP/M files to drive C> enter "pip c:=*.*"',10,13,'$'

;BDOS function calls
;Input characters from command line
coniof:
    mvi c,6! jmp bdos

printf:
    mvi c,9! jmp bdos

seldskf:
    mvi c,14! jmp bdos

openf:
    mvi c,15! jmp bdos
closef:
    mvi c,16! jmp bdos
searchf:
    mvi c,17! jmp bdos
readf:
    mvi c,20! jmp bdos
writef:
    mvi c,21! jmp bdos
makef:
    mvi c,22! jmp bdos
retdskf:
    mvi c,25! jmp bdos
setdmaf:
    mvi c,26! jmp bdos
setmultf:
    mvi c,44! jmp bdos

setermdef:
    mvi c,45! jmp bdos

setattf:
    mvi c,30! jmp bdos

; Redirection functions to BIOS calls
?home:
    mvi a,8! sta bp$func
    mvi c,50! lxi d,biospb
    jmp bdos

?sldsk:
    mvi a,9! sta bp$func
    mov a,c! sta bp$bcreg
    mvi a,0! sta bp$bcreg+1 
    mvi c,50! lxi d,biospb
    jmp bdos

?stsec:
    mvi a,11! sta bp$func
    mov a,c! sta bp$bcreg
    mov a,b! sta bp$bcreg+1 
    mvi c,50! lxi d,biospb
    jmp bdos

?stdma:
    mvi a,12! sta bp$func
    mov a,c! sta bp$bcreg
    mov a,b! sta bp$bcreg+1 
    mvi c,50! lxi d,biospb
    jmp bdos

?write:
    mvi a,14! sta bp$func
    mvi c,50! lxi d,biospb
    jmp bdos

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

DMA equ $+100 ;use TPA after program for file exchange


end    

