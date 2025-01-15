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
                    isPlaying = !isPlaying;
                    if (isPlaying) {
                        backend.startPlayback();
                    } else {
                        backend.stopPlayback();
                    }
                }
            }

            Button {
                text: "Rewind"
                onClicked: {
                    backend.rewindPlayback();
                }
            }

            Button {
                text: isRecording ? "Stop Recording" : "Record"
                onClicked: {
                    isRecording = !isRecording;
                    if (isRecording) {
                        backend.startRecording();
                    } else {
                        backend.stopRecording();
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
                    sequencer.setLoopRange(parseInt(loopStartInput.text), parseInt(loopEndInput.text));
                }
            }

            TextField {
                id: loopEndInput
                placeholderText: "Loop End"
                width: 80
                onEditingFinished: {
                    sequencer.setLoopRange(parseInt(loopStartInput.text), parseInt(loopEndInput.text));
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
                height: parent.height - 150
                contentHeight: trackModel.count * 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    spacing: 10
                    width: trackNamesScroll.width
                    height: trackNamesScroll.contentHeight

                    Repeater {
                        model: trackModel

                        Rectangle {
                            width: trackNamesScroll.width
                            height: 50
                            color: index === sequencer.getSelectedTrackIndexQml() ? "lightblue" : "transparent"
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
                height: parent.height - 150
                contentWidth: 2000
                contentHeight: trackModel.count * 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    spacing: 10
                    width: eventScroll.contentWidth
                    height: eventScroll.contentHeight

                    Repeater {
                        model: trackModel

                        Row {
                            spacing: 10
                            height: 50

                            Repeater {
                                model: 8
                                Rectangle {
                                    width: 40
                                    height: 40
                                    color: "red"
                                    border.color: "black"
                                }
                            }
                        }
                    }
                }

                // Sync with trackNamesScroll
                onContentYChanged: {
                    if (trackNamesScroll.contentY !== contentY) {
                        trackNamesScroll.contentY = contentY;
                    }
                }

                // Playhead
                Rectangle {
                    id: playhead
                    width: 2
                    height: eventScroll.height
                    color: "blue"
                    x: playheadPosition
                    anchors.top: eventScroll.top
                    anchors.bottom: eventScroll.bottom
                    visible: true
                }
            }
        }

        // Add/Remove Track Buttons
        Row {
            spacing: 10
            height: 50
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: "Add Track"
                onClicked: {
                    let trackName = "Track " + (trackModel.count + 1);
                    trackModel.append({ "name": trackName });
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
            function onPlaybackPositionChanged(tick) {
                playheadPosition = tick * 2; // Adjust tick-to-pixel ratio if needed
            }
        }
}
