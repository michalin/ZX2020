# ZX 2020

Yet another homebuilt Z80 Computer, but this one works without any FPGAs or Microcontrollers, but components that were available at the time when the Z80 processor was state of the art. With only five ICs it can run historic programs like Multiplan, Wordstar and MBasic, as well as some games. It now supports PATA drives. This is a reminiscense to the Sinclair ZX81 computer. 

## To build the ZX 2020, do the following
- Wire the parts on a breadboard or perfboard like shown in the schematic
- Copy the CPM directory tree to any location on your PC, e.g. your user directory 
- Load the Arduino Sketch into an Arduino Mega
- Connect the TxDB and RxDB pins of the DART with a Serial-USB converter or Pin 0 and 1 of your Arduino Mega
- Start a serial terminal emulation, for example "Putty", set 125000 Baud, 8 Bit, 1 Stopbit, no parity
- Compile and run the tool `cpmloader.exe`. Then click on "Load CP/M" and select the file `bootldr.com`
- When a welcome message and the CP/M prompt "A>" appears on your terminal emulation, the ZX2020 is ready to use. If you have a PATA compatible hard drive connected, you need to format it with the "mkdsk" tool before you can use it. Note that all data on the disk will be lost. 

## Notes on TMS9918 Video Display Processor
CP/M is pre-built for supporting a PS/2 compatible keyboard and a TV or monitor. When using without a TMS99x8 (Serial connection only), you can change the following parameters in gencpm.dat and rebuild.
- MEMTOP   = FF  
- PAGWID   = 50  (80 columns)