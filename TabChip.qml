pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property string label
  required property int count
  property bool selected: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal clicked()

  Rectangle {
    anchors.fill: parent
    radius: Math.max(2, Style.cornerRadius - 1)
    color: root.selected
      ? Util.alpha(Color.accent, 0.22)
      : (hover.hovered ? Util.alpha(root.foreground, 0.08) : "transparent")

    Rectangle {
      visible: root.selected
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(6)
      height: 2
      radius: 1
      color: Color.accent
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      textFormat: Text.PlainText
      text: root.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: root.selected
      anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
      width: Math.max(Style.space(18), countLabel.implicitWidth + Style.space(8))
      height: Style.space(18)
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter
      color: root.selected ? Util.alpha(Color.accent, 0.35) : Util.alpha(root.foreground, 0.10)

      Text {
        id: countLabel
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: String(root.count)
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
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
