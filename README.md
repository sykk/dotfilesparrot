# Brandon's Dotfiles Backup

This directory backs up the current desktop setup using home-relative paths under
`home/`.

## Included

- KDE/Plasma config: panels, shell, KWin, KDE globals, notifications, defaults
- Active Plasma assets: `EvilMorty`, `EvilMorty.Transparent`, and
  active local plasmoids
- EvilMorty theme source and exported Code profile
- Active color/icon/cursor themes: `EvilMorty.colors`, `YAMIS`,
  `Apple-cursors`
- Bundled EvilHackerMorty wallpaper package
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

On CachyOS, `./install.sh` runs the guided one-command setup:

```sh
./install.sh --setup
```

That checks optional system setup, opens the app selector, stops Plasma while
desktop config is restored, normalizes home paths, applies the wallpaper, then
asks whether to start Plasma again. Use
`./install.sh --restore-only` to skip app/system setup and only restore the
dotfiles.

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

Optional setup helpers:

```sh
./install.sh --install-apps
./install.sh --install-aur-helper
./install.sh --enable-flathub
./install.sh --enable-sddm-autologin
./install.sh --setup
./install.sh --restore-only
```

`--install-apps` opens a terminal checklist for Discord, Git, GitHub CLI,
Opera GX, Code, Ghostty, Fastfetch, Conky, Deskflow, Steam, and Lutris.
App installation expects an Arch-like system with `pacman` and uses `paru` or `yay`. In
`--setup`, app and system setup runs before dotfiles are restored. The restored
Plasma config remains the source of truth; the script only reapplies the
wallpaper afterward by copying it to `~/.local/share/wallpapers/EvilMorty.png`.

The bundled Global Theme package is also kept in sync with the restored setup:
it uses YAMIS icons, Breeze window decorations, the EvilHackerMorty wallpaper
package, and the same dock launcher set as the saved Plasma config.

`--enable-sddm-autologin` writes `/etc/sddm.conf.d/10-autologin.conf` for the
current user after confirmation. It defaults to `plasma.desktop`; override with
`SDDM_AUTOLOGIN_SESSION=name.desktop` if needed.

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
