#!/usr/bin/env bash
set -euo pipefail

plasma_was_running=0

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  printf 'Error: do not run install.sh as root; run ./install.sh as your user.\n' >&2
  exit 1
fi

APP_PACKAGES=(
  discord
  opera-gx
  klassy
)

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt="$1"
  local reply

  [[ -t 0 ]] || return 1
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == [Yy] || "$reply" == [Yy][Ee][Ss] ]]
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

install_packages() {
  if ! confirm "Install configured packages now?"; then
    log "Package installation skipped"
    return 0
  fi

  require_command sudo
  require_command apt

  log "Updating package lists"
  sudo apt update

  log "Installing packages with apt: ${APP_PACKAGES[*]}"
  sudo apt install -y "${APP_PACKAGES[@]}"
}

active_display_manager() {
  local display_manager_link="/etc/systemd/system/display-manager.service"
  local display_manager_target

  [[ -e "$display_manager_link" ]] || return 0
  display_manager_target="$(readlink -f "$display_manager_link" 2>/dev/null || true)"
  basename "$display_manager_target"
}

configure_autologin() {
  local user_name session_name display_manager autologin_config override_config

  if ! confirm "Enable autologin for this user?"; then
    return 0
  fi

  require_command sudo

  user_name="$USER"
  display_manager="$(active_display_manager)"

  if [[ "$display_manager" == "plasmalogin.service" || -f /etc/plasmalogin.conf || -x /usr/bin/plasmalogin ]]; then
    session_name="${PLASMALOGIN_AUTOLOGIN_SESSION:-plasma.desktop}"

    log "Writing Plasma Login autologin config"
    printf '[Autologin]\nSession=%s\nUser=%s\n' "$session_name" "$user_name" | sudo tee /etc/plasmalogin.conf >/dev/null
    if command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable -f plasmalogin.service >/dev/null 2>&1 || true
    fi
    return 0
  fi

  session_name="${SDDM_AUTOLOGIN_SESSION:-plasma}"
  autologin_config="/etc/sddm.conf.d/autologin.conf"
  override_config="/etc/sddm.conf.d/99-autologin.conf"

  log "Writing SDDM autologin config"
  sudo mkdir -p /etc/sddm.conf.d
  sudo rm -f /etc/sddm.conf.d/10-autologin.conf
  printf '[Autologin]\nUser=%s\nSession=%s\nRelogin=true\n' "$user_name" "$session_name" | sudo tee "$autologin_config" >/dev/null
  sudo cp -f "$autologin_config" "$override_config"
}

restore_dotfiles() {
  local dotfiles_dir="$1"
  local source_dir="$dotfiles_dir/home/"
  local backup_dir="$dotfiles_dir/restore-backups/$(date +%Y%m%d-%H%M%S)"

  [[ -d "$source_dir" ]] || die "missing dotfiles payload: $source_dir"

  mkdir -p "$backup_dir"
  log "Restoring dotfiles into $HOME"
  rsync -a --backup --backup-dir="$backup_dir" "$source_dir" "$HOME/"
  log "Overwritten originals were saved in $backup_dir"
}

stage_wallpaper() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilMorty.png"
  local package_wallpaper="$HOME/.local/share/wallpapers/EvilHackerMorty/contents/images/EvilMorty.png"

  mkdir -p "$HOME/.local/share/wallpapers"

  if [[ -f "$package_wallpaper" ]]; then
    cp -f "$package_wallpaper" "$wallpaper"
  fi
}

apply_evilmorty_colors() {
  local color_scheme="$HOME/.local/share/color-schemes/EvilMorty.colors"
  local kdeglobals="$HOME/.config/kdeglobals"

  if [[ -f "$color_scheme" ]] && command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    log "Applying EvilMorty colors"
    plasma-apply-colorscheme EvilMorty || log "Could not apply EvilMorty color scheme"
  fi

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$kdeglobals" --group General --key ColorScheme EvilMorty
    kwriteconfig6 --file "$kdeglobals" --group General --key Name EvilMorty
    kwriteconfig6 --file "$kdeglobals" --group General --key AccentColor "0,255,102"
    kwriteconfig6 --file "$kdeglobals" --group General --key LastUsedCustomAccentColor "0,255,102"
    kwriteconfig6 --file "$kdeglobals" --group General --key accentColorFromWallpaper false
  fi
}

