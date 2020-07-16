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
#include "sram.h"

#define CHUNK 20 //Bit position of chunk value

const uint8_t chunksize = 32;
const uint8_t reqlen = 21;
//void getChunk(byte *, byte *);
char dbgmsg[255];

void mount()
{
    Serial1.begin(125000);
    //Serial1.setTimeout(10);
    Serial.print("@mnt@");
}
void unmount()
{
    Serial.print("@umnt@");
    Serial1.end();
}

void serialEvent1()
{
    //Serial.print("-->serialEvent");
    byte pc_dta[chunksize]; //Data PC --> Z80
    byte z80_dta[128];      //Data Z80 --> PC
    static uint8_t len = 0;

    Serial1.readBytes(z80_dta, reqlen);
    if (!strncmp((char *)z80_dta, "@@@", 3)) //request
    {
        if (z80_dta[CHUNK] & 0x08) //chunk bit 3 set?
        { //write request
            Serial.write(z80_dta, reqlen); //Send request to the PC
            char ack[5];
            while(!Serial.available());
            Serial.readBytes(ack, 5);
            if(!memcmp(ack, "@ack@", 5)){ //Acknowledge from PC that it is ready to receive the chunk
                //Serial.write("Ack received");
                Serial1.write("&", 1); //Signal to Z80 that he can send the chunk
                while(!Serial1.available());
                Serial1.readBytes(z80_dta, chunksize); //Now get the data
                Serial.write(z80_dta, chunksize); //Forwared to PC
                //while(!Serial.available()); //Wait for Acknowledge
            }
        }
        else
        { //Read request
            do
            {
                Serial.write(z80_dta, reqlen); //Send read request to PC
                while (!Serial.available())
                    ;                                //Wait for reply from PC
                Serial.readBytes(pc_dta, chunksize); //Receive chunk from PC
            } while (!strncmp((char *)pc_dta, "@error@", 7));
            Serial1.write(pc_dta, chunksize); //Send chunk to Z80
        }
    }
}
