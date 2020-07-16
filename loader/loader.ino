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
#include "serdisk.h"
#include "Z80.h"
#include "sram.h"


char msg[255];
bool prog_loaded, debug;

void busInit()
{ //Initialize bus to be controlled by Z80 (All portpins input)
  DDRA = 0;
  PORTA = 0; //0xff;
  DDRB &= ~((1 << MREQ_PIN) + (1 << WAIT_PIN) + (1 << RD_PIN) + (1 << WR_PIN));
  DDRC = 0;
  PORTC = 0; //0xff;
  DDRD &= ~((1 << RST_PIN) + (1 << IORQ_PIN));
  DDRG &= ~((1 << BUSACK_PIN) + (1 << M1_PIN));
  DDRL = 0;
  PORTL = 0; //0xff;
}

// the setup function runs once when you press reset or power the board
void setup()
{
  BUSRQ(PSV_HI);
  busInit();
  Serial.begin(115200);
  unmount();
  delay(10);
  Serial.println("@reset@");
}

void loadProgram(uint16_t saddr, uint16_t &bytestoload)
{
  static uint16_t addr = saddr;

  //Write serial input bytes into SRAM
  while (Serial.available())
  {
    uint8_t inChar = Serial.read();
    sramWrite(addr++, inChar);
    bytestoload--;
  }

  if (!bytestoload)
  {
    sprintf(msg, "%u bytes loaded, Start address: 0x%04X", addr - saddr, saddr);
    Serial.println(msg);
    addr = 0;
  }
}

//uint8_t _debug = 0;
void serialEvent()
{
  uint16_t proglen;
  static uint16_t saddr;
  static uint16_t bytestoload;

  //Serial.println("-->SerialEvent");
  if (bytestoload)
  {
    loadProgram(saddr, bytestoload);
  }
  uint8_t command[] = "@cmd@xxxxx";
  int i;
  
  while (Serial.available() && i < 9)
  {
    command[i++] = Serial.read();
    //Serial.println((char*)command);
    delay(1);
  }

  if (!memcmp(command, "@lad@", 5))
  {
    bitClear(DDRB, WAIT_PIN);
    BUSRQ(ACT_LO);
    Serial.println("Z80 program load");

    for (uint16_t i = 0x0000; i < 0xffff; i++) //Delete memory
      sramWrite(i, 0);

    //Get start address and total number of bytes expected
    saddr = 256 * (uint16_t)command[6] + command[5];
    proglen = 256 * (uint16_t)command[8] + command[7];
    bytestoload = proglen;
    //sprintf(msg, "%u bytes to load @ 0x%04X", bytestoload, saddr);
    //Serial.println(msg);
  }
  else if (!memcmp(command, "@run@", 5))
  {
    mount();
    delay(100);
    BUSRQ(PSV_HI);
    RESET();
    Serial.print("@running@");
    prog_loaded = true;
  }
  else if (!memcmp(command, "@mount@", 7))
  {
    mount();
  }
}

void loop()
{
}
