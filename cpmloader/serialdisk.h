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

#include <QFileSystemWatcher>
#include <QFile>
#include <QDir>
#include <QList>
#include <QSerialPort>
#include <QtMath>
#include <QtDebug>
#include <QDateTime>

#define NAME "Serial Disk Drive"
#define PATH_A "/driveA"

//File system parameters
const int sectlen = 256;
const int sctpertrk = 64;
const int blksize = 16384;
const int dirsize = 16384;
const int disksize = blksize * 0x800;

class Serialdisk : public QObject
{
    Q_OBJECT
public:
    explicit Serialdisk(QSerialPort*, QString*, QObject *parent = nullptr);
    void reload();

private slots:
    void on_command(const QByteArray);


private:
    QString mCpmPath, *p_cpmPath;
    QByteArray mDir;
    QSerialPort *p_serial;
    void writeFile(const QByteArray&, uint16_t, uint8_t);
    QByteArray readFile(uint16_t, uint8_t);
    QString ext2fname(QByteArray);
    void make_extend(QByteArray);
    void readUserDir(QString, uint8_t);
    void onRxDataComplete(QByteArray);
    void write2disk(QByteArray);
    QDateTime mLastSync;
    bool file_changed = false;

signals:
    void on_activeA(int);
    void message(const QString);
};

#endif // SERIALDISK_H
