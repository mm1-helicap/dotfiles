#!/usr/bin/env bash
set -euo pipefail

# Creates a local encrypted backup of personal SSH keys and config.
# Private keys are NEVER committed to the dotfiles git repo.
#
# Usage:
#   ./scripts/backup-personal.sh
#   ./scripts/backup-personal.sh /media/usb/backups

OUT_BASE="${1:-$HOME}"
STAMP="$(date +%Y%m%d)"
BACKUP_DIR="${OUT_BASE}/personal-backup-${STAMP}"
ARCHIVE="${BACKUP_DIR}.tar.gz"
ENCRYPTED="${ARCHIVE}.gpg"

mkdir -p "${BACKUP_DIR}/ssh"

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    cp -a "$src" "$dest"
    echo "  + $(basename "$src")"
  fi
}

echo "Backing up personal SSH keys and config to ${BACKUP_DIR}"

copy_if_exists "${HOME}/.ssh/id_ed25519" "${BACKUP_DIR}/ssh/"
copy_if_exists "${HOME}/.ssh/id_ed25519.pub" "${BACKUP_DIR}/ssh/"
copy_if_exists "${HOME}/.ssh/id_ed06112024" "${BACKUP_DIR}/ssh/"
copy_if_exists "${HOME}/.ssh/id_ed06112024.pub" "${BACKUP_DIR}/ssh/"

if [ -f "${HOME}/.ssh/config" ]; then
  grep -v -E 'hifx|inflect' "${HOME}/.ssh/config" > "${BACKUP_DIR}/ssh/config" || true
  if [ ! -s "${BACKUP_DIR}/ssh/config" ]; then
    cp "${HOME}/dotfiles-sync/ssh/config.example" "${BACKUP_DIR}/ssh/config" 2>/dev/null \
      || cp "$(dirname "$0")/../ssh/config.example" "${BACKUP_DIR}/ssh/config"
  fi
  echo "  + config (company hosts stripped)"
else
  cp "$(dirname "$0")/../ssh/config.example" "${BACKUP_DIR}/ssh/config"
  echo "  + config.example"
fi

cat > "${BACKUP_DIR}/MANIFEST.txt" <<EOF
Personal backup created: $(date -Iseconds)
Host: $(hostname)
Contents:
  - Personal SSH private/public keys (NOT company hifx key)
  - SSH config without company hosts

Restore on new Ubuntu:
  ./scripts/restore-personal.sh ${ENCRYPTED}
EOF

tar -czf "${ARCHIVE}" -C "$(dirname "${BACKUP_DIR}")" "$(basename "${BACKUP_DIR}")"
rm -rf "${BACKUP_DIR}"

echo ""
echo "Created archive: ${ARCHIVE}"

if [ "${BACKUP_NO_ENCRYPT:-0}" = "1" ]; then
  chmod 600 "${ARCHIVE}"
  echo ""
  echo "Unencrypted backup ready (encrypt before copying off-machine):"
  echo "  gpg --symmetric --cipher-algo AES256 -o ${ENCRYPTED} ${ARCHIVE}"
  echo "  ${ARCHIVE}"
  exit 0
fi

echo "Encrypting with GPG (you will be prompted for a passphrase)..."
if gpg --symmetric --cipher-algo AES256 -o "${ENCRYPTED}" "${ARCHIVE}"; then
  rm -f "${ARCHIVE}"
  chmod 600 "${ENCRYPTED}"
  echo ""
  echo "Encrypted backup ready:"
  echo "  ${ENCRYPTED}"
else
  chmod 600 "${ARCHIVE}"
  echo ""
  echo "GPG encryption skipped (no TTY?). Unencrypted archive kept at:"
  echo "  ${ARCHIVE}"
  echo "Encrypt manually: gpg --symmetric --cipher-algo AES256 -o ${ENCRYPTED} ${ARCHIVE}"
fi
echo ""
echo "Copy to USB or cloud storage. Do not leave unencrypted keys on shared machines."
