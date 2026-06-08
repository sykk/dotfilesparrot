#!/usr/bin/env bash
set -euo pipefail

repo_url="${DOTFILES_REPO_URL:-}"
install_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
branch="${DOTFILES_BRANCH:-}"
pull_updates=1
dry_run=0
restart_plasma=0
install_apps=0
install_aur_helper=0
enable_flathub=0
enable_sddm_autologin=0
run_setup=0
restore_only=0
explicit_action=0
plasma_was_running=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Install Brandon's dotfiles into $HOME.

Options:
  -r, --repo URL       Git repository to clone when the dotfiles directory is missing
  -d, --dir PATH       Dotfiles checkout directory (default: $HOME/.dotfiles)
  -b, --branch NAME    Branch to clone or update
      --no-pull        Do not pull updates before restoring
      --dry-run        Show what would be restored without changing $HOME
      --restart-plasma Restart Plasma after restoring dotfiles
      --install-apps   Prompt to install the configured app package set
      --install-aur-helper
                       Install an AUR helper when one is missing
      --enable-flathub Enable the Flathub Flatpak remote
      --enable-sddm-autologin
                       Configure SDDM autologin for this user
      --setup          Run package install prompt plus optional system setup
      --restore-only   Only restore dotfiles and apply wallpaper
  -h, --help           Show this help

Examples:
  ./install.sh
  ./install.sh --setup
  ./install.sh --restore-only
  ./install.sh --install-apps --enable-flathub
  DOTFILES_REPO_URL=https://github.com/USER/dotfiles.git bash install.sh
  bash install.sh --repo https://github.com/USER/dotfiles.git
USAGE
}

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo)
      [[ $# -ge 2 ]] || die "$1 requires a URL"
      repo_url="$2"
      shift 2
      ;;
    -d|--dir)
      [[ $# -ge 2 ]] || die "$1 requires a path"
      install_dir="$2"
      shift 2
      ;;
    -b|--branch)
      [[ $# -ge 2 ]] || die "$1 requires a branch name"
      branch="$2"
      shift 2
      ;;
    --no-pull)
      pull_updates=0
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --restart-plasma)
      restart_plasma=1
      explicit_action=1
      shift
      ;;
    --install-apps)
      install_apps=1
      explicit_action=1
      shift
      ;;
    --install-aur-helper)
      install_aur_helper=1
      explicit_action=1
      shift
      ;;
    --enable-flathub)
      enable_flathub=1
      explicit_action=1
      shift
      ;;
    --enable-sddm-autologin)
      enable_sddm_autologin=1
      explicit_action=1
      shift
      ;;
    --setup)
      run_setup=1
      install_apps=1
      enable_sddm_autologin=1
      explicit_action=1
      shift
      ;;
    --restore-only)
      restore_only=1
      explicit_action=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_command git
require_command rsync

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

confirm() {
  local prompt="$1"
  local reply

  [[ -t 0 ]] || return 1
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == [Yy] || "$reply" == [Yy][Ee][Ss] ]]
}

require_arch_like() {
  command -v pacman >/dev/null 2>&1 || die "package installation currently supports Arch-like systems with pacman"
}

aur_helper() {
  if command -v paru >/dev/null 2>&1; then
    printf 'paru\n'
  elif command -v yay >/dev/null 2>&1; then
    printf 'yay\n'
  fi
}

aur_install() {
  local helper="$1"
  shift

  case "$helper" in
    paru)
      PAGER=cat "$helper" -S --needed --noconfirm --skipreview "$@"
      ;;
    yay)
      PAGER=cat "$helper" -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None "$@"
      ;;
    *)
      PAGER=cat "$helper" -S --needed --noconfirm "$@"
      ;;
  esac
}

install_paru_helper() {
  local helper
  helper="$(aur_helper || true)"
  if [[ -n "$helper" ]]; then
    log "AUR helper already installed: $helper"
    return 0
  fi

  require_arch_like
  require_command sudo

  log "Installing paru AUR helper"
  sudo pacman -S --needed --noconfirm base-devel git
  require_command makepkg

  local build_dir
  build_dir="$(mktemp -d)"
  log "Building paru-bin from AUR"
  git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
  (cd "$build_dir/paru-bin" && makepkg -si --noconfirm)
}

install_configured_apps() {
  local helper

  if ! confirm "Install configured packages now?"; then
    log "Package installation skipped"
    return 0
  fi

  require_arch_like

  if ! helper="$(aur_helper)"; then
    install_paru_helper
    helper="$(aur_helper)"
  fi
  [[ -n "$helper" ]] || die "could not find paru or yay after AUR helper setup"

  log "Installing configured packages with $helper: ${APP_PACKAGES[*]}"
  aur_install "$helper" "${APP_PACKAGES[@]}"
}

enable_flathub_remote() {
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

  require_command sudo

  user_name="${SUDO_USER:-$USER}"
  session_name="${SDDM_AUTOLOGIN_SESSION:-plasma.desktop}"
  config_path="/etc/sddm.conf.d/10-autologin.conf"

  log "Writing $config_path"
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Autologin]\nUser=%s\nSession=%s\n' "$user_name" "$session_name" |
    sudo tee "$config_path" >/dev/null
}

run_post_app_setup() {
  if confirm "Enable Flathub Flatpak remote?"; then
    enable_flathub_remote
  fi

  configure_sddm_autologin
}

