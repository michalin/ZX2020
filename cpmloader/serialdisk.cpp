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

Serialdisk::Serialdisk(QSerialPort *serial, QString *p_cpmpath, QObject *parent) : QObject(parent)
{
    p_serial  = serial;
    this->p_cpmPath = p_cpmpath;
}

void Serialdisk::reload(){
    emit message("Serial disk files loaded");
    mCpmPath = *p_cpmPath;
    mDir.fill(0xe5, disksize);

    for(uint8_t usr = 0; usr < 16; usr++){
        readUserDir(mCpmPath+PATH_A, usr);
    }
}

void Serialdisk::on_command(const QByteArray cmd)
{
    //emit message(cmd);
    uint8_t sector = 0;
    uint16_t block = 0;
    if(cmd.startsWith("R:") || cmd.startsWith("W:")){
        block = (uint8_t)cmd[2] + 256*(uint8_t)cmd[3];
        sector = cmd[4];

        if (cmd.startsWith("R:")) //Send sector data over serial connection
        {
            //emit message(QString("Read: Track=%1, Sector=%2)").arg(track).arg(sector));
            p_serial->write(readFile(block, sector), sectlen);
        }
        else if (cmd.startsWith("W:"))
        {
            //emit message(QString("Write: Track=%1, Sector=%2)").arg(block).arg(sector));
            writeFile(cmd.right(sectlen), block, sector);
            p_serial->write("@ack@");//Send back chunk as confirmation
        }
    }
    //qDebug() << "Serial disk: Invalid command: " + cmd;
}

/* Read sector sect from track trk */
QByteArray Serialdisk::readFile(uint16_t block, uint8_t sect)
{
    QByteArray r = mDir.mid(blksize*block + sectlen*sect, sectlen);
    return r;
}

/* Write Sector sect on track trk.
   Also handling the cossesponding file on disk */
void Serialdisk::writeFile(const QByteArray &newsect, uint16_t block, uint8_t sect)
{
    QByteArray oldsect = mDir.mid(blksize*block+sectlen*sect, sectlen);
    //If nothing has changed, leave it
    if(oldsect == newsect)
        return;

    //static QByteArray newextent;
    if(block == 0) //New file created, renamed or deleted
    {
        //Compare the sector to write with the sector already on disk to find the extent that hes changed
        QByteArray oldextent,newextent;
        for(int i=0; i<sectlen; i+=32)
        {
            newextent = newsect.mid(i, 32);
            oldextent = oldsect.mid(i,32);
            if(oldextent != newextent)
                break;
        }

        //Handling (Delete, create or rename) of files on PC
        QString newfname = ext2fname(newextent);
        QString oldfname = ext2fname(oldextent);

        if((uint8_t)newextent[0] == 0xe5 && (uint8_t)oldextent[0] != 0xe5)
        {
            emit message(tr("deleted: ")+newextent.mid(1,11));
            QFile f(oldfname);
            f.moveToTrash();
        }
        else if ((uint8_t)oldextent[0] == 0xe5 && (uint8_t)newextent[0] != 0xe5)
        {
            emit message(tr("New file created: ")+newextent.mid(1,11));
            QFile f(newfname);
            f.open(QIODevice::ReadWrite);
            f.close();
        }
        else if (newextent.mid(1,11) != oldextent.mid(1,11))
        {
            emit message(tr("File renamed: ")+oldextent.mid(1,11)+"-->"+newextent.mid(1,11));
            QFile f(oldfname);
            f.rename(newfname);
            newextent.fill(0, 32);
        }
        else
        {
            int oldsize=blksize*oldextent[12]+128*oldextent[15];
            int newsize=blksize*newextent[12]+128*newextent[15];
            emit message(tr("File size changed: %1 -> %2").arg(oldsize).arg(newsize));
            write2disk(newextent);
        }
        mDir.replace(blksize*block + sectlen*sect, sectlen, newsect); //Update directory
    }
    else //File data
    {
        mDir.replace(blksize*block + sectlen*sect, sectlen, newsect); //Update file content
        emit message(tr("Write block: %1 sector: %2").arg(block).arg(sect));

        //Search directory for the extent that belongs to the block we want to write
        for(int i=0; i<dirsize; i+=32) //Go through extents
        {
            QByteArray extent = mDir.mid(i,32);
            for(uint8_t j=16; j<=30; j+=2) //Go through allocation list
            {
                int b = 256*(uint8_t)extent[j+1]+(uint8_t)extent[j];
                if(b==block && (uint8_t)extent[0]<16)
                {
                    qDebug() << "Found: " << extent;
                    write2disk(extent);
                    j=32;i=dirsize; //found, can break loop here
                }
            }
        }
    }
}

