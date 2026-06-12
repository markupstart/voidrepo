#!/usr/bin/env bash
# Build all custom packages and copy to binpkgs directory

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOID_PACKAGES_DIR="${REPO_DIR}/void-packages"
BINPKGS_DIR="${REPO_DIR}/binpkgs"

if [ ! -d "$VOID_PACKAGES_DIR" ]; then
    echo "Error: void-packages not found. Run bootstrap.sh first."
    exit 1
fi

# Create binpkgs directory
mkdir -p "$BINPKGS_DIR"

# Get list of custom packages
PACKAGES=()
for pkg in "$REPO_DIR"/srcpkgs/*; do
    if [ -d "$pkg" ] && [ "$(basename "$pkg")" != ".gitkeep" ]; then
        PACKAGES+=($(basename "$pkg"))
    fi
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "No packages found in $REPO_DIR/srcpkgs/"
    exit 0
fi

echo "==> Building ${#PACKAGES[@]} package(s)..."
cd "$VOID_PACKAGES_DIR"

# Build each package
for pkg in "${PACKAGES[@]}"; do
    echo ""
    echo "==> Building: $pkg"
    ./xbps-src pkg "$pkg"
done

# Copy built packages to binpkgs directory
echo ""
echo "==> Copying packages to $BINPKGS_DIR..."

# Determine architecture
ARCH=$(xbps-uhelper arch)
HOSTDIR_BINPKGS="${VOID_PACKAGES_DIR}/hostdir/binpkgs"

for pkg in "${PACKAGES[@]}"; do
    # Find the built package (it will have version in filename)
    pkg_file=$(find "$HOSTDIR_BINPKGS" -name "${pkg}-*.${ARCH}.xbps" -type f | sort -V | tail -1)
    if [ -n "$pkg_file" ]; then
        cp -v "$pkg_file" "$BINPKGS_DIR/"
    else
        echo "Warning: Built package not found for $pkg"
    fi
done

# Create repository index
echo ""
echo "==> Creating repository index..."
cd "$BINPKGS_DIR"
xbps-rindex -a *.xbps 2>/dev/null || true

echo ""
echo "==> Build complete!"
echo "==> Packages available in: $BINPKGS_DIR"
echo ""
echo "To create a release:"
echo "  gh release create v\$(date +%Y.%m.%d) $BINPKGS_DIR/*.xbps -t 'Release \$(date +%Y-%m-%d)'"
