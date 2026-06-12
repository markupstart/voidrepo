#!/usr/bin/env bash
# Bootstrap script for setting up void-packages on a new machine

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOID_PACKAGES_DIR="${REPO_DIR}/void-packages"

echo "==> Bootstrapping Void Linux package build environment..."

# Check if running on Void Linux
if [ ! -f /etc/os-release ] || ! grep -q "void" /etc/os-release; then
    echo "Warning: This script is designed for Void Linux"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install required dependencies
echo "==> Installing build dependencies..."
sudo xbps-install -Syu || true
sudo xbps-install -y base-devel git

# Clone void-packages if not present
if [ ! -d "$VOID_PACKAGES_DIR" ]; then
    echo "==> Cloning void-packages repository..."
    git clone --depth=1 https://github.com/void-linux/void-packages.git "$VOID_PACKAGES_DIR"
else
    echo "==> Updating void-packages repository..."
    cd "$VOID_PACKAGES_DIR"
    git pull
fi

cd "$VOID_PACKAGES_DIR"

# Bootstrap xbps-src
if [ ! -d "$VOID_PACKAGES_DIR/masterdir" ]; then
    echo "==> Bootstrapping xbps-src..."
    ./xbps-src binary-bootstrap
else
    echo "==> xbps-src already bootstrapped"
fi

# Link custom packages
echo "==> Linking custom packages..."
for pkg in "$REPO_DIR"/srcpkgs/*; do
    if [ -d "$pkg" ] && [ "$(basename "$pkg")" != ".gitkeep" ]; then
        pkg_name=$(basename "$pkg")
        if [ ! -e "$VOID_PACKAGES_DIR/srcpkgs/$pkg_name" ]; then
            ln -sf "$pkg" "$VOID_PACKAGES_DIR/srcpkgs/$pkg_name"
            echo "  Linked: $pkg_name"
        fi
    fi
done

echo ""
echo "==> Bootstrap complete!"
echo "==> void-packages location: $VOID_PACKAGES_DIR"
echo ""
echo "To build a package:"
echo "  cd $VOID_PACKAGES_DIR"
echo "  ./xbps-src pkg <package-name>"
echo ""
echo "Or use: $REPO_DIR/scripts/build-all.sh"
