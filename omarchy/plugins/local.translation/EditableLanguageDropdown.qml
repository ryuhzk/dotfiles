import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
  id: root

  property alias text: input.text
  property string placeholderText: ""
  property var options: []
  property color foreground: Color.foreground
  property color background: Color.popups.background
  property color popupBorder: Color.popups.border
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property bool popupOpen: popup.opened
  readonly property var popupBorderSpec: Border.localOrSurfaceSpec(
    "popups",
    "border",
    popupBorder,
    Color.popups.border,
    Style.normalBorderWidth
  )

  signal selected(string language)
  signal closeRequested()

  function open() {
    popup.open()
  }

  function close() {
    popup.close()
  }

  function toggle() {
    popup.opened ? popup.close() : popup.open()
  }

  implicitHeight: input.implicitHeight

  TextField {
    id: input
    anchors.left: parent.left
    anchors.right: dropdownButton.left
    anchors.rightMargin: Style.space(4)
    anchors.verticalCenter: parent.verticalCenter
    placeholderText: root.placeholderText
    foreground: root.foreground

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_F4 ||
          (event.key === Qt.Key_Down && event.modifiers & Qt.AltModifier)) {
        root.toggle()
        event.accepted = true
      } else if (event.key === Qt.Key_Escape) {
        if (popup.opened) popup.close()
        else root.closeRequested()
        event.accepted = true
      }
    }
  }

  Button {
    id: dropdownButton
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: input.implicitHeight
    height: input.implicitHeight
    iconText: popup.opened ? "󰅃" : "󰅀"
    bordered: true
    tooltipText: "Common target languages"
    onClicked: root.toggle()
  }

  Popup {
    id: popup
    x: 0
    y: root.height + Style.spacing.xxs
    width: root.width
    implicitHeight: optionList.contentHeight +
      topPadding + bottomPadding
    padding: Style.spacing.hairline
    leftPadding: Border.left(root.popupBorderSpec) + Style.spacing.hairline
    rightPadding: Border.right(root.popupBorderSpec) + Style.spacing.hairline
    topPadding: Border.top(root.popupBorderSpec) + Style.spacing.hairline
    bottomPadding: Border.bottom(root.popupBorderSpec) + Style.spacing.hairline
    focus: true

    background: BorderSurface {
      color: root.background
      borderSpec: root.popupBorderSpec
      radius: Style.cornerRadius
    }

    onOpened: {
      optionList.currentIndex = 0
      optionList.forceActiveFocus()
    }

    contentItem: ListView {
      id: optionList
      implicitHeight: contentHeight
      spacing: Style.spacing.labelGap
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: root.options
      currentIndex: -1

      function selectCurrent() {
        if (currentIndex < 0 || currentIndex >= root.options.length) return
        var option = root.options[currentIndex]
        root.text = String(option.language)
        root.selected(String(option.language))
        popup.close()
        input.forceActiveFocus()
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          popup.close()
          input.forceActiveFocus()
          event.accepted = true
        } else if (event.key === Qt.Key_Down || event.text === "j") {
          optionList.currentIndex = Math.min(
            root.options.length - 1,
            optionList.currentIndex + 1
          )
          event.accepted = true
        } else if (event.key === Qt.Key_Up || event.text === "k") {
          optionList.currentIndex = Math.max(0, optionList.currentIndex - 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          optionList.selectCurrent()
          event.accepted = true
        }
      }

      delegate: Rectangle {
        required property var modelData
        required property int index

        width: optionList.width
        height: Style.spacing.popupRowHeight
        color: index === optionList.currentIndex
          ? Style.hoverFillFor(root.foreground, root.accent)
          : "transparent"

        Row {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.spacing.controlPaddingX
          anchors.rightMargin: Style.spacing.controlPaddingX

          Text {
            text: String(parent.parent.modelData.label)
            color: parent.parent.index === optionList.currentIndex
              ? Style.hoverStateColor(root.foreground, root.accent)
              : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onPositionChanged: optionList.currentIndex = parent.index
          onClicked: optionList.selectCurrent()
        }
      }
    }
  }
}
