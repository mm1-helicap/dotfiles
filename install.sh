#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX=".pre-dotfiles-$(date +%Y%m%d)"

link_file() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    cp -a "$dest" "${dest}${BACKUP_SUFFIX}" 2>/dev/null || true
    rm -f "$dest"
  fi

  ln -sf "$src" "$dest"
  echo "linked $dest -> $src"
}

link_dir_contents() {
  local src_dir="$1"
  local dest_dir="$2"

  mkdir -p "$dest_dir"
  for item in "$src_dir"/*; do
    [ -e "$item" ] || continue
    link_file "$item" "$dest_dir/$(basename "$item")"
  done
}

mkdir -p "$HOME/.local/bin" "$HOME/.cursor"

link_file "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/bash/.profile" "$HOME/.profile"
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

chmod +x "$DOTFILES_DIR/scripts/"*.sh
link_file "$DOTFILES_DIR/scripts/change_wallpaper.sh" "$HOME/.local/bin/change_wallpaper.sh"
link_file "$DOTFILES_DIR/scripts/tailscale-status-display-names.sh" "$HOME/.local/bin/tailscale-status-display-names.sh"

if [ -d "$DOTFILES_DIR/cursor/skills" ]; then
  link_dir_contents "$DOTFILES_DIR/cursor/skills" "$HOME/.cursor/skills"
fi

if [ -d "$DOTFILES_DIR/cursor/skills-cursor" ]; then
  link_dir_contents "$DOTFILES_DIR/cursor/skills-cursor" "$HOME/.cursor/skills-cursor"
fi

if [ -f "$DOTFILES_DIR/ssh/config.example" ] && [ ! -f "$HOME/.ssh/config" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cp "$DOTFILES_DIR/ssh/config.example" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  echo "created ~/.ssh/config from config.example"
fi

echo ""
echo "Done. Next steps:"
echo "  1. Restore SSH keys: ./scripts/restore-personal.sh ~/personal-backup-*.tar.gz.gpg"
echo "  2. Open a new shell or run: source ~/.bashrc"
