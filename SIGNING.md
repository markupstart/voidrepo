# Package Signing Implementation Plan

This document outlines the plan for implementing package signing for the voidrepo repository.

## Overview

Remote XBPS repositories **must** be signed. This plan implements RSA key-based signing for all packages built and distributed via GitHub Releases.

## Phase 1: Key Generation (One-time Setup)

### 1.1 Generate RSA Key Pair

Generate a 4096-bit RSA key in PEM format:

```bash
ssh-keygen -t rsa -b 4096 -m PEM -f ~/.ssh/voidrepo-signing.pem
```

**Important:** Do NOT set a passphrase (needed for CI automation)

Alternative using OpenSSL:
```bash
openssl genrsa -out ~/.ssh/voidrepo-signing.pem 4096
```

### 1.2 Extract Public Key

```bash
ssh-keygen -y -f ~/.ssh/voidrepo-signing.pem > voidrepo-signing.pub
```

### 1.3 Store Private Key in GitHub Secrets

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `XBPS_SIGNING_KEY`
4. Value: Paste entire contents of `~/.ssh/voidrepo-signing.pem`
5. Click "Add secret"

### 1.4 Commit Public Key to Repository

```bash
mkdir -p keys
cp voidrepo-signing.pub keys/
git add keys/voidrepo-signing.pub
git commit -m "Add package signing public key"
git push
```

## Phase 2: Update GitHub Actions Workflow

### 2.1 Add Signing Step

Add this step to `.github/workflows/build-packages.yml` after the "Build packages" step and before "Create repository index":

```yaml
      - name: Sign packages
        env:
          SIGNING_KEY: ${{ secrets.XBPS_SIGNING_KEY }}
        run: |
          cd "$VOID_PACKAGES_DIR"
          
          # Save private key to temporary file
          echo "$SIGNING_KEY" > /tmp/signing-key.pem
          chmod 600 /tmp/signing-key.pem
          
          # Sign repository metadata (initializes repository signature)
          xbps-rindex --privkey /tmp/signing-key.pem \
            --sign \
            --signedby "markupstart voidrepo" \
            "$GITHUB_WORKSPACE/binpkgs"
          
          # Sign all built packages
          xbps-rindex --privkey /tmp/signing-key.pem \
            --sign-pkg "$GITHUB_WORKSPACE/binpkgs"/*.xbps
          
          # Clean up private key
          shred -u /tmp/signing-key.pem
```

### 2.2 Update Repository Index Step

The "Create repository index" step should run AFTER signing:

```yaml
      - name: Create repository index
        run: |
          cd "$GITHUB_WORKSPACE/binpkgs"
          test -n "$(ls -1 *.xbps 2>/dev/null)" || { echo "No packages built"; exit 1; }
          # Index is already created by xbps-rindex --sign, just verify
          ls -lh *-repodata
```

## Phase 3: Update User Documentation

### 3.1 Update README.md Quick Start

Add step 3 after adding the repository:

```markdown
3. **Trust the repository signing key:**

   ```bash
   sudo mkdir -p /var/db/xbps/keys
   sudo wget -O /var/db/xbps/keys/voidrepo.plist \
     https://raw.githubusercontent.com/markupstart/voidrepo/main/keys/voidrepo-signing.pub
   ```

4. **Install packages:**

   ```bash
   sudo xbps-install -S your-package-name
   ```
```

### 3.2 Add Signing Section to README

Add a new section explaining signing:

```markdown
## 🔐 Package Signing

All packages in this repository are signed with an RSA key for security and authenticity.

### Verifying Package Signatures

Signatures are automatically verified by XBPS when you install the repository public key (see Quick Start).

To manually verify a package:

```bash
xbps-rindex --verify /path/to/package.xbps
```

### Public Key Location

The repository public key is available at:
- **URL:** https://raw.githubusercontent.com/markupstart/voidrepo/main/keys/voidrepo-signing.pub
- **Local:** `keys/voidrepo-signing.pub` in this repository
```

## Phase 4: Update Scripts

### 4.1 Update scripts/setup-repo.sh

Add automatic key installation:

```bash
#!/bin/bash
set -e

REPO_URL="${1:-https://github.com/markupstart/voidrepo/releases/download/latest}"
KEY_URL="https://raw.githubusercontent.com/markupstart/voidrepo/main/keys/voidrepo-signing.pub"

echo "=== Setting up voidrepo package repository ==="

# Create repo configuration
echo "Creating repository configuration..."
echo "repository=$REPO_URL" | sudo tee /etc/xbps.d/10-voidrepo.conf

# Install signing key
echo "Installing repository signing key..."
sudo mkdir -p /var/db/xbps/keys
sudo wget -q -O /var/db/xbps/keys/voidrepo.plist "$KEY_URL"

# Sync repository
echo "Syncing package index..."
sudo xbps-install -S

echo "✓ Repository configured and key installed!"
echo ""
echo "You can now install packages with:"
echo "  sudo xbps-install package-name"
```

