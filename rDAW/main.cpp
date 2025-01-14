#include <QGuiApplication>
#include <QTimer>
#include "MidiEngine.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    // Initialize the MIDI Engine
    MidiEngine midiEngine;

    // Start MIDI input
    midiEngine.startMidiInput();

    // Add a track to the sequencer for recording
    auto& sequencer = midiEngine.getSequencer();
    sequencer.addTrack("Recorded Track");

    // Start playback
    sequencer.start();

    // Start recording
    midiEngine.startRecording();

    // Automatically stop recording after 10 seconds for testing
    QTimer::singleShot(10000, [&]() {
        midiEngine.stopRecording();

        // Print recorded events for debugging
        auto& recordedTrack = sequencer.getTrack(0);
        qDebug() << "Recorded Events:";
        for (const auto& event : recordedTrack.events) {
            qDebug() << "Tick:" << event.tick
                << "Type:" << static_cast<int>(event.type)
                << "Channel:" << event.channel
                << "Pitch:" << event.pitch
                << "Velocity:" << event.velocity;
        }

        // Optionally stop playback after testing
        sequencer.stop();
        });

    return app.exec();
}
