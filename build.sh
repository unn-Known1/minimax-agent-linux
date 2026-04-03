#!/bin/bash
# MiniMax Agent Linux Build Script
# This script builds the .deb package from the source files

set -e

VERSION="3.0.13"
ARCH="amd64"
BUILD_DIR="linux-build"
OUTPUT_DIR="output"
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

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check for required tools
echo "[1/4] Checking build dependencies..."
MISSING_TOOLS=()
command -v dpkg-deb >/dev/null 2>&1 || MISSING_TOOLS+=("dpkg-dev")
command -v fakeroot >/dev/null 2>&1 || MISSING_TOOLS+=("fakeroot")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Missing tools: ${MISSING_TOOLS[*]}"
    echo "Install them with: sudo apt install ${MISSING_TOOLS[*]}"
    exit 1
fi

echo "  All dependencies satisfied."

# Clean previous builds
echo ""
echo "[2/4] Cleaning previous builds..."
rm -f "$OUTPUT_DIR/$PACKAGE_NAME"
rm -rf "$BUILD_DIR/DEBIAN/*.deb"

# Build the package
echo ""
echo "[3/4] Building package..."
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/$PACKAGE_NAME"

# Verify the package
echo ""
echo "[4/4] Verifying package..."
if [ -f "$OUTPUT_DIR/$PACKAGE_NAME" ]; then
    echo "  Package created successfully!"
    ls -lh "$OUTPUT_DIR/$PACKAGE_NAME"
    echo ""
    echo "  Install with: sudo dpkg -i $OUTPUT_DIR/$PACKAGE_NAME"
else
    echo "  Error: Package creation failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