### 4.2 Update scripts/build-all.sh

Add optional signing for local builds:

```bash
# After creating repository index
if [ -f ~/.ssh/voidrepo-signing.pem ]; then
  echo "=== Signing packages ==="
  xbps-rindex --privkey ~/.ssh/voidrepo-signing.pem \
    --sign --signedby "$(whoami) local build" \
    "$BINPKGS_DIR"
  
  xbps-rindex --privkey ~/.ssh/voidrepo-signing.pem \
    --sign-pkg "$BINPKGS_DIR"/*.xbps
  
  echo "✓ Packages signed"
else
  echo "⚠ Signing key not found at ~/.ssh/voidrepo-signing.pem"
  echo "  Packages will not be signed"
fi
```

## Phase 5: Testing

### 5.1 Local Testing

Test signing locally before implementing in CI:

```bash
# Build a package
cd void-packages
./xbps-src pkg rocm-cmake

# Copy to binpkgs
mkdir -p ../binpkgs
cp hostdir/binpkgs/*.xbps ../binpkgs/

# Sign repository
cd ..
xbps-rindex --privkey ~/.ssh/voidrepo-signing.pem \
  --sign --signedby "markupstart voidrepo" \
  binpkgs/

# Sign packages
xbps-rindex --privkey ~/.ssh/voidrepo-signing.pem \
  --sign-pkg binpkgs/*.xbps

# Verify signing worked
ls -l binpkgs/*-repodata
```

### 5.2 CI Testing

1. Implement Phase 2 changes
2. Push a small change to trigger build
3. Check Actions logs for signing output
4. Download artifacts and verify signatures

### 5.3 Installation Testing

On a test machine:

```bash
# Add repository and key
./scripts/setup-repo.sh

# Try installing a package
sudo xbps-install -S
sudo xbps-install rocm-cmake

# Verify it works
xbps-query -l | grep rocm
```

## Security Considerations

### ✅ Security Best Practices

- Private key stored in GitHub Secrets (encrypted at rest)
- Key only used in ephemeral CI environment
- shred used to securely delete temporary key file
- Public key distributed via version-controlled repository
- No passphrase needed for automation (acceptable for CI-only key)

### ⚠️ Security Notes

- **Key Compromise:** If private key is compromised, generate new key and rotate
- **Backup:** Keep secure local backup of private key
- **Access:** Only repository admins should have access to GitHub Secrets
- **Rotation:** Consider rotating key annually or after security incidents

### 🔒 Key Storage

**Private Key:**
- Primary: GitHub Secrets (for CI)
- Backup: Secure local storage (encrypted disk/vault)
- Do NOT: Commit to git, share via email, store in cloud unencrypted

**Public Key:**
- Git repository (`keys/voidrepo-signing.pub`)
- Distributed to users via HTTPS

## Implementation Checklist

- [ ] **Phase 1:** Generate keys
  - [ ] Generate RSA key pair
  - [ ] Extract public key
  - [ ] Add private key to GitHub Secrets
  - [ ] Commit public key to repository
  
- [ ] **Phase 2:** Update workflow
  - [ ] Add signing step to GitHub Actions
  - [ ] Update repository index step
  - [ ] Test CI build
  
- [ ] **Phase 3:** Update documentation
  - [ ] Update README Quick Start
  - [ ] Add Signing section to README
  
- [ ] **Phase 4:** Update scripts
  - [ ] Update setup-repo.sh
  - [ ] Update build-all.sh
  - [ ] Make scripts executable
  
- [ ] **Phase 5:** Testing
  - [ ] Test local signing
  - [ ] Test CI signing
  - [ ] Test package installation with signatures
  - [ ] Verify signature validation works

## Implementation Order

1. **Phase 1** - Generate and store keys
2. Test signing locally
3. **Phase 2** - Update GitHub Actions workflow
4. Test CI build and signing
5. **Phase 3** - Update documentation
6. **Phase 4** - Update helper scripts
7. **Phase 5** - End-to-end testing

## Reference

- [Void Linux - Signing Repositories](https://docs.voidlinux.org/xbps/repositories/signing.html)
- [xbps-rindex(1) Manual](https://man.voidlinux.org/xbps-rindex.1)
- [GitHub Actions Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
