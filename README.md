# Omarchy Dotfiles

Minimal, public-oriented personal configuration for Omarchy 4.x.

Omarchy owns the desktop defaults. This repository only keeps deliberate
personal additions:

- Lazygit workflow customizations
- Small Yazi overrides
- Fcitx5 + Rime input-method preferences
- Keybindings for the independently maintained Omarchy Translation plugin
- Custom multilingual Chinese/Japanese/English and Japanese-only Rime schemas
- Hyprland appearance overrides and theme-level Omarchy shell styling
- The custom `onepiece` Omarchy theme
- The animated `zoro` Plymouth theme
- A reproducible global CLI toolset managed by mise

<p align="center">
  <img src="assets/zoro-plymouth.gif" alt="Zoro Plymouth boot animation preview">
</p>

It intentionally does not replace Omarchy's Neovim, tmux, terminal, Git,
shell, bar, lock-screen, or generated theme state. The Hyprland files contain
only small user-owned input and keybinding overrides.

## Compatibility

Tested against:

- Omarchy `4.0.0.r1472.g283276b-1` (`edge`)
- Hyprland `0.56.1`
- Lazygit `0.63.1`
- Yazi `26.5.6`
- Plymouth `26.134.222`
- Limine-based initramfs rebuilding

The repository follows Omarchy's public CLI and user-override boundaries. It
never writes to `/usr/share/omarchy`.

## Install

Inspect the repository first:

```bash
./check all
./install --dry-run all
```

On a fresh Omarchy machine, install the recovered system packages, the global
mise toolset, and all unprivileged configuration in one pass:

```bash
./install --dry-run bootstrap
./install bootstrap
```

The bootstrap includes explicit packages recovered from the current machine's
shell and pacman history: `cloc`, `cosign`, `minisign`, and `silicon`.
Package-manager dependencies are not listed separately. It deliberately
excludes Plymouth because changing the boot splash rebuilds the initramfs.

Install the unprivileged modules:

```bash
./install all
```

`all` installs Lazygit, Yazi, Hyprland overrides,
appearance overrides, Fcitx5, and the One Piece theme. It deliberately excludes
Plymouth because changing the boot splash rebuilds the initramfs.

Install packages required by the optional modules:

```bash
./install packages
```

Install only the global development tools:

```bash
./install tools
```

This links `~/.config/mise` to the repository and runs `mise install`. Native
tools such as Bun, Node.js, Go, Java, Codex, Claude, GitHub CLI, OpenCode, and
the Android SDK use their mise backends. JavaScript CLIs previously installed
globally with Bun or npm (`fizzyx`, `agent-device`, `eas-cli`, and Playwright)
use mise's isolated `npm:` backend, so they no longer depend on a shared global
package directory. The recovered package versions are pinned where known;
existing rolling tool selections remain on `latest`.

Install Zoro Plymouth explicitly:

```bash
./install --dry-run plymouth
./install plymouth
```

The Plymouth installer asks `sudo` for authorization in the interactive
terminal, preserves an existing custom Zoro directory, changes the selected
theme, and rebuilds with `limine-mkinitcpio` when available.

## One Piece theme

Install the theme as a real user-owned directory:

```bash
./install onepiece
omarchy theme set onepiece
```

The installer does not switch themes automatically.

## Appearance

The `looknfeel` module replaces Omarchy's conservative Hyprland defaults with a
more animated desktop, without touching any keybinding:

```bash
./install looknfeel
```

It installs `~/.config/hypr/looknfeel.lua`, which Omarchy loads after both its
own defaults and the active theme's Hyprland overrides. It turns on blur,
shadows, rounded corners, and inactive-window dimming; re-enables the workspace
slide animation that Omarchy disables; and replaces the default easing with
Material 3 expressive curves, where spatial properties overshoot slightly before
settling and opacity never does.

Border width is set here because it is theme-agnostic, but border colors are
deliberately left out so `omarchy theme set` keeps control of them; the One
Piece theme sets its own below. `./check looknfeel` enforces that split, and
also verifies that every easing curve referenced by an animation is actually
defined — Hyprland silently substitutes a default curve for a misspelled name.

The module also blurs the `omarchy-bar` layer, which is what lets the One Piece
theme make the bar transparent without the text becoming unreadable.

An anti-flashbang screen shader was tried here and removed. Estimating average
screen luminance inside a fragment shader makes the dim factor track screen
content, so the whole screen visibly pulses whenever anything moves, and a
stateless shader cannot smooth that over time. For night comfort use Omarchy's
own `omarchy toggle nightlight`, which shifts color temperature through
hyprsunset rather than modulating brightness.

Note that on Omarchy 4 the Hyprland config is Lua, and `hyprctl keyword` no
longer works against it. Runtime changes have to go through `hyprctl eval`.

