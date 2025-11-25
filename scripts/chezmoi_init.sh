#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[chezmoi] Configuring chezmoi to use repository as source of truth."

# Initialize chezmoi if not already initialized
if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
  echo "[chezmoi] Running initial chezmoi init..."
  chezmoi init
fi

# Set source directory to this repo
export CHEZMOI_SOURCE_DIR="${REPO_DIR}"

# Apply dotfiles from source
echo "[chezmoi] Applying dotfiles from source: ${REPO_DIR}"
chezmoi apply --source="${REPO_DIR}"

echo "[chezmoi] Done."
echo "[chezmoi] To backup changes, run: scripts/chezmoi_backup.sh"



