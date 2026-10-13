import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Recent downloads: bar button + popup listing the last 10 files from
// XDG_DOWNLOAD_DIR (else ~/Downloads). Images show a thumbnail; other types
// show a large icon by extension. Each row has copy (path or image/png) and
// drag-out as text/uri-list. Refreshes while the popup is open so new
// downloads appear without closing the menu.
BarWidget {
  id: root
  moduleName: "samiriasbeck.downloads"

  property bool popupOpen: false
  property bool dragging: false
  property var files: []
  property string downloadDir: ""
  property string copiedPath: ""
  property double nowMs: Date.now()

  readonly property bool opened: popupOpen
  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family

  readonly property string listScript: [
    "[ -f \"$HOME/.config/user-dirs.dirs\" ] && . \"$HOME/.config/user-dirs.dirs\"",
    "dir=\"${XDG_DOWNLOAD_DIR:-$HOME/Downloads}\"",
    "printf 'DIR\\t%s\\n' \"$dir\"",
    "find \"$dir\" -maxdepth 1 -type f ! -name '.*' ! -name '*.crdownload' ! -name '*.part' -printf '%T@\\t%s\\t%p\\n' 2>/dev/null | sort -rn | head -n 10"
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
    if (dragging) return
    popupOpen = false
  }

  function toggle() {
    if (popupOpen) close()
    else open()
  }

  function isImagePath(path) {
    var lower = String(path || "").toLowerCase()
    return /\.(png|jpe?g|gif|webp|bmp|avif|svg)$/.test(lower)
  }

  function iconForPath(path) {
    var name = String(path || "").toLowerCase()
    var dot = name.lastIndexOf(".")
    var ext = dot >= 0 ? name.slice(dot + 1) : ""
    switch (ext) {
    case "pdf": return "󰈦"
    case "zip":
    case "7z":
    case "rar":
    case "tar":
    case "gz":
    case "xz": return "󰗄"
    case "mp4":
    case "mkv":
    case "webm":
    case "mov":
    case "avi": return "󰕧"
    case "mp3":
    case "flac":
    case "ogg":
    case "wav": return "󰎈"
    case "doc":
    case "docx":
    case "odt": return "󰈙"
    case "xls":
    case "xlsx":
    case "ods": return "󰈛"
    case "ppt":
    case "pptx": return "󰈧"
    case "txt":
    case "md": return "󰈙"
    case "json":
    case "yaml":
    case "yml":
    case "toml": return "󰘦"
    default: return "󰈔"
    }
  }

  function formatSize(bytes) {
    var n = Number(bytes)
    if (!isFinite(n) || n < 0) return ""
    if (n < 1024) return n + " B"
    if (n < 1048576) return (n / 1024).toFixed(n < 10240 ? 1 : 0) + " KB"
    if (n < 1073741824) return (n / 1048576).toFixed(n < 10485760 ? 1 : 0) + " MB"
    return (n / 1073741824).toFixed(1) + " GB"
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
      var rest = line.slice(tab + 1)
      if (key === "DIR") {
        dir = rest
        continue
      }
      var tab2 = rest.indexOf("\t")
      if (tab2 < 0) continue
      var sizeStr = rest.slice(0, tab2)
      var value = rest.slice(tab2 + 1)
      var ms = Math.round(Number(key) * 1000)
      if (!isFinite(ms) || value === "") continue
      out.push({
        path: value,
        name: value.slice(value.lastIndexOf("/") + 1),
        mtime: ms,
        size: Number(sizeStr)
      })
    }
    root.downloadDir = dir
    root.files = out
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

  function subtitleFor(item, copied) {
    if (copied) return "Copiado para a área de transferência"
    var parts = [root.ago(item.mtime)]
    var size = root.formatSize(item.size)
    if (size !== "") parts.push(size)
    return parts.join(" · ")
  }

  function copyFile(path) {
    if (root.isImagePath(path)) {
      Util.execArgv(["bash", "-c", "wl-copy --type image/png < \"$1\"", "downloads-copy-img", path])
    } else {
      Util.execArgv(["bash", "-c", "wl-copy \"$1\"", "downloads-copy-path", path])
    }
    root.copiedPath = path
    copiedTimer.restart()
  }

  function openFile(path) {
    Util.execArgv(["xdg-open", path])
    root.close()
  }

  function openFolder() {
    if (!root.downloadDir) return
    Util.execArgv(["uwsm-app", "--", "nautilus", "--new-window", root.downloadDir])
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

  Timer {
    id: liveRefresh
    interval: 2500
    repeat: true
    running: root.popupOpen && !root.dragging
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "samiriasbeck.downloads"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function list(): string { return JSON.stringify({ dir: root.downloadDir, open: root.popupOpen, files: root.files }) }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰇚"
    fontFamily: root.family
    fontSize: Style.font.body
    foreground: root.bar ? root.bar.barForeground : Color.bar.text
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: "Downloads recentes"
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
          text: "Downloads recentes"
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
          text: root.files.length > 0 ? root.files.length + " de 10 · arraste ou copie" : ""
          color: Qt.darker(root.fg, 1.4)
          font.family: root.family
          font.pixelSize: Style.font.caption
        }

        PanelActionButton {
          id: folderButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰉋"
          tooltipText: "Abrir pasta Downloads"
          foreground: root.fg
          fontFamily: root.family
          enabled: root.downloadDir !== ""
          onClicked: root.openFolder()
        }
      }

      Text {
        visible: root.files.length === 0
        width: parent.width
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        text: root.downloadDir !== "" ? "Nenhum arquivo em " + root.downloadDir : "Carregando…"
        color: Qt.darker(root.fg, 1.4)
        font.family: root.family
        font.pixelSize: Style.font.bodySmall
      }

      Repeater {
        model: root.files

        delegate: Item {
          id: row
          required property var modelData
          width: column.width
          height: Style.space(80)

          readonly property string path: modelData.path
          readonly property bool copied: root.copiedPath === row.path
          readonly property bool isImage: root.isImagePath(row.path)
          readonly property string fileIcon: root.iconForPath(row.path)

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
              visible: row.isImage
              anchors.fill: parent
              anchors.margins: 1
              source: row.isImage ? Util.fileUrl(row.path) : ""
              sourceSize.width: Style.space(256)
              asynchronous: true
              cache: false
              smooth: true
              fillMode: Image.PreserveAspectCrop
            }

            Text {
              visible: !row.isImage
              anchors.centerIn: parent
              text: row.fileIcon
              color: root.fg
              font.family: root.family
              font.pixelSize: Style.space(36)
            }

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
              onPressed: {
                if (row.isImage) {
                  thumb.grabToImage(function(result) { dragProxy.Drag.imageSource = result.url })
                } else {
                  dragProxy.Drag.imageSource = ""
                }
              }
              onClicked: root.openFile(row.path)
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
              text: root.subtitleFor(row.modelData, row.copied)
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
            tooltipText: row.isImage ? "Copiar imagem" : "Copiar caminho"
            foreground: row.copied ? Color.accent : root.fg
            fontFamily: root.family
            onClicked: root.copyFile(row.path)
          }
        }
      }
    }
  }
}
