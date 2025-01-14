#ifndef SEQUENCERDATA_H
#define SEQUENCERDATA_H

#include <vector>
#include <string>

// MIDI Event Types
enum class MidiEventType {
    NoteOn,
    NoteOff,
    ControlChange,
    PitchBend,
    Aftertouch
};

// MIDI Event Structure
struct MidiEvent {
    double tick;       // Time in ticks
    MidiEventType type;
    int channel;       // MIDI channel (1-16)
    int pitch;         // For Note On/Off
    int velocity;      // For Note On/Off
    int value;         // For CC or Pitch Bend

    // Constructor for convenience
    MidiEvent(double tick, MidiEventType type, int channel, int pitch = 0, int velocity = 0, int value = 0)
        : tick(tick), type(type), channel(channel), pitch(pitch), velocity(velocity), value(value) {}
};

// Track Structure
struct Track {
    std::string name;
    std::vector<MidiEvent> events;

    double loopStart;   // Start of the loop in ticks
    double loopEnd;     // End of the loop in ticks
    bool isLooping;     // Whether looping is enabled for this track
    double trackTick;   // Current tick for this track

    Track(const std::string& name)
        : name(name), loopStart(0), loopEnd(0), isLooping(false), trackTick(0) {}

    void addEvent(const MidiEvent& event) {
        events.push_back(event);
    }

    void setLoopPoints(double start, double end) {
        loopStart = start;
        loopEnd = end;
        isLooping = true;
    }
};


#endif // SEQUENCERDATA_H