/*Write from serial disk to PC*/
void Serialdisk::write2disk(QByteArray extent)
{
    QString filename = ext2fname(extent);
    QFile wrfile(filename);
    QByteArray content;
    for(uint8_t i=16; i<=30; i+=2)
    {
        uint16_t block = 256*(uint8_t)extent[i+1] + (uint8_t)extent[i];
        if(block)
        {
            content.append(mDir.mid(blksize*block, blksize));
        }
    }
    if(wrfile.open(QIODevice::ReadWrite) == false)
    {
        emit message(tr("Error: Cannot open file:")+wrfile.fileName());
        return;
    }
    size_t fsize = (extent[12])*blksize + 128*(uint8_t)extent[15];
    content.truncate(fsize);
    wrfile.write(content);
    wrfile.close();
    emit message(tr("%1 bytes written").arg(content.size()));
}

/* returns filename, takes extent */
QString Serialdisk::ext2fname(QByteArray extent)
{
    uint8_t usernr = extent[0];
    QString path = QString("%1%2/%3").arg(mCpmPath, PATH_A).arg(usernr);
    if(extent[10] & 0x80) //System attribute
    {
        path = mCpmPath;
    }
    for(uint8_t i = 1; i <= 11; i++) //Clear attribute flags
        extent[i] = extent[i] & 0x7f;

    QByteArray base = extent.mid(1,8).trimmed();
    QByteArray ext = "." + extent.mid(9,3).trimmed();
    return QString("%1/%2%3").arg(path,base,ext);
}

/*
 * directory: Array with file extents for a particular user
 * path: Location of user files on PC
 * usernum: User 0-15
 */
void Serialdisk::readUserDir(QString path, uint8_t usernr) {
    static uint16_t rec_idx; //Index of extent
    static uint16_t blocknr; //Block 0 is allocated by directory entries
    path += QString("/%1").arg(usernr);
    QFileInfoList fileinfos;

    if(usernr == 0)
    { //System files
        blocknr = 1;
        rec_idx = 0;
        QFileInfo cpm3info(path+"/../..", "cpm3.sys");
        fileinfos.append(cpm3info); //Kernel file must be the first entry
        QFileInfo ldrinfo(path+"/../..", "bootldr.com");
        fileinfos.append(ldrinfo); //
        QFileInfo ccpinfo(path+"/../..", "ccp.com");
        fileinfos.append(ccpinfo); //
    }
    QDir dir(path);
    fileinfos.append(dir.entryInfoList(QDir::Files));

    if(fileinfos.size() > dirsize / 32)
    {
        emit message("Warning: maximum number of files exceeded");
    }

    for(int i = 0; i < fileinfos.size(); i++)
    {
        //Check file
        const char* filename = fileinfos[i].fileName().toLocal8Bit().data();
        if(fileinfos[i].baseName().size() > 8){
            emit message(QString("Warning: %1 name too long, will skip this.").arg(filename));
        }
        else if(fileinfos[i].suffix().size() > 3){
            emit message(QString("Warning: %1 extension too long, will skip this.").arg(filename));
        }
        else if(fileinfos[i].size() > 8*blksize){
            emit message(QString("Warning: Size of %1 is too big, will skip this.").arg(filename));
        }
        else {
            //Copy file content into memory buffer
            QFile file(fileinfos[i].absoluteFilePath());
            file.open(QIODevice::ReadOnly);
            QByteArray r = file.readAll();
            //qDebug() << "Filename: " << file.fileName() << "Size: " << file.size() << "Block: " << blocknr;
            mDir.replace(blksize*blocknr, blksize, r);

            //Fill the directory extents
            QByteArray extent(32, 0);
            extent[0] = usernr; //User number
            QByteArray bname = fileinfos[i].baseName().toUpper().toLocal8Bit();
            size_t bname_len = bname.size();
            bname.append(8-bname_len, ' ');
            extent.replace(1, 8, bname); //Insert filename

            QByteArray ext = fileinfos[i].suffix().toUpper().toLocal8Bit();
            size_t ext_len = ext.size();
            if(usernr == 0 && i < 3) //Set the first three entries as system files
            {
                //qDebug() << i << " "<<files[i].baseName();
                ext[1] = ext[1]+0x80; //System attribute
            }

            ext.append(3-ext_len, ' ');
            extent.replace(9, 3, ext); //Insert extension

            size_t size = fileinfos[i].size();
            uint8_t size_b = floor((float)size / blksize); //Size in full blocks
            extent[12] = size_b;
            extent[15] = (size-blksize*size_b) / 128; //Allocated space of last block in 128k records
            for(uint8_t j = 0; j <= 2*size_b; j+=2) //Fill allocation list
            {
                extent[j+16] = (uint8_t)blocknr;
                extent[j+17] = (uint8_t)(blocknr >> 8);
                blocknr++;
            }
            mDir.replace(rec_idx++ * 32, 32, extent); //Insert extent entry
        }
    }
}



