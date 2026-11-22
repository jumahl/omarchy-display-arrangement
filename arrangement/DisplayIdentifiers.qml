import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons as C
import "DisplayLabels.js" as Labels

Variants {
    id: identifiers
    property var rows: []
    function show() { timeout.restart() }

    model: timeout.running ? Quickshell.screens : []
    property Timer timeout: Timer { interval: 3000 }

    delegate: Component {
        PanelWindow {
            id: badge
            required property var modelData
            readonly property int number: Labels.displayNumber(identifiers.rows, modelData.name)
            screen: modelData
            visible: number > 0
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Rectangle {
                anchors.centerIn: parent
                width: Math.max(C.Style.space(104), label.implicitWidth + C.Style.space(32))
                height: C.Style.space(104)
                radius: C.Style.space(12)
                color: C.Color.background
                border.color: C.Color.accent
                border.width: 2

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: C.I18n.formatNumber(badge.number)
                    textFormat: Text.PlainText
                    color: C.Color.foreground
                    font.family: C.Style.font.family
                    font.pixelSize: C.Style.space(56)
                    font.bold: true
                }
            }
        }
    }
}
