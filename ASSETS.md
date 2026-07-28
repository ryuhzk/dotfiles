# Media assets

The following directories contain visual media derived from or inspired by
One Piece:

- `omarchy/themes/onepiece/backgrounds/`
- `system/plymouth/themes/zoro/`

They are excluded from the repository's MIT license. Their original sources,
authors, and redistribution terms have not yet been documented.

The Fcitx5 Catppuccin theme under
`share/fcitx5/themes/catppuccin-macchiato-maroon/` is third-party work credited
in its `theme.conf`. Catppuccin is MIT-licensed, but the exact upstream source
for this copy should be recorded before publication.

Before making the repository public, replace any asset that cannot be
redistributed and add source and license information for every retained asset.

## Input-method data

The repository contains original integration schemas derived from the behavior
of the previous local setup. It does not redistribute the large Japanese
dictionaries.

The installer fetches these dictionary files from a pinned revision of
`https://github.com/gkovacs/rime-japanese`:

- `japanese.jmdict.dict.yaml`
- `japanese.kana.dict.yaml`
- `japanese.mozc.dict.yaml`

That upstream combines data from JMdict and Mozc. Its repository does not
provide a single top-level license, so the files remain external and retain
their upstream terms.
