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
#include <QDebug>
#include <QFile>
#include <QThread>
#include "loader.h"

Loader::Loader(QSerialPort *serial, QObject *parent) : QObject(parent)
{
    p_serial  = serial;
}
void Loader::on_RxData(){

    QByteArray data = p_serial->readAll();
    if(data.contains("@reset@")){
        loadCPM();
    } else if (data.contains("@running")){
        disconnect(p_serial, SIGNAL(readyRead()), this, SLOT(on_RxData()));
        emit finished();
    }

    qDebug("Loader: ");
    for(int i = 0; i < data.size(); i++){
        printf("%c", (char)data[i]);
    }
    fflush(stdout);
    //emit serialDataReceived(data);

}

void Loader::open(const QString sysFileName){
    this->sysFileName = sysFileName;
    //qDebug("-->Loader::openPort(%s)", name.toLocal8Bit().data());
    connect(p_serial, SIGNAL(readyRead()), this, SLOT(on_RxData()));
   p_serial->setDataTerminalReady(true);
   p_serial->setDataTerminalReady(false);
}

void Loader::loadCPM(){
    qDebug("-->loadCPM()");

    QByteArray cpm;
    uint16_t bios, bdos;
    gencpm(sysFileName, cpm, bdos, bios);
    qDebug("BDOS base: 0x%04X", bdos);
    qDebug("BIOS base: 0x%04X", bios);
    upload(cpm, bdos, bios);
    p_serial->write("@run@    "); //Start command
    p_serial->waitForBytesWritten();
}

void Loader::upload(QByteArray cpm, const uint16_t bdos, const uint16_t bios){
    QByteArray header = "@lad@";

    QByteArray jump;  //Construct jump vector to Bios
    jump.append(0xC3); //JP nn
    jump.append(bios);
    jump.append(bios >> 8);
    cpm.prepend(jump);

   uint16_t base = bdos - 3;
   uint16_t size = cpm.size();

    header.append((uint8_t)base);
    header.append((uint8_t)(base >> 8));
    header.append((uint8_t)size);
    header.append((uint8_t)(size >> 8));
    p_serial->write(header); //Command + Header
    p_serial->waitForBytesWritten();
    QThread::sleep(2);


    p_serial->write(cpm); //now the program
    p_serial->waitForBytesWritten();
}

void Loader::gencpm(const QString file, QByteArray &cpm, uint16_t &bdosbase, uint16_t &biosbase)  //Does the same like GENCPM.COM
{
    //QCoreApplication a(argc, argv);
    QFile cpm3sys(file);
    if(!cpm3sys.exists()){
        qDebug("Error: No cpm3.sys\n");
    }

    cpm3sys.open(QIODevice::ReadOnly);
    QByteArray inbuf = cpm3sys.readAll();
    cpm3sys.close();
    if(inbuf.isEmpty()){
        qDebug("Error: cpm3.sys could not be read\n");
    }

    //Write inbuf records into list
    QList<QByteArray> records;
    for(int i = 0; i < inbuf.size()/128; i++){
        QByteArray rec = inbuf.mid(128*i, 128);
        records.append(rec);
    }

    //Read out remaining records in a reverted order
    for(int i = records.size()-1; i >= 2; i--){
        for(int j = 0; j < 128; j++){
            cpm.append(records[i][j]);
        }
    }

    bdosbase = inbuf.mid(0xac, 4).toUInt(nullptr, 16);
    biosbase = inbuf.mid(0x91, 4).toUInt(nullptr, 16);
}

Loader::~Loader(){
    qDebug("~Loader()");
}
