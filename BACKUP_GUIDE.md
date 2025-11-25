# Complete Backup Guide: Start to Finish

This guide walks you through the complete process of backing up all your dotfiles with encryption support.

## Prerequisites

- ✅ Chezmoi installed (`brew install chezmoi`)
- ✅ Age installed (`brew install age`) - for encryption
- ✅ Git repository initialized
- ✅ This dotfiles repository cloned

## Step-by-Step Process

### Step 1: Initial Setup (First Time Only)

#### 1.1 Initialize Chezmoi

```bash
./scripts/chezmoi_init.sh
```

This will:
- Initialize chezmoi if not already done
- Apply existing dotfiles from the repository to your home directory

#### 1.2 Set Up Encryption

```bash
./scripts/chezmoi_setup_encryption.sh
```

This will:
- Generate an age encryption key (if not exists)
- Configure chezmoi to use age encryption
- Test encryption
- **IMPORTANT**: Note your age public key and backup location

**Critical**: Backup your age private key immediately:
- Location: `~/.config/age/keys.txt`
- Store in: Password manager (1Password, Bitwarden), encrypted USB, or secure cloud storage
- **Never commit the private key to git!**

### Step 2: Review and Update .chezmoiignore

#### 2.1 Identify Files to Encrypt vs Ignore

Open `.chezmoiignore` and review the patterns. Files that should be **encrypted** instead of ignored:

**Currently ignored but should be encrypted:**
- `**/.ssh/id_*` - SSH private keys (if you want to back them up)
- `**/.aws/credentials` - AWS credentials (if you want to back them up)
- `**/.gcloud/**` - GCloud configs (if non-sensitive parts exist)

**Should remain ignored (too sensitive or auto-generated):**
- `**/configstore/**` - Usually contains API keys
- `**/github-copilot/**` - Contains tokens
- `**/firebase/**` - Contains credentials
- `**/.ssh/*_rsa` - Already covered by `id_*` pattern
- Cache and temporary files

#### 2.2 Update .chezmoiignore

Remove patterns for files you want to encrypt:

```bash
# Edit .chezmoiignore
# Remove or comment out lines for files you want to encrypt:
# **/.ssh/id_*          # Remove if you want to encrypt SSH keys
# **/.aws/credentials   # Remove if you want to encrypt AWS creds
```

**Example**: If you want to encrypt SSH keys, remove this line:
```
**/.ssh/id_*
```

### Step 3: Add and Encrypt Sensitive Files

#### 3.1 Use the Encryption Helper Script

```bash
./scripts/chezmoi_encrypt_secrets.sh
```

Choose option **4** (Encrypt all recommended files interactively) to:
- See which files should be encrypted
- Choose which ones to encrypt
- Automatically encrypt and add them to the repository

#### 3.2 Manual Encryption (Alternative)

For specific files:

```bash
# Encrypt and add a file
chezmoi add --encrypt --source="${HOME}/dot_files" ~/.ssh/id_rsa

# Or use the backup script option 3
./scripts/chezmoi_backup.sh
# Select option 3, enter file path
# Script will detect it's sensitive and offer to encrypt
```

### Step 4: Add Regular (Non-Sensitive) Files

#### 4.1 Add Standard Dotfiles

```bash
./scripts/chezmoi_backup.sh
```

Choose option **1** (All tracked files) to:
- Re-add all existing tracked files
- Update any that have changed

#### 4.2 Add New Configurations

```bash
./scripts/chezmoi_backup.sh
```

Choose option **3** (Add specific file/directory) to add:
- New config files you've created
- Updated configurations

**Examples:**
```bash
# Add a new config
./scripts/chezmoi_backup.sh
# Option 3
# Enter: ~/.config/gh

# Add multiple files
./scripts/chezmoi_backup.sh
# Option 2 (interactive mode)
```

### Step 5: Review Changes

#### 5.1 Check What Will Be Committed

```bash
# See all changes
chezmoi diff --source="${HOME}/dot_files"

# See git status
git status

# See encrypted files
find . -name "*.age" -o -name "*.encrypted" 2>/dev/null
```

#### 5.2 Verify Encrypted Files

Encrypted files will have `.age` extension in the repository:
- `private_dot_ssh_id_rsa.age` (encrypted SSH key)
- `private_dot_aws_credentials.age` (encrypted AWS creds)

### Step 6: Commit and Push

#### 6.1 Stage Changes

```bash
git add -A
```

#### 6.2 Review Staged Files