### Theme-level shell styling

Omarchy's stock control chrome is border-first: a 1px outline over an almost
transparent fill. That is most of what gives the shell its terminal look. The
One Piece theme inverts it — no outlines, and a tonal fill that carries the
shape instead — through three files:

- `shell.controls.toml` — control state tokens, using palette role names so
  they keep following `colors.toml`
- `shell.bar.toml` — a transparent bar
- `hyprland.lua` — muted window borders, since the generated default uses the
  raw accent at full opacity

`omarchy theme set` merges any `shell.<section>.toml` over the matching section
of the generated `shell.toml`, and never overwrites a file the theme already
ships. Both are supported extension points, so none of this touches
`/usr/share/omarchy`.

The merge replaces a whole section rather than individual keys, so each file
repeats every token that section needs. `[bar]` resolves through a path that
takes hex only, so its colors are duplicated from `colors.toml`;
`./check onepiece` compares the two and fails when they drift apart.

## Input methods

The Fcitx5 module keeps three Rime choices:

- `Mixed ZH-JA-EN` (`japanese_tw_eng`) for the previous mixed Pinyin, Romaji,
  and English workflow
- `Rime Ice` (`rime_ice`) for the full upstream Chinese experience
- `Japanese` (`sno_japanese`) for the previous focused Romaji workflow

The mixed schema retains its `P` Japanese Kanji Pinyin lookup, `T` Rime Ice
lookup, `J`-prefixed English-to-Japanese lookup, translation hints, and
Hiragana/Katakana conversion. Left Shift switches between native and Latin
input, matching the previous configuration.

Rime Ice is provided by `rime-ice-git`. The Japanese and translation
dictionaries are installed from pinned revisions of `gkovacs/rime-japanese`
and `snomiao/rime-snomiao`. The repository keeps only custom schemas and small
conversion rules, avoiding roughly 65 MB of vendored third-party data.

After copying the configuration, the installer deploys the Rime schemas and
dictionaries. On current Omarchy systems it then restarts
`omarchy-fcitx5.service` and verifies that the service is active. Older setups
without that service fall back to reloading the running Fcitx5 instance.

## Translation shortcuts

The translation implementation now lives in a separate Omarchy plugin. This
repository only binds `Super+Shift+T` to translate the current Wayland
selection and `Super+Alt+T` to open the installed plugin panel. It contains no
translation backend or Neovim integration.

## Private Git identity

Keep author identity and signing information out of the public repository:

```bash
bin/git-identity
```

The interactive setup writes `~/.config/git/identity` with mode `0600` and
adds that file to Git's global include list. Existing identity data is backed
up under `~/.local/state/dotfiles/backups/`.

When signing is enabled, the script reuses a secret key matching the Git email.
If none exists, it creates a passphrase-protected Ed25519 signing key with a
two-year expiration and records its full fingerprint automatically. GnuPG asks
for the passphrase in the interactive terminal; neither the passphrase nor the
secret key is stored by this repository.

For non-interactive setup:

```bash
bin/git-identity \
  --name "Your Name" \
  --email "your-private-or-noreply@example.com" \
  --sign
```

Use `--signing-key "YOUR_OPENPGP_FINGERPRINT"` to select an existing key
explicitly, or `--no-sign` when commit signing is not wanted. Automatic key
creation still requires an interactive terminal so GnuPG can request a
passphrase. The script contains no real name, email address, or key fingerprint.

Back up the secret key separately after creating it. Never store a private-key
export in this repository.

Print the configured public key in ASCII-armored form:

```bash
bin/git-identity --export-public-key
```

Copy it directly for GitHub:

```bash
bin/git-identity --export-public-key | wl-copy
```

This action exports only the public key associated with Git's configured
fingerprint. The script deliberately provides no secret-key export action.

## Individual modules

```bash
./install lazygit
./install yazi
./install fcitx5
./install onepiece
./install plymouth
```

Conflicting user configuration is moved to:

```text
~/.local/state/dotfiles/backups/<timestamp>/
```

## Repository policy

- Only allowlisted modules are installed.
- Machine-local and private data never belongs in this repository.
- Omarchy-generated state under `~/.local/state/omarchy` is never tracked.
- Omarchy themes are copied, not symlinked.
- Fcitx5 files are copied individually. The Rime Ice override is deployed to
  `~/.local/share/fcitx5/rime/default.custom.yaml`, which is Fcitx5-Rime's
  active user-data path.
- Rime build output, learned dictionaries, sync data, and installation IDs stay
  machine-local and are never tracked.
- Documentation and explanatory comments are English-only. Non-English strings
  remain only where they are functional input-method or theme data.
- System themes require an explicit module install.
- Media assets are not covered by the repository's MIT license; see
  [ASSETS.md](ASSETS.md).
