import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

Item {
  id: root

  // address -> { app, class, title, pid } from resolve-apps.py
  property var appByAddress: ({})
  property int geometryTick: 0
  property int namesTick: 0

  readonly property string resolver: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/samiriasbeck.window-titles/resolve-apps.py"

  function refreshGeometry() {
    Hyprland.refreshToplevels()
    geometryTick++
    if (!nameProbe.running) nameProbe.running = true
  }

  function labelFor(toplevel) {
    if (!toplevel) return ""
    var ipc = toplevel.lastIpcObject || {}
    var addr = String(toplevel.address || "")
    // Touch namesTick so labels refresh when the probe finishes.
    var _names = root.namesTick
    var mapped = root.appByAddress[addr]
    if (mapped && mapped.app) return String(mapped.app)

    // Fallback before the probe returns: class aliases only (never raw chat title alone).
    var cls = String(ipc["class"] || ipc.initialClass || "")
    if (cls === "org.telegram.desktop" || cls.toLowerCase().indexOf("telegram") !== -1)
      return "Telegram"
    if (cls === "org.omarchy.agent") return "Agent"
    if (cls === "google-chrome" || cls.indexOf("chrome-") === 0) return "Chrome"
    if (cls === "org.remmina.Remmina") return "Remmina"
    var parts = cls.split(".")
    var last = parts.length ? parts[parts.length - 1] : cls
    if (!last || last.toLowerCase() === "desktop") {
      if (parts.length >= 2) last = parts[parts.length - 2]
    }
    if (!last) return "App"
    return last.charAt(0).toUpperCase() + last.slice(1)
  }

  function windowsForMonitor(mon) {
    var _tick = root.geometryTick
    var _names = root.namesTick
    if (!mon || !mon.activeWorkspace || !mon.activeWorkspace.toplevels)
      return []

    var values = mon.activeWorkspace.toplevels.values
    var out = []
    for (var i = 0; i < values.length; i++) {
      var t = values[i]
      if (!t) continue
      var ipc = t.lastIpcObject || {}
      if (ipc.mapped === false || ipc.hidden === true) continue
      if (Number(ipc.fullscreen || 0) > 0) continue
      if (!Array.isArray(ipc.at) || !Array.isArray(ipc.size)) continue
      if (ipc.size[0] < 120 || ipc.size[1] < 80) continue

      var text = labelFor(t)
      if (!text) continue

      var scale = Number(mon.scale || 1)
      if (!(scale > 0)) scale = 1

      out.push({
        address: String(t.address || i),
        text: text,
        active: !!t.activated,
        x: (Number(ipc.at[0]) - Number(mon.x || 0)) / scale,
        y: (Number(ipc.at[1]) - Number(mon.y || 0)) / scale,
        w: Number(ipc.size[0]) / scale,
        h: Number(ipc.size[1]) / scale
      })
    }
    return out
  }

  Process {
    id: nameProbe
    command: ["python3", root.resolver]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          if (parsed && !parsed.error) {
            root.appByAddress = parsed
            root.namesTick++
          }
        } catch (e) {}
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (!name) return
      if (name === "openwindow" || name === "closewindow" || name === "movewindow"
          || name === "movewindowv2" || name === "resizewindow" || name === "resizewindowv2"
          || name === "activewindow" || name === "activewindowv2"
          || name === "workspace" || name === "workspacev2"
          || name === "fullscreen" || name === "changefloatingmode"
          || name === "windowtitle" || name === "windowtitlev2") {
        refreshTimer.restart()
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 80
    repeat: false
    onTriggered: root.refreshGeometry()
  }

  Timer {
    interval: 1200
    running: true
    repeat: true
    onTriggered: root.refreshGeometry()
  }

  Component.onCompleted: root.refreshGeometry()

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData

        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        surfaceFormat.opaque: false
        WlrLayershell.namespace: "omarchy-window-titles"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
        readonly property var winList: root.windowsForMonitor(hyprMonitor)
        readonly property bool showLabels: winList.length >= 2

        Repeater {
          model: panel.showLabels ? panel.winList : []

          delegate: Item {
            id: chip
            required property var modelData

            x: modelData.x + Style.space(8)
            y: modelData.y + Style.space(6)
            width: Math.min(label.implicitWidth + Style.space(14), Math.max(40, modelData.w - Style.space(16)))
            height: label.implicitHeight + Style.space(6)
            opacity: modelData.active ? 0.92 : 0.55
            z: modelData.active ? 2 : 1

            Rectangle {
              anchors.fill: parent
              radius: Style.space(4)
              color: Util.alpha(Color.background, modelData.active ? 0.72 : 0.55)
              border.width: 1
              border.color: Util.alpha(Color.foreground, modelData.active ? 0.18 : 0.10)
            }

            Text {
              id: label
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: Style.space(7)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(7)
              text: modelData.text
              color: modelData.active ? Color.foreground : Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.weight: modelData.active ? Font.DemiBold : Font.Normal
              elide: Text.ElideRight
              textFormat: Text.PlainText
            }
          }
        }
      }
    }
  }
}
