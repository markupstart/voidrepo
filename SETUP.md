# Initial Setup Instructions

## 1. Initialize Git Repository (if not done)

```bash
cd /home/mark/Projects/voidrepo
git init
git add .
git commit -m "Initial commit: Void Linux package repository setup"
```

## 2. Create GitHub Repository

**Option A: Using GitHub CLI**
```bash
# Install gh if needed
sudo xbps-install -y github-cli

# Login to GitHub
gh auth login

# Create repository
gh repo create voidrepo --public --source=. --remote=origin --push
```

**Option B: Using Web Interface**
1. Go to https://github.com/new
2. Create repository named `voidrepo`
3. Don't initialize with README (we already have one)
4. Add remote and push:
   ```bash
   git remote add origin https://github.com/YOURUSERNAME/voidrepo.git
   git branch -M main
   git push -u origin main
   ```

## 3. Set Up Git LFS (for large files)

```bash
# Install git-lfs
sudo xbps-install -y git-lfs

# Initialize in repository
cd /home/mark/Projects/voidrepo
git lfs install
git lfs track "*.xbps"
git add .gitattributes
git commit -m "Configure Git LFS for binary packages"
git push
```

## 4. Configure GitHub Actions Permissions

1. Go to your repository on GitHub
2. Settings → Actions → General
3. Under "Workflow permissions", select:
   - ✅ Read and write permissions
   - ✅ Allow GitHub Actions to create and approve pull requests
4. Save

## 5. Add Your Package Templates

```bash
# Move your existing ROCm packages to srcpkgs/
mv /path/to/your/rocm srcpkgs/
mv /path/to/your/rocm-llvm srcpkgs/

# Commit
git add srcpkgs/
git commit -m "Add ROCm packages"
git push
```

## 6. First Build

After pushing, GitHub Actions will automatically:
- Build all packages in `srcpkgs/`
- Create a release with built `.xbps` files
- Tag it as `latest` and with a date stamp

Check progress at: `https://github.com/YOURUSERNAME/voidrepo/actions`

## 7. Use on Other Machines

On any Void Linux machine:
```bash
# Clone the repo
git clone https://github.com/YOURUSERNAME/voidrepo.git
cd voidrepo

# Add as package source
./scripts/setup-repo.sh https://github.com/YOURUSERNAME/voidrepo/releases/download/latest

# Install packages
sudo xbps-install -S rocm rocm-llvm
```

## Notes

- Replace `YOURUSERNAME` with your GitHub username in all commands
- The GitHub Actions workflow requires write permissions to create releases
- Large binary files (built .xbps) are hosted on GitHub Releases, not in git
- Source templates are small and stored in git normally
