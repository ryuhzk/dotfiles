# Omarchy Dotfiles

Minimal, public-oriented personal configuration for Omarchy 4.x.

Omarchy owns the desktop defaults. This repository only keeps deliberate
personal additions:

- Lazygit workflow customizations
- Small Yazi overrides
- Fcitx5 + Rime input-method preferences
- Custom multilingual Chinese/Japanese/English and Japanese-only Rime schemas
- The custom `onepiece` Omarchy theme
- The animated `zoro` Plymouth theme

<p align="center">
  <img src="assets/zoro-plymouth.gif" alt="Zoro Plymouth boot animation preview">
</p>

It intentionally does not replace Omarchy's Neovim, tmux, terminal, Git,
Hyprland, shell, bar, lock-screen, or generated theme state.

## Compatibility

Tested against:

- Omarchy `4.0.0.r1429.gf4e8470-1` (`edge`)
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

Install the unprivileged modules:

```bash
./install all
```

`all` installs Lazygit, Yazi, Fcitx5, and the One Piece theme. It deliberately
excludes Plymouth because changing the boot splash rebuilds the initramfs.

Install the optional Yazi package:

```bash
./install packages
```

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
