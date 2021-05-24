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

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    (new QDir())->mkpath(homepath);
    imgFileName = p_settings->value(FNAME_KEY).toString();
    if(imgFileName == ""){
        imgFileName = homepath + NEWFILENAME;
    }

    ui->pButtonLoad->setText("Load CP/M");
    //ui->pButtonReload->setEnabled(false);

    setBinFile(imgFileName);
    setWindowTitle(imgFileName.section("/", -1) + " - " + PROGNAME);

    QTimer *timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(on_timer()));
    timer->start(1000);

    p_serial->setBaudRate(125000);//QSerialPort::Baud115200);
    connect(p_serial, SIGNAL(errorOccurred(QSerialPort::SerialPortError)), this, SLOT(on_serialError(QSerialPort::SerialPortError)));
    connect(p_serial, SIGNAL(readyRead()), this, SLOT(on_RxData()));
    connect(p_serial, SIGNAL(aboutToClose()), this, SLOT(on_SerialClose()));

    connect(p_loader, SIGNAL(message(QString)), this, SLOT(on_message(QString)));
    connect(this, SIGNAL(command(QByteArray)), p_loader, SLOT(on_command(QByteArray)));

    connect(p_serdisk, SIGNAL(on_activeA(int)), ui->progressBarA, SLOT(setValue(int)));
    connect(p_serdisk, SIGNAL(message(QString)), this, SLOT(on_message(QString)));
    connect(this, SIGNAL(command(QByteArray)), p_serdisk, SLOT(on_command(QByteArray)));
    //connect(p_serdisk, SIGNAL(unmount()), this, SLOT(on_loaded()));
    p_serdisk->reload();
}

/*
 * Handler function for received serial data
 * Decide here what to do
 */
void MainWindow::on_RxData()
{
    QByteArray rx = p_serial->readAll();

    rxData.append(rx); //Handle debug messages
    //qDebug() << rxData;

    if(rxData.contains("</DBG>")){  //Comments from Arduino
        int start = rxData.indexOf("<DBG>"); //Start index of payload data
        int end = rxData.indexOf("</DBG>"); //end index of payload data
        ui->debug->insertPlainText(rxData.mid(start+5, (end-start-5)));
        rxData.remove(start, end-start+6); //remove the <data>...</data> from data array
    }

    if(rxData.contains("</$>")){ //A message from the Arduino or Z80
        int start = rxData.indexOf("<$>"); //Start index of message
        int end = rxData.indexOf("</$>"); //end index of message
        QByteArray cmd = rxData.mid(start+3, (end-start-3));
        rxData.remove(start, end-start+4); //remove the <$>command</$> from data array
        if(cmd == "ready") { //Arduino setup() finished
            ui->debug->clear();
            switch(task)
            {
            case tasks::LOAD:
                p_loader->upload(imgFileName);
                break;
            case tasks::DUMP:
                uint16_t addr = (p_address->text()).toUInt(nullptr, 16);
                QByteArray cmd = "@dump";
                cmd.append(addr>>8);
                cmd.append(addr&0xFF);
                //cmd.append("@");
                p_serial->write(cmd);
                break;
            }
            task=tasks::IDLE;


        } else if(cmd == "started"){ //Kernel loaded
            ui->pButtonLoad->setEnabled(true);
            ui->progressBarA->setValue(3);
        } else if(cmd.startsWith("wrsec")) {
            ui->statusbar->showMessage(tr("Written: track: %1, sector: %2").arg((uint8_t)cmd[6]).arg((uint8_t)cmd[7]));
        } else if(cmd.startsWith("R:") | cmd.startsWith("W:")) {
            static uint8_t p;
            ui->progressBarA->setValue(p++ & 1);
        } else if(cmd == "error"){
            ui->statusbar->showMessage("Error");
            ui->pButtonLoad->setEnabled(true);
        }
        emit command(cmd); //Forward command to connected classes
    }
}

void MainWindow::on_timer(){
    static qint16 numPorts;
    //Poll for changes in serial port configuration. There seems to be no signal for this
    QList<QString>freePortNames;

    QList<QSerialPortInfo> ports = QSerialPortInfo::availablePorts();
    for(QList<QSerialPortInfo>::iterator i=ports.begin(); i<ports.end(); i++)
    {
        if(!i->isBusy())
            freePortNames.append(i->portName() + ": " + i->description());   //List with available ports
    }

    if(freePortNames.size()!=numPorts && !p_serial->isOpen())
    {
        ui->portSelector->clear();
        ui->portSelector->addItems(freePortNames);
    }

    numPorts = freePortNames.size();
}

//Debug and status messages
void MainWindow::on_message(const QString msg){
    ui->debug->ensureCursorVisible();
    ui->debug->append(msg);
}

