#!/bin/bash
# Setup script to download and prepare the binary files
# This script downloads the required Electron binaries for the Linux port

set -e

VERSION="3.0.13"
ELECTRON_VERSION="v33.2.0"
ELECTRON_URL="https://github.com/electron/electron/releases/download/${ELECTRON_VERSION}/electron-${ELECTRON_VERSION}-linux-x64.zip"

echo "=========================================="
echo "  MiniMax Agent Setup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Create app directory
echo "[1/5] Creating application directory..."
mkdir -p /opt/minimax-agent/resources
mkdir -p /opt/minimax-agent/locales
mkdir -p /opt/minimax-agent/swiftshader
mkdir -p /var/cache/minimax-agent
echo "  Directory created."

# Download Electron if not present
echo ""
echo "[2/5] Downloading Electron runtime..."
if [ ! -f /var/cache/minimax-agent/electron.zip ]; then
    curl -L -o /var/cache/minimax-agent/electron.zip "$ELECTRON_URL"
fi
echo "  Download complete."

# Extract Electron
echo ""
echo "[3/5] Extracting Electron..."
cd /opt/minimax-agent
unzip -o /var/cache/minimax-agent/electron.zip
mv electron "${APP_DIR:-/opt/minimax-agent}/electron" 2>/dev/null || true
echo "  Extraction complete."

# Set permissions
echo ""
echo "[4/5] Setting permissions..."
chmod 755 /opt/minimax-agent/electron
chmod 4755 /opt/minimax-agent/chrome-sandbox 2>/dev/null || true
echo "  Permissions set."

# Register protocol handlers
echo ""
echo "[5/5] Registering protocol handlers..."
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default minimax-agent.desktop x-scheme-handler/minimax 2>/dev/null || true
    xdg-mime default minimax-agent.desktop x-scheme-handler/minimax-agent 2>/dev/null || true
fi

# Update desktop database
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

# Update icon cache
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
fi

echo "  Protocol handlers registered."

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo ""
echo "  Note: You still need to place the app.asar file"
echo "  in /opt/minimax-agent/resources/"
echo ""
echo "  Get it from the Windows installer or extract from:"
echo "  https://github.com/unn-Known1/minimax-agent-linux/releases"
echo "=========================================="
