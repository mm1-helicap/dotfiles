#!/usr/bin/env bash
set -euo pipefail

# Restores personal SSH keys from an encrypted backup.
#
# Usage:
#   ./scripts/restore-personal.sh ~/personal-backup-20260713.tar.gz.gpg

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 /path/to/personal-backup-YYYYMMDD.tar.gz.gpg"
  exit 1
fi

ENCRYPTED="$1"
TMP_ARCHIVE="${TMPDIR:-/tmp}/personal-restore-$$.tar.gz"
RESTORE_DIR="${TMPDIR:-/tmp}/personal-restore-$$"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

echo "Decrypting ${ENCRYPTED}..."
gpg --decrypt -o "${TMP_ARCHIVE}" "${ENCRYPTED}"

mkdir -p "${RESTORE_DIR}"
tar -xzf "${TMP_ARCHIVE}" -C "${RESTORE_DIR}"

SRC="$(find "${RESTORE_DIR}" -mindepth 1 -maxdepth 1 -type d | head -1)/ssh"
if [ ! -d "${SRC}" ]; then
  echo "Error: backup does not contain ssh/ directory"
  rm -rf "${RESTORE_DIR}" "${TMP_ARCHIVE}"
  exit 1
fi

for key in id_ed25519 id_ed06112024; do
  if [ -f "${SRC}/${key}" ]; then
    cp -a "${SRC}/${key}" "${HOME}/.ssh/${key}"
    chmod 600 "${HOME}/.ssh/${key}"
    echo "restored ${key}"
  fi
  if [ -f "${SRC}/${key}.pub" ]; then
    cp -a "${SRC}/${key}.pub" "${HOME}/.ssh/${key}.pub"
    chmod 644 "${HOME}/.ssh/${key}.pub"
    echo "restored ${key}.pub"
  fi
done

if [ -f "${SRC}/config" ]; then
  cp -a "${SRC}/config" "${HOME}/.ssh/config"
  chmod 600 "${HOME}/.ssh/config"
  echo "restored config"
fi

rm -rf "${RESTORE_DIR}" "${TMP_ARCHIVE}"
echo ""
echo "Done. Test with: ssh -T git@github.com"
