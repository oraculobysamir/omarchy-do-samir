import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Use WidgetButton (same as omarchy.clock) so the glyph paints with the
// identical foreground / font path as the time label — BarIconButton's
// OpticalGlyph was reading much darker next to the clock.
BarWidget {
  id: root
  moduleName: "samiriasbeck.lock-button"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function lockNow() {
    Quickshell.execDetached(["omarchy-system-lock"])
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌾"
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    fontSize: Style.font.body
    foreground: root.bar ? root.bar.barForeground : Color.bar.text
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: "Bloquear tela (Super+Ctrl+L)"
    onPressed: root.lockNow()
  }
}
