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
  readonly property string status: Todos.normalizeStatus(task ? task.status : "", task ? task.completed : false)
  readonly property bool completed: status === "complete"
  readonly property bool parked: status === "backlog"
  readonly property color accent: Todos.color(editing ? draftPriority : priority)

  property string draftTitle: ""
  property string draftDescription: ""
  property string draftPriority: "medium"

  signal toggleCompleted()
  signal statusRequested(string status)
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
    color: Util.alpha(root.foreground, root.completed ? 0.03 : 0.045)
    border.width: 1
    border.color: Util.alpha(root.foreground, 0.10)
    opacity: root.completed ? 0.78 : 1
  }

  Item {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(8)
    anchors.topMargin: Style.space(8)
    anchors.bottomMargin: Style.space(8)
    readonly property real firstRowHeight: Math.max(pill.height, check.height, actions.height)

    implicitHeight: headerBand.height
      + (root.editing ? extra.implicitHeight : 0)
      + ((root.expanded && !root.editing) ? extra.implicitHeight + Style.space(8) : 0)

    Item {
      id: check
      width: Style.space(20)
      height: Style.space(20)
      anchors.left: parent.left
      y: root.editing ? 0 : Math.round((body.firstRowHeight - height) / 2)

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

    Item {
      id: headerBand
      visible: !root.editing
      anchors.left: check.right
      anchors.right: actions.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(8)
      height: root.editing ? 0 : Math.max(
        body.firstRowHeight,
        titleLabel.y + titleLabel.height
      )

      Rectangle {
        id: pill
        x: 0
        y: Math.round((body.firstRowHeight - height) / 2)
        width: pillLabel.implicitWidth + Style.space(10)
        height: pillLabel.implicitHeight + Style.space(4)
        radius: height / 2
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
        id: titleLabel
        anchors.left: pill.right
        anchors.leftMargin: Style.space(8)
        anchors.right: parent.right
        y: {
          var line = implicitHeight / Math.max(1, lineCount)
          return Math.round((body.firstRowHeight - line) / 2)
        }
        height: implicitHeight
        textFormat: Text.PlainText
        text: root.title
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: !root.completed
        font.strikeout: root.completed
        wrapMode: Text.Wrap
        maximumLineCount: root.expanded && !root.editing ? 12 : 2
        elide: Text.ElideRight
        verticalAlignment: Text.AlignTop
      }
    }

    Column {
      id: extra
      anchors.left: check.right
      anchors.right: actions.left
      anchors.top: headerBand.bottom
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(8)
      anchors.topMargin: (root.expanded && !root.editing) ? Style.space(8) : 0
      spacing: Style.space(8)

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
      y: root.editing ? 0 : Math.round((body.firstRowHeight - height) / 2)
      spacing: Style.space(2)

      PanelActionButton {
        iconText: root.expanded && !root.editing ? "\uF077" : "\uF078"
        tooltipText: {
          if (root.expanded && !root.editing) return "Hide extra"
          return titleLabel.truncated ? "Show the rest" : "Show description"
        }
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.expandToggled()
      }

      PanelActionButton {
        visible: !root.completed
        iconText: root.parked ? "\uF04B" : "\uF04C"
        tooltipText: root.parked ? "Move to Ongoing" : "Move to Backlog"
        foreground: root.foreground
        fontFamily: root.fontFamily
        onClicked: root.statusRequested(root.parked ? "ongoing" : "backlog")
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
