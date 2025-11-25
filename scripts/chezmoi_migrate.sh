#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[chezmoi] Migration to New Device"
echo "================================="
echo ""

# Check prerequisites
echo "[chezmoi] Checking prerequisites..."

# Check git
if ! command -v git >/dev/null 2>&1; then
    echo "[chezmoi] ✗ Git is not installed"
    echo "[chezmoi] Install git first: brew install git"
    exit 1
else
    echo "[chezmoi] ✓ Git is installed"
fi

# Check chezmoi
if ! command -v chezmoi >/dev/null 2>&1; then
    echo "[chezmoi] ✗ Chezmoi is not installed"
    echo "[chezmoi] Installing chezmoi..."
    
    if command -v brew >/dev/null 2>&1; then
        brew install chezmoi
    else
        echo "[chezmoi] Error: Homebrew not found. Please install chezmoi manually:"
        echo "[chezmoi]   https://www.chezmoi.io/install/"
        exit 1
    fi
else
    echo "[chezmoi] ✓ Chezmoi is installed"
fi

echo ""

# Check if repository is already cloned
if [[ ! -d "${REPO_DIR}/.git" ]]; then
    echo "[chezmoi] Warning: This doesn't appear to be a git repository."
    echo "[chezmoi] If you're running this from a cloned repo, that's fine."
    echo "[chezmoi] If not, make sure you're in the dotfiles directory."
    echo ""
    read -p "[chezmoi] Continue? [Y/n]: " continue_migration
    if [[ "$continue_migration" =~ ^[Nn]$ ]]; then
        exit 0
    fi
fi

# Initialize chezmoi if not already initialized
if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
    echo "[chezmoi] Initializing chezmoi..."
    chezmoi init
    echo "[chezmoi] ✓ Chezmoi initialized"
else
    echo "[chezmoi] ✓ Chezmoi already initialized"
fi

# Set source directory
export CHEZMOI_SOURCE_DIR="${REPO_DIR}"

# Apply dotfiles
echo ""
echo "[chezmoi] Applying dotfiles from: ${REPO_DIR}"
chezmoi apply --source="${REPO_DIR}"

if [[ $? -eq 0 ]]; then
    echo "[chezmoi] ✓ Dotfiles applied successfully"
else
    echo "[chezmoi] ✗ Error applying dotfiles"
    exit 1
fi

# Check for encrypted files
echo ""
CHEZMOI_CONFIG="${REPO_DIR}/.chezmoi.toml"
if [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "^encryption.*=.*\"age\"" "$CHEZMOI_CONFIG" 2>/dev/null; then
    ENCRYPTION_TYPE="age"
elif [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "^encryption.*=.*\"gpg\"" "$CHEZMOI_CONFIG" 2>/dev/null; then
    ENCRYPTION_TYPE="gpg"
else
    ENCRYPTION_TYPE="none"
fi

if [[ "$ENCRYPTION_TYPE" != "none" ]]; then
    echo "[chezmoi] Encryption is configured: ${ENCRYPTION_TYPE}"
    echo ""
    echo "[chezmoi] ========================================="
    echo "[chezmoi] ENCRYPTED FILES DETECTED"
    echo "[chezmoi] ========================================="
    echo ""
    
    if [[ "$ENCRYPTION_TYPE" == "age" ]]; then
        AGE_KEY_FILE="${HOME}/.config/age/keys.txt"
        if [[ -f "$AGE_KEY_FILE" ]]; then
            echo "[chezmoi] ✓ Age key found at: ${AGE_KEY_FILE}"
            echo "[chezmoi] Attempting to apply encrypted files..."
            chezmoi apply --source="${REPO_DIR}"
            echo "[chezmoi] ✓ Encrypted files applied"
        else
            echo "[chezmoi] ✗ Age key not found at: ${AGE_KEY_FILE}"
            echo "[chezmoi] To restore encrypted files:"
            echo "  1. Restore your age key to: ${AGE_KEY_FILE}"
            echo "  2. Or set CHEZMOI_AGE_IDENTITY environment variable"
            echo "  3. Then run: chezmoi apply --source=\"${REPO_DIR}\""
            echo ""
            read -p "[chezmoi] Have you restored your age key? [y/N]: " key_restored
            if [[ "$key_restored" =~ ^[Yy]$ ]]; then
                chezmoi apply --source="${REPO_DIR}"
                echo "[chezmoi] ✓ Encrypted files applied"
            else
                echo "[chezmoi] Skipping encrypted files. Restore your key and run:"
                echo "  chezmoi apply --source=\"${REPO_DIR}\""
            fi
        fi
    elif [[ "$ENCRYPTION_TYPE" == "gpg" ]]; then
        if gpg --list-secret-keys >/dev/null 2>&1; then
            echo "[chezmoi] ✓ GPG keys found"
            echo "[chezmoi] Attempting to apply encrypted files..."
            chezmoi apply --source="${REPO_DIR}"
            echo "[chezmoi] ✓ Encrypted files applied"
        else
            echo "[chezmoi] ✗ GPG keys not found"
            echo "[chezmoi] To restore encrypted files:"
            echo "  1. Import your GPG key: gpg --import <your-key-file>"
            echo "  2. Then run: chezmoi apply --source=\"${REPO_DIR}\""
            echo ""
            read -p "[chezmoi] Have you imported your GPG key? [y/N]: " key_imported
            if [[ "$key_imported" =~ ^[Yy]$ ]]; then
                chezmoi apply --source="${REPO_DIR}"
                echo "[chezmoi] ✓ Encrypted files applied"
            else
                echo "[chezmoi] Skipping encrypted files. Import your key and run:"
                echo "  chezmoi apply --source=\"${REPO_DIR}\""
            fi
        fi
    fi
else
    echo "[chezmoi] No encryption configured. All files applied."
fi

# Verify installation
echo ""
echo "[chezmoi] Verifying installation..."
if chezmoi verify --source="${REPO_DIR}" 2>/dev/null; then
    echo "[chezmoi] ✓ Verification passed"
else
    echo "[chezmoi] ⚠ Some files may differ from source"
    echo "[chezmoi] Run 'chezmoi diff --source=\"${REPO_DIR}\"' to see differences"
fi

# Show summary
echo ""
echo "[chezmoi] ========================================="
echo "[chezmoi] Migration Complete!"
echo "[chezmoi] ========================================="
echo ""
echo "[chezmoi] Next steps:"
echo "  1. Verify your configurations are working"
echo "  2. Check for any differences: chezmoi diff --source=\"${REPO_DIR}\""
echo "  3. If you have encrypted files, ensure your keys are properly restored"
echo "  4. Test your shell, editor, and other tools"
echo ""
echo "[chezmoi] To backup changes in the future:"
echo "  ./scripts/chezmoi_backup.sh"
echo ""

