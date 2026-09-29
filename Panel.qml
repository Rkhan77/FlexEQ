import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "flexeq.audio"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  property int volumePercent: hostWidget ? hostWidget.volumePercent : 0
  property bool muted: hostWidget ? hostWidget.muted : false
  property string backend: hostWidget ? hostWidget.backend : "Detecting audio…"
  property string defaultSink: "@DEFAULT_SINK@"
  property string statusText: ""

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function closeForPopoutSwitch() { root.close() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function") return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }
  function runPactl(args) { commandProc.command = ["pactl"].concat(args); commandProc.running = true }
  function refresh() { if (root.hostWidget) root.hostWidget.refresh(); sinkList.running = true; effectsCheck.running = true }
  Component.onCompleted: refresh()

  Process {
    id: commandProc
    command: ["pactl"]
    onExited: function(code) {
      root.statusText = code === 0 ? "Audio updated" : "Command failed · check audio service"
      if (root.hostWidget) root.hostWidget.refresh()
      statusTimer.restart()
    }
  }
  Process {
    id: sinkList
    command: ["pactl", "list", "short", "sinks"]
    stdout: StdioCollector { onStreamFinished: {
      sinkModel.clear()
      const lines = text.trim().split("\n")
      for (let i = 0; i < lines.length; i++) {
        const cols = lines[i].trim().split(/\s+/)
        if (cols.length > 1) sinkModel.append({ sinkId: cols[1], sinkName: cols.slice(1).join(" ") })
      }
    } }
  }
  Process {
    id: effectsCheck
    command: ["sh", "-lc", "command -v easyeffects >/dev/null 2>&1 && echo available || echo unavailable"]
    stdout: StdioCollector { onStreamFinished: root.effectsAvailable = text.trim() === "available" }
  }
  property bool effectsAvailable: false
  ListModel { id: sinkModel }
  Timer { id: statusTimer; interval: 1800; onTriggered: root.statusText = "" }
  Process { id: launchEffects; command: ["easyeffects"]; onExited: function(code) {} }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight
        clip: true
        Column {
          id: content
          width: parent.width
          spacing: Style.space(14)

          Row {
            width: parent.width
            spacing: 12
            Column {
              width: parent.width - refreshButton.width - 12
              Text { text: "FlexEQ"; color: root.barForeground; font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.title; font.bold: true }
              Text { text: "Audio control"; color: root.barForeground; opacity: 0.68; font.pixelSize: Style.font.bodySmall }
            }
            WidgetButton { id: refreshButton; bar: root.bar; text: "↻"; tooltipText: "Refresh audio status"; onPressed: root.refresh() }
          }

          Rectangle { width: parent.width; height: 1; color: root.barForeground; opacity: 0.16 }

          Column {
            width: parent.width
            spacing: 6
            Text { text: "OUTPUT VOLUME"; color: root.barForeground; opacity: 0.62; font.pixelSize: Style.font.caption; font.bold: true }
            Row {
              width: parent.width
              spacing: 10
              WidgetButton { bar: root.bar; text: root.muted ? "×" : "♫"; tooltipText: root.muted ? "Unmute" : "Mute"; onPressed: root.runPactl(["set-sink-mute", "@DEFAULT_SINK@", "toggle"]) }
              Slider {
                id: volumeSlider
                width: parent.width - 62
                from: 0; to: 100; value: root.volumePercent
                onMoved: root.runPactl(["set-sink-volume", "@DEFAULT_SINK@", Math.round(value) + "%"])
              }
              Text { width: 42; text: Math.round(volumeSlider.value) + "%"; color: root.barForeground; font.pixelSize: Style.font.body; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter }
            }
          }

          Column {
            width: parent.width
            spacing: 6
            Text { text: "OUTPUT DEVICE"; color: root.barForeground; opacity: 0.62; font.pixelSize: Style.font.caption; font.bold: true }
            Repeater {
              model: sinkModel
              delegate: Rectangle {
                required property string sinkId
                required property string sinkName
                width: parent.width; height: 36; radius: 8
                color: "transparent"
                border.width: 1; border.color: root.barForeground; opacity: 0.9
                Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 20; text: sinkName; elide: Text.ElideRight; color: root.barForeground; font.pixelSize: Style.font.bodySmall }
                MouseArea { anchors.fill: parent; onClicked: root.runPactl(["set-default-sink", sinkId]) }
              }
            }
          }

          Rectangle { width: parent.width; height: 1; color: root.barForeground; opacity: 0.16 }
          Row {
            width: parent.width
            spacing: 10
            Rectangle { width: 8; height: 8; radius: 4; anchors.verticalCenter: parent.verticalCenter; color: root.backend === "No audio server found" ? "#e06c75" : "#98c379" }
            Text { text: root.backend; color: root.barForeground; font.pixelSize: Style.font.bodySmall; verticalAlignment: Text.AlignVCenter }
          }
          Row {
            width: parent.width
            spacing: 8
            Text { text: "Equalizer"; color: root.barForeground; font.pixelSize: Style.font.body; verticalAlignment: Text.AlignVCenter; width: parent.width - openEffects.width - 8 }
            WidgetButton {
              id: openEffects
              bar: root.bar
              text: root.effectsAvailable ? "Open EasyEffects ↗" : "Install EasyEffects"
              tooltipText: root.effectsAvailable ? "Open EasyEffects to customize EQ" : "EasyEffects is not installed"
              interactive: root.effectsAvailable
              onPressed: if (root.effectsAvailable) launchEffects.running = true
            }
          }
          Text {
            width: parent.width
            text: root.effectsAvailable ? "Use EasyEffects for full parametric EQ, bands, and presets." : "Install EasyEffects for parametric EQ and presets. FlexEQ will detect it automatically."
            color: root.barForeground; opacity: 0.62; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap
          }
          Text { text: root.statusText; color: root.barForeground; opacity: root.statusText ? 0.8 : 0; font.pixelSize: Style.font.caption }
        }
      }
    }
  }
}
