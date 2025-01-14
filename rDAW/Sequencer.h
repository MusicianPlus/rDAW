#ifndef SEQUENCER_H
#define SEQUENCER_H

#include "SequencerData.h"
#include <QObject>
#include <vector>
#include <functional>

class Sequencer : public QObject {
    Q_OBJECT
public:
    explicit Sequencer(QObject* parent = nullptr);

    // Add and manage tracks
    void addTrack(const std::string& name);
    Track& getTrack(size_t index);
    size_t getTrackCount() const;

    // Playback control
    void start();
    void stop();
    void setTempo(double bpm);
    
    // Callback for sending MIDI messages
    void setMidiOutputCallback(std::function<void(const MidiEvent&)> callback);
    double getCurrentTick() const {
        return currentTick;
    }

signals:
    void playbackPositionChanged(double tick);

private:
    std::vector<Track> tracks;
    double tempo; // BPM
    bool isPlaying;
    double currentTick;

    std::function<void(const MidiEvent&)> midiOutputCallback;

    void playbackLoop(); // Internal playback engine
};

#endif // SEQUENCER_H
