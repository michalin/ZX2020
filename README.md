# Z80-CPM
A super-simple Z80 based computer that runs CP/M

This is the QT App that lets you upload the CP/M kernel (CPM3.SYS) to your Z80 computer. It also serves as serial "Fileserver".
I recommend to use Qt Creator 4.12.4 along with QT 5.15.0/MinGW 8.1.0 64-bit and CMake 3.17.1 to build the executable. 
I developed and tested all under Windows 10, but it might also work on other platforms that are supported by QT. 
I have never tested this, so I cannot tell whether it works.

the following directory structure is necessary:

<cpmhome>
|
|_ CPM3.SYS
   |
   |__ "driveA"
   |  |__"0"   ;files for user 0 (mandatory)
   |  |__"1"   ;files for user 1 (optional)
   |  |__<n> ;files for user 2..15 (optional)
   |
   |__"driveB"
   |  |__"0"   ;files for user 0 (mandatory)
   |  |__"1"   ;files for user 1 (optional)
   |  |__<n> ;files for user 2..15 (optional)

Make sure you have write permission. 
It does not matter where the cpmloader.exe is located, but it will ask for the location the directory <cpmhome> that must contain the CPM3.SYS file,
when you click the "load CP/M" button for the first time.
