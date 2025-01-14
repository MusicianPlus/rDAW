#ifndef MIDIENGINE_H
#define MIDIENGINE_H

#include <QObject>
#include "libs/rtmidi/RtMidi.h"
#include <QString>
#include <QDebug>

class MidiEngine : public QObject {
    Q_OBJECT
public:
    explicit MidiEngine(QObject* parent = nullptr);
    ~MidiEngine();

    Q_INVOKABLE void listMidiDevices();
    Q_INVOKABLE void sendMidiNoteOn(int channel, int note, int velocity);
    Q_INVOKABLE void sendMidiNoteOff(int channel, int note);
    Q_INVOKABLE QStringList getAvailableMidiDevices();
    Q_INVOKABLE void openMidiDevice(int index);
    Q_INVOKABLE void startMidiInput();

private:
    RtMidiIn* midiIn;
    RtMidiOut* midiOut;

signals:
    void midiMessageReceived(QString message);

};

#endif // MIDIENGINE_H
