#include "MidiEngine.h"
#include "libs/rtmidi/RtMidi.h"

// Callback function to handle incoming MIDI messages
void midiCallback(double deltaTime, std::vector<unsigned char>* message, void* userData) {
    Q_UNUSED(deltaTime);
    MidiEngine* engine = static_cast<MidiEngine*>(userData);

    if (message->size() > 0) {
        QString msg = "MIDI Message: ";
        for (size_t i = 0; i < message->size(); ++i) {
            msg += QString::number((*message)[i], 16).rightJustified(2, '0') + " ";
        }
        qDebug() << msg;
        emit engine->midiMessageReceived(msg);
    }
}

void MidiEngine::startMidiInput() {
    if (!midiIn) {
        qDebug() << "No MIDI input available.";
        return;
    }

    // Only start if the port is not already open
    if (!midiIn->isPortOpen()) {
        midiIn->openPort(0);
        qDebug() << "MIDI input started on device:" << QString::fromStdString(midiIn->getPortName(0));
    }
    else {
        qDebug() << "MIDI input is already active.";
    }
}


MidiEngine::MidiEngine(QObject* parent)
    : QObject(parent), midiIn(nullptr), midiOut(nullptr) {
    try {
        midiOut = new RtMidiOut();
        midiIn = new RtMidiIn();

        // Open MIDI output
        unsigned int outPorts = midiOut->getPortCount();
        if (outPorts > 0) {
            midiOut->openPort(0);
            qDebug() << "Opened MIDI output device:" << QString::fromStdString(midiOut->getPortName(0));
        }
        else {
            qDebug() << "No MIDI output devices available.";
        }

        // Open MIDI input
        unsigned int inPorts = midiIn->getPortCount();
        if (inPorts > 0) {
            midiIn->openPort(0);
            midiIn->setCallback(&midiCallback, this); // Set the callback here
            midiIn->ignoreTypes(false, true, true);
            qDebug() << "Opened MIDI input device:" << QString::fromStdString(midiIn->getPortName(0));
        }
        else {
            qDebug() << "No MIDI input devices available.";
        }
    }
    catch (RtMidiError& error) {
        qDebug() << "Error initializing MIDI:" << QString::fromStdString(error.getMessage());
    }
}

MidiEngine::~MidiEngine() {
    if (midiIn) delete midiIn;
    if (midiOut) delete midiOut;
}

void MidiEngine::listMidiDevices() {
    if (!midiOut) {
        qDebug() << "No MIDI output available.";
        return;
    }

    unsigned int nPorts = midiOut->getPortCount();
    qDebug() << "Available MIDI output devices:";
    for (unsigned int i = 0; i < nPorts; ++i) {
        qDebug() << i << ":" << QString::fromStdString(midiOut->getPortName(i));
    }
}

void MidiEngine::sendMidiNoteOn(int channel, int note, int velocity) {
    if (!midiOut || !midiOut->isPortOpen()) {
        qDebug() << "No MIDI device is open.";
        return;
    }

    std::vector<unsigned char> message;
    message.push_back(0x90 + (channel - 1)); // Note On message
    message.push_back(note);
    message.push_back(velocity);

    midiOut->sendMessage(&message);
    qDebug() << "Sent Note On:" << channel << note << velocity;
}

void MidiEngine::sendMidiNoteOff(int channel, int note) {
    if (!midiOut || !midiOut->isPortOpen()) {
        qDebug() << "No MIDI device is open.";
        return;
    }

    std::vector<unsigned char> message;
    message.push_back(0x80 + (channel - 1)); // Note Off message
    message.push_back(note);
    message.push_back(0); // Velocity is 0 for Note Off

    midiOut->sendMessage(&message);
    qDebug() << "Sent Note Off:" << channel << note;
}

QStringList MidiEngine::getAvailableMidiDevices() {
    QStringList deviceList;
    if (!midiOut) return deviceList;

    unsigned int nPorts = midiOut->getPortCount();
    for (unsigned int i = 0; i < nPorts; ++i) {
        deviceList.append(QString::fromStdString(midiOut->getPortName(i)));
    }

    return deviceList;
}

void MidiEngine::openMidiDevice(int index) {
    if (!midiOut) return;

    try {
        midiOut->openPort(index);
        qDebug() << "Opened MIDI device:" << index;
    }
    catch (RtMidiError& error) {
        qDebug() << "Failed to open MIDI device:" << QString::fromStdString(error.getMessage());
    }
}