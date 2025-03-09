import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Controls.Material 6.8

ApplicationWindow {
    visible: true
    width: 1280
    height: 400
    title: "rDAW MVP"
    color: "#ffffff"

    // Use the Material style for non-native customization.
    Material.theme: Material.Light
    Material.accent: "#2196F3"

    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.FramelessWindowHint

    maximumWidth: width
    maximumHeight: height

    ListModel {
        id: trackModel
    }

    property bool isPlaying: false
    property bool isRecording: false
    property int playheadPosition: 0
    property int selectedIndex: -1
    property double pixelRate: 0.1

    // Top Bar (Playback/Recording controls)
    Rectangle {
        id: topBar
        anchors.top: parent.top
        width: parent.width
        height: 70
        color: Material.accent

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 20

            // Touch-friendly custom Button style
            Button {
                id: playButton
                text: isPlaying ? "Stop" : "Play"
                height: 50
                width: 100
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: playButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
                onClicked: {
                    isPlaying = !isPlaying
                    if (isPlaying)
                        backend.startPlayback()
                    else
                        backend.stopPlayback()
                }
            }

            Button {
                id: rewindButton
                text: "Rewind"
                height: 50
                width: 100
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: rewindButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
                onClicked: backend.rewindPlayback()
            }

            Button {
                id: recordButton
                text: isRecording ? "Stop Recording" : "Record"
                height: 50
                width: 120
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: recordButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
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
                id: loadSoundButton
                text: "Load Sound"
                height: 50
                width: 120
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: loadSoundButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()
                    if (selectedIndex >= 0) {
                        const currentTick = sequencer.getCurrentTickQml()
                        trackModel.setProperty(selectedIndex, "hasWaveform", true)
                        trackModel.setProperty(selectedIndex, "waveformStart", currentTick)
                        trackModel.setProperty(selectedIndex, "waveformEnd", currentTick + 1000)
                        const waveformData = backend.loadSoundFile();
                        trackModel.setProperty(selectedIndex, "waveformData", waveformData);
                    }
                }
            }

            // Tempo Slider
            Slider {
                id: tempoSlider
                from: 60
                to: 180
                value: 120
                stepSize: 1
                width: 200
                height: 50
                onValueChanged: sequencer.setTempoQml(value)

                background: Rectangle {
                    x: tempoSlider.leftPadding
                    y: tempoSlider.topPadding + tempoSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: tempoSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: "#bdbebf"

                    Rectangle {
                        width: tempoSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#21be2b"
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: tempoSlider.leftPadding + tempoSlider.visualPosition * (tempoSlider.availableWidth - width)
                    y: tempoSlider.topPadding + tempoSlider.availableHeight / 2 - height / 2
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: tempoSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                    border.color: "#bdbebf"
                }
            }

            Text {
                text: "Tempo: " + tempoSlider.value + " BPM"
                height: 50
                font.pixelSize: 16
                color: "white"
                verticalAlignment: Text.AlignVCenter
            }

            CheckBox {
                id: loopingToggle
                text: "Enable Looping"
                font.pixelSize: 16
                onCheckedChanged: sequencer.setLooping(checked)
            }

            TextField {
                id: loopStartInput
                placeholderText: "Loop Start"
                width: 80
                height: 50
                font.pixelSize: 16
                onEditingFinished: updateLoopRange()
            }

            TextField {
                id: loopEndInput
                placeholderText: "Loop End"
                width: 80
                height: 50
                font.pixelSize: 16
                onEditingFinished: updateLoopRange()
            }

            function updateLoopRange() {
                sequencer.setLoopRange(
                    parseFloat(loopStartInput.text),
                    parseFloat(loopEndInput.text)
                )
            }
        }
    }

    // Main Content Area (Timeline and Track List)
    Rectangle {
        id: mainContent
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: "transparent"

        Row {
            anchors.fill: parent
            spacing: 10

            // Track Names Column
            Flickable {
    id: trackNamesScroll
    width: parent.width * 0.3
    height: parent.height
    contentHeight: trackColumn.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 2000

    Rectangle {
        anchors.fill: parent
        color: "#f7f7f7"
    }

    Column {
        id: trackColumn
        spacing: 10
        width: parent.width
        padding: 5

        Repeater {
            model: trackModel
            delegate: Rectangle {
                // Each track item has a fixed height, subtle border, and slight rounding.
                width: parent.width - 10  // leave some margin
                height: 60
                color: (index === sequencer.selectedTrackIndex) ? "#E3F2FD" : "#FFFFFF"
                border.color: "#B0BEC5"
                border.width: 1
                radius: 4

                Row {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Instrument Icon
                    Rectangle {
                        width: 60
                        height: 60
                        radius: 4
                        color: "#bdbdbd"
                        border.color: "#424242"
                        border.width: 1
                        Text {
                            text: "Inst"
                            anchors.centerIn: parent
                            font.pixelSize: 14
                            color: "#424242"
                        }
                    }

                    // Track Name (expands as needed)
                    Text {
                        text: model.name
                        font.pixelSize: 16
                        color: "#212121"
                        height: 60
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        // Using Layout.fillWidth if using a layout; otherwise it stretches by default.
                        // Alternatively, you could set width: parent.width - 40 - 40 - 40 - 8*3
                        // Here we let it fill the remaining space.
                        //Layout.fillWidth: true
                        width: parent.width - 60 - 60 - 60
                    }

                    // Mute Button
                    Rectangle {
                        width: 60
                        height: 60
                        radius: 4
                        color: model.mute ? "#E57373" : "#bdbdbd"
                        border.color: "#424242"
                        border.width: 1
                        Text {
                            text: "M"
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            color: model.mute ? "white" : "#424242"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: trackModel.setProperty(index, "mute", !model.mute)
                        }
                    }

                    // Solo Button
                    Rectangle {
                        width: 60
                        height: 60
                        radius: 4
                        color: model.solo ? "#FFF176" : "#bdbdbd"
                        border.color: "#424242"
                        border.width: 1
                        Text {
                            text: "S"
                            anchors.centerIn: parent
                            font.pixelSize: 16
                            color: model.solo ? "white" : "#424242"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: trackModel.setProperty(index, "solo", !model.solo)
                        }
                    }
                }

                // Allow tapping anywhere on the item to select the track.
                MouseArea {
                    anchors.fill: parent
                    onClicked: sequencer.setSelectedTrackIndexQml(index)
                }
            }
        }
    }

    // Sync scrolling with the timeline (if needed)
    onContentYChanged: {
        if (eventScroll && eventScroll.contentY !== contentY)
            eventScroll.contentY = contentY;
    }
}


            // Timeline Events Column
            Flickable {
                id: eventScroll
                width: parent.width * 0.7
                height: parent.height
                contentWidth: 2000
                contentHeight: trackModel.count * 70
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 2000

                Column {
                    spacing: 10
                    width: parent.width

                    Repeater {
                        model: trackModel
                        Rectangle {
                            width: parent.width
                            height: 60
                            color: "transparent"

                            // Recording Pattern Rectangle
                            Rectangle {
                                id: patternRect
                                color: "#EF5350"
                                radius: 2
                                height: 60
                                x: model.recordStart * pixelRate
                                width: (model.recordEnd - model.recordStart) * pixelRate
                                visible: model.recordEnd > model.recordStart
                                y: 5
                            }

                            // Waveform Box
                            Rectangle {
                                id: waveformBox
                                visible: model.hasWaveform
                                x: model.waveformStart * pixelRate
                                width: (model.waveformEnd - model.waveformStart) * pixelRate
                                height: 60
                                color: "#81C784"
                                radius: 2
                                y: 5

                                Canvas {
                                    id: waveformCanvas
                                    anchors.fill: parent
                                    antialiasing: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        if (!model.waveformData || model.waveformData.length === 0)
                                            return;
                                        let waveformPoints;
                                        try {
                                            waveformPoints = JSON.parse(model.waveformData);
                                        } catch (e) {
                                            return;
                                        }
                                        ctx.beginPath();
                                        ctx.strokeStyle = "#388E3C";
                                        ctx.lineWidth = 2;
                                        for (let i = 0; i < waveformPoints.length; i++) {
                                            const x = (i / (waveformPoints.length - 1)) * width;
                                            const y = (1 - (waveformPoints[i] + 1) / 2) * height;
                                            if (i === 0)
                                                ctx.moveTo(x, y);
                                            else
                                                ctx.lineTo(x, y);
                                        }
                                        ctx.stroke();
                                    }
                                    Connections {
                                        target: trackModel
                                        function onDataChanged() {
                                            if (index === sequencer.selectedTrackIndex)
                                                waveformCanvas.requestPaint();
                                        }
                                    }
                                }

                                // Left Handle
                                Rectangle {
                                    width: 20
                                    height: parent.height
                                    color: "#388E3C"
                                    radius: 2
                                    anchors.left: parent.left
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        propagateComposedEvents: false
                                        preventStealing: true
                                        property real pressX: 0
                                        property real initialStart: 0
                                        onPressed: {
                                            pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                            initialStart = model.waveformStart;
                                            eventScroll.interactive = false;
                                        }
                                        onPositionChanged: {
                                            if (pressed) {
                                                const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                                const delta = (currentX - pressX) / pixelRate;
                                                const newStart = Math.max(0, Math.round(initialStart + delta));
                                                if (newStart < model.waveformEnd)
                                                    trackModel.setProperty(index, "waveformStart", newStart);
                                            }
                                        }
                                        onReleased: eventScroll.interactive = true
                                        onClicked: mouse.accepted = true
                                    }
                                }

                                // Right Handle
                                Rectangle {
                                    width: 20
                                    height: parent.height
                                    color: "#388E3C"
                                    radius: 2
                                    anchors.right: parent.right
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeHorCursor
                                        propagateComposedEvents: false
                                        preventStealing: true
                                        property real pressX: 0
                                        property real initialEnd: 0
                                        onPressed: {
                                            pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                            initialEnd = model.waveformEnd;
                                            eventScroll.interactive = false;
                                        }
                                        onPositionChanged: {
                                            if (pressed) {
                                                const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                                const delta = (currentX - pressX) / pixelRate;
                                                const newEnd = Math.round(initialEnd + delta);
                                                if (newEnd > model.waveformStart)
                                                    trackModel.setProperty(index, "waveformEnd", newEnd);
                                            }
                                        }
                                        onReleased: eventScroll.interactive = true
                                        onClicked: mouse.accepted = true
                                    }
                                }

                                // Middle Drag Area (move waveform)
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
                                        pressX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                        initialX = waveformBox.x;
                                        eventScroll.interactive = false;
                                    }
                                    onPositionChanged: {
                                        if (pressed) {
                                            const currentX = mapToItem(eventScroll.contentItem, mouseX, 0).x;
                                            const delta = currentX - pressX;
                                            const newX = Math.max(0, initialX + delta);
                                            const newStart = Math.round(newX / pixelRate);
                                            const duration = model.waveformEnd - model.waveformStart;
                                            const newEnd = newStart + duration;
                                            if (newEnd * pixelRate <= eventScroll.contentWidth) {
                                                trackModel.setProperty(index, "waveformStart", newStart);
                                                trackModel.setProperty(index, "waveformEnd", newEnd);
                                            }
                                        }
                                    }
                                    onReleased: eventScroll.interactive = true
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
                    color: "#42A5F5"
                    x: playheadPosition
                }
                onContentYChanged: {
                    if (trackNamesScroll.contentY !== contentY)
                        trackNamesScroll.contentY = contentY;
                }
            }
        }
    }

    // Bottom Bar (Track management)
    Rectangle {
        id: bottomBar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 70
        color: Material.accent

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 40

            ComboBox {
                id: outputDeviceCombo
                model: backend.getAvailableMidiOutputDevices()
                height: 50
                font.pixelSize: 16
                onActivated: backend.openMidiOutputDevice(currentIndex)
            }

            TextField {
                id: renameField
                placeholderText: "New Name"
                width: 120
                height: 50
                font.pixelSize: 16
            }

            Button {
                id: renameButton
                text: "Rename Track"
                height: 50
                width: 120
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: renameButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
                onClicked: {
                    let selectedIndex = sequencer.getSelectedTrackIndexQml()
                    if (selectedIndex >= 0) {
                        trackModel.setProperty(selectedIndex, "name", renameField.text)
                        sequencer.renameTrackQml(selectedIndex, renameField.text)
                    }
                }
            }

            Button {
                id: addTrackButton
                text: "Add Track"
                height: 50
                width: 120
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: addTrackButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
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
                        "waveformData": "[]"
                    })
                    sequencer.addTrackQml(trackName)
                }
            }

            Button {
                id: removeTrackButton
                text: "Remove Selected Track"
                height: 50
                width: 150
                font.pixelSize: 16
                background: Rectangle {
                    radius: 2
                    color: removeTrackButton.down ? "#1976D2" : "#2196F3"
                    border.color: "#424242"
                    border.width: 1
                }
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
                if (selectedIndex >= 0)
                    trackModel.setProperty(selectedIndex, "recordEnd", tick)
            }
        }
    }
}
