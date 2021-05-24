;Bootloader remains in RAM

;Includes
maclib ports
maclib utils
maclib z80

extrn sd$init,sd$read,sd$write ;serdisk.asm
extrn pa$init,pa$read,pa$write ;pata.asm
extrn ?setup
public @trk,@sect,@dma

CLS MACRO
    local ?msg,?go
    jmp ?go
 ?msg:
    db 27,'[2J',27,'[H'
 ?go:
 	EXX
    mvi b, ?go-?msg
    mvi c, p$zdart
	lxi h, ?msg
	OUTIR
	EXX 
    ENDM

;General constants
cr	equ 13
lf	equ 10
bootdev equ 08000h ;Byte in memory shared with bios boot routine. Contains drive to boot from
                    ;0: Serial disk (A:), no HD
                    ;1: Serial disk (A:), init HD 
                    ;3: Hard disk (C:)
; 
; Main program
;
    db 0,0 ;reserved, must be zero
    jmp start
tmpbdos:
    db 0 ;jmp
    dw 0 ;Reserved space for temporary bdos jump vector used by BOOT.ASM/?rlldr
start:
    lxi sp, stack$end
;Init DART A
    mvi b,cfglen
    mvi c,p$zdart+1 ;Config Port A
    lxi h,dart$config
    OUTIR
;Init DART B
    mvi b,cfglen
    mvi c,p$zdart+3 ;Config Port B
    lxi h,dart$config
    OUTIR
    DLY 0FFFFh

;Init vars
    lxi h,0! shld @sect! shld @trk
    lxi h, dma$data! shld @dma

    CLS ;Clear screen
    PRINT 'ZX 2020 Bootloader V1.0 (c) by Doctor Volt'

    ;PRINT 'Init memory from 0x8000-0xffff'
    lxi h, 08000h
init$mem:  
    mvi m,0
    inr l! jnz init$mem
    inr h! jnz init$mem


;Init disk drive
    call pa$init
    ora a! jnz sdboot1 ;HD not available
; If a hard disk is available, check if it has a kernel file 
    Print 'hard drive found'
    call pa$read
;jmp sdboot2 ; Uncomment to always boot from serial
    call find$rec
    ora a! jnz sdboot2
    jmp hdboot
sdboot1:
    PRINT 'No hard drive found'
    mvi a,0! sta bootdev
    jmp sdboot
sdboot2:
    PRINT 'No CP/M system found on hard drive'
    mvi a,1! sta bootdev
sdboot: 
    PRINT 'Boot from Serial disk'
    call sd$read
    ora a! jnz sdboot$err
    lxi h,0! shld @sect ;Sector with the memory maps
    lxi h,1! shld @trk ;Track with cpm3.sys
    call find$rec
    ora a! jz boot
 sdboot$err:
    PRINT 'Serial disk not connected or CPM3.SYS missing'
    hlt

hdboot:
    PRINT 'Boot from hard drive'
    lxi h,0! shld @sect
    lxi h,1! shld @trk ; Read the first sector on Track 1 with the memory maps
    mvi a,3! sta bootdev
boot:
    call dev$read
    PRINT 'CP/M Load addresses:'
    PRINT ''
    ;Get load adresses of Kernel
    lxi d,biosbase! lxi h,dma$data+091h ;Base addr of BIOS
    call ?str2hex
    PRINT '*************************'
    PRINT '* BIOS START: 0x'
    lhld biosbase! call ?hex16
    lxi d,bdosbase! lxi h,dma$data+0ach ;Base addr of BDOS
    call ?str2hex
    PRINT '* BDOS START: 0x'
    lhld bdosbase! call ?hex16
    mvi a,JMP! sta tmpbdos
    lxi b,6! dad b! shld tmpbdos+1

    lxi d,biostop! lxi h,dma$data+097h ;BIOS size
    call ?str2hex
    lhld biostop
    LBCD biosbase
    dad b ;add BIOS base and BIOS size
    shld biostop ;store result in bistop
    PRINT '* TOP: 0x'
    call ?hex16

    lhld biostop
    LBCD bdosbase
    adi 0; this resets the carry flag
    DSBC BC ;BIOS Top - BDOS Base 
    shld krnlsize 
    PRINT '* KERNEL SIZE: 0x'! lhld krnlsize! call ?hex16
    ;Now read 256 byte sectors and copy 128-byte records in reverse order to biostop and below
    PRINT '*************************'
    PRINT ''

    mov b,h ; b contains number of sectors
    LDED biostop ;destination address for Kernel
copy$loop:
    push b
    ;Read next sector from disk
    lda @sect! inr a! sta @sect
    jnz copy$loop$rd
    lhld @trk! inx h! shld @trk
 copy$loop$rd: 
    push d! call dev$read! pop d
    dcr d ;Next target addr
    lhld @dma! lxi b,080h! dad b ;Upper 128 byte record of DMA buffer
    LDIR
    lxi b, 080h! lhld @dma ;Lower 128 byte record of DMA buffer
    LDIR
    dcr d
    pop b
    DJNZ copy$loop

biosstart:
    lhld biosbase
    pchl
;
; Auxiliary and debug functions
;
;find the string "CPM3   SYS" at the beginning of the dma buffer?
;returns a=0: if found. a=1 otherwise
find$rec 
    mvi b,11
    lxi h, krnl$rec
    LDED @dma! inx d! inx d
 fr$loop:
    ldax d! ani 07fh! cmp m 
    jnz fr$notfound
    inx d! inx h ;next two characters to compare
    DJNZ fr$loop
    xra a! ret
 fr$notfound:
    mvi a,1! ret

 krnl$rec db 'CPM3    SYS' ;Name of kernel file

;
;Branch to the read function
dev$read
    lda bootdev
 read$dev0:
    cpi 0! ;Read from A> (No HD)
    jz sd$read
 read$dev1:
    cpi 1! ;Read from A> (HD Avail.)
    jz sd$read
 read$dev2:
    cpi 2! ;Read from B>
    rz
 read$dev3:
    cpi 3! ;Read from C>
    jz pa$read

;
; Data area
;
dseg
dart$config:
wr$0: db 0, 00011000b     ;wr0, channel reset
wr$1: db 1, 10000000b    ;wr1, halt CPU until character sent
wr$3: db 3, 11000001b     ;wr3, Rx 8 Bit, receive enable
wr$4: db 4, 10000100b     ;wr4, X32 Clock, No Parity, one stop bit
wr$5: db 5, 01101000b     ;wr5, Tx 8 Bit, transmit enable
cfglen equ $-dart$config

bdosbase ds 2
biosbase ds 2
biostop ds 2
krnlsize ds 2
dma$data ds 256
@trk: ds 2
@sect: ds 2
@dma: ds 2

stack ds 16
db 'ende'
stack$end equ $


end
;trash

    lxi h,0! mvi b,0
    foo:
        mov a,m! call ?hex8
        inx h 
    DJNZ foo


