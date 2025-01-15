import QtQuick 6.8
import QtQuick.Controls 6.8

ApplicationWindow {
    visible: true
    width: 1000
    height: 600
    title: "Dynamic Timeline - Fixed"

    ListModel {
        id: trackModel
    }

    Column {
        anchors.fill: parent

        // Track List Controls
        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: "Add Track"
                onClicked: {
                    let trackName = "Track " + (trackModel.count + 1);
                    trackModel.append({ "name": trackName }); // Ensure "name" is defined
                    console.log("Track added:", trackName);
                }
            }

            Button {
                text: "Remove Track"
                onClicked: {
                    if (trackModel.count > 0) {
                        trackModel.remove(trackModel.count - 1);
                        console.log("Last track removed.");
                    }
                }
            }
        }

        // Timeline
        Flickable {
            width: parent.width
            height: parent.height - 100
            contentWidth: 2000 // Scrollable horizontally
            contentHeight: trackModel.count * 60 // Dynamic height for track rows
            clip: true

            Column {
                width: 2000 // Match Flickable's contentWidth
                spacing: 10

                Repeater {
                    model: trackModel

                    Row {
                        spacing: 10
                        height: 50

                        // Track Name
                        Text {
                            text: model.name || "Unnamed Track" // Fallback to prevent undefined
                            width: 100
                            color: "black"
                        }

                        // Placeholder Events
                        Repeater {
                            model: 8 // Placeholder: 8 events per track
                            Rectangle {
                                width: 40
                                height: 40
                                color: "red"
                                border.color: "black"

                                Text {
                                    anchors.centerIn: parent
                                    text: index + 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
