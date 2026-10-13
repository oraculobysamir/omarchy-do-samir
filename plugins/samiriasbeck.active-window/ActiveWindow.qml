import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "samiriasbeck.active-window"

  property string label: ""

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property int maxLabelWidth: Number(setting("maxWidth", 280))
  readonly property real sidePad: Style.spacing.controlPaddingX * 2
  readonly property string resolver: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/samiriasbeck.window-titles/resolve-apps.py"

  visible: label !== "" && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, Math.ceil(metrics.advanceWidth)) + sidePad : 0
  implicitHeight: barSize

  function refresh() {
    if (!nameProbe.running)
      nameProbe.running = true
  }

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  TextMetrics {
    id: metrics
    text: root.label
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
  }

  Process {
    id: nameProbe
    command: ["python3", root.resolver, "--active"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").trim()
        if (next !== root.label)
          root.label = next
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (!name) return
      if (name === "activewindow" || name === "activewindowv2"
          || name === "windowtitle" || name === "windowtitlev2"
          || name === "openwindow" || name === "closewindow"
          || name === "workspace" || name === "workspacev2") {
        refreshTimer.restart()
      }
    }
  }

  Connections {
    target: root.toplevel
    function onTitleChanged() { refreshTimer.restart() }
  }

  onToplevelChanged: refreshTimer.restart()

  Timer {
    id: refreshTimer
    interval: 60
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.refresh()

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    clip: true

    Text {
      id: labelText
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      width: parent.width
      text: root.label
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
      opacity: 0.85
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
        root.toplevel.close()
      } else {
        root.toplevel.activate()
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.label)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
