import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Multiline description editor matching the kit TextField chrome.
// Two rows at rest; Shift+Enter inserts a newline and the field grows.
TextArea {
  id: root

  property color foreground: Color.foreground
  property color accent: Color.accent
  property color selectionTint: Style.selectionFillFor(foreground, accent)
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.inputPaddingY
  property int minLines: 2
  property int maxLines: 8

  signal submitted()
  signal escapePressed()

  wrapMode: TextEdit.Wrap
  selectByMouse: true
  font.family: Style.font.family
  font.pixelSize: Style.font.body
  color: foreground
  selectionColor: selectionTint
  selectedTextColor: foreground
  placeholderText: "Short description"
  placeholderTextColor: Qt.darker(foreground, 1.6)

  readonly property bool _focused: activeFocus
  readonly property bool _hot: hover.hovered || _focused
  readonly property var _borderSpec: Border.controlSpec(_focused ? "focus" : (_hot ? "hover-cursor" : "normal"), root.foreground, root.accent)
  readonly property real linePitch: Math.ceil(font.pixelSize * 1.45)
  readonly property real minHeight: minLines * linePitch + topPadding + bottomPadding
  readonly property real maxHeight: maxLines * linePitch + topPadding + bottomPadding

  leftPadding: horizontalPadding + Border.left(_borderSpec)
  rightPadding: horizontalPadding + Border.right(_borderSpec)
  topPadding: verticalPadding + Border.top(_borderSpec)
  bottomPadding: verticalPadding + Border.bottom(_borderSpec)

  implicitHeight: Math.min(maxHeight, Math.max(minHeight, contentHeight + topPadding + bottomPadding))
  height: implicitHeight

  background: BorderSurface {
    color: Style.controlFill(root._focused, root._hot, root.foreground, root.accent)
    borderSpec: root._borderSpec
    radius: Style.cornerRadius
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.IBeamCursor
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.escapePressed()
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (event.modifiers & Qt.ShiftModifier) {
        root.insert(root.cursorPosition, "\n")
        event.accepted = true
      } else {
        root.submitted()
        event.accepted = true
      }
    }
  }
}
