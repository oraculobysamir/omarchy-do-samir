import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Recent screenshots: bar button + popup listing the last 10 captures from
// the Omarchy screenshot directory (OMARCHY_SCREENSHOT_DIR, else
// XDG_PICTURES_DIR, else ~/Pictures — same resolution as
// omarchy-capture-screenshot). Each row has a thumbnail, a copy button
// (wl-copy image/png) and can be dragged out as a file (text/uri-list).
//
// Drag-out note: PopupCard dismisses on outside clicks through a Hyprland
// focus grab, and that grab would swallow the drop on another app. While a
// drag is in flight the card switches to "hover" mode (grab off) and ignores
// close requests, so the pointer can carry the file onto any window.
BarWidget {
  id: root
  moduleName: "samiriasbeck.screenshots"

  property bool popupOpen: false
  property bool dragging: false
  property var shots: []
  property string shotDir: ""
  property string copiedPath: ""
  property double nowMs: Date.now()

  readonly property bool opened: popupOpen
  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family

  readonly property string listScript: [
    "[ -f \"$HOME/.config/user-dirs.dirs\" ] && . \"$HOME/.config/user-dirs.dirs\"",
    "dir=\"${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}\"",
    "printf 'DIR\\t%s\\n' \"$dir\"",
    "find \"$dir\" -maxdepth 1 -type f -iname '*screenshot*.png' -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -n 10"
  ].join("\n")

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    root.nowMs = Date.now()
    lister.running = false
    lister.running = true
  }

  function open() {
    refresh()
    popupOpen = true
  }

  function close() {
    // A drop onto another window must not be cut short by the focus grab
    // clearing or the bar coordinator asking us to close mid-drag.
    if (dragging) return
    popupOpen = false
  }

  function toggle() {
    if (popupOpen) close()
    else open()
  }

  function parseList(text) {
    var lines = String(text || "").split("\n")
    var out = []
    var dir = ""
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (!line) continue
      var tab = line.indexOf("\t")
      if (tab < 0) continue
      var key = line.slice(0, tab)
      var value = line.slice(tab + 1)
      if (key === "DIR") {
        dir = value
        continue
      }
      var ms = Math.round(Number(key) * 1000)
      if (!isFinite(ms) || value === "") continue
      out.push({ path: value, name: value.slice(value.lastIndexOf("/") + 1), mtime: ms })
    }
    root.shotDir = dir
    root.shots = out
  }

  function ago(ms) {
    var diff = Math.max(0, root.nowMs - ms) / 1000
    if (diff < 60) return "agora"
    if (diff < 3600) return "há " + Math.floor(diff / 60) + " min"
    var then = new Date(ms)
    var now = new Date(root.nowMs)
    if (then.toDateString() === now.toDateString()) return "hoje " + Qt.formatTime(then, "HH:mm")
    var yesterday = new Date(root.nowMs - 86400000)
    if (then.toDateString() === yesterday.toDateString()) return "ontem " + Qt.formatTime(then, "HH:mm")
    return Qt.formatDateTime(then, "dd/MM HH:mm")
  }

  function copyShot(path) {
    // argv only: the path lands in $1 and is never re-tokenized by a shell.
    Util.execArgv(["bash", "-c", "wl-copy --type image/png < \"$1\"", "screenshots-copy", path])
    root.copiedPath = path
    copiedTimer.restart()
  }

  function openShot(path) {
    Util.execArgv(["xdg-open", path])
    root.close()
  }

  function openFolder() {
    if (!root.shotDir) return
    Util.execArgv(["uwsm-app", "--", "nautilus", "--new-window", root.shotDir])
    root.close()
  }

  Process {
    id: lister
    command: ["bash", "-c", root.listScript]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseList(text)
    }
  }

  Timer {
    id: copiedTimer
    interval: 1600
    onTriggered: root.copiedPath = ""
  }

  IpcHandler {
    target: "samiriasbeck.screenshots"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function list(): string { return JSON.stringify({ dir: root.shotDir, open: root.popupOpen, shots: root.shots }) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰄀"
    fontFamily: root.family
    fontSize: Style.font.body
    foreground: root.bar ? root.bar.barForeground : Color.bar.text
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: "Screenshots recentes"
    onPressed: root.toggle()
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    triggerMode: root.dragging ? "hover" : "click"
    contentWidth: popup.fittedContentWidth(Style.space(440))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(6)

      Item {
        width: parent.width
        implicitHeight: Math.max(headerTitle.implicitHeight, folderButton.implicitHeight)

        Text {
          id: headerTitle
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: "Screenshots recentes"
          color: root.fg
          font.family: root.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          anchors.left: headerTitle.right
          anchors.leftMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.shots.length > 0 ? root.shots.length + " de 10 · arraste ou copie" : ""
          color: Qt.darker(root.fg, 1.4)
          font.family: root.family
          font.pixelSize: Style.font.caption
        }

        PanelActionButton {
          id: folderButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰉋"
          tooltipText: "Abrir pasta"
          foreground: root.fg
          fontFamily: root.family
          enabled: root.shotDir !== ""
          onClicked: root.openFolder()
        }
      }

      Text {
        visible: root.shots.length === 0
        width: parent.width
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        text: root.shotDir !== "" ? "Nenhum screenshot em " + root.shotDir : "Carregando…"
        color: Qt.darker(root.fg, 1.4)
        font.family: root.family
        font.pixelSize: Style.font.bodySmall
      }

      Repeater {
        model: root.shots

        delegate: Item {
          id: row
          required property var modelData
          width: column.width
          height: Style.space(80)

          readonly property string path: modelData.path
          readonly property bool copied: root.copiedPath === row.path

          HoverHandler { id: rowHover }

          Rectangle {
            anchors.fill: parent
            radius: Style.cornerRadius
            color: rowHover.hovered ? Style.hoverFillFor(root.fg, root.fg) : "transparent"
          }

          Item {
            id: thumbBox
            anchors.left: parent.left
            anchors.leftMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(128)
            height: Style.space(72)

            Rectangle {
              anchors.fill: parent
              radius: Style.cornerRadius
              color: Util.alpha(root.fg, 0.08)
            }

            Image {
              id: thumb
              anchors.fill: parent
              anchors.margins: 1
              source: Util.fileUrl(row.path)
              sourceSize.width: Style.space(256)
              asynchronous: true
              cache: false
              smooth: true
              fillMode: Image.PreserveAspectCrop
            }

            // Invisible proxy the MouseArea "moves"; its attached Drag carries
            // the file URI to whatever window the pointer drops on.
            Item {
              id: dragProxy
              width: thumbBox.width
              height: thumbBox.height
              Drag.active: dragArea.drag.active
              Drag.dragType: Drag.Automatic
              Drag.supportedActions: Qt.CopyAction
              Drag.proposedAction: Qt.CopyAction
              Drag.hotSpot.x: width / 2
              Drag.hotSpot.y: height / 2
              Drag.mimeData: ({
                "text/uri-list": Util.fileUrl(row.path) + "\r\n",
                "text/plain": row.path
              })
              Drag.onDragStarted: root.dragging = true
              Drag.onDragFinished: function(dropAction) {
                dragProxy.x = 0
                dragProxy.y = 0
                root.dragging = false
                if (dropAction !== Qt.IgnoreAction) root.close()
              }
            }

            MouseArea {
              id: dragArea
              anchors.fill: parent
              drag.target: dragProxy
              cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
              onPressed: thumb.grabToImage(function(result) { dragProxy.Drag.imageSource = result.url })
              onClicked: root.openShot(row.path)
            }
          }

          Column {
            anchors.left: thumbBox.right
            anchors.leftMargin: Style.space(10)
            anchors.right: copyButton.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(3)

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: row.modelData.name
              elide: Text.ElideMiddle
              color: root.fg
              font.family: root.family
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: row.copied ? "Copiado para a área de transferência" : root.ago(row.modelData.mtime)
              color: row.copied ? Color.accent : Qt.darker(root.fg, 1.4)
              font.family: root.family
              font.pixelSize: Style.font.caption
            }
          }

          PanelActionButton {
            id: copyButton
            anchors.right: parent.right
            anchors.rightMargin: Style.space(6)
            anchors.verticalCenter: parent.verticalCenter
            iconText: row.copied ? "󰄬" : "󰆏"
            tooltipText: "Copiar imagem"
            foreground: row.copied ? Color.accent : root.fg
            fontFamily: root.family
            onClicked: root.copyShot(row.path)
          }
        }
      }
    }
  }
}
