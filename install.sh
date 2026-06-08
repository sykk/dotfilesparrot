#!/usr/bin/env bash
set -euo pipefail

plasma_was_running=0

APP_PACKAGES=(
  discord
  git
  github-cli
  opera-gx
  code
  ghostty
  fastfetch
  conky
  deskflow
  steam
  lutris
)

AUR_PACKAGES=(
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

aur_helper() {
  if command -v paru >/dev/null 2>&1; then
    printf 'paru\n'
  elif command -v yay >/dev/null 2>&1; then
    printf 'yay\n'
  fi
}

install_aur_packages() {
  local helper

  [[ "${#AUR_PACKAGES[@]}" -gt 0 ]] || return 0

  helper="$(aur_helper || true)"
  [[ -n "$helper" ]] || die "AUR packages require paru or yay: ${AUR_PACKAGES[*]}"

  log "Installing AUR packages with $helper: ${AUR_PACKAGES[*]}"
  case "$helper" in
    paru)
      PAGER=cat "$helper" -S --needed --noconfirm --skipreview "${AUR_PACKAGES[@]}"
      ;;
    yay)
      PAGER=cat "$helper" -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None "${AUR_PACKAGES[@]}"
      ;;
  esac
}

install_packages() {
  if ! confirm "Install configured packages now?"; then
    log "Package installation skipped"
    return 0
  fi

  require_command sudo
  require_command pacman

  log "Upgrading system and repository packages"
  sudo pacman -Syu --noconfirm

  log "Installing packages with pacman: ${APP_PACKAGES[*]}"
  sudo pacman -S --needed --noconfirm "${APP_PACKAGES[@]}"

  install_aur_packages
}

enable_flathub_remote() {
  if ! confirm "Enable Flathub Flatpak remote?"; then
    return 0
  fi

  require_command flatpak

  if flatpak remotes --columns=name | grep -qx flathub; then
    log "Flathub is already enabled"
    return 0
  fi

  log "Enabling Flathub"
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

configure_sddm_autologin() {
  local user_name session_name config_path

  if ! confirm "Enable SDDM autologin for this user?"; then
    return 0
  fi

  require_command sudo

  user_name="${SUDO_USER:-$USER}"
  session_name="${SDDM_AUTOLOGIN_SESSION:-plasma.desktop}"
  config_path="/etc/sddm.conf.d/10-autologin.conf"

  log "Writing $config_path"
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Autologin]\nUser=%s\nSession=%s\n' "$user_name" "$session_name" |
    sudo tee "$config_path" >/dev/null
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

apply_window_decoration_config() {
  local kwinrc="$HOME/.config/kwinrc"

  [[ -f "$kwinrc" ]] || return 0

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnLeft ""
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnRight IAX
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key library org.kde.breeze
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key theme Breeze
  else
    sed -i \
      -e 's/^ButtonsOnLeft=.*/ButtonsOnLeft=/' \
      -e 's/^ButtonsOnRight=.*/ButtonsOnRight=IAX/' \
      -e 's/^library=.*/library=org.kde.breeze/' \
      -e 's/^theme=.*/theme=Breeze/' \
      "$kwinrc"
  fi
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
  enable_flathub_remote
  configure_sddm_autologin

  stop_plasma_shell_for_restore
  restore_dotfiles "$dotfiles_dir"

  normalize_home_paths
  stage_wallpaper
  apply_evilmorty_colors
  write_wallpaper_config
  apply_window_decoration_config

  if [[ "$plasma_was_running" -eq 1 ]]; then
    start_plasma_shell
    wait_for_plasma_shell || true
    reconfigure_kwin
    apply_wallpaper_live
  fi

  log "Install complete"
  log "KDE changes were reloaded if Plasma was running; otherwise log out and back in."
}

main "$@"
