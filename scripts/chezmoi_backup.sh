#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[chezmoi] Starting backup process..."
echo "[chezmoi] Repository: ${REPO_DIR}"

# Check if chezmoi is initialized
if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
    echo "[chezmoi] Error: Chezmoi is not initialized. Run scripts/chezmoi_init.sh first."
    exit 1
fi

# Set source directory to this repo
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
if [[ "$ENCRYPTION_TYPE" != "none" ]]; then
    echo "[chezmoi] Encryption: ${ENCRYPTION_TYPE}"
fi

# Function to check if a file should be encrypted
should_encrypt() {
    local file_path="$1"
    # Patterns that typically should be encrypted
    if [[ "$file_path" =~ \.ssh/(id_|.*_rsa|.*_ed25519|.*_ecdsa) ]] || \
       [[ "$file_path" =~ \.aws/credentials ]] || \
       [[ "$file_path" =~ \.gcloud/ ]] || \
       [[ "$file_path" =~ \.config/gh/hosts\.yml ]] || \
       [[ "$file_path" =~ credentials ]] || \
       [[ "$file_path" =~ secrets ]]; then
        return 0
    fi
    return 1
}

# Function to check if a file is encrypted
is_encrypted() {
    local target_file="$1"
    local source_file
    
    source_file=$(chezmoi source-path --source="${REPO_DIR}" "$target_file" 2>/dev/null || echo "")
    
    if [[ -z "$source_file" ]]; then
        echo "not_tracked"
        return
    fi
    
    if chezmoi chattr --source="${REPO_DIR}" "$target_file" 2>/dev/null | grep -q "encrypted"; then
        echo "encrypted"
    else
        echo "not_encrypted"
    fi
}

# Show current status
echo ""
echo "[chezmoi] Checking for changes..."
chezmoi diff --source="${REPO_DIR}" || true

# Ask user which files to add/update
echo ""
echo "[chezmoi] Select files to backup:"
echo "  1) All tracked files (re-add existing)"
echo "  2) Add new files interactively"
echo "  3) Add specific file/directory"
echo "  4) Show current status only (no changes)"
if [[ "$ENCRYPTION_TYPE" != "none" ]]; then
    echo "  5) Show encryption status"
fi
read -p "Enter choice [1-5] (default: 1): " choice
choice=${choice:-1}

