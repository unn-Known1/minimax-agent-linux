#!/bin/bash
# Download and install MiniMax Agent for Linux

set -e

VERSION="3.0.13"
DEB_FILE="minimax-agent_${VERSION}_amd64.deb"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo $0)"
    exit 1
fi

# Download the .deb file
if [ ! -f "$DEB_FILE" ]; then
    echo "Downloading MiniMax Agent $VERSION..."
    curl -L -o "$DEB_FILE" "https://github.com/unn-Known1/minimax-agent-linux/raw/main/releases/minimax-agent_3.0.13_amd64.deb"
fi

# Install the package
echo "Installing MiniMax Agent..."
dpkg -i "$DEB_FILE" || apt --fix-broken install -y

echo ""
echo "Installation complete!"
echo "Launch with: minimax-agent"