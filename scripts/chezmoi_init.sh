#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to add private_config files to chezmoi tracking
add_private_config_files() {
    local repo_dir="$1"
    local private_config_dir="${repo_dir}/private_config"
    
    if [[ ! -d "$private_config_dir" ]]; then
        return 0
    fi
    
    echo "[chezmoi] Adding private_config files to chezmoi tracking..."
    
    # Find all files in private_config
    find "$private_config_dir" -type f | while IFS= read -r source_file; do
        # Get relative path from private_config
        rel_path="${source_file#${private_config_dir}/}"
        target="${HOME}/.config/${rel_path}"
        
        # Create target directory if it doesn't exist
        target_dir=$(dirname "$target")
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi
        
        # Copy file to target location if it doesn't exist
        if [[ ! -f "$target" ]]; then
            cp "$source_file" "$target"
            echo "[chezmoi] Created: $target"
        fi
        
        # Add to chezmoi tracking
        if chezmoi add --source="$repo_dir" "$target" 2>/dev/null; then
            echo "[chezmoi] Tracked: $target"
        else
            # If add fails, try re-add (file might already be tracked)
            chezmoi re-add --source="$repo_dir" "$target" 2>/dev/null || true
        fi
    done
    
    echo "[chezmoi] Finished adding private_config files."
}

echo "[chezmoi] Configuring chezmoi to use repository as source of truth."

# Initialize chezmoi if not already initialized
if [[ ! -d "${HOME}/.local/share/chezmoi" ]]; then
  echo "[chezmoi] Running initial chezmoi init..."
  chezmoi init
fi

# Set source directory to this repo
export CHEZMOI_SOURCE_DIR="${REPO_DIR}"

# Add private_config files to chezmoi tracking
add_private_config_files "${REPO_DIR}"

# Apply dotfiles from source
echo "[chezmoi] Applying dotfiles from source: ${REPO_DIR}"
chezmoi apply --source="${REPO_DIR}"

echo "[chezmoi] Done."
echo "[chezmoi] To backup changes, run: scripts/chezmoi_backup.sh"



