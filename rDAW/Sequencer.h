#ifndef SEQUENCER_H
#define SEQUENCER_H

#include "SequencerData.h" // Assuming it contains definitions for Track and MidiEvent
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

    // QML-exposed methods (wrappers)
    Q_INVOKABLE void addTrackQml(const QString& name);  // Add track (QML)
    Q_INVOKABLE int getTrackCountQml() const;          // Get track count (QML)
    Q_INVOKABLE void startQml();                       // Start playback (QML)
    Q_INVOKABLE void stopQml();                        // Stop playback (QML)
    Q_INVOKABLE void setTempoQml(double bpm);          // Set tempo (QML)
    Q_INVOKABLE void removeTrackQml(int index);         // Remove track (QML)

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
