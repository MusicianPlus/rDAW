#include "Sequencer.h"
#include <QtConcurrent/QtConcurrent>
#include <QThread>
#include <QDebug>

// Constructor
Sequencer::Sequencer(QObject* parent)
    : QObject(parent), tempo(120.0), isPlaying(false), currentTick(0) {}

// Add a new track
void Sequencer::addTrack(const std::string& name) {
    tracks.emplace_back(name);
    qDebug() << "Track added:" << QString::fromStdString(name)
        << "Total tracks:" << tracks.size();
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
    if (isPlaying) {
        qDebug() << "Sequencer is already playing";
        return;
    }
    isPlaying = true;
    QtConcurrent::run([this]() { playbackLoop(); });
    qDebug() << "Playback started";
}

// Stop playback
void Sequencer::stop() {
    if (!isPlaying) {
        qDebug() << "Sequencer is already stopped";
        return;
    }
    isPlaying = false;
    qDebug() << "Playback stopped";
}

// Playback loop
void Sequencer::playbackLoop() {
    while (isPlaying) {
        double tickDurationMs = 60000.0 / (tempo * 480); // Duration of one tick in milliseconds
        QThread::msleep(static_cast<unsigned long>(tickDurationMs));
        currentTick += 1;

        // Handle looping
        if (isLooping && currentTick >= loopEnd) {
            currentTick = loopStart;
            emit playbackPositionChanged(currentTick);
        }

        emit playbackPositionChanged(currentTick);

        // Debug the current tick
        qDebug() << "Playback tick:" << currentTick << "Tempo:" << tempo;

        // Process events for each track
        for (auto& track : tracks) {
            for (const auto& event : track.events) {
                if (event.tick == currentTick) {
                    if (midiOutputCallback) {
                        midiOutputCallback(event);
                    }
                    qDebug() << "Playback Event:"
                        << "Tick:" << event.tick
                        << "Type:" << static_cast<int>(event.type)
                        << "Channel:" << event.channel
                        << "Pitch:" << event.pitch
                        << "Velocity:" << event.velocity;
                }
            }
        }
    }
}

// Set tempo
void Sequencer::setTempo(double bpm) {
    tempo = bpm;
    emit tempoChanged(tempo); // Notify listeners
    qDebug() << "Tempo set to:" << bpm << "BPM";
}

// Wrapper for QML: Add track
void Sequencer::addTrackQml(const QString& name) {
    addTrack(name.toStdString());
}

// Wrapper for QML: Get track count
int Sequencer::getTrackCountQml() const {
    return static_cast<int>(getTrackCount());
}

// Wrapper for QML: Start playback
void Sequencer::startQml() {
    start();
}

// Wrapper for QML: Stop playback
void Sequencer::stopQml() {
    stop();
}

// Wrapper for QML: Set tempo
void Sequencer::setTempoQml(double bpm) {
    setTempo(bpm);
}

void Sequencer::removeTrackQml(int index) {
    if (index >= 0 && index < static_cast<int>(tracks.size())) {
        qDebug() << "Removing track at index:" << index;
        tracks.erase(tracks.begin() + index);
    }
    else {
        qDebug() << "Invalid track index:" << index;
    }
}

int Sequencer::getSelectedTrackIndexQml() const {
    return selectedTrackIndex;
}

void Sequencer::setSelectedTrackIndexQml(int index) {
    if (index >= 0 && index < static_cast<int>(tracks.size())) {
        selectedTrackIndex = index;
        qDebug() << "Selected track index set to:" << index;
    }
    else {
        qDebug() << "Invalid track index selected:" << index;
    }
}

void Sequencer::setMidiOutputCallback(std::function<void(const MidiEvent&)> callback) {
    midiOutputCallback = callback;
}

void Sequencer::rewind() {
    currentTick = 0; // Reset playback position
    emit playbackPositionChanged(currentTick); // Notify the UI
    qDebug() << "Playback position rewound to tick:" << currentTick;
}

void Sequencer::setLoopRange(int start, int end) {
    loopStart = start;
    loopEnd = end;
    qDebug() << "Loop range set to:" << loopStart << "to" << loopEnd;
}

void Sequencer::setLooping(bool looping) {
    isLooping = looping;
    qDebug() << "Looping set to:" << looping;
}
