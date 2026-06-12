#!/usr/bin/env bash
# Setup this repository as a package source on the local machine

set -e

REPO_URL="${1:-https://github.com/YOURUSERNAME/voidrepo/releases/latest/download}"

if [ -z "$1" ]; then
    echo "Usage: $0 <repository-url>"
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/yourusername/voidrepo/releases/latest/download"
    echo ""
    echo "This will configure your system to use this custom repository."
    exit 1
fi

CONF_FILE="/etc/xbps.d/10-voidrepo.conf"

echo "==> Adding custom repository: $REPO_URL"

# Create configuration
sudo tee "$CONF_FILE" > /dev/null <<EOF
# Custom Void Linux package repository
repository=$REPO_URL
EOF

echo "==> Configuration written to $CONF_FILE"
echo "==> Updating package index..."
sudo xbps-install -S

echo ""
echo "==> Setup complete!"
echo "==> You can now install custom packages with: xbps-install -S <package-name>"