void MainWindow::on_pButtonLoad_clicked()
{
    //ui->debug->clear();

    if(imgFileName == homepath + NEWFILENAME){ //Not yet loaded
        on_actionLoad_triggered();
        setBinFile(imgFileName);
        setWindowTitle(imgFileName.section("/", -1) + " - " + PROGNAME);
        return;
    }
    p_serdisk->reload();
    ui->checkConnect->setChecked(true); //Open serial
    task=tasks::LOAD;
    p_serial->setDataTerminalReady(true); //Reset Arduino --> Re-activate command listener
    p_serial->setDataTerminalReady(false);
}

void MainWindow::on_actionLoad_triggered() //CP/M File selected
{
    imgFileName = QFileDialog::getOpenFileName(this,
                                               tr("Open CPM File"), imgFileName, tr("CPM bootloader (bootldr.com)"));
    setBinFile(imgFileName);
    p_serdisk->reload();
    p_settings->setValue(FNAME_KEY, imgFileName);
    ui->pButtonLoad->setEnabled(true);
}

void MainWindow::setBinFile(const QString inFile){
    setWindowTitle(inFile.section("/", -1) + " - " + PROGNAME);
    *p_cpmPath = inFile.section("/", 0, -2);
    //p_fileSystemWatcher->addPath(inFile);
    //connect(p_fileSystemWatcher, SIGNAL(fileChanged(QString&)), this, SLOT(on_sysfileChanged(QString&)));
}

void MainWindow::on_sysfileChanged(const QString& sys){
    qDebug("-->MainWindow::on_sysfileChanged(%s", sys.toLocal8Bit().data());
    on_pButtonLoad_clicked();
}

void MainWindow::on_serialError(QSerialPort::SerialPortError status){
    if(status == QSerialPort::SerialPortError::NoError)
        return;
    ui->statusbar->showMessage(tr("%1 %2").arg(p_serial->portName(), "not connected"));
    ui->progressBarA->setValue(0);
    ui->pButtonLoad->setEnabled(true);
    ui->checkConnect->setChecked(false);
    if(p_serial->isOpen()){
        p_serial->close();
    }

    QString statusString;
    switch(status){
    case QSerialPort::SerialPortError::DeviceNotFoundError:
        statusString = "No COM Port found";
        break;
    case QSerialPort::SerialPortError::WriteError:
        statusString = "WriteError";
        break;
    case QSerialPort::SerialPortError::OpenError:
        statusString = "Cannot open port";
        break;
    case QSerialPort::SerialPortError::PermissionError:
        statusString = "Serial connection lost";
        break;
    case QSerialPort::SerialPortError::ResourceError:
        statusString = "Port connection lost";
        break;
    case QSerialPort::SerialPortError::NotOpenError:
        statusString = "Port not open";
        return;
    default:
        statusString = tr("Unknown error: %1").arg(status);
    }
    //qDebug("Serial Port Error: %s", errorString.toLocal8Bit().data());
    if(status != QSerialPort::SerialPortError::ResourceError)
        QMessageBox::warning(this, "Communication Error", statusString);
}

void MainWindow::on_actionSet_Kernel_File_triggered()
{
    on_actionLoad_triggered();
    setBinFile(imgFileName);
    setWindowTitle(imgFileName.section("/", -1) + " - " + PROGNAME);
}

void MainWindow::on_actionAbout_triggered()
{
    QFile lic(":/resources/license.txt");
    lic.open(QIODevice::ReadOnly);
    QMessageBox::about(this, "About", lic.readAll());
    lic.close();
}

void MainWindow::on_pButtonDump_clicked()
{
    //ui->debug->clear();
    task=tasks::DUMP;
    p_serial->setDataTerminalReady(true); //Reset Arduino --> Re-activate command listener
    p_serial->setDataTerminalReady(false);
}

void MainWindow::on_SerialClose()
{
    qDebug("Serial close");
}
MainWindow::~MainWindow()
{
    qDebug("MainWindow closed");
    //p_serial->close();
    delete ui;
}

void MainWindow::on_actionFormat_disk_triggered()
{
    ui->pButtonLoad->setEnabled(false);
    ui->checkConnect->setChecked(true); //Open serial
   // p_patadisk->init(cpmPath);
}

void MainWindow::on_checkConnect_stateChanged(int check)
{
    //qDebug("Check: %d", check);
    QString portname = ui->portSelector->itemText(ui->portSelector->currentIndex());
    QString port = portname.left(portname.indexOf(":"));
    p_serial->setPortName(port);
    if((check == 2) && (p_serial->open(QIODevice::ReadWrite))) //Open serial port
    {
        ui->debug->clear();
        ui->statusbar->showMessage(tr("%1 %2").arg(p_serial->portName(), "connected"));
        QThread::sleep(1);
    } else
    {
        p_serial->close();
        ui->statusbar->showMessage(tr("%1 %2").arg(p_serial->portName(), "not connected"));
        ui->pButtonLoad->setEnabled(true);
    }
}


void MainWindow::on_pushButtonReload_clicked()
{
    p_serdisk->reload();
}

