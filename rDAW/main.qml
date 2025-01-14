import QtQuick 2.15
import QtQuick.Controls 2.15
import com.djdeck.midi 1.0

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "MIDI Input"

    MidiEngine {
        id: midiEngine
        onMidiMessageReceived: {
            messageLog.text += message + "\n";
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10

        TextArea {
            id: messageLog
            width: 600
            height: 400
            readOnly: true
        }

        Button {
            text: "Start Listening"
            onClicked: midiEngine.startMidiInput()
        }
    }
}
