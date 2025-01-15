#include "MidiEngine.h"

// Constructor
MidiEngine::MidiEngine(QObject* parent)
    : QObject(parent), midiIn(nullptr), midiOut(nullptr) {
    try {
        midiIn = new RtMidiIn();
        midiOut = new RtMidiOut();

        // Set the callback function
        midiIn->setCallback(&midiCallback, this);
    }
    catch (RtMidiError& error) {
        qDebug() << "Error initializing MIDI:" << QString::fromStdString(error.getMessage());
    }
}

// Destructor
MidiEngine::~MidiEngine() {
    delete midiIn;
    delete midiOut;
}

// Expose the sequencer to QML
Sequencer* MidiEngine::getSequencer() {
    return &sequencer;
}

// List all MIDI devices
void MidiEngine::listMidiDevices() {
    qDebug() << "Available MIDI Devices:";
    listInputDevices();
    listOutputDevices();
}

// Send a Note On message
void MidiEngine::sendMidiNoteOn(int channel, int note, int velocity) {
    if (!midiOut) return;

    std::vector<unsigned char> message = {
        static_cast<unsigned char>(0x90 | (channel & 0x0F)),
        static_cast<unsigned char>(note & 0x7F),
        static_cast<unsigned char>(velocity & 0x7F)
    };
    midiOut->sendMessage(&message);
    qDebug() << "Sent Note On:" << channel << note << velocity;
}

// Send a Note Off message
void MidiEngine::sendMidiNoteOff(int channel, int note) {
    if (!midiOut) return;

    std::vector<unsigned char> message = {
        static_cast<unsigned char>(0x80 | (channel & 0x0F)),
        static_cast<unsigned char>(note & 0x7F),
        0
    };
    midiOut->sendMessage(&message);
    qDebug() << "Sent Note Off:" << channel << note;
}

// Get available MIDI devices
QStringList MidiEngine::getAvailableMidiDevices() {
    QStringList devices;
    if (midiIn) {
        unsigned int count = midiIn->getPortCount();
        for (unsigned int i = 0; i < count; ++i) {
            devices << QString::fromStdString(midiIn->getPortName(i));
        }
    }
    return devices;
}

// Open a specific MIDI input device
void MidiEngine::openMidiDevice(int index) {
    if (!midiIn) return;

    try {
        midiIn->openPort(index);
        qDebug() << "Opened MIDI input device:" << QString::fromStdString(midiIn->getPortName(index));
    }
    catch (RtMidiError& error) {
        qDebug() << "Error opening MIDI input device:" << QString::fromStdString(error.getMessage());
    }
}

// Start MIDI input
void MidiEngine::startMidiInput() {
    if (midiIn && !midiIn->isPortOpen()) {
        midiIn->openPort(0); // Default to first port
        midiIn->setCallback(&midiCallback, this);
        midiIn->ignoreTypes(false, true, true);
        qDebug() << "MIDI input started.";
    }
}

// List all input devices
void MidiEngine::listInputDevices() {
    if (!midiIn) return;

    unsigned int count = midiIn->getPortCount();
    qDebug() << "Available MIDI Input Devices:";
    for (unsigned int i = 0; i < count; ++i) {
        qDebug() << i << ":" << QString::fromStdString(midiIn->getPortName(i));
    }
}

// List all output devices
void MidiEngine::listOutputDevices() {
    if (!midiOut) return;

    unsigned int count = midiOut->getPortCount();
    qDebug() << "Available MIDI Output Devices:";
    for (unsigned int i = 0; i < count; ++i) {
        qDebug() << i << ":" << QString::fromStdString(midiOut->getPortName(i));
    }
}

// Start recording
void MidiEngine::startRecording() {
    isRecording = true;
    qDebug() << "Recording started.";
}

// Stop recording
void MidiEngine::stopRecording() {
    isRecording = false;
    qDebug() << "Recording stopped.";
}

// Callback function definition
void midiCallback(double deltaTime, std::vector<unsigned char>* message, void* userData) {
    MidiEngine* engine = static_cast<MidiEngine*>(userData);

    if (!message || message->empty()) return;

    unsigned char status = message->at(0);
    unsigned char data1 = message->size() > 1 ? message->at(1) : 0;
    unsigned char data2 = message->size() > 2 ? message->at(2) : 0;

    // Log incoming MIDI messages
    qDebug() << "Received MIDI Message:"
        << "Status:" << QString::number(status, 16)
        << "Data1:" << data1
        << "Data2:" << data2;

    // Process recording
    if (engine->isRecording) {
        auto& sequencer = *engine->getSequencer(); // Dereference pointer to get reference

        if (sequencer.getTrackCount() > 0) {
            Track& activeTrack = sequencer.getTrack(0); // Initialize activeTrack

            MidiEventType type = (status & 0xF0) == 0x90 && data2 > 0 ? MidiEventType::NoteOn
                : (status & 0xF0) == 0x80 || data2 == 0 ? MidiEventType::NoteOff
                : MidiEventType::ControlChange;

            MidiEvent event(
                sequencer.getCurrentTick(), // Correct tick value
                type,                       // Correct MidiEventType
                status & 0x0F,              // Channel
                data1,                      // Pitch
                data2                       // Velocity
                );

            activeTrack.addEvent(event);
            qDebug() << "Recorded Event:" << "Tick:" << event.tick
                << "Type:" << static_cast<int>(event.type)
                << "Channel:" << event.channel
                << "Pitch:" << event.pitch
                << "Velocity:" << event.velocity;
        }
    }
}
