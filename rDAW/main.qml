import QtQuick 6.8
import QtQuick.Controls 6.8

ApplicationWindow {
    visible: true
    width: 1000
    height: 600
    title: "Playback & Recording Controls"

    ListModel {
        id: trackModel
    }

    property bool isPlaying: false
    property bool isRecording: false
    property int playheadPosition: 0
    property int selectedIndex: -1
    property double pixelRate: 0.1

    Column {
        spacing: 10
        anchors.fill: parent

        // Playback and Recording Controls
        Row {
            spacing: 20
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: isPlaying ? "Stop" : "Play"
                onClicked: {
                    isPlaying = !isPlaying
                    if (isPlaying) {
                        backend.startPlayback()
                    } else {
                        backend.stopPlayback()
                    }
                }
            }

            Button {
                text: "Rewind"
                onClicked: {
                    backend.rewindPlayback();
                }
            }

            Button {  //problem here idk
                text: isRecording ? "Stop Recording" : "Record"
                onClicked: {
                    isRecording = !isRecording
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()

                    if (isRecording) {
                        backend.startRecording()
                        if (selectedIndex >= 0) {
                            let startTick = sequencer.getCurrentTickQml()
                            trackModel.setProperty(selectedIndex, "recordStart", startTick)
                            trackModel.setProperty(selectedIndex, "recordEnd", startTick)
                        }
                    } else {
                        backend.stopRecording()
                        // Optionally finalize recordEnd here, or just leave it as is
                    }
                }
            }


            Slider {
                id: tempoSlider
                from: 60
                to: 180
                value: 120
                stepSize: 1
                width: 200
                onValueChanged: {
                    sequencer.setTempoQml(value);
                }
            }

            Text {
                text: "Tempo: " + tempoSlider.value + " BPM"
            }
        }

        // Looping Controls
        Row {
            spacing: 10
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter

            CheckBox {
                id: loopingToggle
                text: "Enable Looping"
                onCheckedChanged: {
                    sequencer.setLooping(checked);
                }
            }

            TextField {
                id: loopStartInput
                placeholderText: "Loop Start"
                width: 80
                onEditingFinished: {
                    console.log("Loop Start:", parseFloat(loopStartInput.text), 
                        "Loop End:", parseFloat(loopEndInput.text));
                    sequencer.setLoopRange(parseFloat(loopStartInput.text), parseFloat(loopEndInput.text));
                }
            }

            TextField {
                id: loopEndInput
                placeholderText: "Loop End"
                width: 80
                onEditingFinished: {
                    sequencer.setLoopRange(parseFloat(loopStartInput.text), parseFloat(loopEndInput.text));
                }
            }
        }

        // Timeline and Track List
        Row {
            spacing: 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height - 150

            // Track Names (Fixed Column)
            Flickable {
                id: trackNamesScroll
                width: parent.width * 0.3
                height: parent.height - 50
                contentHeight: trackModel.count * 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    spacing: 10
                    width: trackNamesScroll.width
                    height: trackNamesScroll.contentHeight

Repeater {
    model: trackModel

    Row {
        width: trackNamesScroll.width
        height: 50
        spacing: 0

        // 1. Instrument Button (square on the left)
        Rectangle {
            id: instButton
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            color: "#aaaaaa"  // Gray background
            border.color: "black"
            Text {
                text: "Inst"
                anchors.centerIn: parent
                color: "black"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("Instrument button clicked for track index:", index)
                    // Possibly open an instrument selection dialog, or do anything else
                }
            }
        }

        // 2. Main Track Name area (click to select)
        Rectangle {
            id: trackRect
            anchors.verticalCenter: parent.verticalCenter
            // Subtract the squares' widths from the total for a flexible width
            // (We have 40px for Inst, 40px for Mute, 40px for Solo, plus spacing)
            // For simplicity, just do: width: parent.width - 130
            // Alternatively, set a fixed width if you prefer
            width: Math.max(parent.width - 130, 50)
            height: 50
            color: index === sequencer.selectedTrackIndex ? "lightblue" : "transparent"
            border.color: "black"

            Text {
                text: model.name
                anchors.centerIn: parent
                color: "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    sequencer.setSelectedTrackIndexQml(index);
                    console.log("Track selected:", model.name, "at index:", index);
                }
            }
            }

        // 3. Mute Button
        Rectangle {
            id: muteButton
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter

            // Turn red if muted, grey if not
            color: model.mute ? "#cc4444" : "#aaaaaa"
            border.color: "black"

            Text {
                text: "M"
                anchors.centerIn: parent
                color: "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let newMute = !model.mute
                    trackModel.setProperty(index, "mute", newMute)
                    console.log("Mute toggled for track index:", index, "=>", newMute)
                    // Here you could also call a C++ function to actually mute playback 
                    // e.g. sequencer.setTrackMute(index, newMute)
                }
            }
        }

        // 4. Solo Button
        Rectangle {
            id: soloButton
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter

            // Turn yellow if soloed, grey if not
            color: model.solo ? "#eeee44" : "#aaaaaa"
            border.color: "black"

            Text {
                text: "S"
                anchors.centerIn: parent
                color: "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    let newSolo = !model.solo
                    trackModel.setProperty(index, "solo", newSolo)
                    console.log("Solo toggled for track index:", index, "=>", newSolo)
                    // Potentially you want logic that unsolos other tracks if only one track can be solo
                    // e.g. if (newSolo) un-solo other tracks, etc.
                }
            }
        }
    }
}




                }

                // Sync with eventScroll
                onContentYChanged: {
                    if (eventScroll.contentY !== contentY) {
                        eventScroll.contentY = contentY;
                    }
                }
            }

            // Timeline Events
            Flickable {
                id: eventScroll
                width: parent.width * 0.7
                height: parent.height - 50
                contentWidth: 2000
                contentHeight: trackModel.count * 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    spacing: 10
                    width: eventScroll.contentWidth
                    height: eventScroll.contentHeight

                    // Instead of your existing "Repeater { model: 8 ... }"
                    // we have ONE rectangle per track to show recordStart->recordEnd
                    Repeater {
                        model: trackModel

                        Row {
                            spacing: 10
                            height: 50

                            Rectangle {
                                id: patternRect
                                color: "red"
                                border.color: "black"
                                height: 40

                                // Convert ticks to pixels. Suppose 2 px per tick:
                                x: model.recordStart * pixelRate
                                width: (model.recordEnd - model.recordStart) * pixelRate

                                // If recordEnd==recordStart, the width is 0, effectively hidden
                                // Or you can explicitly hide it if you prefer:
                                visible: model.recordEnd > model.recordStart
                            }
                        }
                    }
                }

    Rectangle {
        id: playhead
        width: 2
        height: eventScroll.height
        color: "blue"
        x: playheadPosition
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: true
    }

    // Sync with trackNamesScroll
    onContentYChanged: {
        if (trackNamesScroll.contentY !== contentY) {
            trackNamesScroll.contentY = contentY;
        }
    }
}
        }

        // Add/Remove Track Buttons
        Row {
            spacing: 40
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter

            ComboBox {
                id: outputDeviceCombo
                model: backend.getAvailableMidiOutputDevices() // 'backend' is your MidiEngine
                // This signal passes the new index and text automatically
                onActivated: function() {
                    console.log("Activated index:", currentIndex, "Device:", currentText)
                    backend.openMidiOutputDevice(currentIndex)
                }
            }

            TextField {
                    id: renameField
                    placeholderText: "New Name"
                    width: 120
                }

                Button {
                    text: "Rename Track"
                    onClicked: {
                        let selectedIndex = sequencer.getSelectedTrackIndexQml();
                        if (selectedIndex >= 0) {
                            // Update the QML ListModel
                            trackModel.setProperty(selectedIndex, "name", renameField.text);

                            // Update the Sequencer in C++
                            sequencer.renameTrackQml(selectedIndex, renameField.text);
                        } else {
                            console.log("No valid track selected.");
                        }
                    }
                }

                Button {
                    text: "Add Track"
                    onClicked: {
                        let trackName = "Track " + (trackModel.count + 1);
                        // Add new track with recordStart=0, recordEnd=0
                        trackModel.append({
                            "name": trackName,
                            "recordStart": 0,
                            "recordEnd": 0,
                            "mute": false,
                            "solo": false
                        });
                        sequencer.addTrackQml(trackName);
                        console.log("Track added:", trackName);
                    }
                }

            Button {
                text: "Remove Selected Track"
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml();
                    if (selectedIndex >= 0 && trackModel.count > 0) {
                        trackModel.remove(selectedIndex);
                        sequencer.removeTrackQml(selectedIndex);
                        console.log("Removed track at index:", selectedIndex);

                        sequencer.setSelectedTrackIndexQml(
                            trackModel.count > 0
                            ? Math.min(selectedIndex, trackModel.count - 1)
                            : -1
                        );
                    } else {
                        console.log("No track selected or empty list.");
                    }
                }
            }
        }
    }
            Connections {
            target: sequencer
            function onSelectedTrackIndexChanged() {
                console.log("Selected track index changed:", sequencer.getSelectedTrackIndexQml());
            }
            function onPlaybackPositionChanged(tick) {
                playheadPosition = tick * pixelRate; // Adjust tick-to-pixel ratio if needed
                if (isRecording) { //problem here idk
                    let selectedIndex = sequencer.getSelectedTrackIndexQml();
                    if (selectedIndex >= 0) {
                        trackModel.setProperty(selectedIndex, "recordEnd", tick);
                    }
                }
            }

        }
}
