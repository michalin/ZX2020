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
#include "serialdisk.h"
#include <QObject>
#include <QDir>
#include <QThread>
#include <QtDebug>
#include <QMessageBox>
//#include <QMainWindow>
#include <QRegularExpression>

Serialdisk::Serialdisk(QObject *parent) : QObject(parent)
{
    qDebug("Serialdisk::Serialdisk");
    this->parent = parent;
}

void Serialdisk::unmount(){
    //qDebug("-->unmount()");
    if(!is_mounted) return;
    disconnect(p_serial, SIGNAL(readyRead()), this, SLOT(onRxData()));
    is_mounted = false;
    emit on_unmount();
}

void Serialdisk::mount(QSerialPort *serial, const QString path)
{
    if(is_mounted) return;
    is_mounted = true;
    qDebug("-->Serialdisk::mount()");
    mPath = path;

    p_serial = serial;
    connect(p_serial, SIGNAL(readyRead()), this, SLOT(onRxData()));

    UpdateDirs();

    p_serial->write("@mount@");
}

void Serialdisk::UpdateDirs(){
    qDebug("-->Serialdisk::UpdateDirs()");
    for(uint8_t usr = 0; usr < 16; usr++)
        readUserDir(dirA, mPath+PATH_A, usr);
    for(uint8_t usr = 0; usr < 16; usr++)
        readUserDir(dirB, mPath+PATH_B, usr);
}

void Serialdisk::readUserDir(QByteArray &directory, QString path, uint8_t usernr) {
    //qDebug("-->Serialdisk::dirChanged");
    static uint8_t rec_idx = 0; //Index of record
    static uint8_t blocknr = 1; //Block 0 is allocated by directory entries
    path += tr("/%1").arg(usernr);
    if(usernr == 0){
        directory.fill(0xe5, blksize);
        rec_idx = 0;
        blocknr = 1;
    }
    QDir dir(path, "*");
    QFileInfoList files = dir.entryInfoList();
    //QByteArray sfcb(32, 0);
    //sfcb[0] = 0x21;
    for(int i = 0; i < files.size(); i++)
    {
        //Check file
        const char* filename = files[i].fileName().toLocal8Bit().data();
        if(!files[i].isFile()){
        }
        else if(files[i].baseName().size() > 8){
            qWarning("Warning: %s name too long, will skip this.", filename);
        }
        else if(files[i].suffix().size() > 3){
            qWarning("Warning: %s extension too long, will skip this.", filename);
        }
        else if(files[i].size() > 16*blksize){
            qWarning("Warning: Size of %s is too big, will skip this.", filename);
        }
        else {
            QByteArray chunk(chunksize, 0);
            chunk[0] = usernr; //User number
            QByteArray bname = files[i].baseName().toUpper().toLocal8Bit();
            size_t bname_len = bname.size();
            bname.append(8-bname_len, ' ');
            chunk.replace(1, 8, bname); //Name

            QByteArray ext = files[i].suffix().toUpper().toLocal8Bit();
            size_t ext_len = ext.size();

            ext.append(3-ext_len, ' ');
            chunk.replace(9, 3, ext); //Extension

            size_t size = files[i].size();
            uint8_t size_b = 1 + size / blksize; //Size in blocks
            chunk[15] = size_b * blksize / 1 + size/128; //Number of records for file (rc)
            for(uint8_t j = 0; j < size_b; j++) //Allocation list
            {
                //chunk[j*2+16] = blocknr++;
                chunk[j+16] = blocknr++;
            }
//#define usesfcb
#ifdef usesfcb
            if(rec_idx && (rec_idx+1) % 4 == 0)
            {
                directory.replace(rec_idx++ * 32, 32, sfcb);
            }
#endif
            directory.replace(rec_idx++ * 32, 32, chunk); //Insert record entry
            chunk.clear();

            QFile file(files[i].absoluteFilePath());
            file.open(QIODevice::ReadOnly);
            directory.append(file.readAll());
            file.close();
            directory.append(size_b * blksize - size, 0);
        }
    }
}
void Serialdisk::onRxData()
{
    static uint8_t track=0, sector=0, chunk = 0;
    const QByteArray data = p_serial->readAll(); //Request header

    if(data.contains("@trk:") && data.contains("@sct:") && data.contains("@cnk:")){
        track = data[data.lastIndexOf("@trk:") + 5];
        sector = data[data.lastIndexOf("@sct:") + 5];
        chunk = data[data.lastIndexOf("@cnk:") + 5];
        (chunk & 0xf0) >> 4 == 0? emit on_activeA(chunk & 0x03) : emit on_activeB(chunk & 0x03);
        //qDebug("Request Chunk(trk=%u, sect=%u, chunk = %u)", track, sector, chunk);
        if(chunk & 0x08) //Bit 3
            p_serial->write("@ack@", 5); //Request write data from Arduino
        else {
            readChunk(track, sector, chunk);
        }
    }
    else if(data.contains("@umnt@")){
        unmount();
    } else if(data.length() == 32){ //Data we want to write
        writeChunk(data, track, sector, chunk);

    } else {
        if(data.contains("@trk:") || data.contains("@sct:") || data.contains("@cnk:"))
            p_serial->write("@error@, 7"); //Receive invalid request

        qDebug("Serialdisk: ");
        for (uint8_t i = 0; i < data.size(); i++){
            if(data[i] >=32){
                printf("%c", data[i]);
            } else
                printf("%u", (uint8_t)data[i]);
        }
        printf("\n");
        fflush(stdout);
        //qDebug(data.toStdString().c_str());
    }
}