case "$choice" in
    1)
        echo "[chezmoi] Re-adding all tracked files..."
        # Find all dotfiles in the source directory and re-add them
        # This handles dot_* files and private_config/* directories
        found_files=0
        
        # Re-add dot_* files (they become ~/.{filename})
        for dotfile in "${REPO_DIR}"/dot_*; do
            if [[ -f "$dotfile" ]]; then
                # Extract the target path (e.g., dot_zshrc -> ~/.zshrc)
                filename=$(basename "$dotfile")
                target="${HOME}/.${filename#dot_}"
                if [[ -e "$target" ]]; then
                    echo "[chezmoi] Updating: $target"
                    chezmoi re-add --source="${REPO_DIR}" "$target" || true
                    found_files=1
                fi
            fi
        done
        
        # Re-add private_config/* directories (they become ~/.config/*)
        if [[ -d "${REPO_DIR}/private_config" ]]; then
            while IFS= read -r -d '' config_dir; do
                # Get relative path from private_config
                rel_path="${config_dir#${REPO_DIR}/private_config/}"
                target="${HOME}/.config/${rel_path}"
                if [[ -e "$target" ]]; then
                    echo "[chezmoi] Updating: $target"
                    chezmoi re-add --source="${REPO_DIR}" "$target" || true
                    found_files=1
                fi
            done < <(find "${REPO_DIR}/private_config" -type d -print0)
        fi
        
        if [[ $found_files -eq 0 ]]; then
            echo "[chezmoi] No matching files found in home directory."
            echo "[chezmoi] Make sure you've run scripts/chezmoi_init.sh first."
        fi
        ;;
    2)
        echo "[chezmoi] Interactive mode - chezmoi will prompt for each file"
        chezmoi add --source="${REPO_DIR}" -i
        ;;
    3)
        read -p "Enter file or directory path (e.g., ~/.zshrc or ~/.config/nvim): " file_path
        # Expand ~ to $HOME
        file_path="${file_path/#\~/$HOME}"
        if [[ -e "$file_path" ]]; then
            # Check if file should be encrypted
            if should_encrypt "$file_path"; then
                if [[ "$ENCRYPTION_TYPE" != "none" ]]; then
                    echo "[chezmoi] This file appears to contain sensitive data."
                    read -p "[chezmoi] Encrypt this file? [Y/n]: " encrypt_choice
                    if [[ ! "$encrypt_choice" =~ ^[Nn]$ ]]; then
                        echo "[chezmoi] Adding with encryption: $file_path"
                        chezmoi add --encrypt --force --config="${REPO_DIR}/.chezmoi.toml" --source="${REPO_DIR}" "$file_path" 2>&1 | grep -v "warning:" || true
                    else
                        echo "[chezmoi] Adding without encryption: $file_path"
                        chezmoi add --force --source="${REPO_DIR}" "$file_path" 2>&1 | grep -v "warning:" || true
                    fi
                else
                    echo "[chezmoi] Warning: This file appears sensitive but encryption is not configured."
                    echo "[chezmoi] Adding without encryption: $file_path"
                    echo "[chezmoi] To encrypt, run: ./scripts/chezmoi_setup_encryption.sh first"
                    chezmoi add --source="${REPO_DIR}" "$file_path"
                fi
            else
                echo "[chezmoi] Adding: $file_path"
                chezmoi add --source="${REPO_DIR}" "$file_path"
            fi
        else
            echo "[chezmoi] Error: File or directory not found: $file_path"
            exit 1
        fi
        ;;
    4)
        echo "[chezmoi] Showing status only. No changes made."
        exit 0
        ;;
    5)
        if [[ "$ENCRYPTION_TYPE" == "none" ]]; then
            echo "[chezmoi] Encryption is not configured."
            exit 0
        fi
        echo ""
        echo "[chezmoi] Encryption Status:"
        echo "[chezmoi] Type: ${ENCRYPTION_TYPE}"
        echo ""
        
        # Check common files
        COMMON_FILES=(
            "${HOME}/.ssh/id_rsa"
            "${HOME}/.ssh/id_ed25519"
            "${HOME}/.aws/credentials"
            "${HOME}/.config/gh/hosts.yml"
        )
        
        echo "[chezmoi] Common sensitive files:"
        for file in "${COMMON_FILES[@]}"; do
            if [[ -e "$file" ]]; then
                status=$(is_encrypted "$file")
                case "$status" in
                    encrypted)
                        echo "  ✓ ${file} - ENCRYPTED"
                        ;;
                    not_encrypted)
                        echo "  ○ ${file} - Not encrypted"
                        ;;
                    not_tracked)
                        echo "  - ${file} - Not tracked"
                        ;;
                esac
            fi
        done
        echo ""
        echo "[chezmoi] To encrypt files, run: ./scripts/chezmoi_encrypt_secrets.sh"
        exit 0
        ;;
    *)
        echo "[chezmoi] Invalid choice. Exiting."
        exit 1
        ;;
esac

# Show diff of changes
echo ""
echo "[chezmoi] Changes made:"
chezmoi diff --source="${REPO_DIR}" || echo "[chezmoi] No changes detected."

# Show encryption status if encryption is configured
if [[ "$ENCRYPTION_TYPE" != "none" ]]; then
    echo ""
    echo "[chezmoi] Encryption status:"
    encrypted_count=$(find "${REPO_DIR}" -type f \( -name "*.encrypted" -o -name "*.age" \) 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$encrypted_count" -gt 0 ]]; then
        echo "[chezmoi] ✓ ${encrypted_count} encrypted file(s) in repository"
    else
        echo "[chezmoi] No encrypted files found"
    fi
fi

# Ask if user wants to commit to git
echo ""
read -p "[chezmoi] Commit changes to git? [y/N]: " commit_choice
if [[ "$commit_choice" =~ ^[Yy]$ ]]; then
    cd "${REPO_DIR}"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "[chezmoi] Staging changes..."
        git add -A
        echo "[chezmoi] Changes staged. Run 'git commit' to commit them."
        echo "[chezmoi] Suggested commit message:"
        echo "  git commit -m 'chore: update dotfiles via chezmoi'"
    else
        echo "[chezmoi] Not a git repository. Skipping git operations."
    fi
fi

echo ""
echo "[chezmoi] Backup complete!"

