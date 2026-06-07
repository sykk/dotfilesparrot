# Brandon's Dotfiles Backup

This directory backs up the current desktop setup using home-relative paths under
`home/`.

## Included

- KDE/Plasma config: panels, shell, KWin, KDE globals, notifications, defaults
- Active Plasma assets: `Catppuccin.EvilMorty`, `EvilMorty.Transparent`, and
  active local plasmoids
- EvilMorty theme source and exported Code profile
- Active color/icon/cursor themes: `EvilMorty.colors`, `YAMIS`,
  `Apple-cursors`
- Current wallpaper from `~/Downloads/content.png`
- Panel Colorizer preset
- Conky config and autostart entry
- Kate config and external tools
- Code OSS user settings/profile theme files
- GTK, Kitty, Ghostty, btop, shell profile files

## Install

From a checked-out repo:

```sh
./install.sh
```

From a fresh machine, first download this script or clone the repo, then pass
the Git remote once the repo is published:

```sh
bash install.sh --repo https://github.com/USER/dotfiles.git
```

Or with a downloaded copy of the script:

```sh
DOTFILES_REPO_URL=https://github.com/USER/dotfiles.git bash install.sh
```

Use `./install.sh --dry-run` to preview restored files before changing `$HOME`.
Use `./install.sh --restart-plasma` to confirm and restart Plasma after the
theme files are restored.

## Restore

From this directory:

```sh
./restore.sh
```

The script creates a timestamped backup directory before syncing files back to
`$HOME`.

## Notes

- Code OSS cache, workspace databases, chat history, and other transient state
  are intentionally not included.
- Unused icon packs, wallpaper packs, Aurorae decorations, color schemes, and
  inactive Plasma theme variants were intentionally pruned.
- After restoring Plasma files, log out and back in, or restart Plasma, for all
  theme and panel changes to reload.
