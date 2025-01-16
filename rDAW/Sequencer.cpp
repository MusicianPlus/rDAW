#include "Sequencer.h"
#include <QtConcurrent/QtConcurrent>
#include <QThread>
#include <QDebug>
#include <QElapsedTimer>

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


void Sequencer::playbackLoop()
{
    qDebug() << "Entered playbackLoop";

    QElapsedTimer timer;
    timer.start();

    // Start from the currentTick if you wish to continue where you left off,
    // or just set currentTick = 0 before starting playback if you want a fresh start.
    int lastProcessedTick = currentTick;

    while (isPlaying) {
        // Time (ms) since playbackLoop started
        qint64 elapsedMs = timer.elapsed();

        // This converts your tempo + PPQ into "ticks per millisecond"
        double ticksPerMs = (tempo * 480.0) / 60000.0;  // Hard-coded 480 PPQ

        // How many ticks "should" have passed by now
        int idealTick = static_cast<int>(elapsedMs * ticksPerMs);

        // Optional debug output
        qDebug() << "Loop iteration: elapsedMs=" << elapsedMs
            << "tempo=" << tempo
            << "ticksPerMs=" << ticksPerMs
            << "idealTick=" << idealTick
            << "lastProcessedTick=" << lastProcessedTick
            << "isLooping=" << isLooping;

        // Looping logic
        if (isLooping && idealTick >= loopEnd) {
            // Wrap around
            int overshoot = idealTick - loopEnd;
            idealTick = loopStart + overshoot;
            // Restart timer so elapsedMs resets from 0 at this new loop point
            timer.restart();

            qDebug() << "Looping back to" << idealTick
                << "(timer restarted)";
        }

        // If for some reason idealTick is less than lastProcessedTick (e.g. from looping),
        // reset lastProcessedTick to avoid negative loops.
        if (idealTick < lastProcessedTick) {
            lastProcessedTick = idealTick;
        }

        // Process each tick from (lastProcessedTick+1) to (idealTick)
        for (int t = lastProcessedTick + 1; t <= idealTick; ++t) {
            currentTick = t;

            // Check all tracks for events at this tick
            for (auto& track : tracks) {
                for (auto& event : track.events) {
                    if (event.tick == currentTick) {
                        qDebug() << "Playback Event at tick:" << currentTick
                            << "Type:" << static_cast<int>(event.type)
                            << "Channel:" << event.channel
                            << "Pitch:" << event.pitch
                            << "Velocity:" << event.velocity;

                        // If there's a MIDI output callback, trigger it
                        if (midiOutputCallback) {
                            midiOutputCallback(event);
                        }
                    }
                }
            }

            // Notify QML UI about the currentTick for the playhead
            emit playbackPositionChanged(currentTick);
        }

        // Update lastProcessedTick to the new ideal
        lastProcessedTick = idealTick;

        // Sleep a bit to avoid maxing out the CPU
        QThread::msleep(1);
    }

    qDebug() << "Playback loop ended";
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
        emit selectedTrackIndexChanged(); // Notify QML
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

void Sequencer::renameTrackQml(int index, const QString& newName) {
    if (index >= 0 && index < static_cast<int>(tracks.size())) {
        tracks[index].name = newName.toStdString();  // or use a setter if you have one
        qDebug() << "Renamed track at index" << index << "to" << newName;
    }
    else {
        qDebug() << "Invalid track index for renaming:" << index;
    }
}