void Serialdisk::readChunk(uint8_t trknr, uint8_t sctnr, uint8_t chunk){
    QByteArray &curDir = ((chunk & 0xf0) >> 4 == 0)? dirA : dirB;
    chunk &= 0x03;
    //qDebug("-->Serialdisk::readSector(trk=%u, sect=%u, chunk = %u)", trknr, sctnr, chunk);
    int pos = 128*sctpertrk*trknr + 128*sctnr + chunk*chunksize;
    if(pos > curDir.size())
    {
        curDir.resize(pos+128);
    }
    QByteArray sect2read = curDir.mid(pos, chunksize);
    p_serial->write(sect2read);
    //qDebug("Chunk sent: %u", size);
}

void Serialdisk::writeChunk(const QByteArray &chunk2Write, uint8_t trknr, uint8_t sctnr, uint8_t chunk){
    QByteArray &curDir = ((chunk & 0xf0) >> 4 == 0)? dirA : dirB;
    QString path = mPath + (((chunk & 0xf0) >> 4 == 0)? PATH_A : PATH_B);
    static uint pos0;
    static QFile writeFile(this);

    chunk &= 0x03; //Mask out r/w Bit and drive
    //qDebug("-->Serialdisk::writeChunk(trk=%u, sect=%u, chunk = %u)", trknr, sctnr, chunk);
    int pos = 128*(sctpertrk*trknr + sctnr) + chunk*chunksize;
    if(pos > curDir.size())
    {
        curDir.resize(pos+128);
    }

    uint16_t blocknr = pos / blksize;
    if(blocknr == 0)
    {
        QString fName = chunk2Write.mid(1, 8).trimmed();
        QString fExt = chunk2Write.mid(9, 3).trimmed();
        if(!fExt.isEmpty()){
            fName.append('.');
            fName.append(fExt);
        }

        if((uint8_t)curDir[pos] == 0xE5 && (uint8_t)chunk2Write[0] != 0xE5){
            path += tr("/%1/").arg((uint8_t)chunk2Write[0]);
            qDebug("Make new file: %s", fName.toLocal8Bit().data());
            writeFile.setFileName(path+fName);
            writeFile.open(QIODevice::WriteOnly);
            writeFile.close();
            pos0 = 0;
        }
        else if((uint8_t)chunk2Write[0] == 0xE5 && (uint8_t)curDir[pos] != 0xE5){
            path += tr("/%1/").arg((uint8_t)curDir[pos]);
            qDebug("Erase file: %s", fName.toLocal8Bit().data());
            QFile f(path+fName);
            f.remove();
        } else {
            path += tr("/%1/").arg((uint8_t)chunk2Write[0]);
            QString fName2 = curDir.mid(pos+1, 8).trimmed();
            QString fExt2 = curDir.mid(pos+9, 3).trimmed();
            if(!fExt2.isEmpty()){
                fName2.append('.');
                fName2.append(fExt2);
            }
            if(fName != fName2){ //Old filename: fname2
                qDebug("Rename File %s->%s", fName2.toLocal8Bit().data(), fName.toLocal8Bit().data());
                QFile f(path+fName2);
                f.rename(path+fName);
            }
        }
    } else { //Locate the file we want to write
        QString fName;
        getWriteFileName(curDir, blocknr, fName, pos0);
        fName = path + fName;
        if(pos0 && fName != writeFile.fileName()){
            qDebug("File: %s", fName.toLocal8Bit().data());
            writeFile.setFileName(fName);
        }

        if(pos0 == 0){ //New file
            writeFile.open(QIODevice::Append);
            writeFile.write(chunk2Write);
            writeFile.close();
        } else {
            writeFile.open(QIODevice::ReadWrite);
            writeFile.seek(pos - pos0);
            writeFile.write(chunk2Write);
            writeFile.close();
        }
        qDebug("Write file: %s, pos: %u, pos0: %u", writeFile.fileName().toLocal8Bit().data(), pos, pos0);
    }
    curDir.replace(pos, chunksize, chunk2Write);
}

/* Returns filename and usernumber of the file that belongs to the chunk*/
void Serialdisk::getWriteFileName(const QByteArray &dir, const uint16_t blocknr, QString &filename, uint &pos0){
    uint8_t usr = 0xff;
    pos0 = 0; //If file not found or just created
    for(int i = 0; i < blksize; i += 32){ //search through directory entries; i points to beginning of entry
        for(int j = 16; j < 32; j ++){
            uint16_t blockptr = dir[(i + j)];
            if(blockptr == blocknr){ //Until file found to which the block blocknr belongs
                usr = dir[i];
                filename = tr("/%1/").arg((uint8_t)usr) + dir.mid(i+1, 8).trimmed();
                QString ext = dir.mid(i+9, 3).trimmed();
                if(!ext.isEmpty()){
                    filename.append('.');
                    filename.append(ext);
                }
                pos0 = dir[i+16] * blksize;
                break;
            }
        }
    }
}

