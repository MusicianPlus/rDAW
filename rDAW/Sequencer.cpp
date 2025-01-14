#include "Sequencer.h"
#include <QTimer>
#include <QtConcurrent/QtConcurrent>

// Constructor
Sequencer::Sequencer(QObject* parent)
    : QObject(parent), tempo(120.0), isPlaying(false), currentTick(0) {}

// Add a new track
void Sequencer::addTrack(const std::string& name) {
    tracks.emplace_back(name);
}

// Get a track by index
Track& Sequencer::getTrack(size_t index) {
    return tracks.at(index);
}

// Get the total number of tracks
size_t Sequencer::getTrackCount() const {
    return tracks.size();
}

// Start playback
void Sequencer::start() {
    if (isPlaying) return;

    isPlaying = true;
    QtConcurrent::run([this]() { playbackLoop(); });
}

// Stop playback
void Sequencer::stop() {
    isPlaying = false;
}

// Set the tempo (BPM)
void Sequencer::setTempo(double bpm) {
    tempo = bpm;
}

// Set the MIDI output callback
void Sequencer::setMidiOutputCallback(std::function<void(const MidiEvent&)> callback) {
    midiOutputCallback = callback;
}

// Main playback loop
void Sequencer::playbackLoop() {
    while (isPlaying) {
        // Calculate tick duration in milliseconds
        double tickDurationMs = 60000.0 / (tempo * 480); // Assuming 480 ticks per quarter note
        QThread::msleep(static_cast<unsigned long>(tickDurationMs));

        for (auto& track : tracks) {
            // Advance the track-specific tick
            track.trackTick++;

            // Handle looping for this track
            if (track.isLooping && track.trackTick > track.loopEnd) {
                qDebug() << "Looping Track:" << QString::fromStdString(track.name)
                    << "Back to Tick:" << track.loopStart;
                track.trackTick = track.loopStart;
            }

            // Process events for the current track's tick
            for (const auto& event : track.events) {
                if (static_cast<int>(event.tick) == static_cast<int>(track.trackTick)) {
                    qDebug() << "Processing Event: Track:" << QString::fromStdString(track.name)
                        << "Tick:" << event.tick
                        << "Type:" << static_cast<int>(event.type)
                        << "Channel:" << event.channel
                        << "Pitch:" << event.pitch
                        << "Velocity:" << event.velocity;

                    // Send the event via the callback
                    if (midiOutputCallback) {
                        midiOutputCallback(event);
                    }
                }
            }
        }
    }
}
