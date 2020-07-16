	title 'bank & move module for CP/M3 linked BIOS'

	cseg

	public ?move,?xmove,?bank
	extrn @cbnk

	maclib z80
	maclib ports

?xmove:		; ALTOS can't perform interbank moves
	ret

?move:
	xchg		; we are passed source in DE and dest in HL
	ldir		; use Z80 block move instruction
	xchg		; need next addresses in same regs
	ret

					; by exiting through bank select
?bank:
	push b				; save register b for temp
	ral ! ral ! ral ! ani 18h	; isolate bank in proper bit position
	mov b,a				; save in reg B
	in p$bankselect			; get old memory control byte
	ani 0E7h ! ora b		; mask out old and merge in new
	out p$bankselect		; put new memory control byte
	pop b				; restore register b
	ret

				;	128 bytes at a time

	end
