import QtQuick
import Quickshell
import qs.Commons as C
import "DisplayLabels.js" as Labels
import "Layout.js" as Geometry

Rectangle {
    id: map
    property var rows: []
    property bool movable: false
    property color foreground: "white"
    property color accent: "white"
    property color tileColor: "#222"
    property string builtInLabel: ""
    property string fontFamily: ""
    property real labelSize: 12
    signal moved(int index, var position)

    readonly property real minX: rows.length ? Math.min(...rows.map(r => r.x)) : 0
    readonly property real minY: rows.length ? Math.min(...rows.map(r => r.y)) : 0
    readonly property real maxX: rows.length ? Math.max(...rows.map(r => r.x+r.w)) : 1
    readonly property real maxY: rows.length ? Math.max(...rows.map(r => r.y+r.h)) : 1
    readonly property real wide: Math.max(1, ...rows.map(r => r.w))
    readonly property real tall: Math.max(1, ...rows.map(r => r.h))
    // Reserve enough room to carry a tile's center past the neighboring display.
    readonly property real unit: Math.max(0.001, Math.min(
        Math.max(1, width-20) / (maxX-minX+(rows.length > 1 ? wide : 0)),
        Math.max(1, height-20) / (maxY-minY+(rows.length > 1 ? tall : 0))))
    readonly property real originX: (width-(maxX+minX)*unit)/2
    readonly property real originY: (height-(maxY+minY)*unit)/2

    radius: 5
    clip: true
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    Repeater {
        model: map.rows.length
        Rectangle {
            id: tile
            required property int index
            readonly property var row: map.rows[index]
            property var preview: null
            readonly property var shown: preview ?? row
            x: map.originX + shown.x*map.unit
            y: map.originY + shown.y*map.unit
            width: row.w*map.unit
            height: row.h*map.unit
            z: pointer.pressed ? 1 : 0
            radius: 4
            border.color: pointer.pressed ? map.accent : map.foreground
            color: map.tileColor

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 4
                width: Math.max(0, parent.width - 8)
                spacing: 2
                readonly property string modelName: Labels.displayModel(Quickshell.screens, tile.row.name)
                    || (Labels.isBuiltIn(tile.row.name) ? map.builtInLabel : "")

                Text {
                    width: parent.width
                    visible: text !== "" && tile.height >= map.labelSize * 3
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: parent.modelName
                    textFormat: Text.PlainText
                    color: map.foreground
                    font.family: map.fontFamily
                    font.pixelSize: map.labelSize
                    font.bold: true
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: C.I18n.formatNumber(Labels.displayNumber(map.rows, tile.row.name)) + " · " + tile.row.name
                    textFormat: Text.PlainText
                    color: map.foreground
                    font.family: map.fontFamily
                    font.pixelSize: map.labelSize
                }
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                enabled: map.movable
                preventStealing: true
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property point pressedAt
                property bool movedEnough: false

                function position(mouse) {
                    const p = mapToItem(map, mouse.x, mouse.y)
                    if (Math.hypot(p.x-pressedAt.x,p.y-pressedAt.y) >= 3)
                        movedEnough = true
                    if (!movedEnough) return null
                    return Geometry.snap(map.rows, tile.index,
                        tile.row.x+(p.x-pressedAt.x)/map.unit,
                        tile.row.y+(p.y-pressedAt.y)/map.unit)
                }

                onPressed: mouse => {
                    pressedAt = mapToItem(map, mouse.x, mouse.y)
                    movedEnough = false
                }
                onPositionChanged: mouse => {
                    if (pressed) tile.preview = position(mouse)
                }
                onReleased: mouse => {
                    const finalPosition = position(mouse)
                    tile.preview = null
                    if (finalPosition) map.moved(tile.index, finalPosition)
                }
                onCanceled: tile.preview = null
            }
        }
    }
}
