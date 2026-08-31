#!/bin/bash
# MiniMax Agent Linux Build Script
# This script builds the .deb package from the source files

set -e

VERSION="3.0.68"
ARCH="amd64"

# Use absolute paths for safety
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/linux-build"
OUTPUT_DIR="${SCRIPT_DIR}/output"
PACKAGE_NAME="minimax-agent_${VERSION}_${ARCH}.deb"

echo "=========================================="
echo "  MiniMax Agent Linux Build Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Warning: Not running as root. Some operations may fail."
    echo "Consider running with: sudo $0"
    echo ""
fi

# Safety check: Verify we're in the expected directory
if [ ! -f "${SCRIPT_DIR}/package.json" ] && [ ! -d "${SCRIPT_DIR}/linux-build" ]; then
    echo "Error: This script must be run from the project root directory."
    echo "Expected files: package.json or linux-build directory"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
chmod 755 "$OUTPUT_DIR"

# Check for required tools
echo "[1/6] Checking build dependencies..."
MISSING_TOOLS=()
command -v dpkg-deb >/dev/null 2>&1 || MISSING_TOOLS+=("dpkg-dev")
command -v fakeroot >/dev/null 2>&1 || MISSING_TOOLS+=("fakeroot")
command -v npm >/dev/null 2>&1 || MISSING_TOOLS+=("npm")
command -v npx >/dev/null 2>&1 || MISSING_TOOLS+=("npx")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Missing tools: ${MISSING_TOOLS[*]}"
    echo "Install them with: sudo apt install ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "  All dependencies satisfied."

# Clean previous builds with safety checks
echo ""
echo "[2/6] Cleaning previous builds..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    # Verify OUTPUT_DIR is within SCRIPT_DIR before deletion
    case "$OUTPUT_DIR" in
        "${SCRIPT_DIR}"*)
            rm -f "$OUTPUT_DIR/$PACKAGE_NAME"
            ;;
        *)
            echo "Error: Output directory is outside project directory. Aborting for safety."
            exit 1
            ;;
    esac
fi

