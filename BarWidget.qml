import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "flexeq.audio"

  property int volumePercent: 0
  property bool muted: false
  property string backend: "Detecting audio…"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }
  function refresh() { readVolume.running = true; readMute.running = true; detectBackend.running = true }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  Component.onCompleted: refresh()

  Process {
    id: readVolume
    command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
    stdout: StdioCollector { onStreamFinished: {
      const match = text.match(/(\d+)%/)
      if (match) root.volumePercent = Number(match[1])
    } }
    onExited: function(code) { if (code !== 0) root.volumePercent = 0 }
  }
  Process {
    id: readMute
    command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]
    stdout: StdioCollector { onStreamFinished: root.muted = text.indexOf("yes") >= 0 }
  }
  Process {
    id: detectBackend
    command: ["sh", "-lc", "if command -v wpctl >/dev/null && wpctl status >/dev/null 2>&1; then echo PipeWire; elif command -v pactl >/dev/null && pactl info >/dev/null 2>&1; then echo PulseAudio; elif command -v amixer >/dev/null && amixer info >/dev/null 2>&1; then echo ALSA; else echo 'No audio server found'; fi"]
    stdout: StdioCollector { onStreamFinished: root.backend = text.trim() }
  }

  Timer { interval: 2500; running: true; repeat: true; onTriggered: { readVolume.running = true; readMute.running = true } }
  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "♫ " + (root.muted ? "—" : root.volumePercent + "%")
    tooltipText: "FlexEQ · " + root.backend
    onPressed: function(buttonCode) { if (buttonCode === Qt.LeftButton) root.toggle() }
  }
}
