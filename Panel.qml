pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Todos.js" as Todos

Panel {
  id: root
  moduleName: "dejan94.todos"
  ipcTarget: "dejan94.todos"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string storePath: Quickshell.env("HOME") + "/.local/state/omarchy/todos.json"

  property var tasks: []
  property string query: ""
  property string draftPriority: "medium"
  property string activeTab: "ongoing"
  property var expandedIds: ({})
  property var editingIds: ({})

  readonly property var backlogTasks: Todos.listed(tasks, query, "backlog")
  readonly property var ongoingTasks: Todos.listed(tasks, query, "ongoing")
  readonly property var completeTasks: Todos.listed(tasks, query, "complete")
  readonly property var visibleTasks: Todos.listed(tasks, query, activeTab)
  readonly property int ongoingCount: Todos.ongoingCount(tasks)
  readonly property string highestOngoing: Todos.highestOngoing(tasks)
  readonly property color badgeColor: highestOngoing !== "" ? Todos.color(highestOngoing) : Color.accent
  readonly property var priorityOptions: Todos.priorityOptions()
  readonly property var tabOptions: Todos.tabOptions()
  readonly property string draftStatus: Todos.addStatusForTab(activeTab)

  readonly property bool formFocused: titleField.activeFocus
    || descriptionField.activeFocus
    || searchField.activeFocus
    || Object.keys(editingIds).length > 0

  property bool applyingOwnWrite: false
  property bool storeReady: false
  readonly property bool composerOpen: titleField.activeFocus
    || descriptionField.activeFocus
    || Todos.trim(titleField.text) !== ""

  function persist() {
    if (!root.storeReady) return
    applyingOwnWrite = true
    storeFile.setText(Todos.serialize(root.tasks, root.activeTab))
  }

  function addTask() {
    var status = root.draftStatus
    var task = Todos.createTask(titleField.text, descriptionField.text, root.draftPriority, status)
    if (!task.title) {
      titleField.forceActiveFocus()
      return
    }
    root.tasks = Todos.add(root.tasks, task)
    root.persist()
    root.activeTab = task.status
    titleField.text = ""
    descriptionField.text = ""
    Qt.callLater(function() { titleField.forceActiveFocus() })
  }

  function toggleCompleted(id, completed) {
    root.tasks = Todos.setCompleted(root.tasks, id, completed)
    root.persist()
  }

  function moveTask(id, status) {
    root.tasks = Todos.setStatus(root.tasks, id, status)
    root.persist()
  }

  function removeTask(id) {
    root.tasks = Todos.remove(root.tasks, id)
    root.persist()
  }

  function clearCompleted() {
    var next = Todos.removeCompleted(root.tasks)
    if (next === root.tasks) return
    root.tasks = next
    root.persist()
  }

  function editTask(id, title, description, priority) {
    var next = Todos.updateTask(root.tasks, id, title, description, priority)
    if (next === root.tasks) return
    root.tasks = next
    root.persist()
  }

  function isExpanded(id) {
    return !!root.expandedIds[id]
  }

  function isEditing(id) {
    return !!root.editingIds[id]
  }

  function toggleExpanded(id) {
    var expanded = Todos.cloneIdMap(root.expandedIds)
    var editing = Todos.cloneIdMap(root.editingIds)
    if (expanded[id]) {
      delete expanded[id]
      delete editing[id]
    } else {
      expanded[id] = true
    }
    root.expandedIds = expanded
    root.editingIds = editing
  }

  function toggleEditing(id) {
    var expanded = Todos.cloneIdMap(root.expandedIds)
    var editing = Todos.cloneIdMap(root.editingIds)
    if (editing[id]) {
      delete editing[id]
    } else {
      expanded[id] = true
      editing[id] = true
    }
    root.expandedIds = expanded
    root.editingIds = editing
  }

  function tabCount(value) {
    if (value === "complete") return root.completeTasks.length
    if (value === "backlog") return root.backlogTasks.length
    return root.ongoingTasks.length
  }

  function tabChipWidth() {
    var n = root.tabOptions.length
    return (tabRow.width - Style.space(3) * (n + 1)) / n
  }

  function startSearch() {
    searchField.forceActiveFocus()
    searchField.selectAll()
  }

  function startAdd() {
    Qt.callLater(function() { titleField.forceActiveFocus() })
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  onActiveTabChanged: {
    listFlick.contentY = 0
    if (root.storeReady) root.persist()
  }

  FileView {
    id: storeFile
    path: root.storePath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      if (root.applyingOwnWrite) {
        root.applyingOwnWrite = false
        return
      }
      var store = Todos.parseStore(text())
      root.tasks = store.tasks
      root.activeTab = store.activeTab
      root.storeReady = true
    }
    onLoadFailed: {
      root.applyingOwnWrite = false
      root.tasks = []
      root.storeReady = true
    }
    onFileChanged: if (!root.applyingOwnWrite) reload()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(580))
    // availableCardHeight can collapse to 120px when the bar window is
    // screen-sized. Measure the strip itself in that case.
    readonly property real usableCardHeight: {
      var screenH = panel.screenH
      var barH = panel.barH
      var strip = (root.bar && Number(root.bar.barSize) > 0) ? Number(root.bar.barSize) : 0
      if (screenH <= 0) return Style.space(640)
      if ((barH >= screenH || panel.availableCardHeight < Style.space(280)) && strip > 0)
        return Math.max(Style.space(400), screenH - (strip + panel.gap + panel.margin))
      return Math.max(panel.availableCardHeight, Style.space(400))
    }
    // Grow with the list, then scroll. Ceiling is 65% of the previous
    // full-height panel (~88% of usable, at least 640px).
    readonly property real maxCardHeight: Math.round(Math.min(
      usableCardHeight,
      Math.max(Style.space(640), Math.round(usableCardHeight * 0.88))
    ) * 0.65)
    contentHeight: Math.round(Math.min(
      panel.maxCardHeight,
      Math.max(panel.verticalContentInset, content.implicitHeight + panel.verticalContentInset)
    ))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.formFocused
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(text) {
        if (text === "/") root.startSearch()
        else if (text === "n" || text === "N") root.startAdd()
      }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) {
          root.activeTab = Todos.cycleTab(root.activeTab, dx)
          return
        }
        listFlick.flick(0, dy > 0 ? -900 : 900)
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        Item {
          id: header
          width: parent.width
          height: Math.max(headerTitle.implicitHeight, headerMeta.implicitHeight)

          Text {
            id: headerTitle
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: "Todo List"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            id: headerMeta
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: "n add  ·  / search"
            color: Qt.darker(root.contentForeground, 1.55)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }

        TextField {
          id: searchField
          width: parent.width
          placeholderText: "Search tasks"
          foreground: root.contentForeground
          font.family: root.contentFontFamily
          onTextChanged: root.query = text
          Keys.onEscapePressed: {
            if (text !== "") {
              text = ""
              root.query = ""
            } else {
              keyCatcher.forceActiveFocus()
            }
          }
          Keys.onDownPressed: listFlick.flick(0, -900)
          Keys.onUpPressed: listFlick.flick(0, 900)
        }

        Rectangle {
          id: tabRow
          width: parent.width
          height: Style.space(40)
          radius: Style.cornerRadius
          color: Util.alpha(root.contentForeground, 0.05)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.10)

          Row {
            anchors.fill: parent
            anchors.margins: Style.space(3)
            spacing: Style.space(3)

            Repeater {
              model: root.tabOptions

              TabChip {
                required property var modelData
                width: root.tabChipWidth()
                height: parent.height
                label: modelData.label
                count: root.tabCount(modelData.value)
                selected: root.activeTab === modelData.value
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onClicked: root.activeTab = modelData.value
              }
            }
          }
        }

        Flickable {
          id: listFlick
          width: parent.width
          readonly property int cap: {
            var chrome = header.height + searchField.implicitHeight + tabRow.height
                       + composer.implicitHeight + content.spacing * 4
            return Math.max(Style.space(72), Math.round(panel.maxCardHeight - panel.verticalContentInset - chrome))
          }
          height: Math.min(Math.max(listColumn.implicitHeight, Style.space(48)), cap)
          clip: true
          contentWidth: width
          contentHeight: listColumn.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: listColumn
            width: listFlick.width
            spacing: Style.space(8)

            Text {
              visible: root.visibleTasks.length === 0
              width: parent.width
              textFormat: Text.PlainText
              horizontalAlignment: Text.AlignHCenter
              topPadding: Style.space(12)
              bottomPadding: Style.space(12)
              wrapMode: Text.WordWrap
              text: Todos.emptyMessage(root.query, root.activeTab, root.tasks.length)
              color: Qt.darker(root.contentForeground, 1.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.italic: true
            }

            Repeater {
              model: root.visibleTasks

              TaskRow {
                required property var modelData
                width: parent.width
                task: modelData
                expanded: root.isExpanded(String(modelData.id || ""))
                editing: root.isEditing(String(modelData.id || ""))
                priorityOptions: root.priorityOptions
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                onToggleCompleted: root.toggleCompleted(taskId, !completed)
                onStatusRequested: function(status) { root.moveTask(taskId, status) }
                onRemoveRequested: root.removeTask(taskId)
                onExpandToggled: root.toggleExpanded(taskId)
                onEditToggled: root.toggleEditing(taskId)
                onEditRequested: function(title, description, priority) {
                  root.editTask(taskId, title, description, priority)
                }
              }
            }

            Item {
              visible: root.activeTab === "complete" && root.completeTasks.length > 0 && root.query === ""
              width: parent.width
              height: visible ? clearCompletedButton.implicitHeight + Style.space(16) : 0

              Button {
                id: clearCompletedButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: "Clear"
                tooltipText: "Remove every completed task"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                bordered: true
                onClicked: root.clearCompleted()
              }
            }
          }
        }

        Rectangle {
          id: composer
          width: parent.width
          implicitHeight: composerColumn.implicitHeight + Style.space(16)
          radius: Style.cornerRadius
          color: Util.alpha(root.contentForeground, 0.04)
          border.width: 1
          border.color: Util.alpha(root.contentForeground, 0.10)

          Column {
            id: composerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            spacing: Style.space(8)

            TextField {
              id: titleField
              width: parent.width
              placeholderText: root.draftStatus === "backlog" ? "Add to Backlog" : "Add a task"
              foreground: root.contentForeground
              font.family: root.contentFontFamily
              onAccepted: root.addTask()
              Keys.onEscapePressed: {
                if (Todos.trim(text) === "" && !descriptionField.activeFocus) {
                  text = ""
                  descriptionField.text = ""
                  keyCatcher.forceActiveFocus()
                } else {
                  keyCatcher.forceActiveFocus()
                }
              }
            }

            DescriptionArea {
              id: descriptionField
              visible: root.composerOpen
              width: parent.width
              foreground: root.contentForeground
              font.family: root.contentFontFamily
              placeholderText: "Short description  ·  Shift+Enter for a new line"
              onSubmitted: root.addTask()
              onEscapePressed: keyCatcher.forceActiveFocus()
            }

            Item {
              visible: root.composerOpen
              width: parent.width
              height: visible ? Math.max(chipRow.implicitHeight, addButton.implicitHeight) : 0

              Flow {
                id: chipRow
                anchors.left: parent.left
                anchors.right: addButton.left
                anchors.rightMargin: Style.space(10)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(6)

                Repeater {
                  model: root.priorityOptions

                  PriorityChip {
                    required property var modelData
                    priority: modelData.value
                    selected: root.draftPriority === modelData.value
                    foreground: root.contentForeground
                    fontFamily: root.contentFontFamily
                    onClicked: root.draftPriority = modelData.value
                  }
                }
              }

              Button {
                id: addButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Add"
                tooltipText: root.draftStatus === "backlog"
                  ? "Add to Backlog"
                  : "Add to Ongoing"
                foreground: root.contentForeground
                fontFamily: root.contentFontFamily
                bordered: true
                enabled: Todos.trim(titleField.text) !== ""
                onClicked: root.addTask()
              }
            }
          }
        }
      }
    }
  }
}
