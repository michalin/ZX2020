	public @dtbl
	extrn sersd0

	cseg

@dtbl	dw sersd0, sersd0    	; Ramdisk, Serial disk
	dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0		; drives C-P non-existant

	end
