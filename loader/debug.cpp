/*Arduino Library for CF Cards and PATA hard disks
Copyright (C) 2020  Michael Linsenmeier (michalin70@gmail.com)
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.*/

#include "debug.h"

/* output sprintf formatted string */
/*Send sprintf-formatted debug messages to cpmloader*/
void println(const char *msg, ...)
{
    char data[255];
    va_list args;
    va_start(args, msg);
    vsprintf(data, msg, args);
    Serial.print("<DBG>");
    Serial.println(data);
    Serial.print("</DBG>");
}

void print(const char *msg, ...)
{
    char data[255];
    va_list args;
    va_start(args, msg);
    vsprintf(data, msg, args);
    Serial.print("<DBG>");
    Serial.print(data);
    Serial.print("</DBG>");
}


void hexdump(const byte *buf, const uint16_t start, const size_t len=256)
{
    const int rlen = 16;
    const int offset = 8;
    char line[80];
    for (uint16_t addr = 0; addr < len; addr+=16)
    {
        memset(line, 0, 80);
        line[127] = 0;
        sprintf(line, "0x%04x:  ", addr+start);
        for(int i = 0; i < rlen; i++)
        {
            sprintf(line+offset+3*i, "%02X ", buf[addr+i]);
        }
        line[offset+3*rlen] = 32; //blank
        for(int i = 0; i < rlen; i++)
        {
            if(buf[addr+i] >=32 && buf[addr+i] <= 255) //printable character
                sprintf(line+offset+3*rlen+i+1, "%c", buf[addr+i]);
            else
                sprintf(line+offset+3*rlen+i+1, "%s", ".");
        }
        
        Serial.print("<DBG>");
        Serial.println(line);
        Serial.print("</DBG>");
    }
}
