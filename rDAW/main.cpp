#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "MidiEngine.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Register the Sequencer class for QML
    qmlRegisterType<Sequencer>("Sequencer", 1, 0, "Sequencer");

    // Create an instance of MidiEngine
    MidiEngine midiEngine;

    // Expose MidiEngine to QML
    engine.rootContext()->setContextProperty("midiEngine", &midiEngine);

    // Load the main QML file
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
