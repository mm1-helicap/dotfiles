# dotfiles

Personal Ubuntu/Linux configuration.

## Quick install (new machine)

```bash
git clone git@github.com:manikuttan-mm1/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
./scripts/restore-personal.sh ~/personal-backup-YYYYMMDD.tar.gz.gpg
```

## What's included

| Category | Path | Installs to |
|----------|------|-------------|
| Shell | `bash/.bashrc`, `bash/.profile` | `~/.bashrc`, `~/.profile` |
| Git | `git/.gitconfig` | `~/.gitconfig` |
| Vim | `vim/.vimrc` | `~/.vimrc` |
| SSH template | `ssh/config.example` | `~/.ssh/config` (if missing) |
| Scripts | `scripts/*.sh` | `~/.local/bin/` |
| Cursor skills | `cursor/skills/`, `cursor/skills-cursor/` | `~/.cursor/skills/`, `~/.cursor/skills-cursor/` |

## Backup before leaving a machine

```bash
cd ~/.dotfiles
./scripts/backup-personal.sh              # saves to ~/personal-backup-YYYYMMDD.tar.gz.gpg
./scripts/backup-personal.sh /media/usb   # or directly to USB
```

This backs up **personal SSH keys only** (not company keys). Private keys are never committed to git.

## Recommended packages (Ubuntu)

```bash
sudo apt install git git-delta meld docker.io jq xclip gnupg
```

Optional tools referenced in `.bashrc`:

- [NVM](https://github.com/nvm-sh/nvm) — Node.js
- [Homebrew on Linux](https://brew.sh) — `gt` (Graphite), other CLI tools
- [Starship](https://starship.rs) — shell prompt
- [Fabric](https://github.com/danielmiessler/fabric) — AI patterns (`~/.config/fabric/patterns/`)

## After install

1. Git email is set to `manikuttanmm@gmail.com` (change with `git config --global user.email` if needed)
2. Restore SSH keys from encrypted backup (see above)
3. Put wallpapers in `~/Pictures/wallpapers/walls/` for the `wallpaper` alias
4. Test GitHub SSH: `ssh -T git@github.com`

## macOS configs (legacy)

`yabai/`, `sesh/`, and parts of `.zshrc` are from an older macOS setup. Ubuntu uses `bash/` instead.
