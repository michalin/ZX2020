#
# Makefile for CP/M 3
ZXCC="c:\zxcc\bin\zxcc.exe"
RMAC="c:\zxcc\bin\rmac.exe"
LINK="c:\zxcc\bin\drilink.exe"

RM=del
CP=copy

BDOS_SOURCES= CPMBDOS1.ASM CONBDOS.ASM BDOS30.ASM

all: bdos3.spr bios3.spr 
	zxcc gencpm auto 

bios3.spr: bioskrnl.rel scb.rel boot.rel chario.rel move.rel drvtbl.rel serdisk.rel
	$(LINK) BIOS3[OS]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,SERDISK

bioskrnl.rel: bioskrnl.asm
	RMAC bioskrnl
scb.rel: scb.asm
	RMAC scb
boot.rel: boot.asm
	RMAC boot
chario.rel: chario.asm
	RMAC chario
move.rel: move.asm
	RMAC move
drvtbl.rel: drvtbl.asm
	RMAC drvtbl

serdisk.rel: serdisk.asm
	RMAC serdisk

bdos3.spr: BDOS3.ASM
	RMAC BDOS3.ASM
	$(LINK) BDOS3[OS]=BDOS3


clean:
	$(RM) -f *.prn *.rel *.spr *.sym *.sys *.sbin *.$$$

