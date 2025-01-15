#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "MidiEngine.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    MidiEngine midiEngine;

    // Expose both MidiEngine and Sequencer to QML
    engine.rootContext()->setContextProperty("backend", &midiEngine);
    engine.rootContext()->setContextProperty("sequencer", midiEngine.getSequencer());

    // Start MIDI input immediately
    midiEngine.startMidiInput();

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
