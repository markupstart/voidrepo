# Quick Reference

## 🚀 Initial Setup (One Time)

```bash
# Initialize and push to GitHub
./scripts/init-repo.sh

# Or manually:
gh auth login
gh repo create voidrepo --public --source=. --remote=origin --push
```

## 📦 Adding Packages

```bash
# Copy your package template to srcpkgs/
cp -r /path/to/your/package srcpkgs/

# Commit and push
git add srcpkgs/your-package
git commit -m "Add your-package"
git push

# GitHub Actions will automatically build!
```

## 🏗️ Building Locally

```bash
# One-time setup on new machine
./scripts/bootstrap.sh

# Build all packages
./scripts/build-all.sh

# Build specific package
cd void-packages
./xbps-src pkg package-name
```

## 💻 Installing on Machines

```bash
# Method 1: Use GitHub releases (recommended)
./scripts/setup-repo.sh https://github.com/YOURUSERNAME/voidrepo/releases/download/latest
sudo xbps-install -S package-name

# Method 2: Manual download and install
wget https://github.com/YOURUSERNAME/voidrepo/releases/download/latest/package-name.xbps
sudo xbps-install -y ./package-name.xbps

# Method 3: Local build
./scripts/build-all.sh
sudo xbps-install -y binpkgs/package-name-*.xbps
```

## 🔍 Common Tasks

### Check GitHub Actions Build Status
```bash
gh run list
gh run view
```

### Create Manual Release
```bash
./scripts/build-all.sh
gh release create v$(date +%Y.%m.%d) binpkgs/*.xbps -t "Release $(date +%Y-%m-%d)"
```

### Update void-packages
```bash
cd void-packages
git pull
./xbps-src binary-bootstrap
```

### Clean Build
```bash
cd void-packages
./xbps-src clean
./xbps-src zap
```

### List Installed Custom Packages
```bash
xbps-query -l | grep -f <(ls srcpkgs/)
```

## 🐛 Troubleshooting

### Build fails on GitHub Actions
```bash
# Check the logs
gh run view --log

# Test locally first
./scripts/bootstrap.sh
./scripts/build-all.sh
```

### Package not found on install
```bash
# Update package index
sudo xbps-install -S

# Verify repo is configured
cat /etc/xbps.d/10-voidrepo.conf

# Check what's in the release
gh release view latest
```

### Git LFS issues
```bash
# Install and setup LFS
sudo xbps-install -y git-lfs
git lfs install
git lfs track "*.xbps"
```

## 📊 Repository Status

```bash
# Check repository info
gh repo view

# List releases
gh release list

# View latest release
gh release view latest

# Check package index
xbps-query -R --repository=https://github.com/YOURUSERNAME/voidrepo/releases/download/latest -s .
```

## 🔧 Updating README URLs

After creating the GitHub repo, update placeholder URLs:
```bash
# Get your username
GH_USER=$(gh api user -q .login)

# Replace in README.md
sed -i "s/YOURUSERNAME/$GH_USER/g" README.md SETUP.md QUICKREF.md

# Commit
git add README.md SETUP.md QUICKREF.md
git commit -m "Update GitHub username in docs"
git push
```
