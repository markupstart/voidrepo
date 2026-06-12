#!/usr/bin/env bash
# Initialize the repository and push to GitHub

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "==> Void Linux Package Repository Initialization"
echo ""

# Check if git is initialized
if [ ! -d .git ]; then
    echo "==> Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: Void Linux package repository setup"
else
    echo "==> Git repository already initialized"
fi

# Check if GitHub CLI is available
if ! command -v gh &> /dev/null; then
    echo ""
    echo "GitHub CLI not found. Install with: sudo xbps-install -y github-cli"
    echo "Then run: gh auth login"
    echo ""
    read -p "Do you want to continue with manual setup? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    echo ""
    echo "Manual setup:"
    echo "1. Create repository at: https://github.com/new"
    echo "2. Run: git remote add origin https://github.com/YOURUSERNAME/voidrepo.git"
    echo "3. Run: git branch -M main"
    echo "4. Run: git push -u origin main"
    exit 0
fi

# Check if already authenticated
if ! gh auth status &> /dev/null; then
    echo "==> Please authenticate with GitHub..."
    gh auth login
fi

# Get GitHub username
GH_USER=$(gh api user -q .login)
echo "==> GitHub user: $GH_USER"

# Check if remote exists
if git remote | grep -q origin; then
    echo "==> Remote 'origin' already exists"
    REMOTE_URL=$(git remote get-url origin)
    echo "    URL: $REMOTE_URL"
else
    # Create GitHub repository
    echo ""
    read -p "Create GitHub repository 'voidrepo'? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "==> Creating GitHub repository..."
        gh repo create voidrepo --public --source=. --remote=origin
    else
        echo "Skipping repository creation"
        exit 0
    fi
fi

# Set up Git LFS
if command -v git-lfs &> /dev/null; then
    echo "==> Setting up Git LFS..."
    git lfs install
else
    echo ""
    echo "Warning: Git LFS not found. Install with: sudo xbps-install -y git-lfs"
    echo "This is recommended for large package files."
fi

# Push to GitHub
echo ""
read -p "Push to GitHub? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git branch -M main
    git push -u origin main
    
    echo ""
    echo "==> Setup complete!"
    echo ""
    echo "Repository: https://github.com/$GH_USER/voidrepo"
    echo ""
    echo "Next steps:"
    echo "1. Add your package templates to srcpkgs/"
    echo "2. Commit and push: git add srcpkgs/ && git commit -m 'Add packages' && git push"
    echo "3. GitHub Actions will automatically build and create releases"
    echo "4. Check Actions tab: https://github.com/$GH_USER/voidrepo/actions"
    echo ""
    echo "Update README.md to replace YOURUSERNAME with: $GH_USER"
fi
