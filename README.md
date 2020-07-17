# ZX 2020

Yet another homebuilt Z80 Computer, but this one works without any FPGAs or Microcontrollers, but components that were available at the time when the Z80 processor was state of the art. With only three ICs it can run historic programs like Multiplan, Wordstar and MBasic, as well as some games. This is a reminiscense to the Sinclair ZX81 computer. 

To build the ZX 2020, do the following:
- Wire the parts on a breadboard or perfboard like shown in the schematic
- Copy the CPM directory tree to any location on your PC, e.g. your user directory 
- Load the Arduino Sketch into an Arduino Mega
- Start a serial terminal emulation, for example "Putty", set 125000 Baud, 8 Bit, 1 Stopbit, no parity
- Compile and run the tool cpmloader.exe
- Click on "Load CP/M" and select the file CPM3.SYS
- When a welcome message and the CP/M prompt "A>" appears on your terminal emulation, the ZX2020 is ready to use.

