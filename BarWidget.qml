import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Todos.js" as Todos

BarWidget {
  id: root
  moduleName: "dejan94.todos"

  readonly property bool opened: panelItem ? panelItem.opened === true : false
  readonly property int ongoingCount: panelItem ? (panelItem.ongoingCount || 0) : 0
  readonly property string highestOngoing: panelItem ? String(panelItem.highestOngoing || "") : ""
  readonly property color badgeColor: panelItem && panelItem.badgeColor ? panelItem.badgeColor : Color.accent

  function open() { if (panelItem) panelItem.open() }
  function close() { if (panelItem) panelItem.close() }
  function togglePanel() { if (panelItem) panelItem.toggle() }

  readonly property bool popoutSwitchClosing: panelItem ? panelItem.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelItem) panelItem.closeForPopoutSwitch() }

  property var panelItem: null

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    panelItem = target
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "dejan94.todos"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  Component {
    id: notepadIcon
    NotepadIcon {
      foreground: button.active && button.useActiveColor ? button.activeColor : button.foreground
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: notepadIcon
    tooltipText: Todos.badgeTooltip(root.ongoingCount, root.highestOngoing)
    active: root.highestOngoing === "critical" || root.opened
    activeColor: root.highestOngoing === "critical" ? root.badgeColor : (root.bar ? root.bar.urgent : Color.urgent)

    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
    }
  }

  Rectangle {
    id: countBadge
    visible: root.ongoingCount > 0
    anchors.top: button.top
    anchors.right: button.right
    z: 10
    implicitWidth: Math.max(Style.space(14), badgeLabel.implicitWidth + Style.space(6))
    implicitHeight: Style.space(14)
    radius: height / 2
    color: root.badgeColor
    border.width: 1
    border.color: root.bar ? root.bar.background : "transparent"

    Text {
      id: badgeLabel
      anchors.centerIn: parent
      text: root.ongoingCount > 9 ? "9+" : String(root.ongoingCount)
      color: "white"
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption * 0.85
      font.bold: true
    }
  }
}
