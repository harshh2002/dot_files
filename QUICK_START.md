# Quick Start: Complete Backup Workflow

## Complete Workflow (Start to Finish)

### Phase 1: Initial Setup (One-Time)

```bash
# 1. Initialize chezmoi
./scripts/chezmoi_init.sh

# 2. Set up encryption
./scripts/chezmoi_setup_encryption.sh
# ⚠️ CRITICAL: Backup your age key shown in the output!
# Location: ~/.config/age/keys.txt
```

### Phase 2: Configure What to Backup

```bash
# 3. Edit .chezmoiignore to decide what to encrypt vs ignore
# Remove lines for files you want to encrypt:
#   - **/.ssh/id_*          (if you want to backup SSH keys encrypted)
#   - **/.aws/credentials   (if you want to backup AWS creds encrypted)
# See .chezmoiignore for details
```

### Phase 3: First Backup

```bash
# 4. Encrypt sensitive files
./scripts/chezmoi_encrypt_secrets.sh
# Choose option 4: Encrypt all recommended files interactively

# 5. Add regular (non-sensitive) files
./scripts/chezmoi_backup.sh
# Choose option 1: All tracked files

# 6. Review changes
chezmoi diff --source="${HOME}/dot_files"
git status

# 7. Commit and push
git add -A
git commit -m "chore: initial backup with encryption"
git push
```

### Phase 4: Regular Backups (Daily/Weekly)

```bash
# Quick backup of all tracked files
./scripts/chezmoi_backup.sh
# Option 1: Re-add all tracked files
# Review, commit, push
```

## Order of Operations Summary

1. ✅ **Setup** → `chezmoi_init.sh` + `chezmoi_setup_encryption.sh`
2. ✅ **Backup encryption key** → Store `~/.config/age/keys.txt` securely
3. ✅ **Update .chezmoiignore** → Remove patterns for files to encrypt
4. ✅ **Encrypt secrets** → `chezmoi_encrypt_secrets.sh`
5. ✅ **Backup regular files** → `chezmoi_backup.sh`
6. ✅ **Review** → `chezmoi diff` + `git status`
7. ✅ **Commit** → `git add`, `git commit`, `git push`

## Files to Encrypt (Common)

- `~/.ssh/id_rsa` - SSH private key
- `~/.ssh/id_ed25519` - SSH Ed25519 key
- `~/.aws/credentials` - AWS credentials
- `~/.config/gh/hosts.yml` - GitHub CLI config (may contain tokens)

## Files to Always Ignore

- `~/.config/age/keys.txt` - Your encryption key (NEVER commit!)
- `**/configstore/**` - API keys
- `**/github-copilot/**` - GitHub tokens
- Cache and temporary files

## Troubleshooting

**Encryption not working?**
```bash
# Check config
cat .chezmoi.toml

# Test manually
echo "test" | chezmoi encrypt --age-recipient "age1..."
```

**File not being tracked?**
```bash
# Check if ignored
chezmoi check-ignore ~/.somefile --source="${HOME}/dot_files"

# Force add
chezmoi add --force --source="${HOME}/dot_files" ~/.somefile
```

For detailed instructions, see [BACKUP_GUIDE.md](BACKUP_GUIDE.md).

