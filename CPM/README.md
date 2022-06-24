This folder contains the system files, sources and some CP/M user programs in the directory *driveA*. You only need to compile the source files (*.asm), if you want to make changes to the kernel. 

**Compiling CP/M and auxiliary programs (if necessary)**
Requirements: 

 - Windows command prompt or PowerShell
 - GNU make utility for Windows: gnuwin32.sourceforge.net/packages/make.htm

todo:
- Add GNU make utiliy executable (make.exe) to your Path.
- Open command shell, cd into this directory and type "make"

When using without TMS99x8 (Serial connection only), you can change the following parameters in gencpm.dat and rebuild.
- MEMTOP   = FF  
- PAGWID   = 50  (80 columns)