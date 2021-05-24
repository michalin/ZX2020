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
#define IORQ_PIN PB2 //Arduino Pin 51) Z80 Pin 20
#define WR_PIN PB3   //(Arduino Pin 50) Z80 Pin 22
#define CLK_PIN PB4  //(Arduino Pin 10) Z80 Pin 6
//Port G
#define BUSACK_PIN PG0 //(Arduino Pin 41) Z80 Pin 23
#define BUSRQ_PIN PG1  //(Artduino Pin 40) Z80 Pin 25
//#define RESERVED PG2   
//Port D
#define RST_PIN PD7 //(Arduino Pin 38) Z80 PIN 26
//Port E
#define TX0_PIN PE0 //(Arduino Pin0 / RX0)
#define TX1_PIN PE1 //(Arduino Pin1 / TX1)
//Address bus
#define ADDR_LO PINA //A0..A7
#define ADDR_HI PINC //A8..A9
#define ADDR ((ADDR_HI << 8) + ADDR_LO)

#define ACTIVE 1  //0V
#define PASSIVE 0 //5V, pulled up by 10k resistor

inline void RD(uint8_t b)
{
  (b == ACTIVE) ? bitClear(PORTB, RD_PIN) : bitSet(PORTB, RD_PIN);
}
inline void WR(uint8_t b)
{
  (b == ACTIVE) ? bitClear(PORTB, WR_PIN) : bitSet(PORTB, WR_PIN);
}

inline void MREQ(uint8_t b)
{
  (b == ACTIVE) ? bitClear(PORTB, MREQ_PIN) : bitSet(PORTB, MREQ_PIN);
}

inline void IORQ(uint8_t b)
{
  (b == ACTIVE) ? bitClear(PORTB, IORQ_PIN) : bitSet(PORTB, IORQ_PIN);
}

/*inline void WAIT(bool b)
{
  //bitSet(DDRB, WAIT_PIN); //Pulled up by 10k resistor
  b == ACT_LO ? bitSet(DDRB, WAIT_PIN) : bitClear(DDRB, WAIT_PIN);
}
inline bool RD()
{
  bitClear(DDRB, RD_PIN);
  return !bitRead(PINB, RD_PIN);
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
inline bool IORQ()
{
  bitClear(DDRB, IORQ_PIN);
  return !bitRead(PINB, IORQ_PIN);
}
inline bool BUSACK()
{
  bitClear(DDRG, BUSACK_PIN);
  return !bitRead(PING, BUSACK_PIN);
}
*/

inline bool BUSRQ(bool b)
{
  if (b) //Allocate bus
  {
    DDRA = 0xFF;
    DDRB |= (1 << RD_PIN) + (1 << WR_PIN) + (1 << MREQ_PIN) + (1 << IORQ_PIN);
    PORTB |= (1 << RD_PIN) + (1 << WR_PIN) + (1 << MREQ_PIN) + (1 << IORQ_PIN);
    DDRC = 0xFF;
    DDRL = 0xFF;
    bitSet(DDRG, BUSRQ_PIN);
  }
  else //Free bus
  {
    DDRA = 0;
    DDRB &= ~((1 << RD_PIN) + (1 << WR_PIN) + (1 << MREQ_PIN) + (1 << IORQ_PIN));
    DDRC = 0;
    DDRL = 0;
    bitClear(DDRG, BUSRQ_PIN);
  }

  uint8_t i = 0;
  while (bitRead(PING, BUSACK_PIN) == b)
  {
    if (i++ == 10)
    { //Allow 10 retries, then return error
      return 0;
    }
    delay(1);
  }
  return 1;
}

inline void RESET(bool b)
{
  b == ACTIVE ? bitSet(DDRD, RST_PIN) : bitClear(DDRD, RST_PIN);
}
inline void RESET()
{
  RESET(ACTIVE);
  delay(100);
  RESET(PASSIVE);
}

void sramWrite(uint16_t, uint8_t);

#endif