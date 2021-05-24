#
# Makefile for CP/M 3
ZXCC=zxcc.exe
RMAC=$(ZXCC) driveA/0/rmac.com
LINK=$(ZXCC) driveA/0/link.com
#LINK="c:\zxcc\bin\ld80.exe"

RM=del
CP=copy 

BDOS_SOURCES= CPMBDOS1.ASM CONBDOS.ASM BDOS30.ASM

all: kernel bootldr mkdsk

kernel: bdos3.spr bios3.spr 
	$(ZXCC) gencpm auto 
	@echo *

mkdsk: utils.rel
	$(RMAC) mkdsk
	$(LINK) mkdsk,utils
	$(CP) mkdsk.com driveA\0

bootldr: utils.rel serdisk.rel pata.rel
	$(RMAC) bootldr
	$(LINK) bootldr[L0]=bootldr,serdisk,pata,utils

bios3.spr: bioskrnl.rel scb.rel boot.rel chario.rel drvtbl.rel move.rel serdisk.rel pata.rel utils.rel
	$(LINK) BIOS3[OS]=BIOSKRNL,SCB,BOOT,CHARIO,DRVTBL,MOVE,SERDISK,PATA,UTILS

bioskrnl.rel: bioskrnl.asm
	$(RMAC) bioskrnl
scb.rel: scb.asm
	$(RMAC) scb
boot.rel: boot.asm
	$(RMAC) boot
chario.rel: chario.asm
	$(RMAC) chario
move.rel: move.asm
	$(RMAC) move
drvtbl.rel: drvtbl.asm
	$(RMAC) drvtbl
serdisk.rel: serdisk.asm
	$(RMAC) serdisk
pata.rel: pata.asm
	$(RMAC) pata
utils.rel: utils.asm
	$(RMAC) utils

bdos3.spr: BDOS3.ASM
	$(RMAC) BDOS3.ASM
	$(LINK) BDOS3[OS]=BDOS3

clean:
	$(RM) *.prn *.rel *.spr *.sym *.sys *.sbin *.$$$ 

