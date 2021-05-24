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

#include "sram.h"

char s_msg[255];

uint8_t sramRead(uint16_t addr)
{
    uint8_t val;
    MREQ(ACTIVE);
    RD(ACTIVE);
    WR(PASSIVE);
    DDRL = 0;
    DDRA = 0xFF;
    PORTA = (uint8_t)addr;
    DDRC = 0xFF;
    PORTC = (uint8_t)(addr >> 8);
    delayMicroseconds(10);
    val = PINL;
    DDRA = 0;
    DDRC = 0;
    RD(PASSIVE);
    WR(PASSIVE);
    MREQ(PASSIVE);
    return val;
}

void sramRead(uint8_t *buffer, uint16_t saddr, uint16_t len)
{
    for (uint16_t i = 0; i < len; i++)
    {
        buffer[i] = sramRead(saddr + i);
    }
}

void sramWrite(uint16_t addr, uint8_t data)
{
    DDRL = 0xFF;
    MREQ(ACTIVE);
    WR(PASSIVE); //WE must be high during address transitions
    PORTA = (uint8_t)addr;
    PORTC = (uint8_t)(addr >> 8);
    WR(ACTIVE);
    PORTL = data;
    WR(PASSIVE);
    MREQ(PASSIVE);
}

void sramTest()
{
    Serial.println("Starting SRAM Test");
    delay(10);
    BUSRQ(ACTIVE);
    MREQ(ACTIVE);
    int errors = 0;
    for (int addr_hi = 255; addr_hi >= 0; addr_hi--)
    {
        for (uint16_t addr_lo = 0; addr_lo <= 0xFF; addr_lo += 1)
        {
            uint16_t addr = (addr_hi << 8) + addr_lo;
            sramWrite(addr, addr_hi);
        }

        for (uint16_t addr_lo = 0; addr_lo <= 0xFF; addr_lo += 1)
        {
            uint16_t addr = (addr_hi << 8) + addr_lo;
            uint8_t rdback = sramRead(addr);
            if (rdback != addr_hi)
            {
                sprintf(s_msg, "Error at 0x%04X: Readback is 0x%02X, should be 0x%02X", addr, rdback, addr_lo);
                Serial.println(s_msg);
                errors++;
            }
            sramWrite(addr, 0);
        }
    }
    sprintf(s_msg, "\nSRAM test passed with %d errors", errors);
    Serial.println(s_msg);
    BUSRQ(PASSIVE);
}
