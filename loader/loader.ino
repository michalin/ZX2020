/* Copyright (C) 2020  Doctor Volt

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
//#include "serdisk.h"
#include "Z80.h"
#include "sram.h"
#include "debug.h"

#define CHUNKLEN 32

bool wait4chunk = false; //Synchronization

//Parameter structure for the @ldcpm command
struct Ldaddr
{
  uint16_t base; //Memory address where the image starts
  uint16_t size; //Size of the image
  uint16_t reserved; //
} ldaddr;

void on_dtra();

void setup()
{
  bus_idle();
  Serial.begin(125000);
  //Check if there is a response on busrequest if not: ZX2020 not connected
  bool connected = true;
  if(!BUSRQ(ACTIVE))
  {
    connected = false;
  }
  if(!BUSRQ(PASSIVE))
  {
    connected = false;
  }
  if(!connected)
  {
    println("Not connected to ZX 2020 bus");
    Serial.end(); 
    return;
  }
  println("ZX 2020 bus connected");
  Serial.write("<$>ready</$>");

  RESET();
  BUSRQ(ACTIVE);
  //attachInterrupt(digitalPinToInterrupt(39), on_dtra, FALLING);
}
void serialEvent()
{
  static int bytestoload = 0;
  char chunk[CHUNKLEN];
  Serial.readBytes(chunk, CHUNKLEN); //Read chunk
  if (bytestoload == 0)              //Is it a command from PC? (@...@)
  {
    //Handle commands
    String command = String(chunk); // Serial.readString();
    //println(command.c_str());

    if (command.startsWith("@ldcpm")) //Start start addr and size Kernel
    {
      //BUSRQ(ACTIVE);
      for (uint16_t i = 0x0000; i < 0xffff; i++) //Delete memory
        sramWrite(i, 0);

      //Get start address and total number of bytes expected
      memcpy(&ldaddr, (chunk + 6), sizeof(ldaddr));
      println("Loading image file to Ram. Base: 0x%04X, size: 0x%04x", ldaddr.base, ldaddr.size);
      bytestoload = ldaddr.size;
      
      Serial.write("<$>rqcpm</$>"); //Signal for loader to send Kernel
      return;
    }
    else if (command.startsWith("@test")) //Test functions
    {
      BUSRQ(ACTIVE);
      println("Test");
      return;
    }
  }
  else if (bytestoload > 0) //Is there data to load into SRAM?
  {
    static uint16_t addr = ldaddr.base; //start addr = BDOS address
    for (int i = 0; i < CHUNKLEN; i++)
    {
      sramWrite(addr++, chunk[i]);
      bytestoload--;
    }
    if (bytestoload == 0)
    {
      println("Memory image loaded");
      Serial.write("<$>started</$>"); //Report to loader Z80 started

      if (!BUSRQ(PASSIVE))
      {
        println("Error: busrq failed");
      }
      //serdisk = true;
      RESET();
      println("Z80 restarted");
      Serial.end(); //Now the ZX2020 can use the interface
      bus_idle();
    }
  }
}

void bus_idle(){
  DDRA = 0; PORTA = 0;
  DDRB = 0; PORTB = 0;
  DDRC = 0; PORTC = 0;
  DDRD = 0; PORTD = 0;
  ;DDRE = 0; ;PORTE = 0;
  DDRG = 0; PORTG = 0;
  DDRL = 0; PORTL = 0;
}

void on_dtra()
{
  println("dtra");
}

void loop()
{

}
