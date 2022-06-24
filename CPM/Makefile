#
# Makefile for CP/M 3
ZXCC=zxcc.exe
RMAC=../bin/rmac.exe
LINK=../bin/drilink.exe
ZMAC=../bin/zmac.exe  --rel --dri --od ./

RM=del -f
CP=copy 

BDOS_SOURCES= CPMBDOS1.ASM CONBDOS.ASM BDOS30.ASM

all: kernel bootldr mkdsk

kernel: bdos3.spr bios3.spr 
	$(ZXCC) gencpm auto 
	@echo *

mkdsk: utils.rel chario.rel vdp.rel
	$(ZMAC) mkdsk.asm 
	$(LINK) mkdsk,utils
	$(CP) mkdsk.com driveA\0

bootldr: utils.rel serdisk.rel pata.rel chario.rel vdp.rel
	$(ZMAC) bootldr.asm
	$(LINK) bootldr[L0]=bootldr,utils,serdisk,pata,chario,vdp

bios3.spr: bioskrnl.rel scb.rel boot.rel chario.rel drvtbl.rel move.rel serdisk.rel pata.rel utils.rel vdp.rel isrtbl.rel
	$(LINK) BIOS3[OS]=bioskrnl,scb,boot,chario,drvtbl,move,serdisk,pata,utils,vdp,isrtbl

# BIOS Modules
bioskrnl.rel: bioskrnl.asm
	$(RMAC) bioskrnl.asm
scb.rel: scb.asm
	$(RMAC) scb.asm
boot.rel: boot.asm
	$(ZMAC) boot.asm
chario.rel: chario.asm
	$(ZMAC) chario.asm
move.rel: move.asm
	$(RMAC) move.asm
drvtbl.rel: drvtbl.asm
	$(RMAC) drvtbl.asm
serdisk.rel: serdisk.asm
	$(RMAC) serdisk.asm
pata.rel: pata.asm
	$(RMAC) pata.asm
vdp.rel: vdp.asm
	$(ZMAC) vdp.asm
isrtbl.rel: isrtbl.asm
	$(ZMAC) isrtbl.asm

# BDOS
bdos3.spr: BDOS3.ASM
	$(RMAC) BDOS3.ASM
	$(LINK) BDOS3[OS]=BDOS3

# Utilities

utils.rel: utils.asm
	$(ZMAC) utils.asm

clean:
	$(RM) *.prn *.rel *.spr *.sym *.sys *.sbin *lst *.$$$ 

