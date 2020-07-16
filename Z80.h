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

#ifndef Z80_H
#define Z80_H

#include "Arduino.h"
//Port B
#define MREQ_PIN PB0 //(Arduino Pin 53) Z80 Pin 19
#define RD_PIN PB1   //(Arduino Pin 52) Z80 Pin 21
#define WAIT_PIN PB2 //(Arduino Pin 51) Z80 PIN 24
#define WR_PIN PB3   //(Arduino Pin 50) Z80 Pin 22
#define CLK_PIN PB4  //(Arduino Pin 10) Z80 Pin 6
//Port G
#define BUSACK_PIN PG0 //(Arduino Pin 41) Z80 Pin 23
#define BUSRQ_PIN PG1  //(Artduino Pin 40) Z80 Pin 25
#define M1_PIN PG2     //Arduino Pin 39) Z80 Pin 27
//Port D
#define RST_PIN PD7  //(Arduino Pin 38) Z80 PIN 26
#define IORQ_PIN PD0 //(Arduino Pin 21)
//Address bus
#define ADDR_LO PINA //A0..A7
#define ADDR_HI PINC //A8..A9
#define ADDR ((ADDR_HI << 8) + ADDR_LO)

#define ACT_LO 1
#define PSV_HI 0
#define PSV_TRI 2 //Tristate pin

inline void RD(uint8_t b)
{
  b == PSV_TRI ? bitClear(DDRB, RD_PIN) : bitSet(DDRB, RD_PIN);
  b == PSV_HI ?  bitSet(PORTB, RD_PIN) : bitClear(PORTB, RD_PIN);
}
inline bool RD()
{
  bitClear(DDRB, RD_PIN);
  return !bitRead(PINB, RD_PIN);
}
inline void WAIT(bool b)
{
  //bitSet(DDRB, WAIT_PIN); //Pulled up by 10k resistor
  b == ACT_LO ? bitSet(DDRB, WAIT_PIN) : bitClear(DDRB, WAIT_PIN);
}
inline void WR(uint8_t b)
{
  b == PSV_TRI ? bitClear(DDRB, WR_PIN) : bitSet(DDRB, WR_PIN);
  b == PSV_HI ? bitSet(PORTB, WR_PIN) : bitClear(PORTB, WR_PIN);
}
inline bool WR()
{
  bitClear(DDRB, WR_PIN);
  return !bitRead(PINB, WR_PIN);
}
inline bool MREQ()
{
  bitClear(DDRB, MREQ_PIN);
  return !bitRead(PINB, MREQ_PIN);
}
inline void MREQ(uint8_t b)
{
  b == PSV_TRI ? bitClear(DDRB, MREQ_PIN) : bitSet(DDRB, MREQ_PIN);
  b == PSV_HI ? bitSet(PORTB, MREQ_PIN) : bitClear(PORTB, MREQ_PIN);
}
inline bool BUSACK()
{
  bitClear(DDRG, BUSACK_PIN);
  return !bitRead(PING, BUSACK_PIN);
}
inline void BUSRQ(bool b)
{
  b == ACT_LO ? bitSet(DDRG, BUSRQ_PIN) : bitClear(DDRG, BUSRQ_PIN);
  //bitClear(DDRG, BUSACK_PIN);
  //b == ACT_LO ? Serial.println("-->Bus requested") : Serial.println("-->Bus release");
  uint8_t i = 0;
  while (bitRead(PING, BUSACK_PIN) == b)
  {
    if (i++ == 100){
      Serial.println("BUSRQ failed");
      delay(1000);
    }
  }
  //b == ACT_LO ? Serial.println("Bus acknowledged-->") : Serial.println("Bus released-->");
}
inline bool M1()
{
  bitClear(DDRG, M1_PIN);
  return !bitRead(PING, M1_PIN);
}
inline void RESET(bool b)
{
  b == ACT_LO ? bitSet(DDRD, RST_PIN) : bitClear(DDRD, RST_PIN);
}
inline void RESET()
{
  RESET(ACT_LO);
  delay(1);
  RESET(PSV_HI);
}
inline bool IORQ()
{
  bitClear(DDRD, IORQ_PIN);
  return !bitRead(PIND, IORQ_PIN);
}

void sramWrite(uint16_t, uint8_t);
void busInit();


#endif