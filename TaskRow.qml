pragma ComponentBehavior: Bound

import QtQuick
import qs.Commons
import qs.Ui
import "Todos.js" as Todos

// Collapsed: title + priority. Expanded: read-only description.
// Editing: title, description, and priority fields.
Item {
  id: root

  required property var task
  property var priorityOptions: []

  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool expanded: false
  property bool editing: false

  readonly property string taskId: task && task.id ? String(task.id) : ""
  readonly property string title: task && task.title ? String(task.title) : ""
  readonly property string description: task && task.description ? String(task.description) : ""
  readonly property string priority: Todos.normalizePriority(task ? task.priority : "")
  readonly property bool completed: !!(task && task.completed)
  readonly property color accent: Todos.color(editing ? draftPriority : priority)

  property string draftTitle: ""
  property string draftDescription: ""
  property string draftPriority: "medium"

  signal toggleCompleted()
  signal removeRequested()
  signal expandToggled()
  signal editToggled()
  signal editRequested(string title, string description, string priority)

  implicitHeight: body.implicitHeight + Style.space(16)
  height: implicitHeight

  function loadDrafts() {
    draftTitle = title
    draftDescription = description
    draftPriority = priority
    if (titleEdit) titleEdit.text = title
    if (descEdit) descEdit.text = description
  }

  function commit() {
    var nextTitle = (titleEdit && root.editing) ? titleEdit.text : draftTitle
    var nextDescription = (descEdit && root.editing) ? descEdit.text : draftDescription
    nextTitle = Todos.trim(nextTitle)
    nextDescription = Todos.trim(nextDescription)
    if (nextTitle === "") {
      loadDrafts()
      return
    }
    draftTitle = nextTitle
    draftDescription = nextDescription
    if (nextTitle === title && nextDescription === description && draftPriority === priority)
      return
    root.editRequested(nextTitle, nextDescription, draftPriority)
  }

  onTaskChanged: if (!editing) loadDrafts()
  onEditingChanged: {
    if (editing) loadDrafts()
    else commit()
  }
  Component.onCompleted: loadDrafts()
  Component.onDestruction: if (editing) commit()

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(root.accent, root.completed ? 0.05 : 0.12)
    border.width: 1
    border.color: Util.alpha(root.accent, root.completed ? 0.18 : 0.32)
    opacity: root.completed ? 0.78 : 1
  }

  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: Style.space(1)
    anchors.bottomMargin: Style.space(1)
    width: Style.space(4)
    radius: width / 2
    color: root.accent
  }

  Item {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.leftMargin: Style.space(14)
    anchors.rightMargin: Style.space(8)
    anchors.topMargin: Style.space(8)
    anchors.bottomMargin: Style.space(8)
    implicitHeight: Math.max(check.height, copy.implicitHeight, actions.height)

    Item {
      id: check
      width: Style.space(20)
      height: Style.space(20)
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.topMargin: Style.space(1)

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.completed ? root.accent : (checkHover.hovered ? Util.alpha(root.accent, 0.18) : "transparent")
        border.width: 2
        border.color: root.accent

        Text {
          visible: root.completed
          anchors.centerIn: parent
          text: "\u2713"
          color: Color.background
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      HoverHandler {
        id: checkHover
        cursorShape: Qt.PointingHandCursor
      }

      TapHandler {
        onTapped: root.toggleCompleted()
      }
    }

    Column {
      id: copy
      anchors.left: check.right
      anchors.right: actions.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(8)
      spacing: Style.space(8)

      Row {
        visible: !root.editing
        width: parent.width
        spacing: Style.space(8)

        Rectangle {
          id: pill
          width: pillLabel.implicitWidth + Style.space(10)
          height: pillLabel.implicitHeight + Style.space(4)
          radius: height / 2
          anchors.verticalCenter: parent.verticalCenter
          color: Util.alpha(root.accent, 0.22)
          border.width: 1
          border.color: Util.alpha(root.accent, 0.55)

          Text {
            id: pillLabel
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: Todos.label(root.priority).toUpperCase()
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.6
          }
        }

        Text {
          textFormat: Text.PlainText
          width: Math.max(0, parent.width - pill.width - parent.spacing)
          anchors.verticalCenter: parent.verticalCenter
          text: root.title
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: !root.completed
          font.strikeout: root.completed
          elide: Text.ElideRight
          wrapMode: Text.NoWrap
        }
      }

      Text {
        visible: root.expanded && !root.editing
        width: parent.width
        textFormat: Text.PlainText
        text: root.description !== "" ? root.description : "No description"
        color: Qt.darker(root.foreground, root.description !== "" ? 1.45 : 1.7)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.italic: root.description === ""
        wrapMode: Text.Wrap
      }

      Column {
        visible: root.editing
        width: parent.width
        spacing: Style.space(8)

        TextField {
          id: titleEdit
          width: parent.width
          placeholderText: "Title"
          foreground: root.foreground
          font.family: root.fontFamily
          onTextChanged: if (root.editing) root.draftTitle = text
          onAccepted: root.commit()
          Keys.onEscapePressed: root.editToggled()
        }

        DescriptionArea {
          id: descEdit
          width: parent.width
          minLines: 2
          maxLines: 6
          placeholderText: "Short description  ·  Shift+Enter for a new line"
          foreground: root.foreground
          font.family: root.fontFamily
          onTextChanged: if (root.editing) root.draftDescription = text
          onSubmitted: root.commit()
          onEscapePressed: root.editToggled()
        }

        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.priorityOptions

            PriorityChip {
              required property var modelData
              priority: modelData.value
              selected: root.draftPriority === modelData.value
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: {
                root.draftPriority = modelData.value
                root.commit()
              }
            }
          }
        }
      }
    }

    Row {
      id: actions
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(2)

      PanelActionButton {
        iconText: root.expanded && !root.editing ? "\uF077" : "\uF078"
        tooltipText: root.expanded && !root.editing ? "Hide description" : "Show description"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.expandToggled()
      }

      PanelActionButton {
        iconText: "\uF040"
        tooltipText: root.editing ? "Close editor" : "Edit task"
        foreground: root.editing ? Color.accent : root.foreground
        fontFamily: root.fontFamily
        onClicked: root.editToggled()
      }

      PanelActionButton {
        iconText: "\u2715"
        tooltipText: "Remove task"
        foreground: root.foreground
        hoverColor: Color.urgent
        fontFamily: root.fontFamily
        onClicked: root.removeRequested()
      }
    }
  }
}
