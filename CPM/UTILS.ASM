   extrn ?co,?pmsg,@covec

;@covec: dw 0a000h

bdos equ 5
    maclib syscfg
; Reg. HL contains delay time in ms
sleep::
   ld bc,1
 outer$lp:
   push hl ;11
   ld hl,clk$freq/25  ;10
   inner$lp:
    sbc hl,bc; 15
    jp nz,inner$lp ;one loop takes 25 T States (6.25 µs with 4MHz clock) (10)
   pop hl ;10
   sbc hl,bc ;15
   jp nz,outer$lp ;10
   ret

; Print out a 16-Bit HEX value
; Input value in <hl>
hx16::
    push af
    push hl
    ld a,h
    call hx8
    pop hl! ld a,l
    call hx8
    pop af
    ret

; Input value in <a>
hx8::
    push af 
    ld (inval),a
    rra! rra! rra! rra  
    call hex4
    ld a,(inval)
    call hex4
    ld a,(inval)
    pop af
    ret
    inval: ds 1

hex4:
    and 0fh! cp 10 ; >=10
    jp p,a2f 
    add 48 ;output 0-9
    jp ot
 a2f: 
    add 55 ;output a-h
 ot:
   call ?putc
   ;out 10h
   ret

;dump 256 byte starting from location pointed to by HL
;reg. B contains the number of lines
memdmp::
 dump$out: ;outer loop
  push bc
  ld b,16 ;Number of bytes per line
  ld de,line$buf
 dump$ln: ;Inner loop: dump line
  ld a,(hl)! inc hl
  call hx8
  cp 20! jp p,prnttble ;printable char >20
  ld a,'-' ;Replace control chars by -
 prnttble:
  ld (de),a! inc de
  ld a,' '! call ?putc ;Blank
  djnz dump$ln
  ld b,20! ld de,line
 strout:
  ld a,(de)! inc de
  call ?putc
  djnz strout

  ld a,10! call ?putc ;Line break
  ld a,13! call ?putc
  pop bc
  djnz dump$out
  ret
  line db '    '
  line$buf ds 16


; Put character in register a to screen
?putc::
   push a
   ld hl,@covec
   ld a,h! or l! jp nz,putc$bios ; Are we in BIOS scope? (linked against chario.rel)
   pop a
   ld e,a! ld c,6! jmp bdos ; call BDOS function 6: DIRECT CONSOLE IO
   ;ret
 putc$bios: ;BIOS scope
   pop a
   ld hl,(@covec)
	ld c,a! ld b,0		; start with device 0
 co$next:
	adc hl,hl   ; shift out next bit
	jp nc,not$out$device
	push hl		; save the vector
	push bc	   ; save the character and device
	call ?co	   ; if device selected, print it
	pop bc		; recover count and character
	pop hl		; recover the rest of the vector
 not$out$device:
	inc b		; next device number
	ld a,h ! or l	; see if any devices left
	jp nz,co$next	; and go find them...
	ret

;Print a null terminated string pointed to by DE
printstr::
   ld a,(de)! inc de
   or a! ret z ; Terminate when character is zero
   push de
   call ?putc
   pop de
   jp printstr

