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
prompt_restart_plasma=0
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
      --restart-plasma Prompt to restart Plasma after restoring dotfiles
      --install-apps   Select and install apps with a terminal checklist
      --install-aur-helper
                       Install an AUR helper when one is missing
      --enable-flathub Enable the Flathub Flatpak remote
      --enable-sddm-autologin
                       Prompt to configure SDDM autologin for this user
      --setup          Run app selection plus optional system setup prompts
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
      prompt_restart_plasma=1
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
  "discord|Discord|discord|ON"
  "git|Git|git|ON"
  "github-cli|GitHub CLI|github-cli|ON"
  "opera-gx|Opera GX|opera-gx|ON"
  "code|Code|code|ON"
  "ghostty|Ghostty|ghostty|ON"
  "fastfetch|Fastfetch|fastfetch|ON"
  "conky|Conky|conky|ON"
  "klassy|Klassy window decorations|klassy|ON"
  "deskflow|Deskflow|deskflow|ON"
  "steam|Steam|steam|ON"
  "lutris|Lutris|lutris|ON"
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

  if confirm "Install paru AUR helper now?"; then
    log "Installing build dependencies"
    sudo pacman -S --needed --noconfirm base-devel git
    require_command makepkg

    local build_dir
    build_dir="$(mktemp -d)"
    log "Building paru-bin from AUR"
    git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
    (cd "$build_dir/paru-bin" && makepkg -si --noconfirm)
  else
    die "AUR helper is required for app installation"
  fi
}

select_apps_with_gui() {
  local choices=()
  local item id name package default_state

  require_command whiptail

  for item in "${APP_PACKAGES[@]}"; do
    IFS='|' read -r id name package default_state <<<"$item"
    choices+=("$id" "$name ($package)" "$default_state")
  done

  whiptail --title "Application Selection" \
    --checklist "Select apps to install with your AUR helper:" \
    22 78 12 \
    "${choices[@]}" \
    3>&1 1>&2 2>&3
}

install_selected_apps() {
  local selected helper packages=()
  local item id name package default_state selected_id

  [[ -t 0 ]] || die "--install-apps requires an interactive terminal"
  require_arch_like

  if ! helper="$(aur_helper)"; then
    install_paru_helper
    helper="$(aur_helper)"
  fi
  [[ -n "$helper" ]] || die "could not find paru or yay after AUR helper setup"

  selected="$(select_apps_with_gui)" || {
    log "Application installation cancelled"
    return 0
  }

  for selected_id in $selected; do
    selected_id="${selected_id%\"}"
    selected_id="${selected_id#\"}"
    for item in "${APP_PACKAGES[@]}"; do
      IFS='|' read -r id name package default_state <<<"$item"
      if [[ "$id" == "$selected_id" ]]; then
        packages+=("$package")
      fi
    done
  done

  if [[ "${#packages[@]}" -eq 0 ]]; then
    log "No apps selected"
    return 0
  fi

  log "Installing selected apps with $helper: ${packages[*]}"
  aur_install "$helper" "${packages[@]}"
}

ensure_app_selector() {
  if command -v whiptail >/dev/null 2>&1; then
    return 0
  fi

  require_arch_like
  require_command sudo

  if confirm "Install whiptail for the app selection GUI?"; then
    sudo pacman -S --needed --noconfirm libnewt
  fi

  require_command whiptail
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

  [[ -t 0 ]] || die "--enable-sddm-autologin requires an interactive terminal"
  confirm "Enable SDDM autologin for $user_name using session '$session_name'?" || {
    log "Skipped SDDM autologin"
    return 0
  }

  log "Writing $config_path"
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Autologin]\nUser=%s\nSession=%s\n' "$user_name" "$session_name" |
    sudo tee "$config_path" >/dev/null
}

run_pre_app_setup_prompts() {
  if confirm "Install or verify paru AUR helper?"; then
    install_paru_helper
  fi
}

run_post_app_setup_prompts() {
  if confirm "Enable Flathub Flatpak remote?"; then
    enable_flathub_remote
  fi

  if confirm "Configure SDDM autologin?"; then
    configure_sddm_autologin
  fi
}

stage_wallpaper() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilHackerMorty.png"
  local fallback_wallpaper="$HOME/Downloads/content.png"
  local source_wallpaper="$HOME/EvilMortyTheme/wallpapers/EvilHackerMorty/contents/images/1920x1080.png"

  if [[ "${DOTFILES_SKIP_THEME_APPLY:-0}" -eq 1 ]]; then
    log "Skipping wallpaper staging"
    return 0
  fi

  mkdir -p "$HOME/.local/share/wallpapers"

  if [[ -f "$source_wallpaper" ]]; then
    cp -f "$source_wallpaper" "$wallpaper"
  elif [[ ! -f "$wallpaper" && -f "$fallback_wallpaper" ]]; then
    cp -f "$fallback_wallpaper" "$wallpaper"
  fi
}

apply_wallpaper_live() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilHackerMorty.png"

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
    "$HOME/.local/share/plasma/look-and-feel/Catppuccin.EvilMorty/contents/layouts/org.kde.plasma.desktop-layout.js"
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
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnLeft XIA
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key ButtonsOnRight ""
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key library org.kde.klassy
    kwriteconfig6 --file "$kwinrc" --group org.kde.kdecoration2 --key theme Klassy
  else
    sed -i \
      -e 's/^ButtonsOnLeft=.*/ButtonsOnLeft=XIA/' \
      -e 's/^ButtonsOnRight=.*/ButtonsOnRight=/' \
      -e 's/^library=.*/library=org.kde.klassy/' \
      -e 's/^theme=.*/theme=Klassy/' \
      "$kwinrc"
  fi
}

write_wallpaper_config() {
  local wallpaper="$HOME/.local/share/wallpapers/EvilHackerMorty.png"
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
  prompt_restart_plasma=1
fi

if [[ "$restore_only" -eq 1 ]]; then
  run_setup=0
  install_apps=0
  install_aur_helper=0
  enable_flathub=0
  enable_sddm_autologin=0
fi

if [[ "$run_setup" -eq 1 ]]; then
  run_pre_app_setup_prompts
fi

if [[ "$install_aur_helper" -eq 1 ]]; then
  install_paru_helper
fi

if [[ "$install_apps" -eq 1 ]]; then
  ensure_app_selector
  install_selected_apps
fi

if [[ "$run_setup" -eq 1 ]]; then
  run_post_app_setup_prompts
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
write_wallpaper_config
apply_window_decoration_config

if [[ "$restart_plasma" -eq 1 || "$prompt_restart_plasma" -eq 1 ]]; then
  if confirm "Start Plasma shell with restored theme now?"; then
    if [[ "$plasma_was_running" -eq 1 ]]; then
      start_plasma_shell
    else
      restart_plasma_shell
    fi
    wait_for_plasma_shell || true
    reconfigure_kwin
    apply_wallpaper_live
  else
    log "Skipped Plasma start"
  fi
elif [[ "$plasma_was_running" -eq 1 ]]; then
  start_plasma_shell
  wait_for_plasma_shell || true
  reconfigure_kwin
  apply_wallpaper_live
fi

log "Install complete"
log "Use --restart-plasma, or log out and back in, for KDE changes to fully reload."