stage_wallpaper() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilMorty.png"
  local package_wallpaper="$HOME/.local/share/wallpapers/EvilHackerMorty/contents/images/EvilMorty.png"

  if [[ "${DOTFILES_SKIP_THEME_APPLY:-0}" -eq 1 ]]; then
    log "Skipping wallpaper staging"
    return 0
  fi

  mkdir -p "$HOME/.local/share/wallpapers"

  if [[ -f "$package_wallpaper" ]]; then
    cp -f "$package_wallpaper" "$wallpaper"
  fi
}

apply_evilmorty_colors() {
  local color_scheme="$HOME/.local/share/color-schemes/EvilMorty.colors"
  local kdeglobals="$HOME/.config/kdeglobals"

  if [[ "${DOTFILES_SKIP_THEME_APPLY:-0}" -eq 1 ]]; then
    log "Skipping EvilMorty color apply"
    return 0
  fi

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

  if [[ "${DOTFILES_SKIP_THEME_APPLY:-0}" -eq 1 ]]; then
    log "Skipping live wallpaper apply"
    return 0
  fi

  if [[ -f "$wallpaper" ]]; then
    if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
      log "Applying wallpaper"
      plasma-apply-wallpaperimage "$wallpaper" || log "Could not apply wallpaper: $wallpaper"
    else
      log "plasma-apply-wallpaperimage not found; skipping wallpaper apply"
    fi
  else
    log "Wallpaper not found; skipping wallpaper apply"
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

restart_plasma_shell() {
  if ! pgrep -x plasmashell >/dev/null 2>&1; then
    log "Plasma shell is not running; skipping restart"
    return 0
  fi

  log "Restarting Plasma shell"
  if command -v systemctl >/dev/null 2>&1 &&
    systemctl --user list-unit-files --no-legend plasma-plasmashell.service 2>/dev/null | grep -q '^plasma-plasmashell\.service'; then
    systemctl --user restart plasma-plasmashell.service
    return 0
  fi

  if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
  elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell >/dev/null 2>&1 || true
  else
    killall plasmashell >/dev/null 2>&1 || true
  fi

  nohup plasmashell --replace >/dev/null 2>&1 &
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$script_dir/home" && -f "$script_dir/restore.sh" ]]; then
  dotfiles_dir="$script_dir"
elif [[ -d "$install_dir/.git" ]]; then
  dotfiles_dir="$install_dir"
else
  [[ -n "$repo_url" ]] || die "no dotfiles checkout found at $install_dir; pass --repo URL or set DOTFILES_REPO_URL"

  log "Cloning dotfiles into $install_dir"
  clone_args=(clone)
  [[ -n "$branch" ]] && clone_args+=(--branch "$branch")
  clone_args+=("$repo_url" "$install_dir")
  git "${clone_args[@]}"
  dotfiles_dir="$install_dir"
fi

[[ -d "$dotfiles_dir/.git" ]] || die "$dotfiles_dir is not a git repository"
[[ -d "$dotfiles_dir/home" ]] || die "missing dotfiles payload: $dotfiles_dir/home"
[[ -f "$dotfiles_dir/restore.sh" ]] || die "missing restore script: $dotfiles_dir/restore.sh"

if [[ "$pull_updates" -eq 1 ]]; then
  if git -C "$dotfiles_dir" remote get-url origin >/dev/null 2>&1; then
    log "Updating dotfiles checkout"
    if [[ -n "$branch" ]]; then
      git -C "$dotfiles_dir" fetch origin "$branch"
      git -C "$dotfiles_dir" checkout "$branch"
      git -C "$dotfiles_dir" pull --ff-only origin "$branch"
    else
      git -C "$dotfiles_dir" pull --ff-only
    fi
  else
    log "No origin remote configured; using local checkout"
  fi
fi

if [[ "$dry_run" -eq 1 ]]; then
  log "Dry run: listing files that would be restored"
  rsync -ani "$dotfiles_dir/home/" "$HOME/"
  exit 0
fi

if [[ "$explicit_action" -eq 0 ]]; then
  run_setup=1
  install_apps=1
  enable_sddm_autologin=1
fi

if [[ "$restore_only" -eq 1 ]]; then
  run_setup=0
  install_apps=0
  install_aur_helper=0
  enable_flathub=0
  enable_sddm_autologin=0
fi

if [[ "$install_aur_helper" -eq 1 ]]; then
  install_paru_helper
fi

if [[ "$install_apps" -eq 1 ]]; then
  install_configured_apps
fi

if [[ "$run_setup" -eq 1 ]]; then
  run_post_app_setup
fi

if [[ "$enable_flathub" -eq 1 ]]; then
  enable_flathub_remote
fi

if [[ "$enable_sddm_autologin" -eq 1 ]]; then
  configure_sddm_autologin
fi

log "Restoring dotfiles into $HOME"
stop_plasma_shell_for_restore
"$dotfiles_dir/restore.sh"

normalize_home_paths
stage_wallpaper
apply_evilmorty_colors
write_wallpaper_config
apply_window_decoration_config

if [[ "$plasma_was_running" -eq 1 || "$restart_plasma" -eq 1 ]]; then
  start_plasma_shell
  wait_for_plasma_shell || true
  reconfigure_kwin
  apply_wallpaper_live
fi

log "Install complete"
log "KDE changes were reloaded if Plasma was running or --restart-plasma was used; otherwise log out and back in."
