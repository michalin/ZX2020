#
# Makefile for CP/M 3
ZXCC=zxcc.exe
RMAC=../bin/rmac.exe
LINK=../bin/drilink.exe

RM=del -f
CP=copy 

BDOS_SOURCES= CPMBDOS1.ASM CONBDOS.ASM BDOS30.ASM

all: kernel bootldr mkdsk

kernel: bdos3.spr bios3.spr 
	$(ZXCC) gencpm auto 
	@echo *

mkdsk: utils.rel
	$(RMAC) mkdsk.asm
	$(LINK) mkdsk,utils
	$(CP) mkdsk.com driveA\0

bootldr: utils.rel serdisk.rel pata.rel 
	$(RMAC) bootldr.asm
	$(LINK) bootldr[L0]=bootldr,serdisk,pata,utils

bios3.spr: bioskrnl.rel scb.rel boot.rel chario.rel drvtbl.rel move.rel serdisk.rel pata.rel utils.rel
	$(LINK) BIOS3[OS]=bioskrnl, scb, boot, chario, drvtbl, move, serdisk, pata, utils

bioskrnl.rel: bioskrnl.asm
	$(RMAC) bioskrnl.asm
scb.rel: scb.asm
	$(RMAC) scb.asm
boot.rel: boot.asm
	$(RMAC) boot.asm
chario.rel: chario.asm
	$(RMAC) chario.asm
move.rel: move.asm
	$(RMAC) move.asm
drvtbl.rel: drvtbl.asm
	$(RMAC) drvtbl.asm
serdisk.rel: serdisk.asm
	$(RMAC) serdisk.asm
pata.rel: pata.asm
	$(RMAC) pata.asm
utils.rel: utils.asm
	$(RMAC) utils.asm

bdos3.spr: BDOS3.ASM
	$(RMAC) BDOS3.ASM
	$(LINK) BDOS3[OS]=BDOS3

clean:
	$(RM) *.prn *.rel *.spr *.sym *.sys *.sbin *lst *.$$$ 

