import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons as C
import "Layout.js" as Geometry

ColumnLayout {
    id: root
    property var rows: []
    property var initialRows: []
    property string computerVendor: ""
    property bool hasMirror: false
    property string operationStatus: ""
    readonly property bool dirty: JSON.stringify(rows) !== JSON.stringify(initialRows)
    readonly property string helper: Qt.resolvedUrl("layout.py").toString().replace(/^(?:file|qs):\/\//, "")
    Component.onCompleted: {
        refresh()
        readVendor.running = true
    }
    function refresh() {
        if (!read.running && !save.running) read.running = true
    }
    C.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    Process {
        id: readVendor
        command: ["/usr/bin/cat", "/sys/class/dmi/id/sys_vendor"]
        stdout: StdioCollector { id: vendorOutput }
        onExited: (code) => {
            if (code === 0) root.computerVendor = vendorOutput.text.trim()
        }
    }
    Process {
        id: read
        command: ["/usr/bin/python", root.helper, "read"]
        stdout: StdioCollector { id: output }
        onExited: (code) => {
            if (code !== 0) { root.operationStatus = "error"; root.rows = []; root.initialRows = []; return }
            const result = JSON.parse(output.text)
            root.rows = result.rows
            root.initialRows = result.rows
            root.hasMirror = result.mirrored
        }
    }
    Process {
        id: save
        onExited: (code) => {
            root.operationStatus = code === 0 ? "saved" : "error"
            root.refresh()
        }
    }
    spacing: C.Style.space(8)
    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        color: C.Color.foreground
        font.family: C.Style.font.family
        font.pixelSize: C.Style.font.body
        text: strings.tn("count",root.rows.length).arg(C.I18n.formatNumber(root.rows.length))
              + " · " + strings.t(root.hasMirror ? "mirrored" : root.rows.length < 2 ? "single" : "drag")
    }
    MonitorMap {
        Layout.fillWidth: true
        Layout.preferredHeight: C.Style.space(160)
        rows: root.rows
        builtInLabel: root.computerVendor ? strings.t("builtInVendor").arg(root.computerVendor)
                                          : strings.t("builtIn")
        movable: rows.length > 1 && !root.hasMirror && !save.running && !read.running
        fontFamily: C.Style.font.family
        labelSize: C.Style.font.body
        color: C.Color.background
        foreground: C.Color.foreground
        accent: C.Color.accent
        tileColor: C.Style.hoverFillFor(foreground, accent)
        border.color: Qt.alpha(foreground, 0.35)
        onMoved: (index, position) => {
            const next = root.rows.slice()
            next[index] = position
            root.rows = next
            root.operationStatus = ""
        }
    }
    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.operationStatus ? strings.t(root.operationStatus) :
               root.dirty && !Geometry.valid(root.rows) ? strings.t("invalid") : ""
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        color: C.Color.foreground
        font.family: C.Style.font.family
        font.pixelSize: C.Style.font.body
    }
    DisplayIdentifiers {
        id: identifiers
        rows: root.initialRows
    }
    Flow {
        Layout.fillWidth: true
        spacing: C.Style.space(8)
        Ui.Button {
            bordered: true
            focusable: true
            text: strings.t("reset")
            enabled: !save.running && !read.running
            onClicked: { root.operationStatus = ""; root.refresh() }
        }
        Ui.Button {
            bordered: true
            focusable: true
            text: strings.t("identify")
            enabled: root.rows.length > 0 && !save.running && !read.running
            onClicked: identifiers.show()
        }
        Ui.Button {
            bordered: true
            focusable: true
            text: strings.t("save")
            enabled: root.dirty && Geometry.valid(root.rows) && !root.hasMirror && !read.running && !save.running
            onClicked: {
                root.operationStatus = ""
                save.command = ["/usr/bin/python",root.helper,"save",
                                JSON.stringify(root.initialRows),JSON.stringify(root.rows)]
                save.running = true
            }
        }
    }
}
