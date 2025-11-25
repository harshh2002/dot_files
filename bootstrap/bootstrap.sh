#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="${REPO_DIR}/homebrew/Brewfile"

echo "[bootstrap] Starting bootstrap for macOS..."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[bootstrap] This script is intended for macOS. Exiting."
  exit 1
fi

# Xcode Command Line Tools (may open a GUI dialog on fresh systems)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "[bootstrap] If a GUI prompt appeared, complete it, then rerun this script."
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "[bootstrap] Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "[bootstrap] Running brew bundle..."
brew bundle --file="${BREWFILE}"

# oh-my-zsh
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
  echo "[bootstrap] Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "[bootstrap] oh-my-zsh already installed, skipping..."
fi

echo "[bootstrap] Ensuring chezmoi is installed..."
if ! command -v chezmoi >/dev/null 2>&1; then
  brew install chezmoi
fi

echo "[bootstrap] Initializing chezmoi from repo..."
"${REPO_DIR}/scripts/chezmoi_init.sh"

echo "[bootstrap] Applying macOS defaults (safe subset)..."
if [[ -x "${REPO_DIR}/bootstrap/macos_defaults.sh" ]]; then
  "${REPO_DIR}/bootstrap/macos_defaults.sh" || true
fi

echo "[bootstrap] Completed."



