import QtQuick
import qs.Commons

// Compact notepad + pen for the bar. Drawn, not a nerd-font glyph, so it
// cannot be mistaken for the old checklist icon at bar size.
Item {
  id: root
  property color foreground: Color.foreground

  Rectangle {
    id: paper
    x: Math.round(parent.width * 0.06)
    y: Math.round(parent.height * 0.08)
    width: Math.round(parent.width * 0.62)
    height: Math.round(parent.height * 0.84)
    radius: 1.5
    color: "transparent"
    border.width: 1.5
    border.color: root.foreground

    Repeater {
      model: 3
      Rectangle {
        required property int index
        width: Math.round(paper.width * 0.56)
        height: 1.2
        x: Math.round(paper.width * 0.22)
        y: Math.round(paper.height * (0.30 + index * 0.22))
        color: root.foreground
        opacity: 0.8
      }
    }
  }

  Item {
    width: Math.max(3, parent.width * 0.22)
    height: parent.height * 0.86
    anchors.right: parent.right
    anchors.rightMargin: parent.width * 0.02
    anchors.verticalCenter: parent.verticalCenter
    rotation: 42

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      width: Math.max(1.8, parent.width * 0.38)
      height: parent.height * 0.68
      radius: width / 2
      color: root.foreground
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: parent.height * 0.04
      width: Math.max(2.2, parent.width * 0.48)
      height: Math.max(2.2, parent.width * 0.48)
      rotation: 45
      color: root.foreground
    }
  }
}
