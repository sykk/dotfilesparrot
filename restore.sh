#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$dotfiles_dir/home/"
backup_dir="$dotfiles_dir/restore-backups/$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$source_dir" ]]; then
  echo "Missing backup source: $source_dir" >&2
  exit 1
fi

mkdir -p "$backup_dir"

rsync -a --backup --backup-dir="$backup_dir" "$source_dir" "$HOME/"

echo "Restored dotfiles into $HOME"
echo "Overwritten originals, if any, were saved in $backup_dir"