apply_wallpaper_live() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilMorty.png"

  [[ -f "$wallpaper" ]] || {
    log "Wallpaper not found; skipping wallpaper apply"
    return 0
  }

  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    log "Applying wallpaper"
    plasma-apply-wallpaperimage "$wallpaper" || log "Could not apply wallpaper: $wallpaper"
  else
    log "plasma-apply-wallpaperimage not found; skipping wallpaper apply"
  fi
}

normalize_home_paths() {
  local files=(
    "$HOME/.config/plasmarc"
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    "$HOME/.config/conky/conky.conf"
    "$HOME/.config/autostart/conky.desktop"
    "$HOME/.config/fastfetch/config.jsonc"
    "$HOME/.local/share/plasma/look-and-feel/EvilMorty/contents/layouts/org.kde.plasma.desktop-layout.js"
  )
  local file

  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    sed -i "s#/home/brandon#$HOME#g" "$file"
  done
}

apply_app_configs() {
  local fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
  local fastfetch_logo="$HOME/.config/fastfetch/logos/morty.txt"
  local ghostty_config="$HOME/.config/ghostty/config"
  local ghostty_alt_config="$HOME/.config/ghostty/config.ghostty"
  local ghostty_theme="$HOME/.config/ghostty/themes/EvilMorty"

  if [[ -f "$fastfetch_config" && -f "$fastfetch_logo" ]]; then
    log "Applying Fastfetch config"
    sed -i "s#/home/brandon/.config/fastfetch/logos/morty.txt#$fastfetch_logo#g" "$fastfetch_config"
    sed -i "s#$HOME/EvilMortyTheme/ascii.txt#$fastfetch_logo#g" "$fastfetch_config"
  fi

  if [[ -f "$ghostty_config" && -f "$ghostty_theme" ]]; then
    log "Applying Ghostty config"
    if grep -q '^theme *= *' "$ghostty_config"; then
      sed -i 's/^theme *= *.*/theme = EvilMorty/' "$ghostty_config"
    else
      printf 'theme = EvilMorty\n\n' | cat - "$ghostty_config" >"$ghostty_config.tmp"
      mv "$ghostty_config.tmp" "$ghostty_config"
    fi
    cp -f "$ghostty_config" "$ghostty_alt_config"
  fi
}

force_klassy_title_left() {
  local config_file="$1"

  [[ -f "$config_file" ]] || return 0

  if grep -q '^TitleAlignment=' "$config_file"; then
    sed -i 's/^TitleAlignment=.*/TitleAlignment=AlignLeft/' "$config_file"
  else
    printf '\n[Windeco]\nTitleAlignment=AlignLeft\n' >>"$config_file"
  fi
}

apply_window_decoration_config() {
  local kwinrc="$HOME/.config/kwinrc"
  local klassyrc="$HOME/.config/klassy/klassyrc"
  local klassy_presets="$HOME/.config/klassy/windecopresetsrc"

  [[ -f "$kwinrc" ]] || return 0

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnLeft ""
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnRight IAX
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key library org.kde.klassy
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key theme Klassy
    if [[ -f "$klassyrc" ]]; then
      kwriteconfig6 --file "$klassyrc" --group Global --key LookAndFeelSet EvilMorty
    fi
  else
    sed -i \
      -e 's/^ButtonsOnLeft=.*/ButtonsOnLeft=/' \
      -e 's/^ButtonsOnRight=.*/ButtonsOnRight=IAX/' \
      -e 's/^library=.*/library=org.kde.klassy/' \
      -e 's/^theme=.*/theme=Klassy/' \
      "$kwinrc"
  fi

  if [[ -f "$klassyrc" ]]; then
    if command -v kwriteconfig6 >/dev/null 2>&1; then
      kwriteconfig6 --file "$klassyrc" --group Windeco --key TitleAlignment AlignLeft
    fi
    sed -i \
      -e 's/^LookAndFeelSet=.*/LookAndFeelSet=EvilMorty/' \
      "$klassyrc"
    force_klassy_title_left "$klassyrc"
  fi

  if [[ -f "$klassy_presets" ]]; then
    force_klassy_title_left "$klassy_presets"
  fi
}

