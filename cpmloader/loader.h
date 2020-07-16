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

#ifndef LOADER_H
#define LOADER_H

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QList>

class Loader : public QObject
{
    Q_OBJECT
public:
    explicit Loader(QSerialPort *, QObject *parent = nullptr);
    void open(const QString);
    ~Loader();

private:
    QString sysFileName = "";
    QSerialPort *p_serial = new QSerialPort();
    void loadCPM();
    void gencpm(const QString, QByteArray &, uint16_t &, uint16_t &);
    void upload(QByteArray, const uint16_t, const uint16_t);

signals:
    void portsChanged(const QStringList);
    void finished();

private slots:
    void on_RxData();
};

#endif // LOADER_H
