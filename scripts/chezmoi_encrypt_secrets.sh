#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[chezmoi] Secrets Encryption Helper"
echo "===================================="
echo ""

# Check if chezmoi is initialized
if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
    echo "[chezmoi] Error: Chezmoi is not initialized. Run scripts/chezmoi_init.sh first."
    exit 1
fi

# Set source directory
export CHEZMOI_SOURCE_DIR="${REPO_DIR}"

# Check encryption configuration from .chezmoi.toml
CHEZMOI_CONFIG="${REPO_DIR}/.chezmoi.toml"
if [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "^encryption.*=.*\"age\"" "$CHEZMOI_CONFIG" 2>/dev/null; then
    ENCRYPTION_TYPE="age"
elif [[ -f "$CHEZMOI_CONFIG" ]] && grep -q "^encryption.*=.*\"gpg\"" "$CHEZMOI_CONFIG" 2>/dev/null; then
    ENCRYPTION_TYPE="gpg"
else
    ENCRYPTION_TYPE="none"
fi

if [[ "$ENCRYPTION_TYPE" == "none" ]]; then
    echo "[chezmoi] Warning: Encryption is not configured."
    echo "[chezmoi] Run scripts/chezmoi_setup_encryption.sh first."
    echo ""
    read -p "[chezmoi] Continue anyway? [y/N]: " continue_anyway
    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "[chezmoi] Encryption type: ${ENCRYPTION_TYPE}"
fi

echo ""

# Common files that should be encrypted
RECOMMENDED_FILES=(
    "${HOME}/.ssh/id_rsa"
    "${HOME}/.ssh/id_ed25519"
    "${HOME}/.ssh/id_ecdsa"
    "${HOME}/.aws/credentials"
    "${HOME}/.config/gh/hosts.yml"
    "${HOME}/.gcloud/credentials"
)

# Check which recommended files exist
EXISTING_FILES=()
for file in "${RECOMMENDED_FILES[@]}"; do
    if [[ -e "$file" ]]; then
        EXISTING_FILES+=("$file")
    fi
done

# Function to check if a file is encrypted in chezmoi
is_encrypted() {
    local target_file="$1"
    local source_file
    
    # Get the source file path
    source_file=$(chezmoi source-path --source="${REPO_DIR}" "$target_file" 2>/dev/null || echo "")
    
    if [[ -z "$source_file" ]]; then
        echo "not_tracked"
        return
    fi
    
    # Check if file has encrypted attribute
    if chezmoi chattr --source="${REPO_DIR}" "$target_file" 2>/dev/null | grep -q "encrypted"; then
        echo "encrypted"
    else
        echo "not_encrypted"
    fi
}

# Show menu
echo "[chezmoi] Select an option:"
echo "  1) List recommended files to encrypt"
echo "  2) Encrypt a specific file"
echo "  3) Check encryption status of files"
echo "  4) Encrypt all recommended files (interactive)"
echo "  5) Show encrypted files in repository"
read -p "Enter choice [1-5]: " choice

case "$choice" in
    1)
        echo ""
        echo "[chezmoi] Recommended files to encrypt:"
        echo ""
        for file in "${RECOMMENDED_FILES[@]}"; do
            if [[ -e "$file" ]]; then
                status=$(is_encrypted "$file")
                case "$status" in
                    encrypted)
                        echo "  ✓ ${file} (already encrypted)"
                        ;;
                    not_encrypted)
                        echo "  ○ ${file} (not encrypted)"
                        ;;
                    not_tracked)
                        echo "  - ${file} (not tracked)"
                        ;;
                esac
            else
                echo "  ✗ ${file} (does not exist)"
            fi
        done
        echo ""
        ;;
    2)
        read -p "Enter file path to encrypt (e.g., ~/.ssh/id_rsa): " file_path
        # Expand ~ to $HOME
        file_path="${file_path/#\~/$HOME}"
        
        if [[ ! -e "$file_path" ]]; then
            echo "[chezmoi] Error: File not found: ${file_path}"
            exit 1
        fi
        
        echo "[chezmoi] Adding and encrypting: ${file_path}"
        
        # Check if already tracked
        if chezmoi source-path --source="${REPO_DIR}" "$file_path" >/dev/null 2>&1; then
            echo "[chezmoi] File is already tracked. Setting encrypted attribute..."
            chezmoi chattr +encrypted --source="${REPO_DIR}" "$file_path"
            echo "[chezmoi] Re-adding file with encryption..."
            chezmoi re-add --source="${REPO_DIR}" "$file_path"
        else
            echo "[chezmoi] Adding new file with encryption..."
            # Use --force to override ignore patterns when explicitly encrypting
            # Use --config to point to the config file in the repo
            chezmoi add --encrypt --force --config="${REPO_DIR}/.chezmoi.toml" --source="${REPO_DIR}" "$file_path" 2>&1 | grep -v "warning:" || true
        fi
        
        echo "[chezmoi] ✓ File encrypted and added to repository"
        ;;
    3)
        echo ""
        echo "[chezmoi] Encryption status:"
        echo ""
        for file in "${EXISTING_FILES[@]}"; do
            status=$(is_encrypted "$file")
            case "$status" in
                encrypted)
                    echo "  ✓ ${file} - ENCRYPTED"
                    ;;
                not_encrypted)
                    echo "  ○ ${file} - Not encrypted"
                    ;;
                not_tracked)
                    echo "  - ${file} - Not tracked by chezmoi"
                    ;;
            esac
        done
        echo ""
        ;;
    4)
        echo ""
        echo "[chezmoi] Encrypting recommended files (interactive)..."
        echo ""
        for file in "${EXISTING_FILES[@]}"; do
            status=$(is_encrypted "$file")
            if [[ "$status" == "encrypted" ]]; then
                echo "[chezmoi] Skipping ${file} (already encrypted)"
                continue
            fi
            
            read -p "[chezmoi] Encrypt ${file}? [y/N]: " encrypt_file
            if [[ "$encrypt_file" =~ ^[Yy]$ ]]; then
                if [[ "$status" == "not_tracked" ]]; then
                    echo "[chezmoi] Adding and encrypting: ${file}"
                    # Use --force to override ignore patterns when explicitly encrypting
                    # Use --config to point to the config file in the repo
                    chezmoi add --encrypt --force --config="${REPO_DIR}/.chezmoi.toml" --source="${REPO_DIR}" "$file" 2>&1 | grep -v "warning:" || true
                else
                    echo "[chezmoi] Encrypting existing tracked file: ${file}"
                    chezmoi chattr +encrypted --source="${REPO_DIR}" "$file"
                    chezmoi re-add --source="${REPO_DIR}" "$file"
                fi
                
                # Verify it was added
                if chezmoi source-path --source="${REPO_DIR}" "$file" >/dev/null 2>&1; then
                    echo "[chezmoi] ✓ Encrypted: ${file}"
                else
                    echo "[chezmoi] ⚠ Warning: File may still be ignored. Check .chezmoiignore"
                    echo "[chezmoi] Make sure the pattern is commented out in .chezmoiignore"
                fi
            fi
        done
        echo ""
        echo "[chezmoi] Done!"
        ;;
    5)
        echo ""
        echo "[chezmoi] Encrypted files in repository:"
        echo ""
        # Find encrypted files in source directory
        if [[ -d "${REPO_DIR}" ]]; then
            find "${REPO_DIR}" -type f -name "*.encrypted" -o -name "*.age" 2>/dev/null | while read -r file; do
                rel_path="${file#${REPO_DIR}/}"
                echo "  ${rel_path}"
            done
        fi
        echo ""
        ;;
    *)
        echo "[chezmoi] Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "[chezmoi] Next steps:"
echo "  1. Review encrypted files: chezmoi diff --source=\"${REPO_DIR}\""
echo "  2. Commit encrypted files to repository"
echo "  3. Backup your encryption keys separately!"
echo ""

