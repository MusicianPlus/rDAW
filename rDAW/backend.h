#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QDebug>
#include <iostream>

class Backend : public QObject {
    Q_OBJECT
public:
    explicit Backend(QObject* parent = nullptr) : QObject(parent) {}

    // This function can be called from QML
    Q_INVOKABLE void printMessage() {
        qDebug() << "Hello from the Backend!";
    }
};

#endif // BACKEND_H
