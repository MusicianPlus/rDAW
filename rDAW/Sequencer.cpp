#include "Sequencer.h"
#include <QtConcurrent/QtConcurrent>

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
    qDebug() << "Sequencer started";

    // Run playbackLoop in a separate thread
    QtConcurrent::run([this]() { playbackLoop(); });
}

// Stop playback
void Sequencer::stop() {
    if (!isPlaying) {
        qDebug() << "Sequencer is already stopped";
        return;
    }

    isPlaying = false;
    qDebug() << "Sequencer stopped";
}

// Set the tempo
void Sequencer::setTempo(double bpm) {
    tempo = bpm;
    qDebug() << "Tempo set to:" << bpm << "BPM";
}

// Playback loop
void Sequencer::playbackLoop() {
    while (isPlaying) {
        QThread::msleep(50); // Simulate a 50ms step for playback
        currentTick += 1;    // Advance playback position
        emit playbackPositionChanged(currentTick); // Signal for real-time UI updates

        // Debugging playback progress
        qDebug() << "Playback tick:" << currentTick;
    }
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
