#!/bin/bash
# Setup script to download and prepare the binary files
# This script downloads the required Electron runtime for the Linux port

set -e

VERSION="3.0.68"
ELECTRON_VERSION="3.0.68"
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

# Pre-flight checks
echo ""
echo "[PRE-FLIGHT] Checking system requirements..."

SYSTEMD_AVAILABLE=false
if command -v systemctl >/dev/null 2>&1 && [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
    SYSTEMD_AVAILABLE=true
    echo "  [OK] systemd detected (PID 1)"
fi

SUDO_USER_NAME="${SUDO_USER:-$USER}"
if ! SYSTEMD_AVAILABLE; then
    echo "  [WARN] systemd is not the init system."
    echo "         The daemon service (auto-restart on crash) requires systemd."
    echo "         The app will still work, but the daemon won't auto-restart."
fi

if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version 2>/dev/null)
    echo "  [OK] Node.js found: $NODE_VERSION"
else
    echo "  [WARN] Node.js not found in PATH."
    echo "         Install Node.js (v18+) for daemon service support:"
    echo "           curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt install -y nodejs"
fi

# Create app directory structure
echo ""
echo "[1/7] Creating application directory..."
mkdir -p /opt/minimax-agent/resources/resources/daemon/agents
mkdir -p /opt/minimax-agent/resources/resources/daemon/internal-skills
mkdir -p /opt/minimax-agent/resources/resources/daemon/prompts
mkdir -p /opt/minimax-agent/resources/resources/daemon/skills
mkdir -p /opt/minimax-agent/resources/resources/matrix-mcp-cli
mkdir -p /opt/minimax-agent/resources/resources/opencode
mkdir -p /opt/minimax-agent/locales
mkdir -p /opt/minimax-agent/swiftshader
mkdir -p /var/cache/minimax-agent
echo "  Directory created."

# Download Electron if not present
echo ""
echo "[2/7] Downloading Electron runtime..."
if [ ! -f /var/cache/minimax-agent/electron.zip ]; then
    curl -L -o /var/cache/minimax-agent/electron.zip "$ELECTRON_URL"
fi
echo "  Download complete."

# Extract Electron
echo ""
echo "[3/7] Extracting Electron..."
cd /opt/minimax-agent
unzip -o /var/cache/minimax-agent/electron.zip
echo "  Extraction complete."

# Install daemon npm dependencies
echo ""
echo "[4/7] Installing daemon dependencies..."
if command -v npm >/dev/null 2>&1; then
    cd /opt/minimax-agent/resources/resources/daemon
    npm install --omit=dev 2>&1 && echo "  Daemon dependencies installed." || echo "  Warning: npm install failed. Run 'cd /opt/minimax-agent/resources/resources/daemon && npm install' manually."
    cd /opt/minimax-agent
else
    echo "  Warning: npm not found. Install Node.js then run:"
    echo "    cd /opt/minimax-agent/resources/resources/daemon && npm install"
fi

# Set permissions
echo ""
echo "[5/7] Setting permissions..."
chmod 755 /opt/minimax-agent/electron
chmod 4755 /opt/minimax-agent/chrome-sandbox 2>/dev/null || true
chmod 755 /opt/minimax-agent/resources/resources/opencode 2>/dev/null || true
echo "  Permissions set."

# Register protocol handlers
echo ""
echo "[6/7] Registering protocol handlers..."
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

# Build native modules for the daemon
echo ""
echo "[7/7] Building native modules..."
if command -v npm >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
    DAEMON_DIR="/opt/minimax-agent/resources/resources/daemon"
    if [ -d "$DAEMON_DIR/node_modules" ]; then
        echo "  Rebuilding native modules for Linux..."
        cd "$DAEMON_DIR"
        npm rebuild 2>&1 && echo "  Native modules rebuilt for Linux." || echo "  Warning: native modules rebuild failed."
        # Verify better-sqlite3 works
        node -e "require('better-sqlite3'); console.log('  better-sqlite3: OK')" 2>/dev/null && \
            echo "  SQLite module verified." || \
            echo "  WARNING: better-sqlite3 not available. Run: cd $DAEMON_DIR && npm rebuild"
        # Verify fs-native-extensions works
        node -e "require('fs-native-extensions'); console.log('  fs-native-extensions: OK')" 2>/dev/null || \
            echo "  WARNING: fs-native-extensions not available."
    fi
fi

# Fix broken symlink at ~/.mavis (from previous installations)
if [ -n "$SUDO_USER_NAME" ] && [ "$SUDO_USER_NAME" != "root" ]; then
    MAVIS_HOME=$(getent passwd "$SUDO_USER_NAME" 2>/dev/null | cut -d: -f6)
    if [ -n "$MAVIS_HOME" ]; then
        if [ -L "$MAVIS_HOME/.mavis" ] && [ ! -e "$MAVIS_HOME/.mavis" ]; then
            echo ""
            echo "[INFO] Fixing broken symlink at $MAVIS_HOME/.mavis..."
            rm -f "$MAVIS_HOME/.mavis" && echo "  [OK] Removed broken symlink." || echo "  [WARN] Could not remove broken symlink."
        fi
    fi
fi

# Enable systemd user lingering (prevents service installation failures)
if $SYSTEMD_AVAILABLE && [ -n "$SUDO_USER_NAME" ] && [ "$SUDO_USER_NAME" != "root" ]; then
    echo ""
    echo "[INFO] Enabling systemd user lingering for $SUDO_USER_NAME..."
    loginctl enable-linger "$SUDO_USER_NAME" 2>/dev/null && \
        echo "  [OK] Linger enabled. systemd --user services will work." || \
        echo "  [WARN] Could not enable linger. Run manually: loginctl enable-linger $SUDO_USER_NAME"
fi

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo ""
echo "  Note: You still need the opencode Linux binary:"
echo "  Place it at /opt/minimax-agent/resources/resources/opencode/opencode"
echo ""
echo "  If you have the .deb package installed, app.asar,"
echo "  daemon, and matrix-mcp-cli are already in place."
echo ""
if $SYSTEMD_AVAILABLE; then
    echo "  Troubleshooting if backend service fails to start:"
    echo "  1. Run as your user: systemctl --user status mavis.service"
    echo "  2. Check daemon logs: cat ~/.mavis/logs/daemon-spawn.log"
    echo "  3. Verify Node.js: node --version"
    echo "  4. Try manual service install: mavis service install"
    echo "  5. Check lingering: loginctl show-user \$USER | grep Linger"
fi
echo "=========================================="
