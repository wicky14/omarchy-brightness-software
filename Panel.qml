import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omakid.brightness-software"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(360))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.hostWidget) return
        if (dy !== 0) return
        if (dx > 0) root.hostWidget.adjust(1)
        else if (dx < 0) root.hostWidget.adjust(-1)
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        // ---------- Hero: sun icon · title / mood ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "\uf185"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Software Brightness"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              id: moodLabel
              textFormat: Text.PlainText
              text: (root.hostWidget ? root.hostWidget.moodName() : "Even day").toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
        }

        // ---------- Brightness slider ----------
        Column {
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(sliderHeader.implicitHeight, sliderPercent.implicitHeight)

            PanelSectionHeader {
              id: sliderHeader
              text: "BRIGHTNESS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: sliderPercent
              textFormat: Text.PlainText
              text: Math.round(slider.dragging ? slider.liveValue : slider.value) + "%"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            id: sliderRow
            width: parent.width
            height: slider.implicitHeight + Style.spacing.controlGap
            hasCursor: hoverHandler.hovered
            foreground: root.bar.foreground
            outline: true

            PanelSlider {
              id: slider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: root.hostWidget ? root.hostWidget.gammaMin : 5
              maximum: root.hostWidget ? root.hostWidget.gammaMax : 100
              step: 1
              integer: true
              value: root.hostWidget ? root.hostWidget.brightness : 100
              onMoved: function(v) {
                if (root.hostWidget) root.hostWidget.previewBrightness(v)
              }
              onReleased: function(v) {
                if (root.hostWidget) root.hostWidget.commitBrightness(v)
              }
            }

            HoverHandler {
              id: hoverHandler
            }
          }
        }

        Item {
          width: parent.width
          height: Style.space(4)
        }
      }
    }
  }
}