```bash
git status
```

**Verify:**
- ✅ Encrypted files (`.age` extension) are included
- ✅ Regular dotfiles are included
- ❌ Private keys (`~/.config/age/keys.txt`) are NOT included
- ❌ Sensitive unencrypted files are NOT included

#### 6.3 Commit

```bash
git commit -m "chore: backup dotfiles with encryption

- Added encrypted sensitive files
- Updated configurations
- Added new configs"
```

#### 6.4 Push to Remote

```bash
git push
```

### Step 7: Verify Backup

#### 7.1 Test on Another Machine (Optional)

```bash
# On new machine
git clone <your-repo-url> ~/dot_files
cd ~/dot_files
./scripts/chezmoi_migrate.sh
```

#### 7.2 Restore Encrypted Files

When prompted:
1. Restore your age key: Copy `~/.config/age/keys.txt` from backup
2. Apply dotfiles: `chezmoi apply --source="${HOME}/dot_files"`
3. Verify: Check that encrypted files are decrypted correctly

## Daily/Regular Backup Workflow

After initial setup, use this simplified workflow:

### Quick Backup (Regular Files)

```bash
./scripts/chezmoi_backup.sh
# Option 1: Re-add all tracked files
# Review changes
# Commit if needed
```

### Adding New Sensitive Files

```bash
./scripts/chezmoi_encrypt_secrets.sh
# Option 2 or 3: Encrypt specific file
# Then commit
```

### Adding New Regular Files

```bash
./scripts/chezmoi_backup.sh
# Option 3: Add specific file
# Script will detect if encryption is needed
```

## Complete Checklist

### Initial Setup
- [ ] Run `./scripts/chezmoi_init.sh`
- [ ] Run `./scripts/chezmoi_setup_encryption.sh`
- [ ] **Backup age private key** (`~/.config/age/keys.txt`)
- [ ] Store key in password manager/secure location

### Configuration
- [ ] Review `.chezmoiignore`
- [ ] Remove patterns for files you want to encrypt
- [ ] Update `.chezmoiignore` with comments

### First Backup
- [ ] Run `./scripts/chezmoi_encrypt_secrets.sh` (encrypt sensitive files)
- [ ] Run `./scripts/chezmoi_backup.sh` (add regular files)
- [ ] Review changes with `chezmoi diff`
- [ ] Verify encrypted files exist (`.age` extension)
- [ ] Commit and push

### Verification
- [ ] Test restore on another machine (optional)
- [ ] Verify encrypted files decrypt correctly
- [ ] Verify all configs are applied

## Troubleshooting

### Encryption Not Working

```bash
# Check encryption config
cat .chezmoi.toml | grep -A 2 encryption

# Test encryption manually
echo "test" | chezmoi encrypt --age-recipient "age1..."

# Verify age key exists
ls -la ~/.config/age/keys.txt
```

### Files Not Being Tracked

```bash
# Check if file is ignored
chezmoi check-ignore ~/.somefile --source="${HOME}/dot_files"

# Force add (if needed)
chezmoi add --force --source="${HOME}/dot_files" ~/.somefile
```

### Encrypted Files Not Decrypting

```bash
# Verify age key is in place
cat ~/.config/age/keys.txt

# Check encryption config
cat .chezmoi.toml

# Try manual decrypt
chezmoi decrypt <encrypted-file>
```

## Security Best Practices

1. **Never commit private keys**:
   - Age private key: `~/.config/age/keys.txt`
   - SSH private keys (unless encrypted)
   - API keys in plain text

2. **Always encrypt sensitive data**:
   - SSH keys
   - API credentials
   - Access tokens
   - Database passwords

3. **Backup encryption keys separately**:
   - Use password manager
   - Store in secure location
   - Never in the repository

4. **Regular key rotation**:
   - Rotate age keys periodically
   - Update encrypted files with new keys

5. **Review .chezmoiignore regularly**:
   - Ensure sensitive files are either ignored or encrypted
   - Don't accidentally commit secrets

## Quick Reference

```bash
# Setup (first time)
./scripts/chezmoi_init.sh
./scripts/chezmoi_setup_encryption.sh

# Encrypt sensitive files
./scripts/chezmoi_encrypt_secrets.sh

# Backup regular files
./scripts/chezmoi_backup.sh

# Migrate to new device
./scripts/chezmoi_migrate.sh

# Manual commands
chezmoi add --encrypt ~/.ssh/id_rsa
chezmoi diff
chezmoi apply
```

