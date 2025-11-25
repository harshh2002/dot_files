# dot_files

Packages, configs and rice of my m1 macbook pro 2020

![image](rice/screenshots/profile_1.png)

## Quick Start

**New to this repository?**

- **Setting up on a new machine?** See [RESTORATION_GUIDE.md](RESTORATION_GUIDE.md) for complete restoration instructions.
- **Backing up your dotfiles?** See [BACKUP_GUIDE.md](BACKUP_GUIDE.md) for a complete step-by-step guide from setup to backup.

## Chezmoi Setup

This repository uses [chezmoi](https://www.chezmoi.io/) to manage dotfiles. The repository structure follows chezmoi conventions:

- `dot_*` files become `~/.{filename}` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_config/*` files become `~/.config/*` (e.g., `private_config/nvim/` → `~/.config/nvim/`)

### Initial Setup

1. Run the bootstrap script:

   ```bash
   ./bootstrap/bootstrap.sh
   ```

   Or manually initialize chezmoi:

   ```bash
   ./scripts/chezmoi_init.sh
   ```

### Backing Up Changes

After making changes to your dotfiles (e.g., editing `~/.zshrc` or `~/.config/nvim/init.vim`), sync them back to this repository:

```bash
./scripts/chezmoi_backup.sh
```

The backup script will:

1. Show you what files have changed
2. Allow you to choose which files to backup
3. Update the repository with your changes
4. Optionally stage changes for git commit

### Workflow

1. **Edit files directly** in your home directory (e.g., `~/.zshrc`, `~/.config/nvim/init.vim`)
2. **Run backup script** to sync changes back: `./scripts/chezmoi_backup.sh`
3. **Review changes** shown by the script
4. **Commit to git** (the script can stage changes for you)

### Repository Structure

```
dot_files/
├── dot_zshrc              # ~/.zshrc
├── private_config/         # ~/.config/
│   ├── nvim/
│   ├── neofetch/
│   ├── powerlevel10k/
│   ├── iterm2/
│   ├── alacritty/
│   ├── kitty/
│   └── cava/
├── homebrew/
│   └── Brewfile
├── rice/                   # Wallpapers and screenshots
├── scripts/
│   ├── chezmoi_init.sh           # Initialize chezmoi
│   ├── chezmoi_backup.sh         # Backup changes
│   ├── chezmoi_migrate.sh        # Migrate to new device
│   ├── chezmoi_setup_encryption.sh  # Set up encryption
│   └── chezmoi_encrypt_secrets.sh   # Encrypt sensitive files
├── bootstrap/
│   └── bootstrap.sh         # Full system bootstrap
├── .chezmoi.toml           # Chezmoi configuration
└── .chezmoiignore          # Files to ignore when backing up
```

### Tracked Configurations

Currently tracked configurations:

- **Shell**: `.zshrc`
- **Terminal**: `alacritty`, `kitty`, `iterm2`
- **Editor**: `nvim`
- **Tools**: `neofetch`, `cava`
- **Theme**: `powerlevel10k`

To add additional configurations, use the backup script option 3:

```bash
./scripts/chezmoi_backup.sh
# Select option 3 and enter the path (e.g., ~/.config/gh)
```

**Note**: Sensitive configurations (API keys, credentials) are automatically excluded via `.chezmoiignore`. See [BACKUP_GUIDE.md](BACKUP_GUIDE.md) for instructions on encrypting and backing up sensitive files.

## Migration to New Device

**📖 For complete restoration instructions, see [RESTORATION_GUIDE.md](RESTORATION_GUIDE.md)**

This section provides a quick overview. The restoration guide includes detailed steps, troubleshooting, and verification procedures.

### Prerequisites

- Git installed
- Chezmoi installed (or use the bootstrap script)
- Access to this repository
- Encryption keys (if you've set up encrypted secrets)

### Step-by-Step Migration

#### Option 1: Using the Migration Script (Recommended)

1. Clone the repository:

   ```bash
   git clone <repository-url> ~/dot_files
   cd ~/dot_files
   ```

2. Run the migration script:

   ```bash
   ./scripts/chezmoi_migrate.sh
   ```

   The script will:

   - Check prerequisites
   - Initialize chezmoi
   - Apply all dotfiles
   - Prompt for encryption key restoration (if needed)
   - Verify installation

#### Option 2: Manual Migration

1. Clone the repository:

   ```bash
   git clone <repository-url> ~/dot_files
   cd ~/dot_files
   ```

2. Install chezmoi (if not already installed):

   ```bash
   brew install chezmoi  # macOS
   # or use your system's package manager
   ```

3. Initialize and apply dotfiles:

   ```bash
   ./scripts/chezmoi_init.sh
   ```

4. If you have encrypted secrets, restore your encryption keys:

   - For age: Copy your age key to `~/.config/age/keys.txt` or set `CHEZMOI_AGE_IDENTITY`
   - For GPG: Import your GPG key using `gpg --import`

5. Apply encrypted files:

   ```bash
   chezmoi apply --source="${HOME}/dot_files"
   ```

6. Verify installation:
   ```bash
   chezmoi verify --source="${HOME}/dot_files"
   ```

### Restoring Encrypted Secrets

If you've set up encryption (see Secrets Management section):

1. **Restore encryption keys:**

   - **Age**: Place your age private key in `~/.config/age/keys.txt` or set `CHEZMOI_AGE_IDENTITY` environment variable
   - **GPG**: Import your GPG private key: `gpg --import <your-key-file>`

2. **Apply encrypted files:**

   ```bash
   chezmoi apply --source="${HOME}/dot_files"
   ```

3. **Verify encrypted files are decrypted:**
   ```bash
   chezmoi verify --source="${HOME}/dot_files"
   ```

### Troubleshooting

- **Chezmoi not found**: Install it via Homebrew or your system's package manager
- **Permission denied**: Make scripts executable: `chmod +x scripts/*.sh`
- **Encrypted files not decrypting**: Verify your encryption keys are properly restored
- **Configs not applying**: Check that the source directory is correct: `chezmoi source-path`

## Secrets Management

### Overview

Chezmoi supports encrypting sensitive files using either **age** (recommended) or **GPG**. This allows you to safely store secrets like API keys, SSH keys, and credentials in your repository.

### Setting Up Encryption

#### Using Age (Recommended)

1. **Install age:**

   ```bash
   brew install age  # macOS
   ```

2. **Set up encryption:**

   ```bash
   ./scripts/chezmoi_setup_encryption.sh
   ```

   This will:

   - Generate an age key pair if needed
   - Test encryption/decryption
   - Provide instructions for backing up your key

3. **Backup your age key securely:**
   - Store in a password manager (1Password, Bitwarden, etc.)
   - Save to a secure USB drive
   - **Never commit the private key to the repository**

#### Using GPG

1. **Install GPG:**

   ```bash
   brew install gnupg  # macOS
   ```

2. **Generate a GPG key (if you don't have one):**

   ```bash
   gpg --full-generate-key
   ```

3. **Configure chezmoi to use GPG:**
   ```bash
   chezmoi config encryption gpg
   ```

### Encrypting Files

#### Using the Helper Script

```bash
./scripts/chezmoi_encrypt_secrets.sh
```

This interactive script will:

- List files that should be encrypted
- Show which files are already encrypted
- Help you encrypt new sensitive files

#### Manual Encryption

1. **Add a file to be encrypted:**

   ```bash
   chezmoi add --encrypt ~/.ssh/id_rsa
   ```

2. **Encrypt an existing tracked file:**
   ```bash
   chezmoi chattr +encrypted ~/.ssh/id_rsa
   ```

### Files That Should Be Encrypted

Common files that should be encrypted:

- SSH private keys (`~/.ssh/id_*`)
- API keys and tokens (`~/.config/gh/hosts.yml`, etc.)
- Credentials files (`~/.aws/credentials`)
- GPG private keys
- Any file containing sensitive information

**Note**: Files matching patterns in `.chezmoiignore` are excluded. If you want to back them up encrypted, remove them from `.chezmoiignore` and encrypt them instead.

### Backing Up Encryption Keys

**Critical**: Your encryption keys must be backed up separately from the repository.

**Recommended backup methods:**

1. **Password Manager**: Store keys in 1Password, Bitwarden, or similar
2. **Secure USB Drive**: Encrypted USB drive stored in a safe location
3. **Cloud Storage**: Encrypted cloud storage (with strong password)
4. **Paper Backup**: Print QR code or store in a safe (for age keys)

**For Age:**

- Backup: `~/.config/age/keys.txt` (private key)
- Or note the identity string from `age-keygen -o ~/.config/age/keys.txt`

**For GPG:**

- Export: `gpg --export-secret-keys --armor > gpg-backup.asc`
- Store the exported file securely

### Restoring Encrypted Files on New Device

1. Restore your encryption key (see "Restoring Encrypted Secrets" above)
2. Apply dotfiles: `chezmoi apply --source="${HOME}/dot_files"`
3. Encrypted files will be automatically decrypted

### Security Best Practices

- ✅ Use strong passphrases for encryption keys
- ✅ Backup encryption keys separately (never in the repository)
- ✅ Rotate keys periodically
- ✅ Use age for new setups (simpler than GPG)
- ✅ Document which files are encrypted
- ❌ Never commit encryption keys to the repository
- ❌ Never share encryption keys via insecure channels
- ❌ Don't use the same key for multiple purposes

<sub> Open Source LICENSED </sub>
