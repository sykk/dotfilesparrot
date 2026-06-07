#!/usr/bin/env bash
set -euo pipefail

repo_url="${DOTFILES_REPO_URL:-}"
install_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
branch="${DOTFILES_BRANCH:-}"
pull_updates=1
dry_run=0
restart_plasma=0

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
  -h, --help           Show this help

Examples:
  ./install.sh
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

confirm() {
  local prompt="$1"
  local reply

  [[ -t 0 ]] || return 1
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == [Yy] || "$reply" == [Yy][Ee][Ss] ]]
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

log "Restoring dotfiles into $HOME"
"$dotfiles_dir/restore.sh"

if [[ "$restart_plasma" -eq 1 ]]; then
  if confirm "Restart Plasma shell now?"; then
    restart_plasma_shell
  else
    log "Skipped Plasma restart"
  fi
fi

log "Install complete"
log "Use --restart-plasma, or log out and back in, for KDE changes to fully reload."
