# Brandon's Dotfiles Backup

This directory backs up the current desktop setup using home-relative paths under
`home/`.

## Included

- KDE/Plasma config: panels, shell, KWin, KDE globals, notifications, defaults
- Active Plasma assets: `EvilMorty`, `EvilMorty.Transparent`, and
  active local plasmoids
- Exported EvilMorty Code profile
- Active color/icon/cursor themes: `EvilMorty.colors`, `YAMIS`,
  `Apple-cursors`
- Bundled EvilHackerMorty wallpaper package
- Panel Colorizer preset
- Conky and Deskflow configs plus autostart entries
- Kate config and external tools
- Code OSS user settings/profile theme files
- GTK, Kitty, Ghostty, btop, shell profile files

## Install

From a checked-out repo, run:

```sh
./install.sh
```

The installer has no options. It prompts once for the configured package set,
optionally enables Flathub and SDDM autologin, stops Plasma while desktop config
is restored, normalizes home paths, applies EvilMorty colors before window
decorations, stages the wallpaper at `~/.local/share/wallpapers/EvilMorty.png`,
then restarts Plasma automatically if it was running.

Package installation expects an Arch-like system with `pacman` and installs
Discord, Git, GitHub CLI, Opera GX, Code, Ghostty, Fastfetch, Conky, Deskflow,
Steam, and Lutris.

The bundled Global Theme package is also kept in sync with the restored setup:
it uses YAMIS icons, Breeze window decorations, the EvilHackerMorty wallpaper
package, and the same dock launcher set as the saved Plasma config.

If enabled, SDDM autologin writes `/etc/sddm.conf.d/10-autologin.conf` for the
current user. It defaults to `plasma.desktop`; override with
`SDDM_AUTOLOGIN_SESSION=name.desktop` if needed. The script creates a
timestamped backup directory before syncing files back to `$HOME`.

## Notes

- Code OSS cache, workspace databases, chat history, and other transient state
  are intentionally not included.
- Unused icon packs, wallpaper packs, Aurorae decorations, color schemes, and
  inactive Plasma theme variants were intentionally pruned.
- After restoring Plasma files, log out and back in, or restart Plasma, for all
  theme and panel changes to reload.
