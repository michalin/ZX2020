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
#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QFileDialog>
#include <QMessageBox>
#include <QSerialPortInfo>
#include <QTimer>
#include "loader.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    (new QDir())->mkpath(homepath);
    sysFileName = p_settings->value(FNAME_KEY).toString();
    if(sysFileName == ""){
        sysFileName = homepath + NEWFILENAME;
    } /*else {
        ui->pButtonLoad->setEnabled(true);
    }*/
    setBinFile(sysFileName);
    setWindowTitle(sysFileName.section("/", -1) + " - " + PROGNAME);

    QTimer *timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(on_timer()));
    timer->start(1000);

    connect(p_loader, SIGNAL(finished()), this, SLOT(on_loaderFinished()));

    p_serial->setBaudRate(QSerialPort::Baud115200);
    connect(p_serial, SIGNAL(errorOccurred(QSerialPort::SerialPortError)), this, SLOT(on_serialError(QSerialPort::SerialPortError)));
    connect(p_serdisk, SIGNAL(on_activeA(int)), ui->progressBarA, SLOT(setValue(int)));
    connect(p_serdisk, SIGNAL(on_activeB(int)), ui->progressBarB, SLOT(setValue(int)));
}

void MainWindow::on_timer(){
    //Check for changes in serial port configuration
    //qDebug("-->on_timer()");
    static qint16 numPorts;
    if(QSerialPortInfo::availablePorts().size() != numPorts){ //Number of serial ports has changed
        ui->portSelector->clear();
        numPorts = QSerialPortInfo::availablePorts().size();
        QList<QSerialPortInfo> ports = QSerialPortInfo::availablePorts();
        for(QList<QSerialPortInfo>::iterator i = ports.begin(); i < ports.end(); i++)
            ui->portSelector->addItem(i->portName() + ": " + i->description());

        if(p_serial->isOpen())
            on_serialError(QSerialPort::ResourceError);

        ui->pButtonLoad->setEnabled(true);
    }
}

void MainWindow::on_loaderFinished(){
    ui->statusbar->showMessage("CP/M loaded");
    p_serdisk->mount(p_serial, cpmPath);
    ui->progressBarA->setValue(3);
    ui->progressBarB->setValue(3);
}

void MainWindow::on_pButtonLoad_clicked()
{
    p_serdisk->unmount();
    QString portname = ui->portSelector->itemText(ui->portSelector->currentIndex());
    QString port = portname.left(portname.indexOf(":"));
    if(sysFileName == homepath + NEWFILENAME){ //Not yet loaded
        on_actionLoad_triggered();
        setBinFile(sysFileName);
        setWindowTitle(sysFileName.section("/", -1) + " - " + PROGNAME);
    }

    if(p_serial->isOpen()){
        p_serial->close();
    }
    p_serial->setPortName(port);
    if(p_serial->open(QIODevice::ReadWrite))
        p_loader->open(sysFileName);
    ui->statusbar->showMessage(tr("%1 %2").arg(p_serial->portName()).arg(p_serial->isOpen() ? "open" : "not open"));
}

void MainWindow::on_actionLoad_triggered() //CP/M File selected
{
    sysFileName = QFileDialog::getOpenFileName(this,
                                               tr("Open CPM File"), sysFileName, tr("CPM System Files (*.sys)"));
    setBinFile(sysFileName);
    p_settings->setValue(FNAME_KEY, sysFileName);
    ui->pButtonLoad->setEnabled(true);
    //connectSerial(false);
}

void MainWindow::setBinFile(const QString inFile){
    setWindowTitle(inFile.section("/", -1) + " - " + PROGNAME);
    cpmPath = inFile.section("/", 0, -2);
    p_fileSystemWatcher->addPath(inFile);
    connect(p_fileSystemWatcher, SIGNAL(fileChanged(const QString&)), this, SLOT(on_sysfileChanged(const QString&)));
}

void MainWindow::on_sysfileChanged(const QString& sys){
    qDebug("-->MainWindow::on_sysfileChanged(%s", sys.toLocal8Bit().data());
    on_pButtonLoad_clicked();
}

void MainWindow::on_serialError(QSerialPort::SerialPortError status){
    QString statusString;
    switch(status){
    case QSerialPort::SerialPortError::NoError:
        return; //do nothing
    case QSerialPort::SerialPortError::WriteError:
        statusString = "WriteError";
        break;
    case QSerialPort::SerialPortError::OpenError:
        statusString = "Cannot open port";
        break;
    case QSerialPort::SerialPortError::PermissionError:
        statusString = "Port already used by another application";
        break;
    case QSerialPort::SerialPortError::ResourceError:
            statusString = "Port connection lost";
        break;
    default:
        statusString = tr("Unknown error: %1").arg(status);
    }
    //qDebug("Serial Port Error: %s", errorString.toLocal8Bit().data());
    QMessageBox::warning(this, "Communication Error", statusString);
    if(p_serial->isOpen()){
        p_serial->close();
        p_serial->disconnect();
        ui->progressBarA->setValue(0);
        ui->progressBarB->setValue(0);
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_actionSet_Kernel_File_triggered()
{
    on_actionLoad_triggered();
    setBinFile(sysFileName);
    setWindowTitle(sysFileName.section("/", -1) + " - " + PROGNAME);
}

void MainWindow::on_actionAbout_triggered()
{
    QFile lic(":/license.txt");
    lic.open(QIODevice::ReadOnly);
    QMessageBox::about(this, "About", lic.readAll());
    lic.close();
}

void MainWindow::on_pButtonReload_clicked()
{
    p_serdisk->UpdateDirs();
}
