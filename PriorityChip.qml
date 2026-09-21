pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui
import "Todos.js" as Todos

// Compact priority picker chip. The coloured dot stays visible whether or
// not the chip is selected, so Low / Medium / High / Critical can be told
// apart at a glance.
Item {
  id: root

  property string priority: "medium"
  property bool selected: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  readonly property color accent: Todos.color(priority)
  readonly property string caption: Todos.label(priority)

  signal clicked()

  implicitWidth: row.implicitWidth + Style.space(14)
  implicitHeight: Style.space(26)

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.selected
      ? Util.alpha(root.accent, 0.24)
      : (hover.hovered ? Util.alpha(root.accent, 0.10) : "transparent")
    border.width: 1
    border.color: root.selected ? root.accent : Util.alpha(root.accent, hover.hovered ? 0.7 : 0.42)

    Behavior on color { ColorAnimation { duration: 90 } }
    Behavior on border.color { ColorAnimation { duration: 90 } }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Rectangle {
      width: Style.space(8)
      height: width
      radius: width / 2
      anchors.verticalCenter: parent.verticalCenter
      color: root.accent
    }

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: root.caption
      color: root.selected ? root.foreground : Qt.darker(root.foreground, 1.15)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: root.selected
    }
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    onTapped: root.clicked()
  }
}
