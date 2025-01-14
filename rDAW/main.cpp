#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "backend.h"
#include "MidiEngine.h"


int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    qmlRegisterType<Backend>("com.djdeck.backend", 1, 0, "Backend");
    qDebug() << "Backend registered!";
    qmlRegisterType<MidiEngine>("com.djdeck.midi", 1, 0, "MidiEngine");
    qDebug() << "MidiEngine registered!";
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
