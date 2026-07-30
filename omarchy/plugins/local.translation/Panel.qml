import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "local.translation"
  ipcTarget: "local.translation"

  property string pendingSource: ""
  property string pendingCopy: ""
  property string processOutput: ""
  property string processError: ""
  property string settingsOutput: ""
  property string settingsError: ""
  property string toneValue: "natural"
  property string contextValue: "general"
  property string statusText: "Ready"
  property bool settingsVisible: false
  property bool apiKeyConfigured: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool busy: translateProcess.running
  readonly property string commandPath: Quickshell.env("HOME") + "/.local/bin/dotfiles-translate"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function framedText(value) {
    var lines = String(value).split("\n")
    return String(lines.length) + "\n" + lines.join("\n") + "\n"
  }

  function framedValues(values) {
    return String(values.length) + "\n" + values.join("\n") + "\n"
  }

  function translate() {
    var source = sourceArea.text
    if (busy || source.trim() === "") {
      if (source.trim() === "") statusText = "Enter text first"
      return
    }
    pendingSource = source
    processOutput = ""
    processError = ""
    resultArea.text = ""
    statusText = "Translating…"
    translateProcess.command = [
      root.commandPath,
      "--stdin-lines",
      "--stdout",
      "--source",
      sourceLanguage.text.trim(),
      "--target",
      targetLanguage.text.trim(),
      "--tone",
      root.toneValue,
      "--context",
      root.contextValue
    ]
    translateProcess.running = true
  }

  function loadSettings() {
    if (!settingsProcess.running) {
      settingsOutput = ""
      settingsError = ""
      settingsProcess.running = true
    }
  }

  function saveSettings() {
    if (saveSettingsProcess.running) return
    settingsError = ""
    saveSettingsProcess.running = true
  }

  function copyResult() {
    if (resultArea.text === "" || copyProcess.running) return
    pendingCopy = resultArea.text
    copyProcess.running = true
  }

  function clearContent() {
    sourceArea.text = ""
    resultArea.text = ""
    statusText = "Ready"
    sourceArea.forceActiveFocus()
  }

  function toggleOptions() {
    settingsVisible = !settingsVisible
  }

  onOpenedChanged: if (opened) {
    root.loadSettings()
    Qt.callLater(function() { sourceArea.forceActiveFocus() })
  }

  Shortcut {
    sequences: ["Ctrl+Return", "Ctrl+Enter"]
    context: Qt.ApplicationShortcut
    enabled: root.opened
    onActivated: root.translate()
  }

  Shortcut {
    sequence: "Ctrl+L"
    context: Qt.ApplicationShortcut
    enabled: root.opened
    onActivated: root.clearContent()
  }

  Shortcut {
    sequence: "Ctrl+O"
    context: Qt.ApplicationShortcut
    enabled: root.opened
    onActivated: root.toggleOptions()
  }

  Shortcut {
    sequence: "Ctrl+Shift+C"
    context: Qt.ApplicationShortcut
    enabled: root.opened
    onActivated: root.copyResult()
  }

  Shortcut {
    sequence: "Escape"
    context: Qt.ApplicationShortcut
    enabled: root.opened
    onActivated: root.close()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰊿"
    active: root.opened
    tooltipText: "Translate"
    onPressed: root.toggle()
  }

  Process {
    id: settingsProcess
    command: [root.commandPath, "--show-settings"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.settingsOutput = String(text || "")
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.settingsError = String(text || "").trim()
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.statusText = root.settingsError || "Could not load defaults"
        return
      }
      var values = root.settingsOutput.replace(/\n$/, "").split("\n")
      if (values.length < 8) {
        root.statusText = "Translation defaults are incomplete"
        return
      }
      sourceLanguage.text = values[0]
      targetLanguage.text = values[1]
      root.toneValue = values[2]
      root.contextValue = values[3]
      localBaseUrl.text = values[4]
      localModel.text = values[5]
      localTimeout.text = values[6]
      root.apiKeyConfigured = values[7] === "configured"
      localApiKey.text = ""
    }
  }

  Process {
    id: saveSettingsProcess
    command: [root.commandPath, "--save-settings"]
    stdinEnabled: true
    onStarted: write(root.framedValues([
      sourceLanguage.text.trim(),
      targetLanguage.text.trim(),
      root.toneValue,
      root.contextValue,
      localBaseUrl.text.trim(),
      localModel.text.trim(),
      localTimeout.text.trim(),
      localApiKey.text
    ]))
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.settingsError = String(text || "").trim()
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        if (localApiKey.text !== "") root.apiKeyConfigured = true
        localApiKey.text = ""
        root.statusText = "Translation settings saved"
      } else {
        root.statusText = root.settingsError || "Could not save settings"
      }
    }
  }

  Process {
    id: translateProcess
    command: [root.commandPath, "--stdin-lines", "--stdout"]
    stdinEnabled: true
    onStarted: write(root.framedText(root.pendingSource))
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processOutput = String(text || "")
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.processError = String(text || "").trim()
    }
    onExited: function(exitCode) {
      root.pendingSource = ""
      if (exitCode === 0 && root.processOutput !== "") {
        resultArea.text = root.processOutput
        root.statusText = "Translated"
      } else {
        root.statusText = root.processError || "Translation failed"
      }
    }
  }

  Process {
    id: copyProcess
    command: [
      "bash",
      "-c",
      "IFS= read -r count || exit 1; text=; i=0; while [ \"$i\" -lt \"$count\" ]; do IFS= read -r line || line=; if [ \"$i\" -eq 0 ]; then text=$line; else text=\"${text}\n${line}\"; fi; i=$((i + 1)); done; printf %s \"$text\" | wl-copy"
    ]
    stdinEnabled: true
    onStarted: write(root.framedText(root.pendingCopy))
    onExited: function(exitCode) {
      root.pendingCopy = ""
      root.statusText = exitCode === 0 ? "Copied translation" : "Could not copy translation"
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: sourceArea
    centerOnBar: false
    contentWidth: panel.fittedContentWidth(Style.space(620))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(900))

    Flickable {
      id: scroll
      anchors.fill: parent
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: content
        width: scroll.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "Translation"
          meta: root.statusText
          detail: "LOCAL"
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              text: "󰊿"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "SOURCE"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Item {
            width: Math.max(0, parent.width - parent.children[0].width - settingsButton.width - parent.spacing * 2)
            height: 1
          }

          Button {
            id: settingsButton
            text: root.settingsVisible ? "Hide options" : "Translation options"
            iconText: "󰒓"
            bordered: true
            tooltipText: "Ctrl+O"
            onClicked: root.toggleOptions()
          }
        }

        BorderSurface {
          width: parent.width
          height: Style.space(150)
          color: Style.controlFill(sourceArea.activeFocus, sourceArea.hovered, root.foreground, Color.accent)
          borderSpec: Border.controlSpec(sourceArea.activeFocus ? "focus" : "normal", root.foreground, Color.accent)
          radius: Style.cornerRadius

          ScrollView {
            anchors.fill: parent
            clip: true

            TextArea {
              id: sourceArea
              wrapMode: TextEdit.Wrap
              placeholderText: "Type or paste text to translate"
              color: root.foreground
              placeholderTextColor: root.dim
              selectionColor: Style.selectionFillFor(root.foreground, Color.accent)
              selectedTextColor: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              background: null
            }
          }
        }

        Row {
          spacing: Style.space(8)

          Button {
            text: root.busy ? "Translating…" : "Translate"
            iconText: root.busy ? "󰑓" : "󰊿"
            iconSpinning: root.busy
            active: !root.busy && sourceArea.text.trim() !== ""
            bordered: true
            tooltipText: "Ctrl+Enter"
            onClicked: root.translate()
          }

          Button {
            text: "Clear"
            iconText: "󰆴"
            bordered: true
            tooltipText: "Ctrl+L"
            onClicked: root.clearContent()
          }
        }

        Column {
          visible: root.settingsVisible
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: "TRANSLATION OPTIONS"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Text {
            width: parent.width
            text: "Language and style options apply immediately. Save all fields to reuse them in global shortcuts and Neovim."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: sourceLanguage
              width: (parent.width - parent.spacing) * 0.4
              placeholderText: "Source, e.g. auto"
              foreground: root.foreground
              Keys.onEscapePressed: root.close()
            }

            EditableLanguageDropdown {
              id: targetLanguage
              width: (parent.width - parent.spacing) * 0.6
              placeholderText: "Target, e.g. English"
              foreground: root.foreground
              options: [
                {
                  label: "English",
                  language: "English"
                },
                {
                  label: "Japanese",
                  language: "Japanese"
                },
                {
                  label: "Traditional Chinese (Taiwan)",
                  language: "Traditional Chinese (Taiwan)"
                }
              ]
              onCloseRequested: root.close()
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Dropdown {
              width: (parent.width - parent.spacing) / 2
              label: "Context"
              value: root.contextValue
              foreground: root.foreground
              options: [
                { label: "General", value: "general" },
                { label: "Social media (X)", value: "social_x" },
                { label: "Casual chat", value: "casual_chat" },
                { label: "Professional", value: "professional" },
                { label: "Technical", value: "technical" }
              ]
              onChanged: function(value) {
                root.contextValue = value
              }
            }

            Dropdown {
              width: (parent.width - parent.spacing) / 2
              label: "Tone"
              value: root.toneValue
              foreground: root.foreground
              options: [
                { label: "Natural", value: "natural" },
                { label: "Casual", value: "casual" },
                { label: "Humorous", value: "humorous" },
                { label: "Professional", value: "professional" },
                { label: "Concise", value: "concise" }
              ]
              onChanged: function(value) {
                root.toneValue = value
              }
            }
          }

          Text {
            text: "LOCAL MODEL"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }

          Text {
            width: parent.width
            text: "Model settings are stored in the private config. Leave Model empty to discover the first model exposed by the endpoint."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: localBaseUrl
              width: (parent.width - parent.spacing) * 0.75
              placeholderText: "OpenAI-compatible endpoint"
              foreground: root.foreground
            }

            TextField {
              id: localTimeout
              width: (parent.width - parent.spacing) * 0.25
              placeholderText: "Timeout"
              foreground: root.foreground
              inputMethodHints: Qt.ImhDigitsOnly
              validator: IntValidator {
                bottom: 1
                top: 300
              }
            }
          }

          TextField {
            id: localModel
            width: parent.width
            placeholderText: "Model (empty uses auto-discovery)"
            foreground: root.foreground
          }

          TextField {
            id: localApiKey
            width: parent.width
            password: true
            placeholderText: root.apiKeyConfigured
              ? "API key configured — enter a replacement"
              : "Optional API key"
            foreground: root.foreground
          }

          Text {
            width: parent.width
            text: root.apiKeyConfigured
              ? "The saved API key is hidden. Leaving this field empty keeps it unchanged."
              : "The API key is sent over standard input and saved with mode 0600."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          Button {
            text: saveSettingsProcess.running ? "Saving…" : "Save translation settings"
            iconText: saveSettingsProcess.running ? "󰑓" : "󰆓"
            iconSpinning: saveSettingsProcess.running
            bordered: true
            onClicked: root.saveSettings()
          }
        }

        Text {
          text: "RESULT"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }

        BorderSurface {
          width: parent.width
          height: Style.space(170)
          color: Style.controlFill(resultArea.activeFocus, resultArea.hovered, root.foreground, Color.accent)
          borderSpec: Border.controlSpec(resultArea.activeFocus ? "focus" : "normal", root.foreground, Color.accent)
          radius: Style.cornerRadius

          ScrollView {
            anchors.fill: parent
            clip: true

            TextArea {
              id: resultArea
              readOnly: true
              selectByMouse: true
              wrapMode: TextEdit.Wrap
              placeholderText: "The translation will appear here"
              color: root.foreground
              placeholderTextColor: root.dim
              selectionColor: Style.selectionFillFor(root.foreground, Color.accent)
              selectedTextColor: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              background: null
            }
          }
        }

        Row {
          spacing: Style.space(8)

          Button {
            id: copyButton
            text: "Copy result"
            iconText: "󰆏"
            active: resultArea.text !== ""
            bordered: true
            tooltipText: "Ctrl+Shift+C"
            onClicked: root.copyResult()
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.parent.width - copyButton.width - parent.spacing)
            text: "Ctrl+Enter translate · Ctrl+L clear · Ctrl+O options · Ctrl+Shift+C copy · Esc close"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }
        }
      }
    }
  }
}
