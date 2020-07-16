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

#ifndef SERIALDISK_H
#define SERIALDISK_H

#include <QObject>
#include <QSerialPort>
#include <QFile>

#define NAME "Serial Disk Drive"
#define PATH_A "/driveA"
#define PATH_B "/driveB"

class Serialdisk : public QObject
{
    Q_OBJECT
public:
    explicit Serialdisk(QObject *parent = nullptr);
    void mount(QSerialPort *, const QString);
    void unmount();
    void UpdateDirs();


private slots:
    void onRxData();

private:
    QString mPath;
    QSerialPort *p_serial;
    void readChunk(uint8_t, uint8_t, uint8_t=0);
    void writeChunk(const QByteArray&, uint8_t, uint8_t, uint8_t=0);
    void make_dir_record(QByteArray);
    void readUserDir(QByteArray&, QString, uint8_t);
    void getWriteFileName(const QByteArray &, const uint16_t, QString &, uint &);
    QByteArray dirA, dirB;
    bool is_mounted = false;
    const uint8_t reqlen = 18; //Length of request header
    const uint8_t chunksize = 32;
    const uint8_t sctpertrk = 64; //Sectors per track
    const uint16_t blksize = 8192;
    bool acknowledged = false;  //ack for received chunk
    QObject *parent;

signals:
    void on_unmount();
    void on_activeA(int);
    void on_activeB(int);
};

#endif // SERIALDISK_H