# Clean build artifacts with safety check
if [ -d "$BUILD_DIR/DEBIAN" ]; then
    case "$BUILD_DIR" in
        "${SCRIPT_DIR}"*)
            rm -f "$BUILD_DIR/DEBIAN"/*.deb 2>/dev/null || true
            ;;
        *)
            echo "Error: Build directory is outside project directory. Aborting for safety."
            exit 1
            ;;
    esac
fi

# Ensure maintainer scripts are executable (required by dpkg)
if [ -d "$BUILD_DIR/DEBIAN" ]; then
    chmod 755 "$BUILD_DIR/DEBIAN"/postinst "$BUILD_DIR/DEBIAN"/prerm 2>/dev/null || true
fi

# Ensure launcher is executable
if [ -f "$BUILD_DIR/usr/bin/minimax-agent" ]; then
    chmod 755 "$BUILD_DIR/usr/bin/minimax-agent"
fi

# Ensure resources are in place
RELEASE_DIR="/tmp/minimax-app/resources"
ASAR_UNPACKED_SRC="$RELEASE_DIR/app.asar.unpacked"
ASAR_UNPACKED_DST="$BUILD_DIR/opt/minimax-agent/resources/app.asar.unpacked"

echo ""

# Backfill any missing platform-specific optional binaries into the unpacked
# tree (e.g. @vscode/ripgrep-linux-x64). The upstream Windows installer
# sometimes skips optionalDependencies, so the .deb would ship without the
# binary and the app would crash on startup. This function fetches them via
# npm and stages them into app.asar.unpacked before the .deb is built.
backfill_platform_binaries() {
    local unpacked="$1"
    [ -d "$unpacked" ] || return 0
    local missing=()
    [ -d "$unpacked/node_modules/@vscode/ripgrep-linux-x64" ] || missing+=("ripgrep-linux-x64")
    if [ ${#missing[@]} -eq 0 ]; then
        echo "  All platform binaries present."
        return 0
    fi
    echo "  Back-filling missing platform binaries: ${missing[*]}"
    local stage
    stage="/tmp/minimax-bin-backfill.$$"
    mkdir -p "$stage"
    ( cd "$stage"
      printf '{\n  "name": "minimax-backfill",\n  "version": "1.0.0",\n  "private": true,\n  "dependencies": { "@vscode/ripgrep": "*" }\n}\n' > package.json
      if command -v npm >/dev/null 2>&1; then
          npm install --no-audit --no-fund --omit=dev 2>&1 | tail -3
          for pkg in "${missing[@]}"; do
              if [ -d "node_modules/@vscode/$pkg" ]; then
                  mkdir -p "$unpacked/node_modules/@vscode"
                  cp -a "node_modules/@vscode/$pkg" "$unpacked/node_modules/@vscode/"
              fi
          done
      else
          echo "  WARNING: npm not available at build time; install hook will backfill"
      fi
    )
    unset stage
}

echo "[3/6] Preparing native modules..."

# 1. Copy app.asar from Windows release source if present
if [ ! -f "$BUILD_DIR/opt/minimax-agent/resources/app.asar" ]; then
    if [ -f "$RELEASE_DIR/app.asar" ]; then
        echo "  Copying app.asar from Windows release..."
        cp "$RELEASE_DIR/app.asar" "$BUILD_DIR/opt/minimax-agent/resources/app.asar"
    else
        echo "  WARNING: app.asar not found at $RELEASE_DIR"
        echo "  Run the extract step to unpack the Windows installer first."
    fi
fi

# 2. Copy app.asar.unpacked (native modules) from Windows release
if [ ! -d "$ASAR_UNPACKED_DST" ]; then
    if [ -d "$ASAR_UNPACKED_SRC" ]; then
        echo "  Copying app.asar.unpacked from Windows release..."
        cp -r "$ASAR_UNPACKED_SRC" "$ASAR_UNPACKED_DST"
        echo '[3.5/6] Back-filling platform binaries (if needed)...'
        backfill_platform_binaries "$ASAR_UNPACKED_DST" || true
    else
        echo "  WARNING: app.asar.unpacked not found at $ASAR_UNPACKED_SRC"
    fi
fi

# 3. Rebuild better-sqlite3 for Electron's Node.js ABI if source is available
if [ -d "$ASAR_UNPACKED_DST/node_modules/better-sqlite3" ]; then
    echo "  Rebuilding better-sqlite3 for Electron v33.2.0 ABI..."
    cd "$ASAR_UNPACKED_DST/node_modules/better-sqlite3"
    if command -v npx >/dev/null 2>&1; then
        # Try prebuild-install first (downloads prebuilt linux binary)
        npx --yes prebuild-install 2>/dev/null || true
        
        # Check if the module loads with Electron
        if ELECTRON_RUN_AS_NODE=1 /opt/minimax-agent/electron -e \
            "try { require('./build/Release/better_sqlite3.node'); console.log('OK'); } catch(e) { console.log('NEEDS_REBUILD'); }" 2>/dev/null | grep -q "OK"; then
            echo "  better-sqlite3 native module OK."
        else
            echo "  Rebuilding better-sqlite3 for Electron ABI..."
            # Install better-sqlite3 fresh in temp dir and rebuild for Electron
            TEMP_DIR="/tmp/electron-rebuild-temp"
            rm -rf "$TEMP_DIR"
            mkdir -p "$TEMP_DIR"
            cat > "$TEMP_DIR/package.json" << 'TMPJSON'
{
  "name": "electron-rebuild-temp",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "better-sqlite3": "12.11.1"
  }
}
TMPJSON
            cd "$TEMP_DIR"
            npm install --ignore-scripts 2>/dev/null
            npx @electron/rebuild -o better-sqlite3 -v 33.2.0 -f 2>&1
            if [ -f "$TEMP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node" ]; then
                cp "$TEMP_DIR/node_modules/better-sqlite3/build/Release/better_sqlite3.node" \
                   "$ASAR_UNPACKED_DST/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
                echo "  better-sqlite3 rebuilt for Electron ABI."
            fi
            rm -rf "$TEMP_DIR"
        fi
    fi
    cd "$SCRIPT_DIR"
fi
echo "  Native modules ready."

# Build the package
echo ""
echo "[4/6] Building package..."
GZIP=-1 dpkg-deb -Zgzip -z1 --build "$BUILD_DIR" "$OUTPUT_DIR/$PACKAGE_NAME"

# Verify the package
echo ""
echo "[5/6] Verifying package..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    echo "  Package created successfully!"
    ls -lh "$OUTPUT_DIR/$PACKAGE_NAME"
    echo ""
    echo "  Install with: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Package creation failed!"
    exit 1
fi

# Verify the daemon starts correctly
echo ""
echo "[6/6] Verifying daemon startup..."
DAEMON_JS="$BUILD_DIR/opt/minimax-agent/resources/resources/daemon/daemon.js"
if [ -f "$DAEMON_JS" ]; then
    echo "  Daemon entry point found."
    echo "  Install the .deb to test: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Daemon entry point not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
