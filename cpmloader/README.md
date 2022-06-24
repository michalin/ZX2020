This is the QT App that lets you upload the CP/M bootloader (bootldr.com) to your Z80 computer via the Arduino Mega. It also serves as serial "Fileserver". I recommend to use Qt Creator 7.0.1 along with QT 6.3.0/MinGW 11.2.0 64-bit and Gnu make utility for Windows to build the executable. I developed and tested all under Windows 10, but it might also work on other platforms that are supported by QT. I have never tested this, so I cannot tell whether it works. It does not matter where the bootloader executable is located, but it will ask for the location of the CP/M root directory when you click the "load CP/M" button for the first time. The Root directory must contain the bootldr.com file and the folder "driveA" that contains the CP/M programs in up to 16 user folders.
Note that the maximal file size is 128 Kilobyte, which is enough for most cases.

https://www.qt.io

http://gnuwin32.sourceforge.net/packages/make.htm
