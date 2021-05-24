	public @dtbl
	extrn pata0,sersd0

	cseg

	@dtbl	dw sersd0,0,pata0,pata0,pata0,pata0  	; A: Serial disk, C,D,E,F: PATA drive
	;@dtbl	dw 0,0,sersd0      	; A: Serial disk, C: PATA drive
	dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0		; drives C-P non-existant

	end
