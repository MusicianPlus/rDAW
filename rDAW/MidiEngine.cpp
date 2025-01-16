#include "MidiEngine.h"
#include "Sequencer.h"


// Constructor
MidiEngine::MidiEngine(QObject* parent)
    : QObject(parent), midiIn(nullptr), midiOut(nullptr) {
    try {
        midiIn = new RtMidiIn();
        midiOut = new RtMidiOut();

        // Set the callback function for MIDI input
        midiIn->setCallback(&midiCallback, this);

        // List available devices
        qDebug() << "Listing available MIDI devices:";
        listInputDevices();
        listOutputDevices();
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

// Get available MIDI devices (INPUT)
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
        qDebug() << "Opened MIDI input device:"
            << QString::fromStdString(midiIn->getPortName(index));
    }
    catch (RtMidiError& error) {
        qDebug() << "Error opening MIDI input device:"
            << QString::fromStdString(error.getMessage());
    }
}

// Start MIDI input
void MidiEngine::startMidiInput() {
    if (!midiIn) {
        qDebug() << "midiIn is null. Cannot set callback.";
        return;
    }
    if (midiIn) {
        try {
            // Attempt to open the port
            try {
                midiIn->openPort(0);
                qDebug() << "MIDI port opened successfully.";
            }
            catch (RtMidiError& error) {
                qDebug() << "Failed to open MIDI port:"
                    << QString::fromStdString(error.getMessage());
                return;
            }
            qDebug() << "Attempting to set MIDI callback...";

            // Set the callback
            midiIn->setCallback(&midiCallback, this);
            qDebug() << "MIDI callback successfully set.";

            // Ignore certain message types
            midiIn->ignoreTypes(false, true, true);
            qDebug() << "MIDI input started on device:"
                << QString::fromStdString(midiIn->getPortName(0));
        }
        catch (RtMidiError& error) {
            qDebug() << "Error starting MIDI input:"
                << QString::fromStdString(error.getMessage());
        }
    }
    else {
        qDebug() << "MIDI input is null. Initialization failed.";
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

    qDebug() << "Received MIDI Message:"
        << "Status:" << QString::number(status, 16)
        << "Data1:" << data1
        << "Data2:" << data2;

    // Recording logic
    if (engine->isRecording) {
        Sequencer* sequencer = engine->getSequencer();
        if (sequencer->getTrackCountQml() > 0 && sequencer->getSelectedTrackIndexQml() >= 0) {
            int selectedTrack = sequencer->getSelectedTrackIndexQml();
            Track& track = sequencer->getTrack(selectedTrack);

            MidiEventType type =
                ((status & 0xF0) == 0x90 && data2 > 0) ? MidiEventType::NoteOn :
                ((status & 0xF0) == 0x80 || data2 == 0) ? MidiEventType::NoteOff :
                MidiEventType::ControlChange;

            MidiEvent event(
                sequencer->getCurrentTick(),
                type,
                status & 0x0F,
                data1,
                data2
                );

            track.addEvent(event);

            qDebug() << "Recorded Event:" << "Track:" << selectedTrack
                << "Tick:" << event.tick
                << "Type:" << static_cast<int>(event.type)
                << "Channel:" << event.channel
                << "Pitch:" << event.pitch
                << "Velocity:" << event.velocity;
        }
        else {
            qDebug() << "No valid track selected for recording.";
        }
    }
}

void MidiEngine::startPlayback() {
    // Provide a MIDI output callback to Sequencer
    sequencer.setMidiOutputCallback([this](const MidiEvent& event) {
        // Convert MidiEvent to raw MIDI message
        std::vector<unsigned char> message = {
            static_cast<unsigned char>((event.type == MidiEventType::NoteOn ? 0x90 : 0x80) | (event.channel & 0x0F)),
            static_cast<unsigned char>(event.pitch & 0x7F),
            static_cast<unsigned char>(event.velocity & 0x7F)
        };
        midiOut->sendMessage(&message);

        // ADDED: Log that we actually sent the message
        qDebug() << "Sent message to midiOut for tick:" << event.tick
            << (event.type == MidiEventType::NoteOn ? "NoteOn" : "NoteOff")
            << "Channel:" << (event.channel & 0x0F)
            << "Pitch:" << (event.pitch & 0x7F)
            << "Velocity:" << (event.velocity & 0x7F);
        });

    // Start playback on the Sequencer side
    sequencer.startQml();
}

void MidiEngine::stopPlayback() {
    sequencer.stopQml();
}

void MidiEngine::rewindPlayback() {
    sequencer.rewind();
}

// Returns a list of available MIDI OUTPUT devices
QStringList MidiEngine::getAvailableMidiOutputDevices() {
    QStringList devices;
    if (midiOut) {
        unsigned int count = midiOut->getPortCount();
        for (unsigned int i = 0; i < count; ++i) {
            devices << QString::fromStdString(midiOut->getPortName(i));
        }
    }
    return devices;
}

Q_INVOKABLE void MidiEngine::openMidiOutputDevice(int index) {
    if (!midiOut) {
        qDebug() << "midiOut is null, cannot open output device.";
        return;
    }

    // 1. Close any previously opened port
    if (midiOut->isPortOpen()) {
        midiOut->closePort();
        qDebug() << "Closed previous MIDI output port before opening a new one.";
    }

    try {
        midiOut->openPort(static_cast<unsigned int>(index));
        qDebug() << "Opened MIDI output device:"
            << QString::fromStdString(midiOut->getPortName(index));
    }
    catch (RtMidiError& error) {
        qDebug() << "Error opening MIDI output device:"
            << QString::fromStdString(error.getMessage());
    }
}