refresh_window_theme() {
  local kdeglobals="$HOME/.config/kdeglobals"
  local kwinrc="$HOME/.config/kwinrc"

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$kdeglobals" --group WM --key activeBackground "3,13,5"
    kwriteconfig6 --file "$kdeglobals" --group WM --key activeForeground "142,229,101"
    kwriteconfig6 --file "$kdeglobals" --group WM --key inactiveBackground "5,18,8"
    kwriteconfig6 --file "$kdeglobals" --group WM --key inactiveForeground "93,145,70"
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key library org.kde.breeze
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key theme Breeze
  fi

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme EvilMorty >/dev/null 2>&1 || true
  fi

  reconfigure_kwin

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key library org.kde.klassy
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key theme Klassy
  fi

  reconfigure_kwin
}

write_wallpaper_config() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilMorty.png"
  local plasma_config="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  local plasmarc="$HOME/.config/plasmarc"

  [[ -f "$wallpaper" ]] || return 0

  if [[ -f "$plasma_config" ]]; then
    sed -i \
      -e "s#^Image=.*#Image=file://$wallpaper#g" \
      -e "s#^SlidePaths=.*#SlidePaths=$HOME/.local/share/wallpapers/,/usr/share/wallpapers/#g" \
      "$plasma_config"
  fi

  if [[ -f "$plasmarc" ]]; then
    if grep -q '^\[Wallpapers\]' "$plasmarc"; then
      sed -i "s#^usersWallpapers=.*#usersWallpapers=$wallpaper#g" "$plasmarc"
    else
      printf '\n[Wallpapers]\nusersWallpapers=%s\n' "$wallpaper" >>"$plasmarc"
    fi
  fi
}

stop_plasma_shell_for_restore() {
  plasma_was_running=0
  pgrep -x plasmashell >/dev/null 2>&1 || return 0
  plasma_was_running=1

  log "Stopping Plasma shell before restoring desktop config"
  if command -v systemctl >/dev/null 2>&1 &&
    systemctl --user list-unit-files --no-legend plasma-plasmashell.service 2>/dev/null | grep -q '^plasma-plasmashell\.service'; then
    systemctl --user stop plasma-plasmashell.service || true
  elif command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
  elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell >/dev/null 2>&1 || true
  else
    killall plasmashell >/dev/null 2>&1 || true
  fi

  local attempt
  for attempt in {1..30}; do
    pgrep -x plasmashell >/dev/null 2>&1 || return 0
    sleep 0.2
  done

  killall plasmashell >/dev/null 2>&1 || true
}

start_plasma_shell() {
  pgrep -x plasmashell >/dev/null 2>&1 && return 0

  log "Starting Plasma shell"
  if command -v systemctl >/dev/null 2>&1 &&
    systemctl --user list-unit-files --no-legend plasma-plasmashell.service 2>/dev/null | grep -q '^plasma-plasmashell\.service'; then
    systemctl --user start plasma-plasmashell.service
  else
    nohup plasmashell --replace >/dev/null 2>&1 &
  fi
}

wait_for_plasma_shell() {
  local attempt

  for attempt in {1..50}; do
    pgrep -x plasmashell >/dev/null 2>&1 && return 0
    sleep 0.2
  done

  return 1
}

reconfigure_kwin() {
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  elif command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
  fi
}

main() {
  local dotfiles_dir

  [[ $# -eq 0 ]] || die "install.sh does not accept options; run ./install.sh"

  dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [[ -d "$dotfiles_dir/home" ]] || die "missing dotfiles payload: $dotfiles_dir/home"

  require_command rsync

  install_packages
  configure_autologin

  stop_plasma_shell_for_restore
  restore_dotfiles "$dotfiles_dir"

  normalize_home_paths
  apply_app_configs
  stage_wallpaper
  apply_evilmorty_colors
  write_wallpaper_config
  apply_window_decoration_config
  refresh_window_theme

  if [[ "$plasma_was_running" -eq 1 ]]; then
    start_plasma_shell
    wait_for_plasma_shell || true
    refresh_window_theme
    apply_wallpaper_live
  fi

  log "Install complete"
  log "KDE changes were reloaded if Plasma was running; otherwise log out and back in."
}

main "$@"
