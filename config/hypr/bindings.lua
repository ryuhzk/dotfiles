-- Personal keybindings can be added here.

-- Send text to mac-mini even while Moonlight captures the keyboard.
o.bind("SUPER + CTRL + SHIFT + V", "Send clipboard to Mac", "/home/ryu/.local/bin/mac-copy", {
  dont_inhibit = true,
  allow_input_capture = true,
})

-- Translate the selected text with the translation plugin and paste the result over it.
o.bind("SUPER + ALT + T", "Translate selection in place",
  "/home/ryu/.config/omarchy/plugins/ryuhzk.translation/translation.py --replace")

-- Push-to-talk that types English: hold F10, speak Chinese, release. F9 (Omarchy's
-- own binding) stays plain Chinese dictation. The `english` profile in
-- ~/.config/voxtype/config.toml translates the transcript with the local model.
o.bind("F10", "Dictate Chinese as English (push-to-talk)", "voxtype record start --profile english")
o.bind("F10", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
