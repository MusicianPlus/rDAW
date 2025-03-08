#ifndef MIDIENGINE_H
#define MIDIENGINE_H

#include <QVariantList>
#include <QObject>
#include "libs/rtmidi/RtMidi.h"
#include <QString>
#include <QDebug>
#include "Sequencer.h"

// Forward declaration of the callback function
void midiCallback(double deltaTime, std::vector<unsigned char>* message, void* userData);

class MidiEngine : public QObject {
    Q_OBJECT

public:
    explicit MidiEngine(QObject* parent = nullptr);
    ~MidiEngine();

    // Expose the sequencer to QML
    Q_INVOKABLE Sequencer* getSequencer();

    // Public methods
    Q_INVOKABLE void listMidiDevices();
    Q_INVOKABLE void sendMidiNoteOn(int channel, int note, int velocity);
    Q_INVOKABLE void sendMidiNoteOff(int channel, int note);
    Q_INVOKABLE QStringList getAvailableMidiDevices();
    Q_INVOKABLE void openMidiDevice(int index);
    Q_INVOKABLE void startMidiInput();
    Q_INVOKABLE void listInputDevices();
    Q_INVOKABLE void listOutputDevices();
    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void startPlayback();
    Q_INVOKABLE void stopPlayback();
    Q_INVOKABLE void rewindPlayback();
    Q_INVOKABLE QStringList getAvailableMidiOutputDevices();
    Q_INVOKABLE void openMidiOutputDevice(int index);

    // Function to load a sound file and generate waveform data.
    // Now returns a JSON string.
    Q_INVOKABLE QString loadSoundFile(const QString& filePath = QString());

private:
    Sequencer sequencer;
    RtMidiIn* midiIn;
    RtMidiOut* midiOut;
    bool isRecording = false;

    friend void midiCallback(double deltaTime, std::vector<unsigned char>* message, void* userData);

signals:
    void midiMessageReceived(QString message);
};

#endif // MIDIENGINE_H
