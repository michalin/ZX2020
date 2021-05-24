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

//This class loads CP/M BDOS and BIOS into SRAM and initializes the jump vectors
#include "loader.h"

Loader::Loader(QSerialPort *serial, QObject *parent) : QObject(parent)
{
    p_serial  = serial;
}

void Loader::upload(const QString imgFileName){
    imgFile.setFileName(imgFileName);
    imgFile.open(QIODevice::ReadOnly);
    QByteArray cmd = "@ldcpm";
    cmd.append((uint8_t)0); //Base addr 0x0000
    cmd.append((uint8_t)0); //Base addr 0x0000
    cmd.append((uint8_t)imgFile.size());
    cmd.append((uint8_t)(imgFile.size() >> 8));
    cmd.append("@");
    p_serial->write(cmd); //Send Base address and size of image
}

//Singnals forwarded from mainwindow class
void Loader::on_command(const QByteArray cmd){
    if(cmd == "rqcpm"){
        QByteArray img = imgFile.readAll();
        p_serial->write(img);
        imgFile.close();
    }
}

Loader::~Loader(){
    qDebug("~Loader()");
}
