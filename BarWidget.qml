import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "omakid.brightness-software"

  property int brightness: 100
  property int pendingBrightness: 100
  property int lastDispatched: -1
  property bool brightnessAvailable: true

  readonly property real gammaMin: 5
  readonly property real gammaMax: 100
  readonly property int stepSize: 5

  // ---------- Panel lifecycle (forwarded to Panel.qml) ----------
  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  // ---------- Brightness state ----------
  // hyprctl hyprsunset writes need the long-running hyprsunset process.
  // Auto-start it (same pattern as the first-party nightlight service)
  // whenever it is missing, so reads and writes don't go silently dead.
  function ensureCommand() {
    return "pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }; "
  }

  function clampValue(value) {
    return Model.clampBrightness(value, root.gammaMin, root.gammaMax)
  }

  function refresh() {
    if (!readProc.running) readProc.running = true
  }

  function dispatch(value) {
    root.lastDispatched = value
    writeProc.setting = true
    writeProc.command = ["bash", "-lc",
      root.ensureCommand() + "hyprctl hyprsunset gamma " + String(value)]
    writeProc.running = true
  }

  function setBrightness(value) {
    var clamped = root.clampValue(value)
    root.pendingBrightness = clamped
    root.brightness = clamped
    if (writeProc.running) return  // latest pendingBrightness dispatches on exit
    root.dispatch(clamped)
  }

  // Live slider feedback while dragging; commits through a short debounce so
  // dragging doesn't hammer hyprctl.
  function previewBrightness(value) {
    root.brightness = root.clampValue(value)
    brightnessDebounce.restart()
  }

  function commitBrightness(value) {
    brightnessDebounce.stop()
    root.setBrightness(value)
  }

  function adjust(direction) {
    root.setBrightness(root.brightness + (direction > 0 ? root.stepSize : -root.stepSize))
    root.showOsd()
  }

  function resetBrightness() {
    root.setBrightness(root.gammaMax)
    root.showOsd()
  }

  function showOsd() {
    if (!bar || !bar.shell) return
    bar.shell.summon("omarchy.osd", JSON.stringify({
      icon: "brightness",
      value: root.brightness
    }))
  }

  function statusText() {
    return root.brightnessAvailable ? Math.round(root.brightness) + "%" : "—"
  }

  function moodName() {
    return Model.brightnessName(root.brightness)
  }

  Process {
    id: readProc
    command: ["bash", "-lc", root.ensureCommand() + "hyprctl hyprsunset gamma"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = parseFloat(String(text || "").trim())
        if (!isFinite(value) || value <= 0) {
          root.brightnessAvailable = false
          return
        }
        root.brightnessAvailable = true
        root.brightness = root.clampValue(value)
        root.pendingBrightness = root.brightness
        root.lastDispatched = root.brightness
      }
    }
  }

  Process {
    id: writeProc
    property bool setting: false
    onExited: function() {
      writeProc.running = false
      if (!writeProc.setting) return
      writeProc.setting = false
      if (root.pendingBrightness !== root.lastDispatched) {
        root.dispatch(root.pendingBrightness)
      } else {
        root.refresh()
      }
    }
  }

  Timer {
    id: brightnessDebounce
    interval: 180
    repeat: false
    onTriggered: root.setBrightness(root.brightness)
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

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

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf185 " + root.statusText()
    fontSize: Style.font.caption
    tooltipText: "Software brightness (gamma)\nLeft click: open panel\nRight click: reset to 100%\nScroll: adjust"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.RightButton) root.resetBrightness()
    }
    onWheelMoved: function(delta) {
      root.adjust(delta > 0 ? 1 : -1)
    }
  }

  Component.onCompleted: root.refresh()
}