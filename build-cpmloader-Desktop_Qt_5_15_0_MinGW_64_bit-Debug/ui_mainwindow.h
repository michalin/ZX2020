/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.15.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtGui/QIcon>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenu>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QProgressBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QAction *actionAbout;
    QAction *actionSet_Kernel_File;
    QAction *actionExit;
    QWidget *centralwidget;
    QWidget *verticalLayoutWidget;
    QVBoxLayout *verticalLayout;
    QHBoxLayout *horizontalLayout;
    QSpacerItem *horizontalSpacer_2;
    QLabel *label_3;
    QComboBox *portSelector;
    QPushButton *pButtonLoad;
    QHBoxLayout *horizontalLayout_2;
    QSpacerItem *horizontalSpacer;
    QLabel *label;
    QProgressBar *progressBarA;
    QSpacerItem *horizontalSpacer_4;
    QLabel *label_2;
    QProgressBar *progressBarB;
    QSpacerItem *horizontalSpacer_3;
    QPushButton *pButtonReload;
    QMenuBar *menubar;
    QMenu *menuFile;
    QMenu *menuHelp;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->resize(305, 190);
        QSizePolicy sizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(MainWindow->sizePolicy().hasHeightForWidth());
        MainWindow->setSizePolicy(sizePolicy);
        MainWindow->setMinimumSize(QSize(305, 190));
        MainWindow->setMaximumSize(QSize(305, 190));
        actionAbout = new QAction(MainWindow);
        actionAbout->setObjectName(QString::fromUtf8("actionAbout"));
        actionSet_Kernel_File = new QAction(MainWindow);
        actionSet_Kernel_File->setObjectName(QString::fromUtf8("actionSet_Kernel_File"));
        actionExit = new QAction(MainWindow);
        actionExit->setObjectName(QString::fromUtf8("actionExit"));
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName(QString::fromUtf8("centralwidget"));
        sizePolicy.setHeightForWidth(centralwidget->sizePolicy().hasHeightForWidth());
        centralwidget->setSizePolicy(sizePolicy);
        verticalLayoutWidget = new QWidget(centralwidget);
        verticalLayoutWidget->setObjectName(QString::fromUtf8("verticalLayoutWidget"));
        verticalLayoutWidget->setGeometry(QRect(10, 0, 286, 131));
        verticalLayout = new QVBoxLayout(verticalLayoutWidget);
        verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
        verticalLayout->setContentsMargins(0, 0, 0, 0);
        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setObjectName(QString::fromUtf8("horizontalLayout"));
        horizontalSpacer_2 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout->addItem(horizontalSpacer_2);

        label_3 = new QLabel(verticalLayoutWidget);
        label_3->setObjectName(QString::fromUtf8("label_3"));

        horizontalLayout->addWidget(label_3);

        portSelector = new QComboBox(verticalLayoutWidget);
        portSelector->setObjectName(QString::fromUtf8("portSelector"));
        portSelector->setMinimumSize(QSize(150, 0));

        horizontalLayout->addWidget(portSelector);

        pButtonLoad = new QPushButton(verticalLayoutWidget);
        pButtonLoad->setObjectName(QString::fromUtf8("pButtonLoad"));
        pButtonLoad->setEnabled(false);

        horizontalLayout->addWidget(pButtonLoad);


        verticalLayout->addLayout(horizontalLayout);

        horizontalLayout_2 = new QHBoxLayout();
        horizontalLayout_2->setObjectName(QString::fromUtf8("horizontalLayout_2"));
        horizontalSpacer = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_2->addItem(horizontalSpacer);

        label = new QLabel(verticalLayoutWidget);
        label->setObjectName(QString::fromUtf8("label"));

        horizontalLayout_2->addWidget(label);

        progressBarA = new QProgressBar(verticalLayoutWidget);
        progressBarA->setObjectName(QString::fromUtf8("progressBarA"));
        sizePolicy.setHeightForWidth(progressBarA->sizePolicy().hasHeightForWidth());
        progressBarA->setSizePolicy(sizePolicy);
        progressBarA->setMaximumSize(QSize(50, 16777215));
        progressBarA->setMaximum(3);
        progressBarA->setValue(0);
        progressBarA->setTextVisible(false);

        horizontalLayout_2->addWidget(progressBarA);

        horizontalSpacer_4 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_2->addItem(horizontalSpacer_4);

        label_2 = new QLabel(verticalLayoutWidget);
        label_2->setObjectName(QString::fromUtf8("label_2"));

        horizontalLayout_2->addWidget(label_2);

        progressBarB = new QProgressBar(verticalLayoutWidget);
        progressBarB->setObjectName(QString::fromUtf8("progressBarB"));
        sizePolicy.setHeightForWidth(progressBarB->sizePolicy().hasHeightForWidth());
        progressBarB->setSizePolicy(sizePolicy);
        progressBarB->setMaximumSize(QSize(50, 16777215));
        progressBarB->setMaximum(3);
        progressBarB->setValue(0);
        progressBarB->setTextVisible(false);

        horizontalLayout_2->addWidget(progressBarB);

        horizontalSpacer_3 = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout_2->addItem(horizontalSpacer_3);

        pButtonReload = new QPushButton(verticalLayoutWidget);
        pButtonReload->setObjectName(QString::fromUtf8("pButtonReload"));
        QIcon icon;
        icon.addFile(QString::fromUtf8(":/resources/refresh.PNG"), QSize(), QIcon::Normal, QIcon::Off);
        pButtonReload->setIcon(icon);

        horizontalLayout_2->addWidget(pButtonReload);


        verticalLayout->addLayout(horizontalLayout_2);

        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName(QString::fromUtf8("menubar"));
        menubar->setGeometry(QRect(0, 0, 305, 21));
        menuFile = new QMenu(menubar);
        menuFile->setObjectName(QString::fromUtf8("menuFile"));
        menuHelp = new QMenu(menubar);
        menuHelp->setObjectName(QString::fromUtf8("menuHelp"));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName(QString::fromUtf8("statusbar"));
        MainWindow->setStatusBar(statusbar);

        menubar->addAction(menuFile->menuAction());
        menubar->addAction(menuHelp->menuAction());
        menuFile->addSeparator();
        menuFile->addAction(actionSet_Kernel_File);
        menuFile->addAction(actionExit);
        menuHelp->addAction(actionAbout);

        retranslateUi(MainWindow);
        QObject::connect(actionExit, SIGNAL(triggered()), MainWindow, SLOT(close()));

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "MainWindow", nullptr));
        actionAbout->setText(QCoreApplication::translate("MainWindow", "About", nullptr));
        actionSet_Kernel_File->setText(QCoreApplication::translate("MainWindow", "Set Kernel File", nullptr));
        actionExit->setText(QCoreApplication::translate("MainWindow", "Exit", nullptr));
        label_3->setText(QCoreApplication::translate("MainWindow", "Port", nullptr));
        pButtonLoad->setText(QCoreApplication::translate("MainWindow", "Load CP/M", nullptr));
        label->setText(QCoreApplication::translate("MainWindow", "Disk A", nullptr));
        label_2->setText(QCoreApplication::translate("MainWindow", "Disk B", nullptr));
#if QT_CONFIG(tooltip)
        pButtonReload->setToolTip(QCoreApplication::translate("MainWindow", "Reload filesystem", nullptr));
#endif // QT_CONFIG(tooltip)
        pButtonReload->setText(QString());
        menuFile->setTitle(QCoreApplication::translate("MainWindow", "File", nullptr));
        menuHelp->setTitle(QCoreApplication::translate("MainWindow", "Help", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
