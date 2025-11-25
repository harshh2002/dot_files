# Complete Restoration Guide

This guide explains how to restore your dotfiles on a new machine. It covers both regular dotfiles and encrypted secrets.

## Table of Contents

- [How Restoration Works](#how-restoration-works)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Restoration Steps](#detailed-restoration-steps)
- [Restoring Encrypted Files](#restoring-encrypted-files)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Quick Reference](#quick-reference)

## How Restoration Works

### Understanding Chezmoi Restoration

Chezmoi restoration works by:

1. **Source Directory**: The repository serves as the "source of truth" containing your dotfile templates
2. **Target Directory**: Your home directory (`~`) where files are applied
3. **Apply Process**: `chezmoi apply` reads files from the source and writes them to their target locations

### File Mapping

- `dot_*` files → `~/.{filename}` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_config/*` → `~/.config/*` (e.g., `private_config/nvim/` → `~/.config/nvim/`)
- Encrypted files (`.age` extension) → Decrypted to their target locations

### Restoration Process Flow

```
Repository (source)
    ↓
chezmoi apply
    ↓
Home Directory (target)
    ↓
Files in place, ready to use
```

## Prerequisites

Before starting restoration, ensure you have:

- [ ] **Git** installed (`git --version`)
- [ ] **Chezmoi** installed (`chezmoi --version`) or Homebrew to install it
- [ ] **Access to your repository** (GitHub, GitLab, etc.)
- [ ] **Age encryption key** (if you have encrypted files) - stored in password manager or secure backup

### Installing Prerequisites

**On macOS:**

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install git and chezmoi
brew install git chezmoi

# If you have encrypted files, install age
brew install age
```

**On Linux:**

```bash
# Install git
sudo apt install git  # Debian/Ubuntu
# or
sudo yum install git  # RHEL/CentOS

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <your-github-username>
# Or use your package manager

# Install age (if needed)
sudo apt install age  # Debian/Ubuntu
```

## Quick Start

For the fastest restoration on a new machine:

```bash
# 1. Clone the repository
git clone <your-repo-url> ~/dot_files
cd ~/dot_files

# 2. Run the migration script (handles everything)
./scripts/chezmoi_migrate.sh

# 3. If you have encrypted files, restore your age key first:
#    - Copy your age key to ~/.config/age/keys.txt
#    - Then run: chezmoi apply --source="${HOME}/dot_files"
```

That's it! Your dotfiles should now be restored.

## Detailed Restoration Steps

### Step 1: Clone the Repository

```bash
git clone <your-repository-url> ~/dot_files
cd ~/dot_files
```

**Note**: Replace `<your-repository-url>` with your actual repository URL (e.g., `git@github.com:username/dot_files.git` or `https://github.com/username/dot_files.git`).

### Step 2: Install Dependencies

The migration script will check and install dependencies, but you can also do it manually:

```bash
# Check if chezmoi is installed
chezmoi --version

# If not installed, install it
brew install chezmoi  # macOS
# or use your system's package manager
```

### Step 3: Run the Migration Script (Recommended)

The migration script automates the entire restoration process:

```bash
./scripts/chezmoi_migrate.sh
```

**What the script does:**

1. Checks prerequisites (git, chezmoi)
2. Installs chezmoi if missing
3. Initializes chezmoi if needed
4. Applies all dotfiles from the repository
5. Detects encrypted files and prompts for key restoration
6. Verifies the installation

### Step 4: Manual Restoration (Alternative)

If you prefer manual control or the script doesn't work:

#### 4.1 Initialize Chezmoi

```bash
# Initialize chezmoi (if not already done)
chezmoi init

# Set the source directory to your repository
export CHEZMOI_SOURCE_DIR="${HOME}/dot_files"
```

#### 4.2 Apply Dotfiles

```bash
# Apply all dotfiles from the repository
chezmoi apply --source="${HOME}/dot_files"
```

This command:

- Reads all files from `~/dot_files`
- Applies them to your home directory
- Creates necessary directories
- Sets correct file permissions

#### 4.3 Verify Application

```bash
# Check what would change (dry run)
chezmoi diff --source="${HOME}/dot_files"

# Verify files match source
chezmoi verify --source="${HOME}/dot_files"
```

## Restoring Encrypted Files

If your repository contains encrypted files (files with `.age` extension), you need to restore your encryption key first.

### Step 1: Locate Your Age Key

Your age private key should be backed up in one of these locations:

- Password manager (1Password, Bitwarden, etc.)
- Encrypted USB drive
- Secure cloud storage
- Paper backup (if you printed it)

**Key location on the original machine**: `~/.config/age/keys.txt`

### Step 2: Restore the Age Key

#### Option A: Copy to Standard Location (Recommended)

```bash
# Create the age config directory
mkdir -p ~/.config/age

# Copy your age key to the standard location
# (paste the key content from your backup)
cat > ~/.config/age/keys.txt << 'EOF'
AGE-SECRET-KEY-1...
EOF

# Set secure permissions
chmod 600 ~/.config/age/keys.txt
```

#### Option B: Use Environment Variable

```bash
# Set the age identity via environment variable
export CHEZMOI_AGE_IDENTITY="AGE-SECRET-KEY-1..."

# Or set it in your shell profile
echo 'export CHEZMOI_AGE_IDENTITY="AGE-SECRET-KEY-1..."' >> ~/.zshrc
source ~/.zshrc
```

### Step 3: Apply Encrypted Files

Once the key is restored:

```bash
# Apply dotfiles (encrypted files will be automatically decrypted)
chezmoi apply --source="${HOME}/dot_files"
```

### Step 4: Verify Encrypted Files

```bash
# Check that encrypted files were decrypted correctly
chezmoi verify --source="${HOME}/dot_files"

# Manually verify a specific encrypted file
ls -la ~/.ssh/id_rsa  # Should exist if you encrypted SSH keys
cat ~/.ssh/id_rsa     # Should show readable private key (not encrypted)
```

### Troubleshooting Encrypted Files

**Problem**: Encrypted files not decrypting

**Solutions**:

1. **Verify key location**:

   ```bash
   ls -la ~/.config/age/keys.txt
   # Should show the file exists and has correct permissions (600)
   ```

2. **Test decryption manually**:

   ```bash
   # Find an encrypted file
   find ~/dot_files -name "*.age" | head -1

   # Try to decrypt it
   age -d -i ~/.config/age/keys.txt <encrypted-file>
   ```

3. **Check chezmoi encryption config**:

   ```bash
   cat ~/dot_files/.chezmoi.toml | grep -A 3 encryption
   ```

4. **Verify age key format**:
   ```bash
   head -1 ~/.config/age/keys.txt
   # Should start with "AGE-SECRET-KEY-1"
   ```

## Verification

After restoration, verify everything is working correctly.

### Verification Checklist

- [ ] **Files are in place**:

  ```bash
  ls -la ~/.zshrc
  ls -la ~/.config/nvim/init.vim
  ```

- [ ] **No differences from source**:

  ```bash
  chezmoi diff --source="${HOME}/dot_files"
  # Should show no output (or only expected differences)
  ```

- [ ] **Chezmoi verification passes**:

  ```bash
  chezmoi verify --source="${HOME}/dot_files"
  ```

- [ ] **Encrypted files are decrypted** (if applicable):

  ```bash
  # Check encrypted files are readable
  file ~/.ssh/id_rsa  # Should show "OpenSSH private key" not "data"
  ```

- [ ] **Shell configuration works**:

  ```bash
  # Open a new terminal or reload shell
  source ~/.zshrc
  # Check that your prompt and aliases work
  ```

- [ ] **Editor configuration works**:
  ```bash
  nvim --version
  # Open nvim and check that your config loads
  ```

### Verification Commands

```bash
# See what files are tracked
chezmoi managed --source="${HOME}/dot_files"

# Check for differences
chezmoi diff --source="${HOME}/dot_files"

# Verify all files match
chezmoi verify --source="${HOME}/dot_files"

# Check source path is correct
chezmoi source-path --source="${HOME}/dot_files" ~/.zshrc
# Should output: ~/dot_files/dot_zshrc
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: "chezmoi: command not found"

**Solution**: Install chezmoi

```bash
# macOS
brew install chezmoi

# Linux
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <your-github-username>
```

#### Issue: "Permission denied" when running scripts

**Solution**: Make scripts executable

```bash
chmod +x scripts/*.sh
```

#### Issue: Files not applying

**Solution**: Check source directory

```bash
# Verify source directory is set
echo $CHEZMOI_SOURCE_DIR
# Should output: /Users/yourname/dot_files (or similar)

# Or explicitly set it
export CHEZMOI_SOURCE_DIR="${HOME}/dot_files"
chezmoi apply --source="${HOME}/dot_files"
```

#### Issue: Encrypted files not decrypting

**Solution**: Verify age key

```bash
# Check key exists
ls -la ~/.config/age/keys.txt

# Check key format
head -1 ~/.config/age/keys.txt
# Should start with "AGE-SECRET-KEY-1"

# Test decryption
age -d -i ~/.config/age/keys.txt <encrypted-file>
```

#### Issue: "Source path not found"

**Solution**: Ensure you're in the repository directory

```bash
# Verify you're in the right directory
pwd
# Should be: ~/dot_files

# Check it's a git repository
git status
```

#### Issue: Files differ after restoration

**Solution**: This is normal if you've made local changes

```bash
# See what differs
chezmoi diff --source="${HOME}/dot_files"

# If you want to overwrite local changes with repository version
chezmoi apply --source="${HOME}/dot_files" --force
```

#### Issue: Migration script fails

**Solution**: Run steps manually

```bash
# Follow the "Manual Restoration" steps above
# This gives you more control and better error messages
```

### Getting Help

If you encounter issues not covered here:

1. **Check chezmoi documentation**: https://www.chezmoi.io/
2. **Review your repository**: Ensure all files are committed and pushed
3. **Check encryption setup**: Verify `.chezmoi.toml` has correct encryption config
4. **Verify key backup**: Ensure your age key is correctly restored

## Quick Reference

### Essential Commands

```bash
# Clone repository
git clone <repo-url> ~/dot_files
cd ~/dot_files

# Run migration script (easiest)
./scripts/chezmoi_migrate.sh

# Manual restoration
export CHEZMOI_SOURCE_DIR="${HOME}/dot_files"
chezmoi apply --source="${HOME}/dot_files"

# Restore age key (if needed)
mkdir -p ~/.config/age
# Copy key to ~/.config/age/keys.txt
chmod 600 ~/.config/age/keys.txt

# Verify restoration
chezmoi verify --source="${HOME}/dot_files"
chezmoi diff --source="${HOME}/dot_files"
```

### File Locations

| Repository File              | Target Location             |
| ---------------------------- | --------------------------- |
| `dot_zshrc`                  | `~/.zshrc`                  |
| `private_config/nvim/`       | `~/.config/nvim/`           |
| `private_dot_ssh_id_rsa.age` | `~/.ssh/id_rsa` (decrypted) |
| `.chezmoi.toml`              | Configuration (not applied) |

### Environment Variables

```bash
# Set source directory
export CHEZMOI_SOURCE_DIR="${HOME}/dot_files"

# Set age identity (alternative to file)
export CHEZMOI_AGE_IDENTITY="AGE-SECRET-KEY-1..."
```

### Next Steps After Restoration

1. **Test your configurations**:

   - Open a new terminal
   - Test your shell aliases and functions
   - Open your editor and verify plugins load

2. **Install additional tools** (if needed):

   ```bash
   # Install Homebrew packages
   brew bundle --file=~/dot_files/homebrew/Brewfile
   ```

3. **Set up SSH keys** (if restored):

   ```bash
   chmod 600 ~/.ssh/id_*
   ssh-add ~/.ssh/id_rsa  # or id_ed25519
   ```

4. **Configure Git** (if not already done):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## Summary

Restoration is a straightforward process:

1. **Clone** the repository
2. **Run** the migration script (or apply manually)
3. **Restore** encryption keys (if you have encrypted files)
4. **Verify** everything is working

The migration script (`./scripts/chezmoi_migrate.sh`) handles most of the work automatically. For encrypted files, you just need to restore your age key before applying.

If you run into issues, refer to the [Troubleshooting](#troubleshooting) section or run the steps manually for better error visibility.
