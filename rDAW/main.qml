import QtQuick 6.8
import QtQuick.Controls 6.8

ApplicationWindow {
    visible: true
    width: 1000
    height: 600
    title: "rDAW MVP"

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
            height: 30
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
                onClicked: backend.rewindPlayback()
            }

            Button {
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
                    }
                }
            }

            Button {
                text: "Load Sound"
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()
                    if (selectedIndex >= 0) {
                        const currentTick = sequencer.getCurrentTickQml()
                        trackModel.setProperty(selectedIndex, "hasWaveform", true)
                        trackModel.setProperty(selectedIndex, "waveformStart", currentTick)
                        trackModel.setProperty(selectedIndex, "waveformEnd", currentTick + 1000) // 1000 ticks default length
                        const waveformData = backend.loadSoundFile(); // Get waveform data from backend
                        trackModel.setProperty(selectedIndex, "waveformData", waveformData);
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
                onValueChanged: sequencer.setTempoQml(value)
            }

            Text {
                text: "Tempo: " + tempoSlider.value + " BPM"
            }

            // Looping Controls

            CheckBox {
                id: loopingToggle
                text: "Enable Looping"
                onCheckedChanged: sequencer.setLooping(checked)
            }

            TextField {
                id: loopStartInput
                placeholderText: "Loop Start"
                width: 80
                onEditingFinished: updateLoopRange()
            }

            TextField {
                id: loopEndInput
                placeholderText: "Loop End"
                width: 80
                onEditingFinished: updateLoopRange()
            }

            function updateLoopRange() {
                sequencer.setLoopRange(
                    parseFloat(loopStartInput.text),
                    parseFloat(loopEndInput.text)
                )
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
                width: (parent.width - parent.spacing) * 0.3
                height: parent.height - 50
                contentHeight: trackModel.count * 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Rectangle {
                    anchors.fill: parent
                    color: "#f0f0f0"
                }

                Column {
                    spacing: 10
                    width: parent.width

                    Repeater {
                        model: trackModel

                        Row {
                            width: trackNamesScroll.width
                            height: 50
                            spacing: 0

                            Rectangle {
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#aaaaaa"
                                border.color: "black"
                                Text {
                                    text: "Inst"
                                    anchors.centerIn: parent
                                }
                            }

                            Rectangle {
                                width: parent.width - 130
                                height: 50
                                color: index === sequencer.selectedTrackIndex ? "lightblue" : "white"
                                border.color: "black"
                                Text {
                                    text: model.name
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: sequencer.setSelectedTrackIndexQml(index)
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                color: model.mute ? "#cc4444" : "#aaaaaa"
                                border.color: "black"
                                Text {
                                    text: "M"
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: trackModel.setProperty(index, "mute", !model.mute)
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                color: model.solo ? "#eeee44" : "#aaaaaa"
                                border.color: "black"
                                Text {
                                    text: "S"
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: trackModel.setProperty(index, "solo", !model.solo)
                                }
                            }
                        }
                    }
                }

                onContentYChanged: {
                    if (eventScroll.contentY !== contentY) {
                        eventScroll.contentY = contentY
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
                    spacing: 0
                    width: parent.width

                    Repeater {
                        model: trackModel

                        Rectangle {
                            width: parent.width
                            height: 60
                            color: "transparent"

                            // Pattern Rectangle
                            Rectangle {
                                id: patternRect
                                color: "red"
                                border.color: "black"
                                height: 40
                                x: model.recordStart * pixelRate
                                width: (model.recordEnd - model.recordStart) * pixelRate
                                visible: model.recordEnd > model.recordStart
                            }

                            // Waveform Box
                            Rectangle {
                                id: waveformBox
                                visible: model.hasWaveform
                                x: model.waveformStart * pixelRate
                                width: (model.waveformEnd - model.waveformStart) * pixelRate
                                height: 40
                                color: "lightgreen"
                                border.color: "darkgreen"
                                y: 5

                                // Canvas for drawing the waveform
                                Canvas {
                                    id: waveformCanvas
                                    anchors.fill: parent
                                    antialiasing: true

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height); // Clear the canvas

                                        // Check if waveform data exists
                                        if (!model.waveformData || model.waveformData.length === 0) {
                                            console.log("No waveform data available.");
                                            return;
                                        }

                                        // Parse waveform data (assuming it's an array of values between -1 and 1)
                                        let waveformPoints;
                                        try {
                                            waveformPoints = JSON.parse(model.waveformData);
                                            console.log("Parsed waveform data");

                                        } catch (e) {
                                            console.error("Error parsing waveform data:", e);
                                            return;
                                        }

                                        // Draw the waveform
                                        ctx.beginPath();
                                        ctx.strokeStyle = "darkgreen";
                                        ctx.lineWidth = 2;

                                        for (let i = 0; i < waveformPoints.length; i++) {
                                            const x = (i / (waveformPoints.length - 1)) * width;
                                            const y = (1 - (waveformPoints[i] + 1) / 2) * height; // Normalize to canvas height

                                            if (i === 0) {
                                                ctx.moveTo(x, y);
                                            } else {
                                                ctx.lineTo(x, y);
                                            } 
                                        }

                                        ctx.stroke();
                                    }

                                    // Redraw when waveform data changes
                                    Connections {
                                        target: trackModel
                                        function onDataChanged() {
                                            if (index === sequencer.selectedTrackIndex) {
                                                waveformCanvas.requestPaint();
                                            }
                                        }
                                    }
                                }


                                // Left handle
                                Rectangle {
                                    width: 20
                                    height: parent.height
                                    color: "darkgreen"
                                    anchors.left: parent.left
        
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        propagateComposedEvents: false
                                        preventStealing: true
            
                                        property real pressX: 0
                                        property real initialStart: 0
            
                                        onPressed: {
                                            pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                            initialStart = model.waveformStart
                                            eventScroll.interactive = false
                                        }
            
                                        onPositionChanged: {
                                            if (pressed) {
                                                const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                                const delta = (currentX - pressX) / pixelRate
                                                const newStart = Math.max(0, Math.round(initialStart + delta))
                    
                                                if (newStart < model.waveformEnd) {
                                                    trackModel.setProperty(index, "waveformStart", newStart)
                                                }
                                            }
                                        }
            
                                        onReleased: {
                                            eventScroll.interactive = true
                                        }
            
                                        onClicked: mouse.accepted = true
                                    }
                                }

                                // Right handle
                                Rectangle {
                                    width: 20
                                    height: parent.height
                                    color: "darkgreen"
                                    anchors.right: parent.right
        
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        propagateComposedEvents: false
                                        preventStealing: true
            
                                        property real pressX: 0
                                        property real initialEnd: 0
            
                                        onPressed: {
                                            pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                            initialEnd = model.waveformEnd
                                            eventScroll.interactive = false
                                        }
            
                                        onPositionChanged: {
                                            if (pressed) {
                                                const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                                const delta = (currentX - pressX) / pixelRate
                                                const newEnd = Math.round(initialEnd + delta)
                    
                                                if (newEnd > model.waveformStart) {
                                                    trackModel.setProperty(index, "waveformEnd", newEnd)
                                                }
                                            }
                                        }
            
                                        onReleased: {
                                            eventScroll.interactive = true
                                        }
            
                                        onClicked: mouse.accepted = true

                                    }
                                }

                                // Middle drag area
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    cursorShape: Qt.OpenHandCursor
                                    propagateComposedEvents: false
                                    preventStealing: true
        
                                    property real pressX: 0
                                    property real initialX: 0
        
                                    onPressed: {
                                        pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                        initialX = waveformBox.x
                                        eventScroll.interactive = false
                                    }
        
                                    onPositionChanged: {
                                        if (pressed) {
                                            const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x
                                            const delta = currentX - pressX
                                            const newX = Math.max(0, initialX + delta)
                
                                            const newStart = Math.round(newX / pixelRate)
                                            const duration = model.waveformEnd - model.waveformStart
                                            const newEnd = newStart + duration
                
                                            if (newEnd * pixelRate <= eventScroll.contentWidth) {
                                                trackModel.setProperty(index, "waveformStart", newStart)
                                                trackModel.setProperty(index, "waveformEnd", newEnd)
                                            }
                                        }
                                    }
        
                                    onReleased: {
                                        eventScroll.interactive = true
                                    }
        
                                    onClicked: mouse.accepted = true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: playhead
                    width: 2
                    height: parent.height
                    color: "blue"
                    x: playheadPosition
                }

                onContentYChanged: {
                    if (trackNamesScroll.contentY !== contentY) {
                        trackNamesScroll.contentY = contentY
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
                model: backend.getAvailableMidiOutputDevices()
                onActivated: backend.openMidiOutputDevice(currentIndex)
            }

            TextField {
                id: renameField
                placeholderText: "New Name"
                width: 120
            }

            Button {
                text: "Rename Track"
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()
                    if (selectedIndex >= 0) {
                        trackModel.setProperty(selectedIndex, "name", renameField.text)
                        sequencer.renameTrackQml(selectedIndex, renameField.text)
                    }
                }
            }

            Button {
                text: "Add Track"
                onClicked: {
                    let trackName = "Track " + (trackModel.count + 1)
                    trackModel.append({
                        "name": trackName,
                        "recordStart": 0,
                        "recordEnd": 0,
                        "mute": false,
                        "solo": false,
                        "hasWaveform": false,
                        "waveformStart": 0,
                        "waveformEnd": 0,
                        "waveformData": "[]" // Initialize with empty array
                    })
                    sequencer.addTrackQml(trackName)
                }
            }

            Button {
                text: "Remove Selected Track"
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()
                    if (selectedIndex >= 0 && trackModel.count > 0) {
                        trackModel.remove(selectedIndex)
                        sequencer.removeTrackQml(selectedIndex)
                        sequencer.setSelectedTrackIndexQml(
                            trackModel.count > 0 ? Math.min(selectedIndex, trackModel.count - 1) : -1
                        )
                    }
                }
            }
        }
    }

    Connections {
        target: sequencer
        function onSelectedTrackIndexChanged() {
            console.log("Selected track index changed:", sequencer.getSelectedTrackIndexQml())
        }
        function onPlaybackPositionChanged(tick) {
            playheadPosition = tick * pixelRate
            if (isRecording) {
                let selectedIndex = sequencer.getSelectedTrackIndexQml()
                if (selectedIndex >= 0) {
                    trackModel.setProperty(selectedIndex, "recordEnd", tick)
                }
            }
        }
    }
}